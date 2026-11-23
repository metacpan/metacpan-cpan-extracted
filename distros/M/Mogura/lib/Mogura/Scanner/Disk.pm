package Mogura::Scanner::Disk;
use Mojo::Base -base;
use Mojo::JSON qw(decode_json);
use Mojo::File qw(path);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Cwd qw(abs_path);
use Fcntl qw(O_RDONLY O_NONBLOCK);
use Mogura::Scanner::Command;

# _IOR(0x12, 128, __u64) on x86_64 and aarch64, available since Linux 5.15.
use constant BLKGETDISKSEQ => 0x80081280;
use constant BIOS_BOOT_PARTITION_TYPE => '21686148-6449-6e6f-744e-656564454649';

has 'config';
has command => sub { Mogura::Scanner::Command->new };
has app_root => sub { abs_path(__FILE__) };
has sysfs_root => '/sys/dev/block';

sub device_number {
    my ($self, $file) = @_;
    die "Not a block device: $file" unless -b $file;

    # Linux dev_t stores the major/minor fields in separate bit ranges.
    my $device_id = (stat $file)[6];
    my $major = (($device_id >> 8) & 0xfff) | (($device_id >> 32) & 0xfffff000);
    my $minor = ($device_id & 0xff) | (($device_id >> 12) & 0xffffff00);
    return "$major:$minor";
}

sub mount_table {
    my ($self) = @_;

    my @mounts;
    for my $line (split /\n/, path('/proc/self/mountinfo')->slurp) {

        # Optional mount fields vary in length; the separator anchors the
        # filesystem fields without assuming a fixed number of columns.
        my ($mount_description, $filesystem_description) = split / - /, $line, 2;
        die 'Cannot parse mount table' unless defined $filesystem_description;
        my @mount_fields = split / /, $mount_description;
        my @filesystem_fields = split / /, $filesystem_description;

        # The kernel octal-escapes whitespace and backslashes in these paths.
        my ($root, $mountpoint, $source) = (@mount_fields[3, 4], $filesystem_fields[1]);
        for my $value ($root, $mountpoint, $source) {
            $value =~ s/\\([0-7]{3})/chr(oct($1))/ge;
        }
        push @mounts,
            {
            number => $mount_fields[2],
            root => $root,
            target => $mountpoint,
            source => $source,
            fstype => $filesystem_fields[0],
            options => "$mount_fields[5],$filesystem_fields[2]",
            };
    }
    return \@mounts;
}

sub inventory {
    my ($self) = @_;

    my ($nodes, $parents) = $self->_read_block_devices;
    my %busy;
    my @errors;

    # Host use is collected separately from supported guest layouts. A disk
    # must pass both checks before any of its partitions can be selected.
    $self->_read_sysfs($nodes, $parents, \%busy);
    for my $mount (@{$self->mount_table}) {
        $busy{$mount->{number}} = 'Mounted filesystem';
    }
    $self->_protect_scanner_storage($nodes, \%busy, \@errors);
    $self->_exclude_active_swap($nodes, \%busy);

    my $boot_id = path('/proc/sys/kernel/random/boot_id')->slurp;
    my $inventory = $self->classify($nodes, $parents, \%busy, \@errors, $boot_id);
    $inventory->{host} = $self->host_target;

    # Display the live root on its physical disks, including every backing
    # disk of LVM / RAID. This annotation never changes clone eligibility.
    my %root_devices;
    $self->_exclude_ancestors($inventory->{host}{identity}{partition}{'maj:min'},
        1, $parents, \%root_devices, {});
    for my $disk (@{$inventory->{disks}}) {
        $disk->{system_root} = $root_devices{$disk->{'maj:min'}} ? 1 : 0;
    }
    return $inventory;
}

sub host_target {
    my ($self) = @_;

    my ($root) = grep { $_->{target} eq '/' } @{$self->mount_table};
    die 'Cannot identify the running root filesystem' unless $root;
    my $identity = {
        kind => 'host',
        boot_id => path('/proc/sys/kernel/random/boot_id')->slurp,
        disk => {name => $root->{source}},
        partition => {name => '/', fstype => $root->{fstype}, 'maj:min' => $root->{number}},
    };
    return {
        kind => 'host',
        selectable => 1,
        identity => $identity,
        token => sha256_hex(JSON::PP->new->canonical->encode($identity)),
    };
}

sub host_exclusions {
    my ($self) = @_;

    # Limit live scans to the root filesystem and avoid scanning our own
    # growing output and virtual filesystems. Software in temporary or cache
    # directories is still evidence and must remain searchable.
    my %paths = map { $_ => 1 } (
        '/dev', '/proc', '/sys', '/run', $self->config->state,
        $self->config->runtime,
        map { $_->{target} } @{$self->mount_table},
    );
    delete $paths{'/'};
    return [sort keys %paths];
}

sub _read_block_devices {
    my ($self) = @_;

    my @columns = qw(
        NAME KNAME TYPE SIZE RO MAJ:MIN PKNAME FSTYPE UUID PARTUUID
        PTTYPE PARTTYPE SERIAL WWN MODEL MOUNTPOINTS
    );
    my $json = $self->command->run(
        [
            '/usr/bin/lsblk', '--json', '--bytes', '--paths',
            '--tree', '--output', join(',', @columns),
        ]
    );
    my $devices = decode_json($json)->{blockdevices};
    die 'Missing block device inventory' unless ref $devices eq 'ARRAY';

    my (%nodes, %parents);
    for my $device (@$devices) {
        $self->_index_device($device, undef, \%nodes, \%parents);
    }
    return (\%nodes, \%parents);
}

sub _index_device {
    my ($self, $device, $parent_number, $nodes, $parents) = @_;

    my $number = $device->{'maj:min'};
    die 'Unidentifiable block device' unless ($number // '') =~ /\A\d+:\d+\z/;
    $nodes->{$number} = {%$device};
    $parents->{$number}{$parent_number} = 1 if defined $parent_number;

    for my $child (@{$device->{children} // []}) {
        $self->_index_device($child, $number, $nodes, $parents);
    }
}

sub _read_sysfs {
    my ($self, $nodes, $parents, $busy) = @_;

    # lsblk supplies partition relationships; sysfs adds dependencies beneath
    # device-mapper and RAID so host LVM never conceals its physical disks.
    for my $number (keys %$nodes) {
        my $device_directory = path($self->sysfs_root, $number);
        die "Missing sysfs device $number" unless -d $device_directory;

        # Ubuntu 22.04's lsblk has no START column. sysfs exposes the same
        # offset in 512-byte sectors; missing partition geometry must fail closed.
        if ($nodes->{$number}{type} eq 'part') {
            my $start = $device_directory->child('start')->slurp;
            $start =~ s/\s+\z//;
            die "Invalid partition start for $number" unless $start =~ /\A\d+\z/;
            $nodes->{$number}{start} = 0 + $start;
        }

        for my $slave ($device_directory->child('slaves')->list->each) {
            my $backing_number = path($slave, 'dev')->slurp;
            chomp $backing_number;
            $parents->{$number}{$backing_number} = 1;
        }
        if ($device_directory->child('holders')->list->size) {
            $busy->{$number} = 'Referenced by device-mapper / RAID or another block device';
        }

        my $sequence_file = $device_directory->child('diskseq');
        my $sequence = -f $sequence_file ? $sequence_file->slurp : '';
        $sequence =~ s/\s+\z//;
        $nodes->{$number}{diskseq} = $sequence;
    }
}

sub _protect_scanner_storage {
    my ($self, $nodes, $busy, $errors) = @_;

    # Incomplete host topology must fail closed, even if no mounted device in
    # lsblk was recognized as belonging to the scanner.
    for my $protected_path ('/', $self->app_root, $self->config->state) {
        my $json = $self->command->run(
            [
                '/usr/bin/findmnt', '--json',
                '--target', $protected_path,
                '--output', 'MAJ:MIN,FSTYPE,SOURCE',
            ]
        );
        my $mount = decode_json($json)->{filesystems}[0];
        my $number = $mount->{'maj:min'} // '';
        if ($nodes->{$number}) {
            $busy->{$number} = "Scanner storage: $protected_path";
        }
        else {
            push @$errors, "Cannot resolve scanner storage: $protected_path";
        }
    }
}

sub _exclude_active_swap {
    my ($self, $nodes, $busy) = @_;

    my @swap_entries = split /\n/, path('/proc/swaps')->slurp;
    shift @swap_entries; # /proc/swaps begins with a column header.

    for my $entry (@swap_entries) {
        my ($file) = split /\s+/, $entry;
        $file =~ s/\\([0-7]{3})/chr(oct($1))/ge;

        my $number;
        if (-b $file) {
            $number = $self->device_number($file);
        }
        elsif (-f $file) {

            # A swap file protects the filesystem containing it, including
            # every physical ancestor of an LVM or RAID backing device.
            my $json = $self->command->run(
                ['/usr/bin/findmnt', '--json', '--target', $file, '--output', 'MAJ:MIN',]);
            $number = decode_json($json)->{filesystems}[0]{'maj:min'};
        }
        die 'Cannot identify active swap backing device' unless $number && $nodes->{$number};
        $busy->{$number} = 'Active swap';
    }
}

sub classify {
    my ($self, $nodes, $parents, $busy, $errors, $boot_id) = @_;

    my %excluded = %$busy;
    for my $number (keys %$busy) {
        $self->_exclude_ancestors($number, $busy->{$number}, $parents, \%excluded, {});
    }

    my @physical_disks = sort { $a->{name} cmp $b->{name} }
        grep { $_->{type} eq 'disk' } values %$nodes;
    my @disks;
    for my $disk (@physical_disks) {
        my $number = $disk->{'maj:min'};
        my @partitions = sort { ($a->{start} // 0) <=> ($b->{start} // 0) }
            grep { ($parents->{$_->{'maj:min'}} // {})->{$number} } values %$nodes;
        my $reasons = $self->_disk_exclusion_reasons($disk, \@partitions, \%excluded, $errors);

        # A filesystem may occupy either a partition or the complete disk.
        # Every candidate inherits exclusions affecting any part of its disk.
        my @filesystems = @partitions ? @partitions : ($disk);
        my @targets;
        for my $filesystem (@filesystems) {
            push @targets, $self->_build_target($disk, $filesystem, $reasons, $boot_id);
        }
        push @disks, {%$disk, targets => \@targets, reasons => $reasons};
    }
    return {updated_at => time, disks => \@disks, errors => $errors};
}

sub _exclude_ancestors {
    my ($self, $number, $reason, $parents, $excluded, $visited) = @_;

    return if $visited->{$number};
    $visited->{$number} = 1;
    $excluded->{$number} //= $reason;

    for my $parent (keys %{$parents->{$number} // {}}) {
        $self->_exclude_ancestors($parent, $reason, $parents, $excluded, $visited);
    }
}

sub _disk_exclusion_reasons {
    my ($self, $disk, $partitions, $excluded, $errors) = @_;

    my @reasons = @$errors;
    my $number = $disk->{'maj:min'};
    push @reasons, $excluded->{$number} if $excluded->{$number};

    my $hardware_id = ($disk->{serial} // '') || ($disk->{wwn} // '');
    my $has_sequence = ($disk->{diskseq} // '') =~ /\A\d+\z/;
    unless (length($hardware_id) && $has_sequence) {
        push @reasons, 'No hardware serial / WWN or kernel disk sequence';
    }

    if (@$partitions) {
        push @reasons, 'Unsupported partition table: ' . ($disk->{pttype} || '<empty>')
            unless ($disk->{pttype} // '') =~ /\A(?:gpt|dos)\z/;
        push @reasons, 'Ambiguous filesystem and partition table'
            if length($disk->{fstype} // '');
    }
    elsif (length($disk->{pttype} // '')) {
        push @reasons, 'Partition table present but no readable partitions';
    }

    for my $partition (@$partitions) {
        my $filesystem = $partition->{fstype} // '';
        my $is_efi =
            lc($partition->{parttype} // '') =~ /\A(?:c12a7328-f81f-11d2-ba4b-00a0c93ec93b|0xef)\z/;
        my $is_bios_boot_type = lc($partition->{parttype} // '') eq BIOS_BOOT_PARTITION_TYPE;
        my $supported =
            $is_bios_boot_type
            ? $self->_is_bios_boot_partition($disk, $partition)
            : $filesystem =~ /\A(?:ext4|xfs|swap)\z/ || ($is_efi && $filesystem eq 'vfat');
        unless ($partition->{type} eq 'part' && $supported) {
            my $details = join(', ',
                'PTTYPE=' . ($disk->{pttype} || '<empty>'),
                map { uc($_) . '=' . ($partition->{$_} || '<empty>') } qw(type parttype fstype));
            push @reasons, "Unsupported or unknown partition: $partition->{name} ($details)";
        }
        if ($excluded->{$partition->{'maj:min'}}) {
            push @reasons, "Referenced partition: $partition->{name}";
        }
    }
    return \@reasons;
}

sub _is_bios_boot_partition {
    my ($self, $disk, $partition) = @_;

    # GRUB stores bootloader data here without a filesystem. Only this exact
    # GPT layout may coexist with scan targets; host-use checks still apply.
    return
        ($disk->{pttype} // '') eq 'gpt'
        && ($partition->{type} // '') eq 'part'
        && lc($partition->{parttype} // '') eq BIOS_BOOT_PARTITION_TYPE
        && !length($partition->{fstype} // '');
}

sub _build_target {
    my ($self, $disk, $filesystem, $disk_reasons, $boot_id) = @_;

    my @reasons = @$disk_reasons;
    if ($self->_is_bios_boot_partition($disk, $filesystem)) {
        push @reasons, 'BIOS boot partition: bootloader only, not scanned';
    }
    elsif (($filesystem->{fstype} // '') !~ /\A(?:ext4|xfs)\z/) {
        push @reasons, 'Only ext4 / XFS root filesystems are supported';
    }

    # Serial/WWN identify the hardware; boot ID and disk sequence distinguish
    # attachments even when /dev names, partition UUIDs, and sizes are reused.
    my $identity = {
        boot_id => $boot_id,
        disk => {map { $_ => $disk->{$_} } qw(name maj:min size serial wwn diskseq pttype)},
        partition =>
            {map { $_ => $filesystem->{$_} } qw(name maj:min size start fstype uuid partuuid)},
    };
    my $canonical_identity = JSON::PP->new->canonical->encode($identity);
    return {
        %$filesystem,
        reasons => \@reasons,
        identity => $identity,
        token => sha256_hex($canonical_identity),
        selectable => @reasons ? 0 : 1,
    };
}

sub resolve {
    my ($self, $token) = @_;
    die 'Invalid target token' unless ($token // '') =~ /\A[0-9a-f]{64}\z/;
    my $host = $self->host_target;
    return $host if $host->{token} eq $token;

    my @matches;
    for my $disk (@{$self->inventory->{disks}}) {
        push @matches, grep { $_->{token} eq $token && $_->{selectable} } @{$disk->{targets}};
    }
    die 'Disk missing, replaced, busy, unsupported, or no longer identifiable' unless @matches == 1;
    my $target = $matches[0];
    for my $item ($target->{identity}{disk}, $target->{identity}{partition}) {
        die 'Device identity changed'
            unless $self->device_number($item->{name}) eq $item->{'maj:min'};
        sysopen my $handle, $item->{name}, O_RDONLY | O_NONBLOCK or die "Open verified device: $!";

        # Keep the device open throughout mounting. External commands resolve
        # these descriptors instead of a /dev name that hotplug can replace.
        my $descriptor = '/proc/' . $$ . '/fd/' . fileno($handle);
        die 'Opened device identity changed'
            unless $self->device_number($descriptor) eq $item->{'maj:min'};
        push @{$target->{handles}}, $handle;
    }
    $self->verify_sequence($target);
    return $target;
}

sub device_path {
    my ($self, $target, $index) = @_;
    my $handle = $target->{handles}[$index] or die 'Verified device descriptor unavailable';
    return '/proc/' . $$ . '/fd/' . fileno($handle);
}

sub verify_sequence {
    my ($self, $target) = @_;

    # Handle 0 is the whole disk; handle 1 is the selected filesystem. A
    # partition reports its parent disk's sequence, so both must still agree.
    for my $index (0, 1) {
        my $handle = $target->{handles}[$index] or die 'Verified device descriptor unavailable';
        my $actual = $self->_disk_sequence($handle);
        die 'Kernel disk sequence changed' unless $actual eq $target->{identity}{disk}{diskseq};
    }
}

sub _disk_sequence {
    my ($self, $handle) = @_;

    # Ubuntu 22.04's blockdev lacks --getdiskseq. Query the held descriptor
    # directly so hotplug cannot redirect this check to a replacement device.
    my $sequence = pack('Q', 0);
    ioctl($handle, BLKGETDISKSEQ, $sequence) or die "Read kernel disk sequence: $!";
    return unpack('Q', $sequence);
}

sub make_readonly {
    my ($self, $target) = @_;
    $self->verify_sequence($target);
    for my $index (0, 1) {
        my $device = $self->device_path($target, $index);
        $self->command->run(['/usr/sbin/blockdev', '--setro', $device]);
        my $result = $self->command->run(['/usr/sbin/blockdev', '--getro', $device]);
        die "Block read-only verification failed: $device" unless $result =~ /\A1\s*\z/;
    }

    # Re-enumeration catches replacements or new host use during setro.
    return $self->resolve($target->{token});
}

sub options {
    my ($self, $filesystem) = @_;

    # Read-only alone can still replay a journal or log. Suppress recovery
    # explicitly, without modifying UUIDs or repairing the guest filesystem.
    return 'ro,noload,nodev,nosuid,noexec' if $filesystem eq 'ext4';
    return 'ro,norecovery,nouuid,nodev,nosuid,noexec' if $filesystem eq 'xfs';
    die 'Unsupported filesystem';
}

sub mount {
    my ($self, $target, $mountpoint) = @_;
    $self->command->run(
        [
            '/usr/bin/mount', '--no-canonicalize',
            '-t', $target->{fstype},
            '-o', $self->options($target->{fstype}),
            '--', $self->device_path($target, 1),
            "$mountpoint"
        ]
    );
    $self->verify_mount($target, $mountpoint);
}

sub verify_mount {
    my ($self, $target, $mountpoint) = @_;

    # A successful mount command does not prove its source or options. Check
    # kernel-reported state before allowing a cataloger to read guest files.
    my @mounts = grep { $_->{target} eq "$mountpoint" } @{$self->mount_table};
    die 'Mount source verification failed'
        unless @mounts == 1
        && $mounts[0]{root} eq '/'
        && $mounts[0]{number} eq $target->{'maj:min'}
        && $mounts[0]{fstype} eq $target->{fstype};
    my %actual = map { $_ => 1 } split /,/, $mounts[0]{options};
    for my $required (split /,/, $self->options($target->{fstype})) {

        # The kernel reports ext4 noload as norecovery.
        next if $required eq 'noload' && $actual{norecovery};
        die "Missing mount safety option: $required" unless $actual{$required};
    }
    $self->verify_sequence($target);
    for my $index (0, 1) {
        my $value = $self->command->run(
            ['/usr/sbin/blockdev', '--getro', $self->device_path($target, $index)]);
        die 'Block device is no longer read-only' unless $value =~ /\A1\s*\z/;
    }
}

sub unmount {
    my ($self, $target, $mountpoint) = @_;

    # Never detach an unexpected filesystem that appeared at our mountpoint.
    # Only a normal unmount followed by absence in mountinfo counts as cleanup.
    my @mounts = grep { $_->{target} eq "$mountpoint" } @{$self->mount_table};
    return unless @mounts;
    die 'Refusing cleanup: unexpected mount source'
        unless @mounts == 1
        && $mounts[0]{number} eq $target->{'maj:min'};
    $self->command->run(['/usr/bin/umount', '--', "$mountpoint"]);
    die 'Mount remains after umount'
        if grep { $_->{target} eq "$mountpoint" } @{$self->mount_table};
}

1;

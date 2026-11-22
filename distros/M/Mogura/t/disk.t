use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use Mojo::File qw(path);
use Mojo::JSON qw(encode_json);
use lib 'lib';
use Mogura::Scanner::Config;
use Mogura::Scanner::Disk;

# Model a scanner root on LVM and a separate ext4 clone using device numbers,
# so parent traversal can be tested without reading the host device inventory.
my $disk = Mogura::Scanner::Disk->new(config => Mogura::Scanner::Config->new);
my %nodes = (
    '8:0' => {
        name => '/dev/sda',
        type => 'disk',
        'maj:min' => '8:0',
        size => 1000000,
        serial => 'scanner',
        diskseq => 1,
        pttype => 'gpt'
    },
    '8:1' => {name => '/dev/sda1', type => 'part', 'maj:min' => '8:1', fstype => 'LVM2_member'},
    '253:0' => {name => '/dev/dm-0', type => 'lvm', 'maj:min' => '253:0', fstype => 'ext4'},
    '8:16' => {
        name => '/dev/sdb',
        type => 'disk',
        'maj:min' => '8:16',
        size => 2000000,
        serial => 'clone-01',
        diskseq => 2,
        pttype => 'gpt'
    },
    '8:17' => {
        name => '/dev/sdb1',
        type => 'part',
        'maj:min' => '8:17',
        size => 1900000,
        fstype => 'ext4',
        uuid => 'same-fs-uuid',
        partuuid => 'part-1',
        start => 2048
    },
);
my %parents = ('8:1' => {'8:0' => 1}, '253:0' => {'8:1' => 1}, '8:17' => {'8:16' => 1});

# Exercise discovery with the columns available on Ubuntu 22.04 and real
# sysfs-shaped files, including offsets that differ from partition numbering.
{

    package InventoryCommand;
    use Mojo::Base -base;
    has 'json';

    sub run {
        my ($self, $arguments) = @_;
        die 'Unknown column START' if grep { /\bSTART\b/ } @$arguments;
        return $self->json;
    }
}
my $sysfs = path(tempdir(CLEANUP => 1));
for my $number ('8:16', '8:17', '8:18') {
    $sysfs->child($number, 'slaves')->make_path;
    $sysfs->child($number, 'holders')->make_path;
}
$sysfs->child('8:16', 'diskseq')->spurt("2\n");
$sysfs->child('8:17', 'start')->spurt("4096\n");
$sysfs->child('8:18', 'start')->spurt("2048\n");
my %partition = %{$nodes{'8:17'}};
delete $partition{start};
my $discovery_disk = Mogura::Scanner::Disk->new(
    sysfs_root => "$sysfs",
    command => InventoryCommand->new(
        json => encode_json(
            {
                blockdevices => [
                    {
                        %{$nodes{'8:16'}},
                        children => [
                            \%partition,
                            {
                                %partition,
                                name => '/dev/sdb2',
                                'maj:min' => '8:18',
                                partuuid => 'part-2'
                            },
                        ]
                    },
                ]
            }
        )
    ),
);
my ($discovered, $discovered_parents) = $discovery_disk->_read_block_devices;
$discovery_disk->_read_sysfs($discovered, $discovered_parents, {});
my $discovered_inventory =
    $discovery_disk->classify($discovered, $discovered_parents, {}, [], 'boot-1');
my $discovered_targets = $discovered_inventory->{disks}[0]{targets};
is_deeply(
    [map { $_->{name} } @$discovered_targets],
    ['/dev/sdb2', '/dev/sdb1'],
    'Partitions are ordered by sysfs start sector without the lsblk START column'
);
ok($discovered_targets->[0]{selectable}, 'A clone discovered without START remains selectable');
is($discovered_targets->[0]{identity}{partition}{start},
    2048, 'Partition identity retains the numeric start sector');
my $discovered_token = $discovered_targets->[0]{token};
$sysfs->child('8:18', 'start')->spurt("1024\n");
$discovery_disk->_read_sysfs($discovered, $discovered_parents, {});
isnt(
    $discovery_disk->classify($discovered, $discovered_parents, {}, [], 'boot-1')
        ->{disks}[0]{targets}[0]{token},
    $discovered_token,
    'A changed partition offset invalidates the selection token'
);
$sysfs->child('8:18', 'start')->spurt("invalid\n");
eval { $discovery_disk->_read_sysfs($discovered, $discovered_parents, {}) };
like($@, qr/Invalid partition start/, 'Malformed partition geometry fails closed');
unlink $sysfs->child('8:18', 'start') or die $!;
ok(!eval { $discovery_disk->_read_sysfs($discovered, $discovered_parents, {}); 1 },
    'Missing partition geometry fails closed');

sub classify {
    my ($busy_devices, $discovery_errors) = @_;
    return $disk->classify(
        \%nodes, \%parents,
        $busy_devices // {'253:0' => 'Scanner root on LVM'},
        $discovery_errors // [], 'boot-1',
    );
}
my $inventory = classify();
my ($host, $clone) = @{$inventory->{disks}};
ok(!$host->{targets}[0]{selectable}, 'LVM scanner root excludes the parent physical disk');
like(
    join(' ', @{$host->{reasons}}),
    qr/Scanner root/,
    'Host exclusion reason survives parent traversal'
);
ok($clone->{targets}[0]{selectable}, 'Independent ext4 clone can be selected');

# A BIOS boot partition may coexist with data but must never become a scan
# target or bypass disk-wide host-use and identity checks.
{
    local $nodes{'8:18'} = {
        name => '/dev/sdb2',
        type => 'part',
        'maj:min' => '8:18',
        parttype => '21686148-6449-6e6f-744e-656564454649',
        fstype => '',
        start => 34,
    };
    local $parents{'8:18'} = {'8:16' => 1};
    for my $filesystem ('ext4', 'xfs') {
        local $nodes{'8:17'}{fstype} = $filesystem;
        for my $empty ('', undef) {
            local $nodes{'8:18'}{fstype} = $empty;
            my $result = classify()->{disks}[1];
            is_deeply($result->{reasons}, [], 'BIOS boot does not exclude its disk');
            is_deeply([map { $_->{name} } grep { $_->{selectable} } @{$result->{targets}}],
                ['/dev/sdb1'], "Only the $filesystem filesystem is selectable alongside BIOS boot");
            like(
                join(' ', @{$result->{targets}[0]{reasons}}),
                qr/BIOS boot partition:.*not scanned/,
                'BIOS boot exclusion explains its purpose'
            );
        }
    }
    {
        local $nodes{'8:18'}{parttype} = uc $nodes{'8:18'}{parttype};
        ok(classify()->{disks}[1]{targets}[1]{selectable}, 'BIOS boot GUID is case insensitive');
    }
    for my $invalid (
        ['8:16', 'pttype', 'dos'],
        ['8:16', 'pttype', ''],
        ['8:18', 'parttype', ''],
        ['8:18', 'parttype', 'unknown'],
        ['8:18', 'type', 'lvm'],
        map { ['8:18', 'fstype', $_] } qw(ext4 xfs vfat swap crypto_LUKS)
        )
    {
        my ($number, $field, $value) = @$invalid;
        local $nodes{$number}{$field} = $value;
        my $result = classify()->{disks}[1];
        ok(!grep($_->{selectable}, @{$result->{targets}}),
            "Invalid BIOS boot layout ($field=$value) excludes the entire disk");
        like(
            join(' ', @{$result->{reasons}}),
            qr/Unsupported or unknown partition: \/dev\/sdb2 \(PTTYPE=.+, TYPE=.+, PARTTYPE=.+, FSTYPE=.+\)/,
            'Unsupported layout reports the device and all classification fields'
        );
    }
    for my $reason ('Mounted filesystem', 'Active swap', 'Referenced by device-mapper / RAID') {
        my $result = classify({'8:18' => $reason})->{disks}[1];
        ok(!grep($_->{selectable}, @{$result->{targets}}),
            "BIOS boot partition with $reason still excludes the entire disk");
    }
    {
        local $nodes{'8:16'}{serial} = '';
        ok(
            !classify()->{disks}[1]{targets}[1]{selectable},
            'BIOS boot allowance does not bypass disk identity checks'
        );
    }
    {
        local $parents{'8:17'} = {};
        ok(
            !grep($_->{selectable}, @{classify()->{disks}[1]{targets}}),
            'A disk containing only BIOS boot has no selectable targets'
        );
    }
}

# Match the NVMe layout with ext4, BIOS boot, and EFI system partitions.
# Device numbers, offsets, and hardware identity are synthetic test metadata.
{
    my %nvme_nodes = (
        '259:0' => {
            name => '/dev/nvme3n1',
            type => 'disk',
            'maj:min' => '259:0',
            pttype => 'gpt',
            serial => 'fixture-nvme',
            diskseq => 1,
        },
    );
    my %nvme_parents;
    for my $partition (
        [1, 'ext4', '0fc63daf-8483-4772-8e79-3d69d8477de4'],
        [14, '', '21686148-6449-6e6f-744e-656564454649'],
        [15, 'vfat', 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b'],
        )
    {
        my ($index, $fstype, $parttype) = @$partition;
        my $number = "259:$index";
        $nvme_nodes{$number} = {
            name => "/dev/nvme3n1p$index",
            type => 'part',
            'maj:min' => $number,
            pttype => 'gpt',
            fstype => $fstype,
            parttype => $parttype,
            start => $index * 2048,
        };
        $nvme_parents{$number} = {'259:0' => 1};
    }
    my $result = $disk->classify(\%nvme_nodes, \%nvme_parents, {}, [], 'boot-1')->{disks}[0];
    is_deeply($result->{reasons}, [], 'NVMe ext4, BIOS boot, and EFI layout is supported');
    is_deeply(
        [map { [$_->{name}, $_->{selectable}] } @{$result->{targets}}],
        [['/dev/nvme3n1p1', 1], ['/dev/nvme3n1p14', 0], ['/dev/nvme3n1p15', 0]],
        'Only the NVMe ext4 partition is selectable; BIOS boot and EFI are not scanned'
    );
}

# Reused names and UUIDs must not conceal reattachment or replacement.
my $token = $clone->{targets}[0]{token};
$nodes{'8:16'}{diskseq} = 3;
isnt(classify()->{disks}[1]{targets}[0]{token},
    $token, 'Reattachment changes token even with same path and UUID');
$nodes{'8:16'}{diskseq} = 2;
$nodes{'8:16'}{serial} = 'replacement';
isnt(classify()->{disks}[1]{targets}[0]{token}, $token, 'Replacement serial changes identity');
$nodes{'8:16'}{serial} = '';
ok(!classify()->{disks}[1]{targets}[0]{selectable}, 'Unidentifiable disk is rejected');
$nodes{'8:16'}{serial} = 'clone-01';

# Any host use excludes the entire disk; unknown guest layouts fail closed.
for my $reason ('Mounted filesystem', 'Active swap', 'Referenced by device-mapper / RAID') {
    ok(!classify({'8:17' => $reason})->{disks}[1]{targets}[0]{selectable},
        "$reason excludes entire disk");
}
for my $fs ('crypto_LUKS', 'LVM2_member', 'linux_raid_member', 'btrfs', 'zfs_member', 'ntfs', '') {
    local $nodes{'8:17'}{fstype} = $fs;
    ok(!classify()->{disks}[1]{targets}[0]{selectable}, "Unsupported filesystem '$fs' rejected");
}
ok(!classify({}, ['Unresolved host storage'])->{disks}[1]{targets}[0]{selectable},
    'Unknown host topology fails closed');
{
    local $nodes{'8:16'}{fstype} = 'xfs';
    local $nodes{'8:16'}{pttype} = '';
    local $parents{'8:17'} = {};
    ok(classify()->{disks}[1]{targets}[0]{selectable}, 'Whole-disk XFS is supported');
}
{

    package MissingDisk;
    use Mojo::Base 'Mogura::Scanner::Disk';
    sub inventory { return {disks => []} }
}
eval { MissingDisk->new->resolve($token) };
like($@, qr/missing, replaced/, 'Missing or swapped target cannot be resolved at execution time');
is($disk->options('ext4'), 'ro,noload,nodev,nosuid,noexec', 'ext4 disables journal replay');
is(
    $disk->options('xfs'),
    'ro,norecovery,nouuid,nodev,nosuid,noexec',
    'XFS disables recovery and UUID conflicts'
);

# Verify kernel mount state independently of the mount command's exit code.
{

    package ReadonlyCommand;
    use Mojo::Base -base;
    sub run { return "1\n" }

    package VerifiedDisk;
    use Mojo::Base 'Mogura::Scanner::Disk';
    has entries => sub { [] };
    sub mount_table { shift->entries }
    sub verify_sequence { return 1 }
    sub device_path { return '/dev/example' }
}
my $verified = VerifiedDisk->new(
    command => ReadonlyCommand->new,
    entries => [
        {
            target => '/example/mount',
            root => '/',
            number => '8:17',
            fstype => 'ext4',
            options => 'ro,norecovery,nodev,nosuid,noexec'
        }
    ]
);
my $target = {
    fstype => 'ext4',
    'maj:min' => '8:17',
    identity => {
        disk => {name => '/dev/example'},
        partition => {name => '/dev/example1'}
    }
};
ok(eval { $verified->verify_mount($target, '/example/mount'); 1 },
    'Actual kernel option aliases are accepted');
$verified->entries->[0]{options} = 'ro,nodev,nosuid,noexec';
eval { $verified->verify_mount($target, '/example/mount') };
like($@, qr/Missing mount safety option/,
    'Read-only mount without journal suppression is rejected');
$verified->entries->[0]{number} = '8:33';
eval { $verified->verify_mount($target, '/example/mount') };
like($@, qr/source verification/, 'A different actual mount source is rejected');
{

    package SequenceCommand;
    use Mojo::Base -base;
    has calls => sub { [] };

    sub run {
        my ($self, $arguments) = @_;
        push @{$self->calls}, $arguments->[1];
        return "999\n";
    }

    package SequenceDisk;
    use Mojo::Base 'Mogura::Scanner::Disk';
    has sequences => sub { [999] };
    has checked_handles => sub { [] };

    sub _disk_sequence {
        my ($self, $handle) = @_;
        push @{$self->checked_handles}, $handle;
        return shift @{$self->sequences};
    }
}
my $sequence_command = SequenceCommand->new;
my $sequence_disk = SequenceDisk->new(command => $sequence_command);
my $sequence_target = {identity => {disk => {diskseq => 2}}, handles => ['disk', 'partition']};
eval { $sequence_disk->make_readonly($sequence_target) };
like($@, qr/sequence changed/, 'Opened device with changed kernel sequence is rejected');
is_deeply($sequence_command->calls, [], 'A changed open device never reaches setro');
$sequence_disk->sequences([2, 999])->checked_handles([]);
eval { $sequence_disk->make_readonly($sequence_target) };
like($@, qr/sequence changed/, 'A changed partition descriptor is also rejected');
is_deeply(
    $sequence_disk->checked_handles,
    ['disk', 'partition'],
    'Sequence checks use both held descriptors'
);
is_deeply($sequence_command->calls, [], 'A changed partition never reaches setro');
$sequence_disk->sequences([2, 2]);
ok(
    eval { $sequence_disk->verify_sequence($sequence_target); 1 },
    'Matching disk and partition sequences pass verification'
);
my ($ordinary_file) = tempfile;
eval { $disk->_disk_sequence($ordinary_file) };
like($@, qr/Read kernel disk sequence/, 'An unsupported ioctl fails closed');
eval { $disk->verify_sequence({identity => {disk => {diskseq => 2}}}) };
like($@, qr/descriptor unavailable/, 'Sequence checks require held device descriptors');

# Live-host selection is independent of block-device support and never invokes
# a device command. Its token changes when the mounted root changes.
{

    package HostDisk;
    use Mojo::Base 'Mogura::Scanner::Disk';
    has root_number => '253:0';

    sub mount_table {
        my ($self) = @_;
        return [
            {
                target => '/',
                number => $self->root_number,
                source => '/dev/mapper/root',
                fstype => 'ext4'
            },
            {target => '/mnt/other', number => '8:17', source => '/dev/sdb1', fstype => 'ext4'},
        ];
    }
}
my $live_disk = HostDisk->new(config => Mogura::Scanner::Config->new);
my $live = $live_disk->host_target;
is($live_disk->resolve($live->{token})->{kind},
    'host', 'Mounted LVM root can be selected for live reading');
is($live->{identity}{partition}{name}, '/', 'Live target is fixed to the running root');
my $exclusions = $live_disk->host_exclusions;
ok(
    grep($_ eq '/var/lib/mogura-scanner', @$exclusions),
    'Live scan excludes its own generated results'
);
ok(grep($_ eq '/mnt/other', @$exclusions), 'Live scan excludes other mounts');
ok(!grep($_ eq '.' || $_ eq '/', @$exclusions), 'Live scan never excludes its root');

for my $keep ('/tmp', '**/.cache', '**/.git', '**/.rustup/tmp') {
    ok(!grep($_ eq $keep, @$exclusions), "$keep is not discarded by live scan policy");
}
$live_disk->root_number('253:1');
isnt($live_disk->host_target->{token},
    $live->{token}, 'Changing the mounted root invalidates host selection');

# Root-to-disk presentation follows the same topology as clone protection,
# while retaining the live target and its identity when no disk can be mapped.
{

    package InventoryDisk;
    use Mojo::Base 'HostDisk';
    sub _read_block_devices { return (\%nodes, \%parents) }
    sub _read_sysfs { return }
    sub _protect_scanner_storage { return }
    sub _exclude_active_swap { return }
}
my $inventory_disk = InventoryDisk->new(config => Mogura::Scanner::Config->new);
my $mapped = $inventory_disk->inventory;
is_deeply([map { $_->{name} } grep { $_->{system_root} } @{$mapped->{disks}}],
    ['/dev/sda'], 'LVM root is displayed on its physical backing disk');
is(
    $mapped->{host}{token},
    $inventory_disk->host_target->{token},
    'Presentation metadata does not change the live scan token'
);
{
    local $parents{'253:0'} = {'8:1' => 1, '8:17' => 1};
    is_deeply(
        [map { $_->{name} } grep { $_->{system_root} } @{$inventory_disk->inventory->{disks}}],
        ['/dev/sda', '/dev/sdb'],
        'A root spanning multiple disks marks every backing disk'
    );
}
$inventory_disk->root_number('8:16');
is_deeply([map { $_->{name} } grep { $_->{system_root} } @{$inventory_disk->inventory->{disks}}],
    ['/dev/sdb'], 'A whole-disk root is identified without a partition');
$inventory_disk->root_number('0:999');
$mapped = $inventory_disk->inventory;
ok(!grep($_->{system_root}, @{$mapped->{disks}}), 'Unknown root topology never guesses a disk');
ok($mapped->{host}{selectable}, 'Live scanning remains available without a physical disk mapping');
done_testing;

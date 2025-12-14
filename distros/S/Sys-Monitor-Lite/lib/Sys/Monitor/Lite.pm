package Sys::Monitor::Lite;
use strict;
use warnings;
use POSIX qw(uname);
use Time::HiRes qw(sleep);
use JSON::PP ();
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.07';

my %COLLECTORS = (
    system  => \&_system_info,
    cpu     => \&_cpu_usage,
    load    => \&_load_average,
    mem     => \&_memory_usage,
    disk    => \&_disk_usage,
    disk_io => \&_disk_io,
    mounts  => \&_mount_info,
    net     => \&_network_io,
    process => \&_process_list,
);

sub collect_all {
    my ($options) = @_;
    return collect(undef, $options);
}

sub collect {
    my ($which, $options) = @_;
    my @names;
    if (!defined $which) {
        @names = qw(system cpu load mem disk disk_io mounts net);
        if ($options && ref $options eq 'HASH' && exists $options->{process}) {
            push @names, 'process';
        }
    } elsif (ref $which eq 'ARRAY') {
        @names = @$which;
    } else {
        @names = @_;
    }

    my %data = (timestamp => _timestamp());
    my %collector_opts = ref $options eq 'HASH' ? %$options : ();
    for my $name (@names) {
        my $collector = $COLLECTORS{$name} or next;
        my $value = eval { $collector->($collector_opts{$name}) };
        next if $@;
        $data{$name} = $value;
    }
    return \%data;
}

sub _system_info {
    my @u = uname();
    my $uptime = _uptime_seconds();
    return {
        os           => $u[0],
        kernel       => $u[2],
        hostname     => $u[1],
        architecture => $u[4],
        uptime_sec   => $uptime,
    };
}

sub _cpu_usage {
    open my $fh, '<', '/proc/stat' or return {};
    my ($user, $nice, $system, $idle, $iowait) = (split /\s+/, (grep { /^cpu\s/ } <$fh>)[0])[1..5];
    close $fh;
    sleep 0.1;
    open $fh, '<', '/proc/stat' or return {};
    my ($u2, $n2, $s2, $i2, $w2) = (split /\s+/, (grep { /^cpu\s/ } <$fh>)[0])[1..5];
    close $fh;
    my $diff_total = ($u2+$n2+$s2+$i2+$w2) - ($user+$nice+$system+$idle+$iowait);
    my $diff_idle  = ($i2+$w2) - ($idle+$iowait);
    my $used_pct = _percent($diff_total - $diff_idle, $diff_total);
    return {
        cores     => _cpu_cores(),
        usage_pct => { total => $used_pct },
    };
}

sub _load_average {
    open my $fh, '<', '/proc/loadavg' or return {};
    my $line = <$fh> // '';
    close $fh;
    my ($l1, $l5, $l15) = (split /\s+/, $line)[0..2];
    return {
        '1min'  => _maybe_number($l1),
        '5min'  => _maybe_number($l5),
        '15min' => _maybe_number($l15),
    };
}

sub _memory_usage {
    open my $fh, '<', '/proc/meminfo' or return {};
    my %info;
    while (my $line = <$fh>) {
        next unless $line =~ /^(\w+):\s+(\d+)/;
        $info{$1} = $2 * 1024;
    }
    close $fh;

    my $total      = $info{MemTotal} // 0;
    my $available  = $info{MemAvailable} // ($info{MemFree} // 0);
    my $free       = $info{MemFree} // 0;
    my $buffers    = $info{Buffers} // 0;
    my $cached     = ($info{Cached} // 0) + ($info{SReclaimable} // 0);
    my $used       = $total - $available;
    my $swap_total = $info{SwapTotal} // 0;
    my $swap_free  = $info{SwapFree} // 0;
    my $swap_used  = $swap_total - $swap_free;

    return {
        total_bytes      => $total,
        available_bytes  => $available,
        used_bytes       => $used,
        free_bytes       => $free,
        buffers_bytes    => $buffers,
        cached_bytes     => $cached,
        used_pct         => _percent($used, $total),
        swap             => {
            total_bytes => $swap_total,
            used_bytes  => $swap_used,
            free_bytes  => $swap_free,
            used_pct    => _percent($swap_used, $swap_total),
        },
    };
}

sub _disk_usage {
    my $mounts = _mounted_filesystems();
    my %seen;
    my @disks;
    my $has_statvfs = POSIX->can('statvfs');
    my $df_stats    = _df_stats();

    for my $mount_info (@$mounts) {
        my $mount = $mount_info->{mount};
        next if $seen{$mount}++;
        next unless -d $mount;

        my ($total, $used, $free, $inode_total, $inode_used, $inode_free);
        if ($has_statvfs) {
            my @stat = eval { POSIX::statvfs($mount) };
            if (@stat) {
                my ($bsize, $frsize, $blocks, $bfree, $bavail, $files, $ffree) = @stat;
                $total       = $blocks * $frsize;
                $free        = $bavail * $frsize;
                $used        = $total - ($bfree * $frsize);
                $inode_total = _maybe_number($files);
                $inode_free  = _maybe_number($ffree);
                $inode_used  = defined $inode_total && defined $inode_free
                    ? $inode_total - $inode_free
                    : undef;
            }
        }

        if (!defined $total) {
            my $info = $df_stats->{$mount};
            if ($info) {
                $total = $info->{total};
                $used  = $info->{used};
                $free  = $info->{avail};
            }
        }

        push @disks, {
            mount           => $mount,
            filesystem      => $mount_info->{device},
            type            => $mount_info->{type},
            options         => $mount_info->{options},
            read_only       => $mount_info->{read_only},
            total_bytes     => $total,
            used_bytes      => $used,
            free_bytes      => $free,
            used_pct        => _percent($used, $total),
            inodes_total    => $inode_total,
            inodes_used     => $inode_used,
            inodes_free     => $inode_free,
            inodes_used_pct => _percent($inode_used, $inode_total),
        };
    }

    if (!@disks && $df_stats && %$df_stats) {
        for my $mount (sort keys %$df_stats) {
            next if $seen{$mount}++;
            my $info = $df_stats->{$mount};
            next unless $info->{total};
            push @disks, {
                mount        => $mount,
                filesystem   => $info->{filesystem},
                type         => $info->{type} // 'unknown',
                options      => [],
                read_only    => undef,
                total_bytes  => $info->{total},
                used_bytes   => $info->{used},
                free_bytes   => $info->{avail},
                used_pct     => _percent($info->{used}, $info->{total}),
                inodes_total    => undef,
                inodes_used     => undef,
                inodes_free     => undef,
                inodes_used_pct => undef,
            };
        }
    }

    return \@disks;
}

sub _mount_info {
    my $mounts = _mounted_filesystems();
    my %by_mount;

    for my $info (@$mounts) {
        my $key = _mount_key($info->{mount});
        next unless length $key;
        $by_mount{$key} = {
            present     => 1,
            mount       => $info->{mount},
            filesystem  => $info->{device},
            type        => $info->{type},
            options     => $info->{options},
            read_only   => $info->{read_only},
        };
    }

    return \%by_mount;
}

sub _disk_io {
    open my $fh, '<', '/proc/diskstats' or return [];
    my @devices;
    while (my $line = <$fh>) {
        chomp $line;
        my @fields = split /\s+/, $line;
        next unless @fields >= 14;
        my (
            $major,          $minor,          $name,
            $reads_completed, $reads_merged,   $sectors_read, $read_ms,
            $writes_completed,$writes_merged,  $sectors_written, $write_ms,
            $io_in_progress,  $io_ms,          $weighted_io_ms
        ) = @fields[0..13];

        next unless defined $name && length $name;
        next unless -r "/sys/block/$name/stat";

        my $sector_size = _sector_size($name);
        my $reads_sectors  = _maybe_number($sectors_read);
        my $writes_sectors = _maybe_number($sectors_written);
        my $reads_bytes    = defined $reads_sectors  ? $reads_sectors  * $sector_size : undef;
        my $writes_bytes   = defined $writes_sectors ? $writes_sectors * $sector_size : undef;

        push @devices, {
            device      => $name,
            major       => _maybe_number($major),
            minor       => _maybe_number($minor),
            sector_size => $sector_size,
            reads       => {
                ios     => _maybe_number($reads_completed),
                merged  => _maybe_number($reads_merged),
                sectors => $reads_sectors,
                bytes   => defined $reads_bytes ? 0 + $reads_bytes : undef,
                ms      => _maybe_number($read_ms),
            },
            writes      => {
                ios     => _maybe_number($writes_completed),
                merged  => _maybe_number($writes_merged),
                sectors => $writes_sectors,
                bytes   => defined $writes_bytes ? 0 + $writes_bytes : undef,
                ms      => _maybe_number($write_ms),
            },
            in_progress     => _maybe_number($io_in_progress),
            io_ms           => _maybe_number($io_ms),
            weighted_io_ms  => _maybe_number($weighted_io_ms),
        };
    }
    close $fh;
    return \@devices;
}

sub _network_io {
    open my $fh, '<', '/proc/net/dev' or return [];
    my @ifaces;
    while (my $line = <$fh>) {
        next if $line =~ /^(?:Inter| face)/;
        $line =~ s/^\s+//;
        my ($iface, @fields) = split /[:\s]+/, $line;
        next unless defined $iface;
        my ($rx_bytes, $rx_packets, undef, undef, undef, undef, undef, undef,
            $tx_bytes, $tx_packets) = @fields;
        push @ifaces, {
            iface      => $iface,
            rx_bytes   => _maybe_number($rx_bytes),
            rx_packets => _maybe_number($rx_packets),
            tx_bytes   => _maybe_number($tx_bytes),
            tx_packets => _maybe_number($tx_packets),
        };
    }
    close $fh;
    return \@ifaces;
}

sub _process_list {
    my ($opts) = @_;
    $opts ||= {};

    my $uptime    = _uptime_seconds();
    my $clk_tck   = POSIX::sysconf(&POSIX::_SC_CLK_TCK) || 100;
    my $page_size = POSIX::sysconf(&POSIX::_SC_PAGESIZE) || 4096;
    my $cores     = _cpu_cores() || 1;

    opendir my $dh, '/proc' or return [];
    my @pids = grep { /^\d+$/ } readdir $dh;
    closedir $dh;

    my @processes;
    for my $pid (@pids) {
        my $stat_path = "/proc/$pid/stat";
        my $cmd_path  = "/proc/$pid/cmdline";
        my $status_path = "/proc/$pid/status";
        next unless -r $stat_path;

        open my $sfh, '<', $stat_path or next;
        my $stat_line = <$sfh> // '';
        close $sfh;
        next unless $stat_line =~ /^(\d+)\s+\((.*)\)\s+(.+)$/;

        my ($parsed_pid, $comm, $rest) = ($1, $2, $3);
        my @fields = split /\s+/, $rest;
        next unless @fields >= 22;

        my $state      = $fields[0];
        my $ppid       = _maybe_number($fields[1]);
        my $utime      = _maybe_number($fields[11]);
        my $stime      = _maybe_number($fields[12]);
        my $starttime  = _maybe_number($fields[19]);
        my $rss_pages  = _maybe_number($fields[21]);
        my $threads    = _maybe_number($fields[16]);

        my $elapsed = defined $uptime && defined $starttime
            ? $uptime - ($starttime / $clk_tck)
            : undef;
        my $cpu_pct =
            defined $elapsed && $elapsed > 0 && defined $utime && defined $stime
            ? sprintf('%.1f', (($utime + $stime) / $clk_tck) / $elapsed * 100 / $cores)
            : 0;

        my $rss_bytes = defined $rss_pages ? $rss_pages * $page_size : undef;

        my $cmdline = '';
        if (open my $cfh, '<', $cmd_path) {
            local $/ = undef;
            my $raw = <$cfh> // '';
            close $cfh;
            $raw =~ s/\0/ /g;
            $cmdline = $raw;
            $cmdline =~ s/\s+$//;
        }

        my $uid;
        if (open my $stfh, '<', $status_path) {
            while (my $line = <$stfh>) {
                if ($line =~ /^Uid:\s+(\d+)/) {
                    $uid = _maybe_number($1);
                    last;
                }
            }
            close $stfh;
        }

        push @processes, {
            pid       => _maybe_number($parsed_pid),
            ppid      => $ppid,
            name      => $comm,
            command   => length($cmdline) ? $cmdline : $comm,
            state     => $state,
            threads   => $threads,
            uid       => $uid,
            cpu_pct   => _maybe_number($cpu_pct),
            rss_bytes => $rss_bytes,
        };
    }

    my @watch = map { lc $_ } @{ $opts->{watch} // [] };
    my $has_watch = @watch ? 1 : 0;

    my @selected;
    if ($has_watch) {
        push @selected, grep { _process_matches($_, \@watch) } @processes;
    }

    if (my $n = $opts->{top_cpu}) {
        push @selected, _top_processes(\@processes, 'cpu_pct', $n);
    }

    if (my $n = $opts->{top_rss}) {
        push @selected, _top_processes(\@processes, 'rss_bytes', $n);
    }

    if (!$has_watch && !$opts->{top_cpu} && !$opts->{top_rss}) {
        return \@processes;
    }

    my %seen;
    my @deduped;
    for my $proc (@selected) {
        next if $seen{ $proc->{pid} }++;
        push @deduped, $proc;
    }

    return \@deduped;
}

sub _top_processes {
    my ($processes, $field, $n) = @_;
    return () unless $processes && @$processes && $n && $field;
    my @sorted = sort { ($b->{$field} // 0) <=> ($a->{$field} // 0) } @$processes;
    my $limit = $n < @sorted ? $n : scalar @sorted;
    return @sorted[0 .. $limit - 1];
}

sub _process_matches {
    my ($proc, $watch) = @_;
    return 0 unless $proc && $watch && @$watch;
    my $name = lc($proc->{name} // '');
    my $cmd  = lc($proc->{command} // '');
    for my $needle (@$watch) {
        return 1 if index($name, $needle) >= 0;
        return 1 if index($cmd,  $needle) >= 0;
    }
    return 0;
}

sub _df_stats {
    open my $df, '-|', 'df', '-P', '-k' or return {};
    my %stats;
    my $header = <$df>;
    while (my $line = <$df>) {
        chomp $line;
        $line =~ s/^\s+//;
        my @fields = split /\s+/, $line;
        next unless @fields >= 6;
        my ($fs, $blocks, $used, $avail, undef, $mount) = @fields[0,1,2,3,4,5];
        my $total = _maybe_number($blocks);
        my $used_bytes = _maybe_number($used);
        my $avail_bytes = _maybe_number($avail);
        next unless defined $mount && defined $total && defined $used_bytes && defined $avail_bytes;
        $stats{$mount} = {
            filesystem => $fs,
            type       => 'unknown',
            total      => $total * 1024,
            used       => $used_bytes * 1024,
            avail      => $avail_bytes * 1024,
        };
    }
    close $df;
    return \%stats;
}

sub _mounted_filesystems {
    my %seen;
    my @mounts;

    if (open my $fh, '<', '/proc/mounts') {
        while (my $line = <$fh>) {
            my ($device, $mount, $type, $opts) = (split /\s+/, $line)[0..3];
            next if $seen{$mount}++;
            next if $mount =~ m{^/(?:proc|sys|dev|run|snap)};
            next if $type =~ /^(?:proc|sysfs|tmpfs|devtmpfs|cgroup.+|rpc_pipefs|overlay)$/;
            next unless defined $mount && length $mount;

            my @options = defined $opts && length $opts ? split(/,/, $opts) : ();
            my $read_only = grep { $_ eq 'ro' } @options ? 1 : 0;

            push @mounts, {
                device    => $device,
                mount     => $mount,
                type      => $type,
                options   => \@options,
                read_only => $read_only,
            };
        }
        close $fh;
    }

    return \@mounts;
}

sub _mount_key {
    my ($path) = @_;
    return '' unless defined $path && length $path;
    my $key = $path;
    $key =~ s{^/}{root_};
    $key =~ s{[^A-Za-z0-9_.]}{_}g;
    $key =~ s{_+}{_}g;
    $key =~ s{_\z}{};
    return $key;
}

sub to_json {
    my ($data, %opts) = @_;
    my $encoder = JSON::PP->new->canonical->ascii(0);
    if ($opts{pretty}) {
        $encoder = $encoder->pretty;
    }
    return $encoder->encode($data);
}

sub to_yaml {
    my ($data) = @_;
    my $yaml = _yaml_dump($data, 0);
    $yaml .= "\n" unless $yaml =~ /\n\z/;
    return $yaml;
}

sub to_prometheus {
    my ($data, %opts) = @_;
    return '' unless defined $data;

    my $prefix = _sanitize_prefix($opts{prefix});
    my %base_labels;
    if ($opts{labels} && ref $opts{labels} eq 'HASH') {
        for my $key (sort keys %{ $opts{labels} }) {
            my $label = _label_name($key);
            next unless length $label;
            $base_labels{$label} = $opts{labels}{$key};
        }
    }

    my $timestamp = $opts{timestamp} ? ($data->{timestamp} // _timestamp()) : undef;

    my @lines;
    my %type_declared;
    _prometheus_walk($data, [], \%base_labels, \@lines, {
        prefix         => $prefix,
        timestamp      => $timestamp,
        type_declared  => \%type_declared,
    });

    return join('', @lines);
}

sub _yaml_dump {
    my ($data, $indent) = @_;
    my $prefix = '  ' x $indent;

    if (!defined $data) {
        return $prefix . "null\n";
    }

    if (!ref $data) {
        return $prefix . _yaml_scalar($data) . "\n";
    }

    if (ref $data eq 'HASH') {
        my $out = '';
        for my $key (sort keys %$data) {
            my $value = $data->{$key};
            if (_yaml_is_simple($value)) {
                $out .= $prefix . $key . ': ' . _yaml_scalar($value) . "\n";
            } else {
                $out .= $prefix . "$key:\n" . _yaml_dump($value, $indent + 1);
            }
        }
        return $out eq '' ? $prefix . "{}\n" : $out;
    }

    if (ref $data eq 'ARRAY') {
        return $prefix . "[]\n" unless @$data;

        my $out = '';
        for my $value (@$data) {
            if (_yaml_is_simple($value)) {
                $out .= $prefix . '- ' . _yaml_scalar($value) . "\n";
            } else {
                $out .= $prefix . "-\n" . _yaml_dump($value, $indent + 1);
            }
        }
        return $out;
    }

    return $prefix . _yaml_scalar($data) . "\n";
}

sub _prometheus_walk {
    my ($value, $path, $labels, $output, $ctx) = @_;

    if (!ref $value) {
        _emit_prom_metric($path, $labels, $value, $output, $ctx);
        return;
    }

    if (ref $value eq 'HASH') {
        my %label_set = %$labels;
        if (@$path) {
            for my $key (sort keys %$value) {
                my $v = $value->{$key};
                if (!ref($v) && !looks_like_number($v)) {
                    my $label_name = _label_name($key);
                    $label_set{$label_name} = $v if length $label_name && defined $v && $v ne '';
                }
            }
        }

        for my $key (sort keys %$value) {
            my $v = $value->{$key};
            next if !ref($v) && !looks_like_number($v);
            _prometheus_walk($v, [@$path, $key], \%label_set, $output, $ctx);
        }
        return;
    }

    if (ref $value eq 'ARRAY') {
        for my $i (0 .. $#$value) {
            my %with_index = (%$labels, index => $i);
            _prometheus_walk($value->[$i], $path, \%with_index, $output, $ctx);
        }
        return;
    }
}

sub _emit_prom_metric {
    my ($path, $labels, $value, $output, $ctx) = @_;
    return unless defined $value && looks_like_number($value);
    return unless @$path;

    my $name = _metric_name($path, $ctx->{prefix});
    return unless length $name;

    if (!$ctx->{type_declared}{$name}++) {
        push @$output, "# TYPE $name gauge\n";
    }

    my $label_str = _format_prom_labels($labels);
    my $line      = $name . $label_str . ' ' . $value;
    if (defined $ctx->{timestamp}) {
        $line .= ' ' . $ctx->{timestamp};
    }
    push @$output, $line . "\n";
}

sub _format_prom_labels {
    my ($labels) = @_;
    return '' unless $labels && %$labels;

    my @pairs;
    for my $key (sort keys %$labels) {
        my $name = _label_name($key);
        next unless length $name;
        my $value = defined $labels->{$key} ? $labels->{$key} : '';
        my $escaped = $value;
        $escaped =~ s/\\/\\\\/g;
        $escaped =~ s/"/\\"/g;
        $escaped =~ s/\n/\\n/g;
        push @pairs, $name . '="' . $escaped . '"';
    }

    return '' unless @pairs;
    return '{' . join(',', @pairs) . '}';
}

sub _sanitize_prefix {
    my ($prefix) = @_;
    return '' unless defined $prefix && length $prefix;
    my $clean = _snake_case($prefix);
    return '' unless length $clean;
    $clean .= '_' unless $clean =~ /_\z/;
    return $clean;
}

sub _metric_name {
    my ($path, $prefix) = @_;
    my @parts = map { _snake_case($_) } @$path;
    @parts = grep { length } @parts;
    return '' unless @parts;

    my $name = join('_', @parts);
    $name = $prefix . $name if defined $prefix && length $prefix;
    $name = '_' . $name if $name !~ /^[A-Za-z_]/;
    return $name;
}

sub _label_name {
    my ($name) = @_;
    $name = _snake_case($name);
    return '' unless length $name;
    $name = '_' . $name if $name !~ /^[A-Za-z_]/;
    return $name;
}

sub _snake_case {
    my ($text) = @_;
    return '' unless defined $text && length $text;
    $text =~ s/([a-z0-9])([A-Z])/$1_$2/g;
    $text =~ s/[^A-Za-z0-9]+/_/g;
    $text = lc $text;
    $text =~ s/^_+//;
    $text =~ s/_+$//;
    $text =~ s/_+/_/g;
    return $text;
}

sub _yaml_is_simple {
    my ($value) = @_;
    return !ref($value);
}

sub _yaml_scalar {
    my ($value) = @_;

    return 'null' unless defined $value;

    if (looks_like_number($value) && $value !~ /^0[0-9]/) {
        return $value;
    }

    if ($value eq '') {
        return "''";
    }

    if ($value =~ /[\s#:>{}\[\],]|\A[-?]|\n/) {
        my $escaped = $value;
        $escaped =~ s/'/''/g;
        $escaped =~ s/\n/\\n/g;
        return "'$escaped'";
    }

    return $value;
}

sub _timestamp {
    my @t = gmtime();
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $t[5]+1900,$t[4]+1,@t[3,2,1,0]);
}

sub available_metrics {
    return sort keys %COLLECTORS;
}

sub metrics_from_thresholds {
    my ($warn, $crit) = @_;
    my %roots;
    for my $expr (@{ $warn // [] }, @{ $crit // [] }) {
        my $rule = _parse_threshold_expression($expr);
        next unless $rule->{parts} && @{ $rule->{parts} };
        $roots{ $rule->{parts}[0] } = 1;
    }
    return sort keys %roots;
}

sub evaluate_thresholds {
    my ($data, %opts) = @_;
    die "evaluate_thresholds requires a hash reference of data" unless ref $data eq 'HASH';

    my @warn_expr = @{ $opts{warn} // [] };
    my @crit_expr = @{ $opts{crit} // [] };

    my @rules;
    push @rules, map { _build_threshold_rule($_, 'warn') } @warn_expr;
    push @rules, map { _build_threshold_rule($_, 'crit') } @crit_expr;

    my %paths;
    for my $rule (@rules) {
        push @{ $paths{ $rule->{path} }{ $rule->{severity} } }, $rule;
        $paths{ $rule->{path} }{parts} = $rule->{parts};
    }

    my $status = 0;
    my @messages;
    for my $path (sort keys %paths) {
        my $info  = $paths{$path};
        my $value = _dig_value($data, $info->{parts});
        my $path_status = _evaluate_path_thresholds($value, $info);
        $status = $path_status if $path_status > $status;
        push @messages, _format_threshold_message($path, $value, $info);
    }

    my $label   = _status_label($status);
    my $message = @messages ? join(' ', $label . ' -', join('; ', @messages)) : $label;

    return {
        status  => $status,
        label   => $label,
        message => $message,
        details => \%paths,
    };
}

sub _build_threshold_rule {
    my ($expr, $severity) = @_;
    my $parsed = _parse_threshold_expression($expr);
    $parsed->{severity} = $severity;
    return $parsed;
}

sub _parse_threshold_expression {
    my ($expr) = @_;
    die "Invalid threshold expression" unless defined $expr;

    my ($path, $op, $value) = $expr =~ /^([A-Za-z0-9_\.]+)\s*(>=|<=|==|!=|>|<)\s*(.+)$/;
    die "Invalid threshold expression: $expr" unless defined $path && defined $op;

    $value = _maybe_number($value);
    my @parts = split /\./, $path;
    return { path => $path, op => $op, expect => $value, parts => \@parts };
}

sub _dig_value {
    my ($data, $parts) = @_;
    my $current = $data;
    for my $part (@$parts) {
        if (ref $current eq 'HASH' && exists $current->{$part}) {
            $current = $current->{$part};
            next;
        }
        if (ref $current eq 'ARRAY' && $part =~ /^\d+$/ && $part < @$current) {
            $current = $current->[$part];
            next;
        }
        return undef;
    }
    return $current;
}

sub _evaluate_path_thresholds {
    my ($value, $info) = @_;

    return 2 unless defined $value;

    for my $rule (@{ $info->{crit} // [] }) {
        return 2 if _threshold_matched($value, $rule);
    }
    for my $rule (@{ $info->{warn} // [] }) {
        return 1 if _threshold_matched($value, $rule);
    }
    return 0;
}

sub _threshold_matched {
    my ($value, $rule) = @_;

    return 0 unless defined $rule;
    my $expected = $rule->{expect};
    my $op       = $rule->{op};

    if (!defined $value) {
        return 0;
    }

    if ($op eq '>')  { return $value >  $expected }
    if ($op eq '>=') { return $value >= $expected }
    if ($op eq '<')  { return $value <  $expected }
    if ($op eq '<=') { return $value <= $expected }
    if ($op eq '==') { return $value == $expected }
    if ($op eq '!=') { return $value != $expected }
    return 0;
}

sub _format_threshold_message {
    my ($path, $value, $info) = @_;
    my $value_str = defined $value ? $value : 'N/A';

    my @parts;
    if (my $warn = $info->{warn}) {
        push @parts, map { _format_rule($_) } @$warn;
    }
    if (my $crit = $info->{crit}) {
        push @parts, map { _format_rule($_) } @$crit;
    }

    my $suffix = @parts ? '(' . join(' ', @parts) . ')' : '';
    return join('', $path, '=', $value_str, ' ', $suffix) =~ s/\s+\z//r;
}

sub _format_rule {
    my ($rule) = @_;
    return sprintf('%s%s', $rule->{op}, $rule->{expect});
}

sub _status_label {
    my ($status) = @_;
    return $status == 2 ? 'CRIT' : $status == 1 ? 'WARN' : 'OK';
}

sub _percent {
    my ($num, $den) = @_;
    return 0 unless defined $num && defined $den && $den;
    return sprintf('%.1f', ($num / $den) * 100);
}

sub _uptime_seconds {
    open my $fh, '<', '/proc/uptime' or return undef;
    my $line = <$fh> // '';
    close $fh;
    my ($uptime) = split /\s+/, $line;
    return _maybe_number($uptime);
}

sub _cpu_cores {
    my $count = 0;
    if (open my $fh, '<', '/proc/cpuinfo') {
        while (my $line = <$fh>) {
            $count++ if $line =~ /^processor\s*:\s*\d+/;
        }
        close $fh;
    }
    return $count || undef;
}

sub _maybe_number {
    my ($value) = @_;
    return undef unless defined $value;
    return looks_like_number($value) ? 0 + $value : $value;
}

sub _sector_size {
    my ($device) = @_;
    return 512 unless defined $device && length $device;
    my $path = "/sys/block/$device/queue/hw_sector_size";
    if (open my $fh, '<', $path) {
        my $size = <$fh>;
        close $fh;
        if (defined $size) {
            $size =~ s/\s+//g;
            return looks_like_number($size) ? 0 + $size : 512;
        }
    }
    return 512;
}

1;
__END__

=head1 NAME

Sys::Monitor::Lite - Lightweight system monitoring toolkit with JSON/YAML output

=head1 SYNOPSIS

  use Sys::Monitor::Lite qw(collect_all to_json);
  print Sys::Monitor::Lite::to_json(Sys::Monitor::Lite::collect_all());

=head1 DESCRIPTION

A minimal system monitor that outputs structured JSON, YAML, or
Prometheus text exposition for easy automation and integration with
jq-lite, yq, Prometheus scrape targets, or other
tools that consume structured logs.

=head1 FUNCTIONS

=head2 collect_all

    my $data = Sys::Monitor::Lite::collect_all();

Collects all available metrics and returns a hash reference keyed by
metric name. This is a convenience wrapper around L</collect> with no
arguments.

=head2 collect

    my $subset = Sys::Monitor::Lite::collect(['cpu', 'mem']);

Collects the metrics listed in the array reference (or list). Unknown
metrics are ignored. The returned value matches the structure of
L</collect_all> but contains only the requested keys.

=head2 available_metrics

    my @names = Sys::Monitor::Lite::available_metrics();

Returns a sorted list of metric names that the module can collect.

=head2 metrics_from_thresholds

    my @metrics = Sys::Monitor::Lite::metrics_from_thresholds(
        ['mem.used_pct>80'],
        ['load.1min>2'],
    );

Parses threshold expressions and returns the top-level metrics (e.g.
C<mem>, C<load>) that they reference. This is useful for preloading only
the data needed for threshold checks.

=head2 evaluate_thresholds

    my $result = Sys::Monitor::Lite::evaluate_thresholds(
        $data,
        warn => ['mem.used_pct>80'],
        crit => ['mem.used_pct>90'],
    );

Evaluates warning/critical threshold expressions against a collected
metrics hashref and returns a structure containing C<status> (0/1/2),
human-readable C<label>, and a formatted C<message> suitable for CLI
output.

=head2 to_json

    my $json = Sys::Monitor::Lite::to_json($data, pretty => 1);

Serialises the supplied data structure to a JSON string using
L<JSON::PP>. Pass C<pretty =E<gt> 1> to enable human-readable output.

=head2 to_yaml

    my $yaml = Sys::Monitor::Lite::to_yaml($data);

Serialises the supplied data structure to a YAML string using a
minimal built-in emitter.

=head2 to_prometheus

    my $text = Sys::Monitor::Lite::to_prometheus($data, prefix => 'sysmon_');

Serialises the supplied data structure into Prometheus exposition format,
converting keys to snake_case gauge metrics. Pass C<prefix> to prepend a
metric namespace (e.g. C<sysmon_>), C<labels> to include fixed labels, and
C<timestamp =E<gt> 1> to append the sample timestamp to each metric line.

=head1 EXPORT

This module does not export any symbols by default. Functions can be
called with their fully-qualified names, e.g. C<Sys::Monitor::Lite::collect_all()>.

=head1 AUTHOR

Shingo Kawamura E<lt>pannakoota1@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Shingo Kawamura.

This is free software; you can redistribute it and/or modify it under
the same terms as the MIT license included with this distribution.


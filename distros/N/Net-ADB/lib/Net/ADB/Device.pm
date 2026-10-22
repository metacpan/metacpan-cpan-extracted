package Net::ADB::Device;

use strict;
use warnings;
use utf8;
use v5.16;

use Carp;
use List::Util  qw(first);
use Socket      ();
use Time::Piece ();

use Net::ADB::Util qw(wantlist croak_unknown_params shell_quote);

our $VERSION  = '0.01';
our @CARP_NOT = qw(Net::ADB Net::ADB::Shell::Result Net::ADB::Util);

# TCP states taken from (include/net/tcp_states.h)
my %TCP_STATE = (
    '01' => 'ESTABLISHED',
    '02' => 'SYN_SENT',
    '03' => 'SYN_RECV',
    '04' => 'FIN_WAIT1',
    '05' => 'FIN_WAIT2',
    '06' => 'TIME_WAIT',
    '07' => 'CLOSE',
    '08' => 'CLOSE_WAIT',
    '09' => 'LAST_ACK',
    '0A' => 'LISTEN',
    '0B' => 'CLOSING',
    '0C' => 'NEW_SYN_RECV',
);

my %PACKAGE_FIELD = (
    uid           => [qr/^userId=(\d+)/,                                     \&_int],
    first_install => [qr/^firstInstallTime=(\S+\s\S+)/,                      sub { $_[0] }],
    timestamp     => [qr/^timeStamp=(\S+\s\S+)/,                             sub { $_[0] }],
    installer     => [qr/^installerPackageName=(\S+)/,                       sub { $_[0] }],
    last_update   => [qr/^lastUpdateTime=(\S+\s\S+)/,                        sub { $_[0] }],
    version_name  => [qr/^versionName=(\S+)/,                                sub { $_[0] }],
    version_code  => [qr/versionCode=(\d+)/,                                 \&_int],
    min_sdk       => [qr/minSdk=(\d+)/,                                      \&_int],
    target_sdk    => [qr/targetSdk=(\d+)/,                                   \&_int],
    splits        => [qr/^splits=\[(.*)\]/,                                  sub { [split /,\s/, $_[0]] }],
    data_dir      => [qr/^dataDir=(\S+)/,                                    sub { $_[0] }],
    path          => [qr/^codePath=(\S+)/,                                   sub { $_[0] }],
    flags         => [qr/^flags=\[ (.*) \]/,                                 sub { [split / /, $_[0]] }],
    private_flags => [qr/^privateFlags=\[ (.*) \]/,                          sub { [split / /, $_[0]] }],
    primary_abi   => [qr/^primaryCpuAbi=(\S+)/,                              \&_null_to_undef],
    secondary_abi => [qr/^secondaryCpuAbi=(\S+)/,                            \&_null_to_undef],
    shared_user   => [qr{^sharedUser=SharedUserSetting\{\S+\s([^/]+)/\d+\}}, sub { $_[0] }],
);

my @ENABLED_STATE = qw(default enabled disabled disabled_user disabled_until_used);

sub new {
    my ($class, %params) = @_;

    my $serial = delete $params{serial} or Carp::croak "Missing 'serial'";
    my $client = delete $params{client} or Carp::croak "Missing 'client'";

    my $self = {client => $client, serial => $serial};

    return bless $self, $class;
}

sub serial { shift->{serial} }

sub client { shift->{client} }

sub state {
    my $self = shift;
    return $self->{client}->state($self->_target);
}

sub features {
    my $self = shift;
    return $self->{client}->features($self->_target);
}

sub shell {
    my ($self, $command, %params) = @_;
    Carp::croak('Usage: $device->shell($command, %options)') if @_ % 2;
    return $self->{client}->shell_v2(%params, $self->_target, command => $command);
}


# Properties

sub getprop {
    my ($self, %params) = @_;

    delete $self->{properties} if delete $params{refresh};
    croak_unknown_params(\%params);

    return {%{$self->_props}};
}

sub _parse_getprop {
    my $output    = shift;
    my %properies = ();

    for my $line (split /\n/, $output) {
        my ($name, $value) = $line =~ /^\[(.*)\]: \[(.*)\]$/ or next;    # TODO multiple lines?
        $properies{$name} = $value;
    }

    return \%properies;
}

sub info {
    my $self = shift;

    my $product = sub {
        my $field = shift;
        return $self->_prop(map {"ro.product$_.$field"} '', '.vendor', '.system', '.odm');
    };

    my $abilist    = $self->_prop('ro.product.cpu.abilist');
    my $build_date = $self->_prop('ro.build.date.utc');

    return {
        manufacturer   => $product->('manufacturer'),
        brand          => $product->('brand'),
        model          => $product->('model'),
        marketname     => $self->_prop('ro.product.marketname', 'ro.product.vendor.marketname'),
        device         => $product->('device'),
        android        => $self->_prop('ro.build.version.release'),
        sdk            => ($self->_prop('ro.build.version.sdk') // 0) + 0,
        security_patch => $self->_prop('ro.build.version.security_patch'),
        build_id       => $self->_prop('ro.build.id'),
        build_type     => $self->_prop('ro.build.type'),
        build_date     => defined $build_date ? Time::Piece->gmtime($build_date)->datetime . 'Z' : undef,
        fingerprint    => $self->_prop('ro.build.fingerprint'),
        abi            => $self->_prop('ro.product.cpu.abi'),
        abilist        => [defined $abilist ? split /,/, $abilist : ()],
        platform       => $self->_prop('ro.soc.model', 'ro.board.platform'),
        hardware       => $self->_prop('ro.hardware'),
        serial         => $self->_prop('ro.serialno', 'ro.boot.serialno'),
        emulator       => ($self->_prop('ro.boot.qemu', 'ro.kernel.qemu') // 0) ? 1 : 0,
    };
}


# Settings

sub settings {
    my ($self, $namespace) = @_;

    Carp::croak('Usage: $device->settings($namespace)') unless defined $namespace && length $namespace;
    Carp::croak("Invalid namespace '$namespace' (global, secure, system)")
        unless $namespace =~ /^(global|secure|system)$/;

    return _parse_settings($self->shell("settings list $namespace")->assert_success->stdout);
}

sub _parse_settings {
    my $output   = shift;
    my %settings = ();

    for my $line (split /\n/, $output) {
        my ($key, $value) = split /=/, $line, 2;
        next unless defined $value;
        $settings{$key} = $value;
    }

    return \%settings;
}


# Dumpsys

sub dumpsys {
    my ($self, $service, @args) = @_;

    Carp::croak('Usage: $device->dumpsys($service, @args)') unless defined $service && length $service;

    my $cmd = join ' ', 'dumpsys', map { shell_quote($_) } $service, @args;
    my $res = $self->shell($cmd)->assert_success;

    if ($res->stderr =~ /Can't find service/) {
        chomp(my $error = $res->stderr);
        Carp::croak("dumpsys: $error");
    }

    return $res->stdout;
}

sub dumpsys_services {
    my $self = shift;
    my $cmd  = $self->shell('dumpsys -l')->assert_success;

    my @services = map { /^\s+(\S+)/ ? $1 : () } $cmd->stdout_lines;

    return wantlist(\@services);
}


# Kernel

sub kernel { _parse_kernel(shift->_read_file('/proc/version')) }

sub _parse_kernel {
    my $output = shift;

    chomp $output;

    my ($release) = $output =~ /^Linux\sversion\s(\S+)/x;

    # "4.19.127-perf-gec4113d5eb39" -> "4.19.127"
    my ($version) = defined $release ? $release =~ /^(\d+(?:\.\d+)+)/ : ();

    # "#1 SMP PREEMPT Tue Aug 27 16:16:01 CST 2024" (the time zone may be missing)
    my ($build_date) = $output =~ m{
        \#\d+ (?:\s+[A-Z_]+)*
        \s+ (\w{3} \s+ \w{3} \s+ \d+ \s+ [\d:]+ (?:\s+[A-Z]+)? \s+ \d{4})
        \s*$
    }x;

    return {version => $version, release => $release, build_date => $build_date, banner => $output};
}

sub uptime { _parse_uptime(shift->_read_file('/proc/uptime')) }

sub _parse_uptime {
    my $output = shift;

    my ($uptime, $idle) = $output =~ /^([\d.]+)\s+([\d.]+)/ or Carp::croak("Cannot parse uptime: $output");

    return {uptime => $uptime + 0, idle => $idle + 0};
}


# Security

sub security {
    my $self = shift;

    my $settings = eval { $self->settings('global') } // {};
    my $secure   = eval { $self->settings('secure') } // {};
    my $selinux  = eval { $self->selinux };

    my $locked = _bool($self->_prop('ro.boot.flash.locked'), '1', '0')
        // _bool($self->_prop('ro.boot.vbmeta.device_state'), 'locked', 'unlocked');

    my $sdk = $self->_prop('ro.build.version.sdk');

    my $adb_tcp_port
        = first { defined && /^\d+$/ && $_ > 0 } map { $self->_prop($_) } qw(service.adb.tcp.port persist.adb.tcp.port);

    return {
        security_patch    => $self->_prop('ro.build.version.security_patch'),
        verified_boot     => $self->_prop('ro.boot.verifiedbootstate'),
        bootloader_locked => $locked,
        debuggable        => _bool($self->_prop('ro.debuggable'), '1', '0'),
        secure            => _bool($self->_prop('ro.secure'),     '1', '0'),
        adb_secure        => _bool($self->_prop('ro.adb.secure'), '1', '0'),
        build_type        => $self->_prop('ro.build.type'),
        build_tags        => $self->_prop('ro.build.tags'),
        encryption        => $self->_prop('ro.crypto.state'),
        encryption_type   => $self->_prop('ro.crypto.type'),
        selinux           => $selinux,
        adb_enabled       => _bool($settings->{adb_enabled},                  '1', '0'),
        adb_wifi_enabled  => _bool($settings->{adb_wifi_enabled},             '1', '0'),
        developer_options => _bool($settings->{development_settings_enabled}, '1', '0'),
        adb_tcp_port      => defined $adb_tcp_port ? $adb_tcp_port + 0                                   : undef,
        unknown_sources   => $sdk && $sdk < 26     ? _bool($secure->{install_non_market_apps}, '1', '0') : undef,
        private_dns       => _setting($settings, 'private_dns_mode'),
        private_dns_host  => _setting($settings, 'private_dns_specifier'),
        always_on_vpn     => _setting($secure,   'always_on_vpn_app'),
    };
}

sub selinux {
    my $status = shift->shell('getenforce')->assert_success->stdout;
    chomp($status);
    return lc($status);
}

sub privileged_apps {
    my $self   = shift;
    my $secure = $self->settings('secure');

    # Lists of "package/class" components, separated by ":"
    my $components = sub { [split /:/, _setting($secure, shift) // ''] };

    return {
        accessibility_services => $components->('enabled_accessibility_services'),
        notification_listeners => $components->('enabled_notification_listeners'),
    };
}

sub install_sources {
    my $self = shift;
    my $cmd  = $self->shell('appops query-op REQUEST_INSTALL_PACKAGES allow')->assert_success;

    my @packages = grep {length} $cmd->stdout_lines;
    return wantlist(\@packages);
}


# Network

sub connections {
    my $self = shift;

    # Read and concatenate /proc/net/{tcp,tcp6,udp,udp6}
    my $cmd = join '; ', map {"echo '== $_ =='; cat /proc/net/$_"} qw(tcp tcp6 udp udp6);
    my $res = $self->shell($cmd);

    Carp::croak('Cannot read /proc/net: ' . $res->stderr) unless $res->stdout =~ /local_address/;

    return wantlist(_parse_connections($res->stdout));
}

sub listening {
    my $self = shift;

    # TCP sockets in LISTEN, UDP sockets bound to a port and not connected
    my @listening
        = grep { $_->{protocol} eq 'tcp' ? $_->{state} eq 'LISTEN' : $_->{state} eq 'CLOSE' && !$_->{remote_port} }
        $self->connections;

    return wantlist(\@listening);
}

sub _parse_connections {
    my $output  = shift;
    my $table   = undef;
    my %seen    = ();
    my @sockets = ();

    for my $line (split /\n/, $output) {

        if ($line =~ /^==\s(\w+)\s==$/) {
            $table = $1;
            next;
        }

        next unless defined $table;

        my ($local, $remote, $state, $tr_tx_queue, $timer, $retransmits, $uid, $inode, $more) = $line =~ m{
            ^\s*\d+:
            \s+([[:xdigit:]]+:[[:xdigit:]]{4})    # local_address:port
            \s+([[:xdigit:]]+:[[:xdigit:]]{4})    # remote_address:port
            \s+([[:xdigit:]]{2})                  # st(ate)
            \s+(\S+)\s+(\S)+\s+(\S)+              # tx_queue:rx_queue, timer, retransmits
            \s+(\d+)\s+(\d)+\s+(\d+)              # uid, timeout, inode
            \s+(.*)                               # more
        }x or next;

        # TODO Track SO_REUSEPORT ??
        next if $seen{"$table $local $remote $inode"}++;

        my ($local_address,  $local_port)  = _hex_to_address($local);
        my ($remote_address, $remote_port) = _hex_to_address($remote);

        my $connection = {
            protocol       => $table =~ /^tcp/ ? 'tcp' : 'udp',
            family         => $table =~ /6$/   ? 6     : 4,
            state          => $TCP_STATE{uc $state} // $state,
            local_address  => $local_address,
            local_port     => $local_port,
            remote_address => $remote_address,
            remote_port    => $remote_port,
            uid            => $uid + 0,
            inode          => $inode + 0,
        };
        push @sockets, $connection;
    }

    return \@sockets;
}


# Packages

sub packages {
    my ($self, %params) = @_;

    my $third_party = delete $params{third_party};
    my $system      = delete $params{system};

    croak_unknown_params(\%params);

    my $cmd = 'pm list packages -f -U -i --show-versioncode';
    $cmd .= ' -3' if $third_party;
    $cmd .= ' -s' if $system;

    my $packages = _parse_packages($self->shell($cmd)->assert_success->stdout);
    return wantlist($packages);
}

sub _parse_packages {
    my $output   = shift;
    my @packages = ();

    foreach my $line (split /\n/, $output) {

        # package:/path/of/package.apk=com.example.app  versionCode:1 installer=null uid:1000
        my ($path, $name, $version_code, $installer, $uid) = $line =~ m{
            ^package:(\S+)=(\S+)
            \s+versionCode:(\d+)
            \s+installer=(\S+)
            \s+uid:(\d+)$
        }x or next;

        my $package = {
            name         => $name,
            path         => $path,
            version_code => $version_code + 0,
            installer    => $installer eq 'null' ? undef : $installer,
            uid          => $uid + 0,
        };
        push @packages, $package;
    }

    return \@packages;
}

sub package_info {
    my ($self, $name) = @_;

    Carp::croak('Usage: $device->package_info($name)') unless defined $name && length $name;

    my $output = $self->dumpsys('package', $name);
    my $lines  = _indent_lines($output);

    my %info = (
        map({ $_ => undef } keys %PACKAGE_FIELD),
        system               => undef,
        updated_system       => undef,
        privileged           => undef,
        debuggable           => undef,
        allow_backup         => undef,
        persistent           => undef,
        legacy_storage       => undef,
        installed            => undef,
        hidden               => undef,
        suspended            => undef,
        stopped              => undef,
        not_launched         => undef,
        enabled              => undef,
        enabled_state        => undef,
        permissions          => {},
        declared_permissions => {},
    );

    for my $item (@{$lines}) {

        if ($item->[0] eq 'Packages:' && @{$item} > 1 && $item->[1] =~ /^Package \[(\Q$name\E)\]/) {

            $info{name} = $1;

            for my $key (keys %PACKAGE_FIELD) {
                my ($regex, $callback) = @{$PACKAGE_FIELD{$key}};
                if (!defined $info{$key} && $item->[-1] =~ $regex) {
                    $info{$key} = $callback->($1);
                }
            }

            if (@{$item} == 4 && $item->[2] =~ /^(requested|install|declared) permissions:$/) {
                my $section = $1;

                if ($section eq 'declared') {
                    my ($perm, $fields) = split /:\s*/, $item->[-1], 2;
                    my %fields = _kv($fields);
                    my $p      = $info{declared_permissions}{$perm} = {protection => [], installed => undef};
                    $p->{protection} = [split /\|/, $fields{prot} // ''];
                    $p->{installed}  = $fields{INSTALLED} ? 1 : 0;
                }
                else {
                    _permission($info{permissions}, $section, $item->[-1]);
                }

            }

            if (@{$item} == 3 && $item->[2] =~ /^User 0:\s*(.*)$/) {
                my %user = $1 =~ /(\w+)=(\S+)/g;

                $info{installed}     = _bool($user{installed},   'true', 'false');
                $info{hidden}        = _bool($user{hidden},      'true', 'false');
                $info{suspended}     = _bool($user{suspended},   'true', 'false');
                $info{stopped}       = _bool($user{stopped},     'true', 'false');
                $info{not_launched}  = _bool($user{notLaunched}, 'true', 'false');
                $info{enabled}       = defined $user{enabled} ? $user{enabled} + 0 : undef;
                $info{enabled_state} = (defined $info{enabled} ? $ENABLED_STATE[$user{enabled}] : undef);
            }

            if (@{$item} == 5 && $item->[2] =~ /^User 0:/ && $item->[3] eq 'runtime permissions:') {
                _permission($info{permissions}, 'runtime', $item->[-1]);
            }

        }

        if (   $item->[0] eq 'Shared users:'
            && defined $info{shared_user}
            && @{$item} == 5
            && $item->[1] =~ /^SharedUser \[\Q$info{shared_user}\E\]/
            && $item->[2] =~ /^User 0:/
            && $item->[3] eq 'runtime permissions:')
        {
            _permission($info{permissions}, 'runtime', $item->[-1]);
        }
    }

    Carp::croak("Package not found: $name") unless defined $info{name};

    my %flag = map { $_ => 1 } @{$info{flags}}, @{$info{private_flags}};

    $info{system}         = $flag{SYSTEM}                                       ? 1 : 0;
    $info{updated_system} = $flag{UPDATED_SYSTEM_APP}                           ? 1 : 0;
    $info{privileged}     = $flag{PRIVILEGED}                                   ? 1 : 0;
    $info{debuggable}     = $flag{DEBUGGABLE}                                   ? 1 : 0;
    $info{allow_backup}   = $flag{ALLOW_BACKUP}                                 ? 1 : 0;
    $info{persistent}     = $flag{PERSISTENT}                                   ? 1 : 0;
    $info{legacy_storage} = $flag{PRIVATE_FLAG_REQUEST_LEGACY_EXTERNAL_STORAGE} ? 1 : 0;


    return \%info;
}


# Storage

sub df {
    my $self = shift;
    my $cmd  = $self->shell('df -k');

    my $df = _parse_df($cmd->stdout);
    Carp::croak('df failed: ' . $cmd->stderr) unless @{$df};

    return wantlist($df);
}

sub _parse_df {
    my $output = shift;
    my @df     = ();

    for my $line (split /\n/, $output) {

        my ($fs, $size, $used, $available, $use_percent, $mount) = $line =~ m{
            ^(\S+)                      # filesystem
            \s+(\d+)\s+(\d+)\s+(\d+)    # size, used, available (kB)
            \s+(\d+)\%                  # use%
            \s+(\S+)$                   # mount
        }x or next;

        my $data = {
            filesystem  => $fs,
            size        => $size * 1_024,
            used        => $used * 1_024,
            available   => $available * 1_024,
            use_percent => $use_percent + 0,
            mount       => $mount
        };
        push @df, $data;
    }

    return \@df;
}

sub storage {
    my $data = first { $_->{mount} eq '/data' } shift->df;
    return {map { $_ => $data ? $data->{$_} : undef } qw(size used available)};
}

sub mounts {
    my $self   = shift;
    my $output = $self->_read_file('/proc/mounts');

    my $mounts = _parse_mounts($output);
    return wantlist($mounts);
}

sub _parse_mounts {
    my $output = shift;
    my @mounts = ();

    for my $line (split /\n/, $output) {
        my ($device, $mount, $type, $options) = split(' ', $line);
        next unless defined $options;

        s/\\([0-7]{3})/chr oct $1/ge for $device, $mount;

        my $data = {
            device  => $device,
            mount   => $mount,
            type    => $type,
            options => {map { /^([^=]+)=(.*)$/ ? ($1 => $2) : ($_ => 1) } split /,/, $options}
        };
        push @mounts, $data;
    }

    return \@mounts;
}


# Memory

sub meminfo { _parse_meminfo(shift->_read_file('/proc/meminfo')) }

sub _parse_meminfo {
    my $output = shift;
    my %mem    = ();

    for my $line (split /\n/, $output) {
        my ($key, $value, $unit) = $line =~ /^([^:]+):\s+(\d+)(?:\s+(kB))?$/ or next;
        $mem{$key} = $unit ? $value * 1024 : $value + 0;
    }

    return \%mem;
}

sub memory {
    my $mem = shift->meminfo;
    return {
        total      => $mem->{MemTotal},
        available  => $mem->{MemAvailable},
        free       => $mem->{MemFree},
        swap_total => $mem->{SwapTotal},
        swap_free  => $mem->{SwapFree},
    };
}


# CPU

sub cpuinfo { _parse_cpuinfo(shift->_read_file('/proc/cpuinfo')) }

sub _parse_cpuinfo {
    my $output  = shift;
    my %cpuinfo = (processors => [], common => {});

    for my $block (split /\n\s*\n/, $output) {
        my %fields = ();
        for my $line (split /\n/, $block) {
            my ($key, $value) = $line =~ /^([^:]+?)\s*:\s*(.*?)\s*$/ or next;
            $fields{$key} = $value;
        }

        if (defined $fields{processor}) {
            push @{$cpuinfo{processors}}, \%fields;
        }
        else {
            @{$cpuinfo{common}}{keys %fields} = values %fields;
        }
    }

    return \%cpuinfo;
}

sub loadavg { _parse_loadavg(shift->_read_file('/proc/loadavg')) }

sub _parse_loadavg {
    my $output = shift;

    my ($avg1, $avg5, $avg15, $running, $total, $last_pid) = $output =~ m{
        ^ ([\d.]+) \s+ ([\d.]+) \s+ ([\d.]+)    # load averages
        \s+ (\d+) / (\d+)                       # running/total tasks
        \s+ (\d+)                               # last pid
    }x or Carp::croak("Cannot parse loadavg: $output");

    return {
        avg1     => $avg1 + 0,
        avg5     => $avg5 + 0,
        avg15    => $avg15 + 0,
        running  => $running + 0,
        total    => $total + 0,
        last_pid => $last_pid + 0,
    };
}


# Helpers

sub _target { (serial => shift->{serial}) }

sub _read_file {
    my ($self, $file) = @_;

    my $cmd = $self->shell('cat -- ' . shell_quote($file));
    return $cmd->assert_success->stdout;
}

sub _props {
    my $self = shift;
    return $self->{properties} //= _parse_getprop($self->shell('getprop')->assert_success->stdout);
}

sub _prop {
    my ($self, @names) = @_;
    my $props = $self->_props;
    return first { defined && length } map { $props->{$_} } @names;
}

sub _setting {
    my ($settings, $key) = @_;
    my $value = $settings->{$key};
    return defined $value && length $value && $value ne 'null' ? $value : undef;
}

sub _bool {
    my ($value, $true, $false) = @_;
    return undef unless defined $value;
    return $value eq $true ? 1 : $value eq $false ? 0 : undef;
}

sub _hex_to_address {
    my ($address, $port) = split /:/, shift;

    my $bytes  = pack 'V*', map {hex} $address =~ /([[:xdigit:]]{8})/g;
    my $family = length $bytes == 16 ? Socket::AF_INET6() : Socket::AF_INET();

    return (Socket::inet_ntop($family, $bytes), hex $port);
}

sub _indent_lines {
    my (@stack, @lines);
    for my $line (split /\n/, shift) {
        my ($indent, $text) = $line =~ /^( *)(\S.*?)\s*$/ or next;
        next if $text eq 'overlay paths:';    # FIX bad indentation
        pop @stack while @stack && $stack[-1][0] >= length $indent;
        push @stack, [length $indent, $text];
        push @lines, [map { $_->[1] } @stack];
    }
    return \@lines;
}

sub _null_to_undef { $_[0] eq 'null' ? undef : $_[0] }

sub _int { $_[0] + 0 }

sub _kv {
    map { /^(\w+)=(.*)$/ ? ($1 => $2) : ($_ => 1) } split /,\s*/, $_[0] // '';
}

sub _permission {
    my ($permissions, $section, $line) = @_;

    my ($perm, $fields) = split /:\s*/, $line, 2;
    my %fields = _kv($fields);

    my $p = $permissions->{$perm} //= {requested => 0, restricted => 0, type => undef, granted => 0, flags => []};

    if ($section eq 'requested') {
        $p->{requested}  = 1;
        $p->{restricted} = _bool($fields{restricted}, 'true', 'false') // 0;
    }
    else {
        $p->{type}    = $section;
        $p->{granted} = _bool($fields{granted}, 'true', 'false') // 0;
        $p->{flags}   = [grep {length} split /\|/, $fields{flags} =~ s/^\[\s*|\s*\]$//gr] if defined $fields{flags};
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::ADB::Device - Extract information from an Android device

=head1 SYNOPSIS

    use Net::ADB;

    my $adb    = Net::ADB->new;
    my $device = $adb->device(serial => '192.168.0.10:5555');

    my $info = $device->info;

    say "$info->{manufacturer} $info->{model}";    # Example Example Phone
    say "Android $info->{android}";                # Android 13

    my $memory = $device->memory;

    printf "%d MB available of %d MB\n", $memory->{available} / 2**20, $memory->{total} / 2**20;

    say $device->getprop->{'persist.sys.timezone'};    # Europe/Rome

    my $res = $device->shell('ls /sdcard');
    print $res->stdout if $res->is_success;


=head1 DESCRIPTION

L<Net::ADB::Device> extracts information from an Android device by running
shell commands through L<Net::ADB> and parsing their output.

There are two kinds of methods:

=over

=item * Methods named after a source (e.g. L</getprop>, L</meminfo>,
L</mounts>) return its content as is, with the key names used by Android or
by the Linux kernel.

=item * Methods named after an area (e.g. L</info>, L</memory>) return a
summary with fixed key names, built from those sources.

=back

The sources vary across Android versions and vendors: a summary value whose
source is missing on the device is C<undef>.

Sizes are in bytes.

B<NOTE>: The API is experimental and may change.


=head1 CONSTRUCTOR

=head2 new

    my $device = $adb->device(serial => '192.168.0.10:5555');

Create a new L<Net::ADB::Device> instance. Use L<Net::ADB/device> instead of
calling C<new> directly: it resolves the device selection to a serial.

Allowed parameters:

=over

=item * C<client>, L<Net::ADB> instance (I<required>).

=item * C<serial>, device serial (I<required>).

=back


=head1 METHODS

=head2 Device

=head3 serial

    say $device->serial;    # 192.168.0.10:5555

Return the serial of the device (the one used by the ADB server, not
C<ro.serialno>).

=head3 client

    my $port = $device->client->forward(serial => $device->serial, local => 'tcp:0', remote => 'tcp:8080');

Return the L<Net::ADB> instance used by the device.

=head3 state

    say $device->state;    # device

Return the state of the device. See L<Net::ADB/state>.

=head3 features

    my @features = $device->features;
    my $features = $device->features;    # array reference

Return the list of features supported by the device (an array reference in
scalar context). See L<Net::ADB/features>.

=head3 shell

    my $res = $device->shell('ls /sdcard');
    my $res = $device->shell('logcat -d', timeout => 60);

Run a command on the device and return a L<Net::ADB::Shell::Result>
instance. See L<Net::ADB/shell_v2>.

Allowed parameters:

=over

=item * C<timeout>, timeout in seconds for this call.

=back


=head2 System

=head3 getprop

    my $props = $device->getprop;

    say $props->{'ro.build.version.release'};    # 13

    # Read the properties again from the device
    $props = $device->getprop(refresh => 1);

Return a hash reference with all the system properties of the device
(C<getprop>).

The properties are read once and cached in the instance: use C<refresh> to
read them again, e.g. for properties that change at runtime. The returned
hash is a copy of the cache.

Allowed parameters:

=over

=item * C<refresh>, read the properties from the device again (default: C<0>).

=back

=head3 settings

    my $global = $device->settings('global');

    say $global->{adb_enabled};    # 1

Return a hash reference with all the Android settings of a namespace
(C<settings list>): C<global>, C<secure> or C<system>.

The settings are read every time (no cache), and the values are returned as
is: a setting stored without a value is the string C<null>.

=head3 info

    my $info = $device->info;

Return a hash reference with a summary of the device, built from the system
properties (see L</getprop>):

    {
        manufacturer   => 'Example',
        brand          => 'Example',
        model          => 'Example Phone',
        marketname     => undef,
        device         => 'example',
        android        => '13',
        sdk            => 33,
        security_patch => '2024-05-01',
        build_id       => 'TP1A.220624.014',
        build_type     => 'user',
        build_date     => '2024-05-20T09:12:44Z',
        fingerprint    => 'Example/example/example:13/TP1A.220624.014/1234567:user/release-keys',
        abi            => 'arm64-v8a',
        abilist        => ['arm64-v8a', 'armeabi-v7a', 'armeabi'],
        platform       => 'mt6789',
        hardware       => 'mt6789',
        serial         => 'EX0123456789',
        emulator       => 0
    }

=over

=item * C<manufacturer>, C<brand>, C<model>, C<device>: looked up in
C<ro.product.*>, C<ro.product.vendor.*>, C<ro.product.system.*> and
C<ro.product.odm.*>, because these properties moved between partitions over
Android versions.

=item * C<marketname>: commercial name, when set by the vendor.

=item * C<android>, C<sdk>: Android version and API level.

=item * C<security_patch>: security patch level.

=item * C<build_id>, C<build_type>, C<fingerprint>: build information.

=item * C<build_date>: build date in ISO 8601 format (UTC).

=item * C<abi>, C<abilist>: primary and supported ABIs.

=item * C<platform>, C<hardware>: SoC and hardware names.

=item * C<serial>: hardware serial number (C<ro.serialno>). It may differ
from L</serial>, e.g. for TCP/IP devices.

=item * C<emulator>: C<1> if C<ro.boot.qemu> or C<ro.kernel.qemu> is set
(Android emulator), C<0> otherwise.

=back

=head3 dumpsys

    my $battery = $device->dumpsys('battery');
    my $package = $device->dumpsys('package', 'com.example.app');

Run C<dumpsys> for a system service, with optional arguments, and return its
output as a string. Croaks if the service does not exist.

The output format is specific to each service and changes across Android
versions and vendors.

=head3 dumpsys_services

    my @services = $device->dumpsys_services;
    my $services = $device->dumpsys_services;    # array reference

Return the list of system services that can be passed to L</dumpsys>
(e.g. C<activity>, C<battery>, C<package>), or an array reference in scalar
context (C<dumpsys -l>).

=head3 uptime

    my $uptime = $device->uptime;

    printf "up %.1f hours\n", $uptime->{uptime} / 3600;

Return a hash reference with the content of C</proc/uptime>, in seconds:

    {
        uptime => 40360.45,
        idle   => 201485.9
    }

=over

=item * C<uptime>: time since boot.

=item * C<idle>: time spent idle, summed over all CPUs (so it can be greater
than C<uptime>).

=back

=head3 kernel

    my $kernel = $device->kernel;

Return a hash reference with the Linux kernel version, from
C</proc/version>:

    {
        version    => '5.10.43',
        release    => '5.10.43-android12-9-00001',
        build_date => 'Fri Jul 9 10:53:24 UTC 2021',
        banner     => 'Linux version 5.10.43-android12-9-00001 (build-user@build-host) (...) #1 SMP PREEMPT Fri Jul 9 10:53:24 UTC 2021'
    }

=over

=item * C<version>: numeric version, useful to compare against vulnerable
version ranges.

=item * C<release>: full release string, as reported by C<uname -r>.

=item * C<build_date>: build date as written by the kernel (the time zone may
be missing). An old kernel build date on a device with a recent security patch
level may mean that the kernel did not receive the patches.

=item * C<banner>: the whole content of C</proc/version>.

=back

Values that cannot be parsed are C<undef>.


=head2 Security

=head3 security

    my $security = $device->security;

    warn 'Bootloader is unlocked' if defined $security->{bootloader_locked} && !$security->{bootloader_locked};

Return a hash reference with a summary of the security settings of the
device:

    {
        security_patch    => '2024-05-01',
        verified_boot     => 'green',
        bootloader_locked => 1,
        debuggable        => 0,
        secure            => 1,
        adb_secure        => 1,
        build_type        => 'user',
        build_tags        => 'release-keys',
        encryption        => 'encrypted',
        encryption_type   => 'file',
        selinux           => 'enforcing',
        adb_enabled       => 1,
        adb_wifi_enabled  => 0,
        developer_options => 1,
        adb_tcp_port      => undef,
        unknown_sources   => undef,
        private_dns       => 'hostname',
        private_dns_host  => 'dns.example.com',
        always_on_vpn     => undef
    }

Yes/no values are C<1> or C<0>. Values that are not available on the device
are C<undef>, which is not the same as C<0>: e.g. C<bootloader_locked> is
C<undef> when the device does not report the bootloader state.

=over

=item * C<security_patch>: security patch level (C<ro.build.version.security_patch>).

=item * C<verified_boot>: Verified Boot state (C<ro.boot.verifiedbootstate>):
C<green> (locked, verified), C<yellow> (locked, custom key), C<orange>
(unlocked) or C<red> (verification failed).

=item * C<bootloader_locked>: bootloader lock state (C<ro.boot.flash.locked>,
or C<ro.boot.vbmeta.device_state>).

=item * C<debuggable>: debuggable build (C<ro.debuggable>), e.g. C<eng> and
C<userdebug> builds. Production devices are C<0>.

=item * C<secure>: secure mode (C<ro.secure>), C<0> means that C<adbd> runs as
root.

=item * C<adb_secure>: ADB requires authorization of the computer
(C<ro.adb.secure>).

=item * C<build_type>, C<build_tags>: build type (C<user>, C<userdebug>,
C<eng>) and signing keys (C<release-keys>, or C<test-keys> for builds signed
with public test keys).

=item * C<encryption>, C<encryption_type>: storage encryption state
(C<ro.crypto.state>) and type (C<ro.crypto.type>, C<file> or C<block>).

=item * C<selinux>: SELinux mode (see L</selinux>).

=item * C<adb_enabled>, C<adb_wifi_enabled>, C<developer_options>: USB
debugging, wireless debugging and developer options (see L</settings>).

=item * C<adb_tcp_port>: port of ADB over TCP/IP (C<adb tcpip>), C<undef> when
it is disabled (C<service.adb.tcp.port>, C<persist.adb.tcp.port>).

=item * C<unknown_sources>: installation from unknown sources allowed
(C<install_non_market_apps>). Only before Android 8.0, C<undef> on later
versions, where the permission is per app (see L</install_sources>).

=item * C<private_dns>, C<private_dns_host>: Private DNS (DNS over TLS) mode
(C<off>, C<opportunistic> or C<hostname>) and host.

=item * C<always_on_vpn>: package of the always-on VPN.

=back

The properties come from the L</getprop> cache: use C<getprop(refresh =E<gt> 1)>
to read them again.

=head3 privileged_apps

    my $apps = $device->privileged_apps;

    say for @{$apps->{accessibility_services}};

Return a hash reference with the apps granted powerful special permissions,
often abused by malware and stalkerware, as lists of C<package/class>
components:

    {
        accessibility_services => ['com.example.app/com.example.app.AccessibilityService'],
        notification_listeners => ['com.example.watch/com.example.watch.NotificationListener']
    }

=over

=item * C<accessibility_services>: enabled accessibility services, which can
read the screen and act on behalf of the user.

=item * C<notification_listeners>: apps that can read all notifications,
including one-time codes.

=back

=head3 install_sources

    my @packages = $device->install_sources;
    my $packages = $device->install_sources;    # array reference

Return the list of packages allowed to install other apps ("Install unknown
apps"), or an array reference in scalar context
(C<appops query-op REQUEST_INSTALL_PACKAGES allow>).

Requires Android 8.0 or later: on older versions, see C<unknown_sources> in
L</security>.

=head3 selinux

    say $device->selinux;    # enforcing

Return the SELinux mode of the device in lowercase: C<enforcing>,
C<permissive> or C<disabled> (C<getenforce>).


=head2 Network

=head3 connections

    for my $socket ($device->connections) {
        next unless $socket->{state} eq 'ESTABLISHED';
        say "$socket->{local_port} -> $socket->{remote_address}:$socket->{remote_port}";
    }

    my $sockets = $device->connections;    # array reference

Return the list of TCP and UDP sockets (an array reference in scalar context),
one hash reference per socket, from C</proc/net/tcp>, C<tcp6>, C<udp> and
C<udp6>:

    {
        protocol       => 'tcp',
        family         => 6,
        state          => 'ESTABLISHED',
        local_address  => '::ffff:192.168.0.10',
        local_port     => 49166,
        remote_address => '::ffff:203.0.113.5',
        remote_port    => 443,
        uid            => 10245,
        inode          => 4670123
    }

=over

=item * C<protocol>: C<tcp> or C<udp>.

=item * C<family>: C<4> for IPv4, C<6> for IPv6. IPv4 connections of IPv6
sockets have IPv4-mapped addresses (C<::ffff:192.168.0.10>).

=item * C<state>: TCP state (C<LISTEN>, C<ESTABLISHED>, C<TIME_WAIT>,
C<CLOSE_WAIT>, ...). UDP sockets are C<ESTABLISHED> when connected to a remote
address and C<CLOSE> otherwise.

=item * C<local_address>, C<local_port>: local address and port. C<0.0.0.0>
and C<::> accept connections on every interface, C<127.0.0.1> and C<::1> only
from the device itself.

=item * C<remote_address>, C<remote_port>: remote address and port
(C<0.0.0.0> and C<0> when not connected).

=item * C<uid>: Linux user ID of the owner: match it with the C<uid> of
L</packages> to find the app (C<0> is C<root>, C<1000> is C<system>). Several
packages can share the same UID.

=item * C<inode>: socket inode.

=back

=head3 listening

    for my $socket ($device->listening) {
        say "$socket->{protocol} $socket->{local_address}:$socket->{local_port} uid=$socket->{uid}";
    }

    my $sockets = $device->listening;    # array reference

Return the sockets waiting for connections (an array reference in scalar
context): TCP sockets in the C<LISTEN> state and UDP sockets bound to a port
and not connected. The sockets have the same fields as L</connections>.

    my %apps = map { $_->{uid} => $_->{name} } $device->packages;

    for my $socket ($device->listening) {
        say "$socket->{local_port} ", $apps{$socket->{uid}} // "uid $socket->{uid}";
    }


=head2 Packages

=head3 packages

    for my $package ($device->packages(third_party => 1)) {
        say "$package->{name} $package->{version_code}";
    }

    my $packages = $device->packages;    # array reference

Return the list of installed packages (an array reference in scalar
context), one hash reference per package:

    {
        name         => 'com.example.app',
        path         => '/data/app/~~4Xc2bT1fQkZ9GmLwYp3aRA==/com.example.app-Hn5pVz0sJmQ8yXe2LkTr4w==/base.apk',
        version_code => 1020300,
        installer    => 'com.android.vending',
        uid          => 10245
    }

=over

=item * C<name>: package name.

=item * C<path>: path of the APK on the device.

=item * C<version_code>: version code, an integer that increases with each
release (not the version name shown to users, e.g. C<1.2.3>).

=item * C<installer>: package that installed it (e.g. C<com.android.vending>
for Google Play), or C<undef> when the system has not recorded one (e.g.
preinstalled packages).

=item * C<uid>: Linux user ID of the package.

=back

Requires Android 9.0 or later (C<pm list packages --show-versioncode>): on
older versions the list is empty.

Allowed parameters:

=over

=item * C<third_party>, only third-party (non-system) packages
(C<pm list packages -3>).

=item * C<system>, only system packages (C<pm list packages -s>).

=back

=head3 package_info

    my $info = $device->package_info('com.example.app');

    say "$info->{name} $info->{version_name} (target SDK $info->{target_sdk})";

    # Dangerous permissions granted by the user
    my $permissions = $info->{permissions};

    for my $name (sort keys %{$permissions}) {
        my $permission = $permissions->{$name};
        say $name if ($permission->{type} // '') eq 'runtime' && $permission->{granted};
    }

Return a hash reference with the details of an installed package, parsed from
C<dumpsys package NAME>. Croak if the package is unknown to the device.

    {
        name                 => 'com.example.app',
        uid                  => 10245,
        shared_user          => undef,
        version_name         => '1.2.3',
        version_code         => 1020300,
        min_sdk              => 26,
        target_sdk           => 34,
        installer            => 'com.android.vending',
        first_install        => '2024-03-01 10:20:30',
        last_update          => '2024-06-15 18:05:12',
        timestamp            => '2024-06-15 18:04:58',
        path                 => '/data/app/~~4Xc2bT1fQkZ9GmLwYp3aRA==/com.example.app-Hn5pVz0sJmQ8yXe2LkTr4w==',
        data_dir             => '/data/user/0/com.example.app',
        splits               => ['base', 'config.arm64_v8a'],
        primary_abi          => 'arm64-v8a',
        secondary_abi        => undef,
        flags                => ['HAS_CODE', 'ALLOW_CLEAR_USER_DATA', 'ALLOW_BACKUP'],
        private_flags        => ['PRIVATE_FLAG_ACTIVITIES_RESIZE_MODE_RESIZEABLE_VIA_SDK_VERSION'],
        system               => 0,
        updated_system       => 0,
        privileged           => 0,
        debuggable           => 0,
        allow_backup         => 1,
        persistent           => 0,
        legacy_storage       => 0,
        installed            => 1,
        hidden               => 0,
        suspended            => 0,
        stopped              => 0,
        not_launched         => 0,
        enabled              => 0,
        enabled_state        => 'default',
        permissions          => {
            'android.permission.INTERNET' => {
                requested  => 1,
                restricted => 0,
                type       => 'install',
                granted    => 1,
                flags      => []
            },
            'android.permission.CAMERA' => {
                requested  => 1,
                restricted => 0,
                type       => 'runtime',
                granted    => 1,
                flags      => ['USER_SET', 'USER_SENSITIVE_WHEN_GRANTED', 'USER_SENSITIVE_WHEN_DENIED']
            },
            'android.permission.READ_CONTACTS' => {
                requested  => 1,
                restricted => 0,
                type       => 'runtime',
                granted    => 0,
                flags      => ['USER_SENSITIVE_WHEN_GRANTED', 'USER_SENSITIVE_WHEN_DENIED']
            },
            'android.permission.WRITE_SECURE_SETTINGS' => {
                requested  => 1,
                restricted => 0,
                type       => undef,
                granted    => 0,
                flags      => []
            },
        },
        declared_permissions => {
            'com.example.app.permission.C2D_MESSAGE' => {
                protection => ['signature'],
                installed  => 1
            },
        },
    }

Yes/no values are C<1> or C<0>. Values that are not available on the device
are C<undef>. The per-user values are those of user C<0>.

=over

=item * C<name>: package name.

=item * C<uid>: Linux user ID of the package (the same as in L</connections>).

=item * C<shared_user>: name of the shared user ID (C<android:sharedUserId>),
or C<undef>. Packages with the same shared user run with the same C<uid> and
share its permissions.

=item * C<version_name>, C<version_code>: version shown to users and version
code.

=item * C<min_sdk>, C<target_sdk>: minimum and target API level. Apps that
target API level 22 or lower get the dangerous permissions at install time,
without asking the user.

=item * C<installer>: package that installed it (e.g. C<com.android.vending>
for Google Play), or C<undef> when the system has not recorded one (e.g.
preinstalled packages or C<adb install>).

=item * C<first_install>, C<last_update>, C<timestamp>: installation time,
last update time and modification time of the APK, as C<YYYY-MM-DD HH:MM:SS>
in the device local time zone. Preinstalled packages often report a
placeholder date (e.g. C<1970-01-01> or C<2009-01-01>).

=item * C<path>, C<data_dir>: directory of the APK files and data directory.

=item * C<splits>: names of the installed APK splits (C<base> plus, for
app bundles, configuration splits).

=item * C<primary_abi>, C<secondary_abi>: ABIs used to load the native
libraries of the app, C<undef> for apps without native code.

=item * C<flags>, C<private_flags>: application flags as reported by the
system.

=item * C<system>: system app (C<SYSTEM> flag).

=item * C<updated_system>: system app updated after the factory version
(C<UPDATED_SYSTEM_APP>).

=item * C<privileged>: privileged system app, which can be granted
C<signature|privileged> permissions (C<PRIVILEGED>).

=item * C<debuggable>: debuggable app (C<DEBUGGABLE>): its data can be
accessed with C<run-as>.

=item * C<allow_backup>: app data can be backed up (C<ALLOW_BACKUP>).

=item * C<persistent>: app kept always running (C<PERSISTENT>).

=item * C<legacy_storage>: app opted out of scoped storage
(C<PRIVATE_FLAG_REQUEST_LEGACY_EXTERNAL_STORAGE>).

=item * C<installed>, C<hidden>, C<suspended>, C<stopped>, C<not_launched>:
state for the user. C<installed> is C<0> for a system app uninstalled for the
user, C<stopped> is C<1> for an app never started or force-stopped.

=item * C<enabled>, C<enabled_state>: enabled setting for the user, as number
and name: C<0> C<default>, C<1> C<enabled>, C<2> C<disabled>, C<3>
C<disabled_user> (disabled by the user), C<4> C<disabled_until_used>.
C<default> means the state declared in the manifest, which is not always
enabled.

=item * C<permissions>: permissions requested by the package or granted to
its C<uid>, keyed by name:

=over

=item * C<requested>: C<1> if the package requests it in its manifest. It is
C<0> for permissions granted to the C<uid> through another package with the
same C<shared_user>.

=item * C<restricted>: C<1> for a hard-restricted permission (e.g. SMS, call
log), which needs an exemption by the installer.

=item * C<type>: C<install> (normal and signature permissions, granted at
install time), C<runtime> (dangerous permissions, granted by the user) or
C<undef> (requested but never granted, e.g. a signature permission of
another app).

=item * C<granted>: C<1> if granted.

=item * C<flags>: permission flags for runtime permissions (e.g.
C<USER_SET>, C<USER_FIXED>, C<POLICY_FIXED>, C<GRANTED_BY_DEFAULT>).

=back

=item * C<declared_permissions>: permissions defined by the package, keyed by
name, with C<protection> (protection levels, e.g. C<['signature',
'privileged']>) and C<installed>.

=back


=head2 Storage

=head3 df

    for my $fs ($device->df) {
        say "$fs->{mount} $fs->{available}";
    }

    my $df = $device->df;    # array reference

Return the list of mounted filesystems with their size (an array reference in
scalar context), one hash reference per filesystem (C<df -k>):

    {
        filesystem  => '/dev/block/by-name/userdata',
        mount       => '/data',
        size        => 118111600640,
        used        => 53687091200,
        available   => 64424509440,
        use_percent => 46
    }

Sizes are in bytes. C<use_percent> is the C<Use%> column of C<df>, rounded up.

Filesystems that C<df> cannot read are skipped. Croaks if none can be read.

Requires Android 6.0 or later (toybox C<df>).

=head3 storage

    my $storage = $device->storage;

    printf "%.1f GB free\n", $storage->{available} / 2**30;

Return a hash reference with the size of the user data partition (C</data>),
in bytes (see L</df>):

    {
        size      => 118111600640,
        used      => 53687091200,
        available => 64424509440
    }

The values are C<undef> if C</data> is not listed by C<df>.

=head3 mounts

    my ($data) = grep { $_->{mount} eq '/data' } $device->mounts;

    say 'nosuid' if $data->{options}{nosuid};

Return the list of mounted filesystems (an array reference in scalar
context), one hash reference per mount point (C</proc/mounts>):

    {
        device  => '/dev/block/by-name/userdata',
        mount   => '/data',
        type    => 'f2fs',
        options => {rw => 1, nosuid => 1, nodev => 1, noatime => 1, background_gc => 'on'}
    }

C<options> is a hash reference: options without a value (e.g. C<ro>,
C<nosuid>) are C<1>, the others have their value (e.g. C<size>).


=head2 Memory

=head3 meminfo

    my $meminfo = $device->meminfo;

    say $meminfo->{MemTotal};    # 3917221888

Return a hash reference with the content of C</proc/meminfo>, with the kernel
key names (C<MemTotal>, C<MemAvailable>, C<Cached>, C<SwapTotal>, ...). Values
in kB are converted to bytes.

=head3 memory

    my $memory = $device->memory;

Return a hash reference with a summary of the memory, in bytes (see
L</meminfo>):

    {
        total      => 3917221888,
        available  => 1671278592,
        free       => 219500544,
        swap_total => 2147479552,
        swap_free  => 1515728896
    }

C<available> (C<MemAvailable>) estimates the memory available to start new
applications without swapping. C<free> (C<MemFree>) is the memory not used at
all, which is usually low because the kernel uses free memory for caches.


=head2 CPU

=head3 cpuinfo

    my $cpuinfo = $device->cpuinfo;

    say scalar @{$cpuinfo->{processors}};    # 8

Return a hash reference with the content of C</proc/cpuinfo>: C<processors>
is the list of per-processor fields, and C<common> holds the fields shared by
all processors.

    {
        processors => [
            {
                'processor'        => '0',
                'BogoMIPS'         => '26.00',
                'Features'         => 'fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp',
                'CPU implementer'  => '0x41',
                'CPU architecture' => '8',
                'CPU variant'      => '0x2',
                'CPU part'         => '0xd05',
                'CPU revision'     => '0'
            },
            ...
        ],
        common => {}
    }

The fields depend on the architecture and on the kernel. C<common> is often
empty on 64-bit ARM, and may contain C<Hardware> on 32-bit ARM or, on older
kernels, C<Features> and C<CPU part>.

=head3 loadavg

    my $loadavg = $device->loadavg;

Return a hash reference with the content of C</proc/loadavg>:

    {
        avg1     => 2.15,
        avg5     => 1.87,
        avg15    => 1.62,
        running  => 3,
        total    => 1874,
        last_pid => 18342
    }

=over

=item * C<avg1>, C<avg5>, C<avg15>: load average over 1, 5 and 15 minutes.

=item * C<running>, C<total>: running and total tasks (processes and threads).

=item * C<last_pid>: last PID assigned by the kernel.

=back


=head1 ERRORS

All methods croak on error: e.g. when the device is no longer available, or
when a command or a file read fails.


=head1 SEE ALSO

=over

=item * L<Net::ADB>

=item * L<Net::ADB::Shell::Result>

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-ADB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-ADB>

    git clone https://github.com/giterlizzi/perl-Net-ADB.git


=head1 AUTHOR

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Giuseppe Di Terlizzi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

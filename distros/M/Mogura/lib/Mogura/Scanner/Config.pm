package Mogura::Scanner::Config;
use Mojo::Base -base;

use B qw(svref_2object SVp_IOK);
use Cwd qw(abs_path);
use Encode qw(decode FB_CROAK);
use Exporter 'import';
use Fcntl qw(O_RDONLY O_NOFOLLOW O_NONBLOCK);
use Mojo::File qw(path);
use Mojo::URL;
use YAML::PP;

our @EXPORT_OK = qw(trusted_path);
has [qw(server token_file)];
has state => '/var/lib/mogura-scanner';
has runtime => '/run/mogura-scanner';
has syft => '/usr/local/bin/syft';
has grype => '/usr/local/bin/grype';
has command_timeout => 3600;
has upload_timeout => 300;
has exclude_paths => sub { [] };
has jobs => 2;
has inventory_interval => 10;
has spool_limit => 8 * 1024**3;

sub from_options {
    my ($class, $options) = @_;
    my %cli = %$options;
    my $file = delete $cli{config};
    my $settings = defined($file) ? _read_yaml($file) : {};
    $cli{exclude_paths} = delete $cli{'exclude-path'} if exists $cli{'exclude-path'};
    %cli = map { (tr/-/_/r => $cli{$_}) } keys %cli;
    _validate(\%cli, 'command line');
    my $config = $class->new(%$settings, %cli);

    for my $key (qw(server token_file)) {
        die(($file // 'command line') . ": missing $key\n") unless defined $config->$key;
    }
    return $config;
}

sub _open_config {
    my ($file) = @_;
    die "$file: config requires an absolute path without dot components\n" unless _absolute($file);
    eval { trusted_path(path($file)->dirname, 1); 1 } or die "$file: $@";
    sysopen my $fh, $file, O_RDONLY | O_NOFOLLOW | O_NONBLOCK or die "$file: $!\n";
    my @st = stat $fh;
    die "$file: config must be a regular file owned by root without group or other writes\n"
        unless @st && -f $fh && $st[4] == 0 && !($st[2] & 0022);
    return $fh;
}

sub _read_yaml {
    my ($file) = @_;
    my $fh = _open_config($file);
    my $size = read $fh, my $bytes, 65537;
    die "$file: cannot read config: $!\n" unless defined $size;
    die "$file: config exceeds 64 KiB\n" if $size > 65536;
    my $yaml = YAML::PP->new(schema => ['Core'], boolean => 'JSON::PP');
    my @docs = eval { $yaml->load_string(decode('UTF-8', $bytes, FB_CROAK)) };
    if (my $error = $@) {

        # Parser diagnostics can quote input, including an accidentally pasted credential.
        my ($reason) = "$error" =~ /(Duplicate key '[^'\n]+'|Found cyclic ref)/;
        my ($line) = "$error" =~ /Line\s*:\s*(\d+)/;
        $reason //= defined($line) ? "invalid YAML on line $line" : 'invalid YAML';
        die "$file: $reason\n";
    }
    die "$file: expected a single YAML mapping\n" unless @docs == 1 && ref($docs[0]) eq 'HASH';
    _validate($docs[0], $file, 1);
    return $docs[0];
}

sub _absolute {
    my ($path) = @_;
    return
        defined($path)
        && !ref($path)
        && $path =~ m{\A/}
        && index($path, "\0") < 0
        && $path !~ m{(?:\A|/)\.\.?(?:/|\z)};
}

sub _validate {
    my ($settings, $source, $yaml) = @_;
    for my $key (sort keys %$settings) {
        my $value = $settings->{$key};
        my $error = "$source: $key";
        if ($key eq 'server') {
            die "$error requires an HTTPS URL (HTTP only on numeric loopback)\n"
                unless defined($value) && !ref($value) && _server_url($value);
            $settings->{$key} =~ s{/$}{};
        }
        elsif ($key =~ /\A(?:token_file|state|runtime|syft|grype)\z/) {
            die "$error requires an absolute path without dot components\n"
                unless _absolute($value);
        }
        elsif ($key eq 'exclude_paths') {
            die "$error requires an array of absolute literal paths\n"
                unless ref($value) eq 'ARRAY';
            my (@paths, %seen);
            for my $path (@$value) {
                die "$error requires an absolute path without dot components\n"
                    unless _absolute($path);
                $path =~ s{/+}{/}g;
                $path =~ s{/$}{};
                die "$error cannot exclude the root\n" unless length $path;
                push @paths, $path unless $seen{$path}++;
            }
            $settings->{$key} = \@paths;
        }
        elsif ($key =~ /\A(?:jobs|spool_limit|upload_timeout|command_timeout)\z/) {
            die "$error requires a positive integer\n"
                unless defined($value)
                && !ref($value)
                && (!$yaml || svref_2object(\$value)->FLAGS & SVp_IOK)
                && $value =~ /\A[1-9][0-9]*\z/;
            die "$error must be in 1..64\n" if $key eq 'jobs' && $value > 64;
            die "$error must be in 1048576..9999999999999 bytes\n"
                if $key eq 'spool_limit' && (length($value) > 13 || $value < 1048576);
            my $integer = 0 + $value;
            die "$error exceeds the integer range\n"
                unless svref_2object(\$integer)->FLAGS & SVp_IOK;
            $settings->{$key} = $integer;
        }
        else {
            die "$error is an unknown setting\n";
        }
    }
}

sub _server_url {
    my ($value) = @_;
    my $url = Mojo::URL->new($value);
    my $host = $url->host // '';
    my $scheme = $url->scheme // '';
    return
        length($host)
        && !defined($url->userinfo)
        && !defined($url->fragment)
        && !$url->query->to_string
        && $url->path->to_string =~ m{\A/?\z}
        && ($scheme eq 'https'
        || ($scheme eq 'http' && ($host eq '127.0.0.1' || $host eq '[::1]')));
}

sub trusted_path {
    my ($file, $no_links) = @_;
    die "Expected absolute path: $file"
        unless "$file" =~ m{\A/} && "$file" !~ m{(?:\A|/)\.\.(?:/|\z)};
    for my $candidate ("$file", abs_path($file) // die "Missing path: $file") {
        my $p = path($candidate);
        while (1) {
            die "Symlink in config path: $p" if $no_links && -l $p;
            my @st = stat($p);
            die "Root must own $p and deny group/other writes"
                unless @st && $st[4] == 0 && !($st[2] & 0022);
            last if "$p" eq '/';
            $p = $p->dirname;
        }
    }
}

sub mounts {
    my ($self) = @_;
    return $self->runtime . '/mounts';
}

1;

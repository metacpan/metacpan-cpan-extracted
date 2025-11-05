package NVMPL::Config;
use strict;
use warnings;
use JSON::PP qw(decode_json);
use File::Spec;
use File::HomeDir;
use File::Path qw(make_path);

# Default config locations
my $SYSTEM_CONF = '/etc/nvm-pl.conf';
my $USER_CONF = File::Spec->catfile(File::HomeDir->my_home, '.nvmplrc');

# Default values (used if no config files exist)
my %DEFAULTS = (
    install_dir     => File::Spec->catdir(File::HomeDir->my_home, '.nvm-pl', 'install'),
    mirror_url      => 'https://nodejs.org/dist',
    cache_ttl       => 86400,
    auto_use        => 1,
    color_output    => 1,
    log_level       => 'info',
);

my %CONFIG;

# --------------------------------------------------------------------
# Initialize configuration (called once at startup)
# --------------------------------------------------------------------

sub load {
    my $class = shift;

    %CONFIG = %DEFAULTS;

    if (-f $SYSTEM_CONF) {
        _merge_config($SYSTEM_CONF);
    }

    if (-f $USER_CONF) {
        _merge_config($USER_CONF);
    }

    my $install_dir = $CONFIG{install_dir};
    for my $subdir (qw(downloads versions)) {
        my $path = File::Spec->catdir($install_dir, $subdir);
        make_path($path) unless -d $path;
    }

    return \%CONFIG;
}

# --------------------------------------------------------------------
# Return a single config value
# --------------------------------------------------------------------

sub get {
    my ($key) = @_;
    return $CONFIG{$key} // $DEFAULTS{$key};
}

# --------------------------------------------------------------------
# Internal helper: read and merge JSON or simple key=value config files
# --------------------------------------------------------------------

sub _merge_config {
    my ($file) = @_;

    open my $fh, '<', $file or do {
        warn "Warning: could not open $file: $!\n";
        return;
    };

    local $/;
    my $content = <$fh>;
    close $fh;

    my $data;
    eval { $data = decode_json($content) };
    if ($@) {
        for my $line (split /\n/, $content) {
            next if $line =~ /^\s*#/;
            next unless $line =~ /=/;
            my ($key, $val) = split /=/, $line, 2;
            $key =~ s/^\s+|\s+$//g;
            $val =~ s/^\s+|\s+$//g;
            $data->{$key} = $val if defined $key && defined $val;
        }
    }

    for my $k (keys %$data) {
        $CONFIG{$k} = $data->{$k};
    }
}

1;
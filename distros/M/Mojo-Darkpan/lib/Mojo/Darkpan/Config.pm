package Mojo::Darkpan::Config;
use v5.20;
use Moo;
use JSON;
use Mojo::File;
use Cwd;
use Data::Dumper;

has _config => (is => 'lazy');
has directory => (is => 'lazy');
has compressIndex => (is => 'lazy');
has path => (is => 'lazy');
has basic_auth => (is => 'lazy');

sub no_compress {
    my $self = shift;
    return !$self->compressIndex;
}

sub _build_path {
    my $self = shift;
    my $path;
    if ($ENV{DARKPAN_PATH}) {
        $path = $ENV{DARKPAN_PATH};
    }
    else {
        $path = $self->_config->{path}
            if $self->_config && $self->_config->{path};
    }

    # default if undef
    $path //= 'darkpan';

    return $path;
}

sub _build_basic_auth {
    my $self = shift;
    my $config;
    if ($ENV{DARKPAN_AUTH_REALM}) {
        $config->{realm} = $ENV{DARKPAN_AUTH_REALM};
        for my $k (keys %ENV) {
            if ($k =~ m/^DARKPAN_AUTH_(.*)/) {
                $config->{config}->{lc($1)} = $ENV{$k};
            }
        }
    }
    elsif (defined($self->_config) && defined($self->_config->{basic_auth})) {
        my @keys = keys %{$self->_config->{basic_auth}};
        $config = {
            realm  => $keys[0],
            config => $self->_config->{basic_auth}->{$keys[0]}
        };
    }

    return $config;
}

sub _build__config {
    my $self = shift;
    my $location = $ENV{DARKPAN_CONFIG_FILE};

    if (defined($location)) {

        $self->_validateAssetLocation($location);

        my $file = Mojo::File->new($location);
        my $config = JSON->new->utf8->decode($file->slurp);

        return $config;
    }

    return undef;
}

sub _build_directory {
    my $self = shift;

    my $dir;
    if ($ENV{DARKPAN_DIRECTORY}) {
        $dir = $ENV{DARKPAN_DIRECTORY};
    }
    else {
        $dir = $self->_config->{directory}
            if $self->_config && $self->_config->{directory};
    }

    # default if undef
    $dir //= 'darkpan';

    $dir = $self->_validateAssetLocation($dir);

    return $dir;
}

sub _build_compressIndex {
    my $self = shift;
    my $compress;
    if ($ENV{DARKPAN_COMPRESS_INDEX}) {
        $compress = $ENV{DARKPAN_COMPRESS_INDEX};
    }
    else {
        $compress = $self->_config->{compress_index}
            if $self->_config && $self->_config->{compress_index};
    }

    # default if undef
    $compress //= 1;

    return $compress;
}

sub _validateAssetLocation {
    my $self = shift;
    my $dir = shift;

    if ($dir !~ m/^\//) {
        $dir =~ s/^\.\///;
        my $base = getcwd;
        $dir = "$base/$dir";
    }

    return $dir;
}

1;
package Passwd::Keyring::Auto::Config;
use Moo;
use File::HomeDir;
use Config::Tiny;
use Path::Tiny;
use Carp;
use namespace::clean;

=head1 NAME

Passwd::Keyring::Auto::Config - config file support

=head1 DESCRIPTION

Configuration file allows user to configure his or her keyring backend
selection criteria.

Internal object, not intended to be used directly.

=cut

# Explicit location if specified
has 'location' => (is=>'ro');
has 'debug' => (is=>'ro');

# Actual location (may be non-existant if that's default)
has 'config_location' => (is=>'lazy');

# Config object
has '_config_obj' => (is=>'lazy');


sub force($$) {
    my ($self, $app) = @_;
    my $force = $self->_read_param("force", $app);
    return $force;
}

sub forbid($$) {
    my ($self, $app) = @_;
    my $forbid = $self->_read_param("forbid", $app);
    return $forbid;
}

sub prefer($$) {
    my ($self, $app) = @_;
    my $prefer = $self->_read_param("prefer", $app);
    return $prefer;
}

sub backend_args($$$) {
    my ($self, $app_name, $backend_name) = @_;
    my $cfg_obj = $self->_config_obj;
    my %reply;
    my $dflt = $cfg_obj->{_};
    foreach my $key (keys %$dflt) {
        if($key =~ /^$backend_name\.(.*)/x) {
            $reply{$1} = $dflt->{$key};
        }
    }
    if( $app_name && exists $cfg_obj->{$app_name}) {
        my $app = $cfg_obj->{$app_name};
        foreach my $key (keys %$app) {
            if($key =~ /^$backend_name\.(.*)/x) {
                $reply{$1} = $app->{$key};
            }
        }
    }
    return wantarray ? %reply : \%reply;
}

# Return listref of all overriden names
sub apps_with_overrides {
    my $self = shift;
    my $cfg_obj = $self->_config_obj;
    my @apps = grep { /^[^_]/ } keys %$cfg_obj;
    return [sort @apps];
}

sub _read_param {
    my ($self, $param, $app) = @_;

    my $debug = $self->debug;
    my $cfg_obj = $self->_config_obj;

    if( $app && exists $cfg_obj->{$app} ) {
        my $per_app_section = $cfg_obj->{$app};
        if($per_app_section) {
            my $per_app = $per_app_section->{$param};
            if($per_app) {
                print STDERR "[Passwd::Keyring] Per-app config value found for $param (for $app): $per_app\n" if $debug;
                return $per_app;
            }
        }
    }
    my $default = $cfg_obj->{_}->{$param};
    if($default) {
        print STDERR "[Passwd::Keyring] Default config value found for $param: $default\n" if $debug;
        return $default;
    }
    print STDERR "[Passwd::Keyring] No config value found for $param\n" if $debug;
    return; # undef
}

sub _build__config_obj {
    my ($self) = @_;

    my $path = $self->config_location;
    my $config;
    if($path && $path->exists) {
        # print STDERR "[Passwd::Keyring] Reading config from $path\n" if $self->debug;
        $config = Config::Tiny->read("$path", "utf8")
          or croak("Can not read Passwd::Keyring config file from $path: $Config::Tiny::errstr");
        # use Data::Dumper; print STDERR Dumper($config);
    } else {
        $config = Config::Tiny->new;
    }
    return $config;
}

sub _build_config_location {
    my ($self) = @_;

    my $debug = $self->debug;

    my $loc = $self->location;
    if($loc) {
        my $path = path($loc);
        unless($path->is_file) {
            croak("File specified by config=> parameter ($path) does not exist");
        }
        if($debug) {
            print STDERR "[Passwd::Keyring] Using config file specified by config=> parameter: $path\n";
        }
        return $path;
    }

    my $env = $ENV{PASSWD_KEYRING_CONFIG};
    if($env) {
        my $path = path($env);
        unless($path->is_file) {
            croak("File specified by PASSWD_KEYRING_CONFIG environment variable ($path) does not exist");
        }
        if($debug) {
            print STDERR "[Passwd::Keyring] Using config file specified by PASSWD_KEYRING_CONFIG environment variable: $path\n";
        }
        return $path;
    }

    my $path = path(File::HomeDir->my_data)->child(".passwd-keyring.cfg");
    if($path->is_file) {
        if($debug) {
            print STDERR "[Passwd::Keyring] Using default config file: $path\n";
        }
        return $path;
    }

    if($debug) {
        print STDERR "[Passwd::Keyring] Config file not specified by any means, and default config ($path) does not exist. Proceeding without config\n";
    }

    return $path;  # To preserve info where it is to be created, for example
}

1;

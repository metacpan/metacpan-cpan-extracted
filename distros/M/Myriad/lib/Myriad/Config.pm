package Myriad::Config;

use Myriad::Class;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Config

=head1 DESCRIPTION

Configuration support.

=cut

use feature qw(current_sub);

use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use Config::Any;
use YAML::XS;
use List::Util qw(pairmap);
use Ryu::Observable;
use Myriad::Storage;
use URI;
use Myriad::Util::Secret;

use Myriad::Exception::Builder category => 'config';

declare_exception 'ConfigRequired' => (
    message => 'A required configueration key was not set'
);

declare_exception 'UnregisteredConfig' => (
    message => 'Config should be registered by calling "config" before usage'
);

=head1 PACKAGE VARIABLES

=head2 DEFAULTS

The C<< %DEFAULTS >> hash provides base values that will be used if no other
configuration file, external storage or environment variable provides an
alternative.

=cut

# Default values

our %DEFAULTS = (
    config_path            => 'config.yml',
    transport_redis        => 'redis://localhost:6379',
    transport_redis_cache  => 0,
    transport_cluster      => 0,
    log_level              => 'info',
    library_path           => '',
    opentracing_host       => 'localhost',
    opentracing_port       => 6832,
    subscription_transport => undef,
    rpc_transport          => undef,
    storage_transport      => undef,
    transport              => 'redis',
    service_name           => '',
);

=head2 FULLNAME_FOR

The C<< %FULLNAME_FOR >> hash maps commandline shortcuts for common parameters.

=cut

our %FULLNAME_FOR = (
    c   => 'config_path',
    l   => 'log_level',
    lib => 'library_path',
    t   => 'transport',
    s   => 'service_name',
);


=head2 SERVICES_CONFIG

A registry of configs defined by the services using the C<< config  >> helper.

=cut

our %SERVICES_CONFIG;

=head2 ACTIVE_SERVICES_CONFIG

A collection of L<Ryu::Observable> to notify services about updates on the configs values

=cut

our %ACTIVE_SERVICES_CONFIG;

# Our configuration so far. Populated via L</BUILD>,
# can be updated by other mechanisms later.
has $config;

has $config_updates_src;

BUILD (%args) {
    $config //= {};
    $config->{services} //= {};
    # Parameter order in decreasing order of preference:
    # - commandline parameter
    # - environment
    # - config file
    # - defaults

    $self->lookup_from_args($args{commandline});

    $log->tracef('Defaults %s, shortcuts %s, args %s', \%DEFAULTS, \%FULLNAME_FOR, \%args);
    $self->lookup_from_env();

    $config->{config_path} //= $DEFAULTS{config_path};
    $self->lookup_from_file();

    $config->{$_} //= $DEFAULTS{$_} for keys %DEFAULTS;

    # Populate transports with the default transport if they are not already
    # configured by the developer
    my $transport_as_uri = URI->new($config->{transport});
    if ($transport_as_uri->has_recognized_scheme) {
        my $transport_type = $transport_as_uri->scheme;
        $config->{"transport_$transport_type"} = $transport_as_uri->as_string;
        $config->{transport} = $transport_as_uri->scheme;
    }

    $config->{$_} //= $config->{transport} for qw(rpc_transport subscription_transport storage_transport);

    push @INC, split /,:/, $config->{library_path} if $config->{library_path};

    $config->{$_} = Ryu::Observable->new($config->{$_}) for grep { not ref $config->{$_} } keys %$config;

    $log->debugf("Config is %s", $config);
}

method key ($key) { return $config->{$key} // die 'unknown config key ' . $key }

method define ($key, $v) {
    die 'already exists - ' . $key if exists $config->{$key} or exists $DEFAULTS{$key};
    $config->{$key} = $DEFAULTS{$key} = Ryu::Observable->new($v);
}

=head2 parse_subargs

A helper to resolve the correct service config

input is expected to look like <service_name>_[configs|instances].<key>

and this sub will set the correct path to key with the provided value.

Example:

dummy_service.configs.password

will end up in

$config->{services}->{dummy_service}->{configs}->{password}

it takes:

=over 4

=item * C<subarg> - the arguments as passed by the user.

=item * C<root> - the level in which we should add the sub arg, we start from $config->{services}.

=item * C<value> - the value that we should assign after resolving the config path.

=back

=cut

method parse_subargs ($subarg, $root, $value) {
    $subarg =~ s/(.*)[_|\.](configs?|instances?)(.*)/$2$3/;
    die 'invalid service name' unless $2;

    my $service_name = $1;
    $service_name =~ s/_/\./g;
    $root = $root->{$service_name} //= {};

    my @sublist = split /_|\./, $subarg;
    die 'config key is not formated correctly' unless @sublist;
    while (@sublist > 1) {
        my $level = shift @sublist;
        $root->{$level} //= {};
        $root= $root->{$level};
    }
    $root->{$sublist[0]} = $value;
}

=head2 lookup_from_args

Parse the arguments provided from the command line.

There are many modules that can parse command lines arguments
but in our case we have unknown arguments - the services configs - that
might be passed by the user or might not and they are on top of that nested.

This sub simply start looking for a match for the arg at hand in C<%DEFAULTS>
then it searches in the shortcuts map and lastly it tries to parse it as a subarg.

Currently this sub takes into account flags (0|1) configs and config written as:
config=value


=cut

method lookup_from_args ($commandline) {
    return unless $commandline;
    my $error;

    while (1) {
        last unless $commandline->@* && ($commandline->[0] =~ /--?./);

        my $arg = shift $commandline->@*;
        $arg =~ s/--?//;
        ($arg, my $value) = split '=', $arg;

        # First match arg with expected keys
        my $key = exists $DEFAULTS{$arg} ? $arg : $FULLNAME_FOR{$arg};
        if ($key) {
            # Either `--example=123` or `--example 123`
            $value = shift $commandline->@* unless defined $value;
            $config->{$key} = $value;
        } elsif ($arg =~ s/services?[_|\.]//) { # are we doing service config
            $value = shift $commandline->@* unless $value;
            try {
                $self->parse_subargs($arg, $config->{services}, $value);
            } catch {
                $error = "looks like $arg format is wrong can't parse it!";
                last;
            }
        } else {
            $error = "don't know how to deal with option $arg";
            last
        }
    }

    if ($error) {
        $log->error($error);
        die pod2usage(1);
    }
}

=head2 lookup_from_env

Tries to find environments variables that start with MYRIAD_* and parse them.

=cut

method lookup_from_env () {
    $config->{$_} //= delete $ENV{'MYRIAD_' . uc($_)} for grep { exists $ENV{'MYRIAD_' . uc($_)} } keys %DEFAULTS;
    map {
        s/(MYRIAD_SERVICES?_)//;
        $self->parse_subargs(lc($_), $config->{services}, $ENV{$1 . $_});
    } (grep {$_ =~ /MYRIAD_SERVICES?_/} keys %ENV);
}

=head2 lookup_from_file

Fill the config from the config file

this sub doesn't do much currently since the config
structure is modelled exactly like how it should be in the file
so it just read the file.

=cut

method lookup_from_file () {
    if(-r $config->{config_path}) {
        my ($override) = Config::Any->load_files({
            files   => [ $config->{config_path} ],
            use_ext => 1
        })->@*;

        $log->debugf('override is %s', $override);

        my %expanded = pairmap {
                ref($b) ? $b->%* : ($a => $b)
        } $override->%*;

        $config->{$_} //= $expanded{$_} for sort keys %expanded;

        # Merge the services config
        $config->{services}  = {
            $expanded{services}->%*,
            $config->{services}->%*,
        } if $expanded{services};
    }
}

=head2 service_config

Takes a service base package and its current name
and tries to resolve its config from:

1. The framework storage itself (i.e Redis or Postgres ..etc).
2. From the config parsed earlier (cmd, env, file).

and if it fails to find a required config it will throw an error.

it takes

=over 4

=item * C<pkg> - The package name of the service, will be used to lookup for generic config

=item * C<service_name> - The current service name either from the registry or as it bassed by the user, useful for instances config

=back

=cut

async method service_config ($pkg, $service_name) {
    my $service_config = {};
    my $instance = $service_name =~ s/\[(.*)\]$// && $1;
    my $available_config = $config->{services}->{$service_name}->{configs};

    my $instance_overrides = {};
    $instance_overrides =
        $config->{services}->{$service_name}->{instances}->{$instance}->{configs} if $instance;
    if(my $declared_config = $SERVICES_CONFIG{$pkg}) {
        for my $key (keys $declared_config->%*) {
            my $value;
            # First try to hit storage
            my $storage_request = await $self->from_storage($service_name, $instance, $key);
            $value = $storage_request->{value};

            # nothing from storage then try other sources

            $value //= $instance_overrides->{$key} ||
                       $available_config->{$key} ||
                       $declared_config->{$key}->{default} ||
                       Myriad::Exception::Config::ConfigRequired->throw(reason => $key);
            $value = Myriad::Util::Secret->new($value) if $declared_config->{$key}->{secure};
            $ACTIVE_SERVICES_CONFIG{$storage_request->{key}} = $service_config->{$key} = Ryu::Observable->new($value);
        }
    }

    return $service_config;
}

=head2 from_storage

Tries to find the config key in the storage using L<Myriad::Storage>.

it takes

=over 4

=item * C<service_name> - The service name.

=item * C<instance> - If the service has many instances (e.g demo, production) this should the identifier.

=item * C<key> - The required config key (e.g password, username ..etc).

=back

=cut

async method from_storage ($service_name, $instance, $key) {
    my $storage = $Myriad::Storage::STORAGE;
    my $key_service_name = $instance ? "${service_name}[${instance}]" : $service_name;
    my $config_key = "config.service.$key_service_name/$key";
    my $value;
    if ($storage) {
        # First try instance specific
        $value = await $storage->get($config_key);
        # we are dealing with an instance but no specific value for it
        # then we try the general one
        if(!$value && $instance) {
            $config_key = "config.service.$service_name/$key";
            $value = await $storage->get($config_key);
        }
    }

    return {key => $config_key, value => $value};
}

async method listen_for_updates () {
    my $storage = $Myriad::Storage::STORAGE;
    if ($storage) {
        try {
            # This step might throw
            my $sub = await $storage->watch_keyspace('config*');
            $sub->map(async sub {
                my $key = shift;
                if(my $observable = $ACTIVE_SERVICES_CONFIG{$key}) {
                    my $updated_value = await $storage->get($key);
                    if ($observable->value->isa('Myriad::Util::Secret')) {
                        $updated_value = Myriad::Util::Secret->new($updated_value);
                    }
                    $observable->set($updated_value);
                    $log->tracef('Detected an update for config key: %s, new value: %s', $key, $updated_value);
                }
            })->resolve->completed->retain->on_fail(sub {
                $log->warnf('Config: config updates listener failed - %s', shift);
            });
        } catch {
            $log->trace('Config: transport do not support keyspace notifications');
        }
    } else {
        $log->warn('Config: Storage is not initiated, cannot listen to configs updates');
    }
}

method DESTROY { }

method AUTOLOAD () {
    my ($k) = our $AUTOLOAD =~ m{^.*::([^:]+)$};
    die 'unknown config key ' . $k unless blessed $config->{$k} && $config->{$k}->isa('Ryu::Observable');
    my $code = method () { return $self->key($k); };
    { no strict 'refs'; *$k = $code; }
    return $self->$code();
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.


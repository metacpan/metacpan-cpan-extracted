package Passwd::Keyring::Auto::Chooser;
use Moo 1.001000;
use Carp;
use Passwd::Keyring::Auto::Config;
use namespace::clean;

=head1 NAME

Passwd::Keyring::Auto::Chooser - actual implementation of keyring picking algorithm

=head1 DESCRIPTION

Internal object, not intended to be used directly.

Implements prioritizing keyrings and finding the best suitable.

See L<Passwd::Keyring::Auto> for algorithm description.

=cut


has 'app' => (is=>'ro', default=>"Passwd::Keyring");
has 'group' => (is=>'ro', default=>"Passwd::Keyring passwords");
has 'config' => (is=>'ro');
has 'force' => (is=>'ro');
has 'prefer' => (is=>'ro');
has 'forbid' => (is=>'ro');
has 'backend_args' => (is=>'ro');

sub BUILDARGS {
    my ($class, %args) = @_;
    my %backend_args;
    foreach my $arg_name (keys %args) {
        unless($arg_name =~ /^(app|group|config|force|prefer|forbid)$/) {
            $backend_args{$arg_name} = $args{$arg_name};
            delete $args{$arg_name};
        }
    }
    $args{backend_args} = \%backend_args;
    return \%args;
}

has '_config' => (
    is=>'lazy', builder=> sub {
        my $self = shift;
        return Passwd::Keyring::Auto::Config->new(location=>$self->config,
                                                  debug=>$self->debug);
    });

has 'debug' => (is=>'lazy', builder=>sub {
                    return $ENV{PASSWD_KEYRING_DEBUG} ? 1 : 0;
                });

sub get_keyring {
    my ($self) = @_;

    my $debug = $self->debug;
    my $app = $self->app;
    my $group = $self->group;

    my $config = $self->_config;

    my $force = $self->force
                || $ENV{PASSWD_KEYRING_FORCE}
                || $config->force($app);

    if($debug) {
        print STDERR "[Passwd::Keyring] Calculated param: force=", $force || '', "\n";
    }

    #################################################################
    # Fast path for force
    #################################################################

    if($force) {
        my $keyring = $self->_try_backend($force);
        return $keyring if $keyring;
        croak "Can not load enforced keyring $force";
    }

    #################################################################
    # Remaining params
    #################################################################

    my $forbid = $self->forbid
                 || [ split(/\s+/x, $ENV{PASSWD_KEYRING_FORBID} 
                                    || $config->forbid($app)
                                    || '') ];
    my $prefer = $self->prefer
                 || [ split(/\s+/x, $ENV{PASSWD_KEYRING_PREFER} 
                                    || $config->prefer($app)
                                    || '') ];

    unless(ref($forbid)) {
        $forbid = [$forbid];
    }
    unless(ref($prefer)) {
        $prefer = [$prefer];
    }

    if($debug) {
        print STDERR "[Passwd::Keyring] Calculated param: forbid=[", join(", ", @$forbid), "]\n";
    }
    if($debug) {
        print STDERR "[Passwd::Keyring] Calculated param: prefer=[", join(", ", @$prefer), "]\n";
    }

    #################################################################
    # Selection and scoring of possible options.
    #################################################################

    # Note: we prefer to check possibly wrong module than to miss some.

    my %candidates =(  # name → score, score > 0 means possible
        'Gnome' => 0,
        'KDEWallet' => 0,
        'OSXKeychain' => 0,
        'Memory' => 1,
        );

    # Scoring: +HUGE for preferred, +100 for session-related, +10 for
    # sensible, +1 for possible

    if($^O eq 'darwin') {
        $candidates{'OSXKeychain'} += 100;
    }

    if( $ENV{DISPLAY} || $ENV{DESKTOP_SESSION} ) {
        $candidates{'KDEWallet'} += 11; # To give it some boost, more portable
        $candidates{'Gnome'} += 10;
    }

    if($ENV{GNOME_KEYRING_CONTROL}) {
        $candidates{'Gnome'} += 100;
    }

    if($ENV{DBUS_SESSION_BUS_ADDRESS}) {
        $candidates{'KDEWallet'} += 10;
    }

    my $prefer_bonus = 1_000_000;
    foreach (@$prefer) { 
        $candidates{$_} += $prefer_bonus;
        $prefer_bonus -= 1_000;
    }

    delete $candidates{$_} foreach (@$forbid);

    my @attempts = grep { $candidates{$_} > 0 } keys %candidates;

    @attempts = sort { ($candidates{$b} <=> $candidates{$a})
                       ||
                       ($a cmp $b)
                   } @attempts;

    if($debug) {
        print STDERR "[Passwd::Keyring] Selected candidates(score): ",
          join(", ", map { "$_($candidates{$_})" } @attempts), "\n";
    }

    foreach my $keyring_name (@attempts) {
        my $keyring = $self->_try_backend($keyring_name);
        return $keyring if $keyring;
    }

    croak "Could not load any keyring backend (attempted: " . join(", ", @attempts) . ")";
}

sub _get_env {
    my ($self, $name) = @_;
    my $full_name = "PASSWD_KEYRING_" . $name;
    if(exists $ENV{$full_name}) {
        print STDERR "[Passwd::Keyring] Found (and using) environment variable $full_name: $ENV{$full_name}\n";
        return $ENV{$full_name};
    }
}

# Loads module of given name or returns undef if it does not work
sub _try_backend {
    my ($self, $backend_name) = @_;

    my $debug = $self->debug;

    # Sanity check
    unless($backend_name =~ /^[A-Za-z][A-Za-z0-9_]*$/) {
        if($debug) {
            print STDERR "[Passwd::Keyring] Ignoring illegal backend name: $backend_name\n";
        }
        return undef;
    }

    my @options = (
        app => $self->app,
        group => $self->group,
        %{ $self->_config->backend_args($self->app, $backend_name) },
        %{ $self->backend_args }
       );

    my $keyring;
    my $require = "Passwd/Keyring/$backend_name.pm";
    my $module = "Passwd::Keyring::$backend_name";
    if($debug) {
        print STDERR "[Passwd::Keyring] Trying to load $module and setup it with (" . join(", ", @options) . ")\n";
    }
    eval {
        require $require;
        $keyring = $module->new(@options);
    };
    if($debug) {
        unless($@) {
            print STDERR "[Passwd::Keyring] Succesfully initiated $module, returning it\n";
        } else {
            print STDERR "[Passwd::Keyring] Attempt to use $module failed, error: $@\n";
        }
    }
    return $keyring;
}

1;

package MooseRoom;
use strict;
our $VERSION = '0.0.1';
use Moose;
use POE qw(Component::Server::IRC);

with qw(MooseX::Getopt);
with qw(MooseX::Daemonize);

has servername => (
    isa     => 'Str',
    is      => 'ro',
    default => sub { 'moose.room' },
);

has nicklen => (
    isa     => 'Int',
    is      => 'ro',
    default => sub { 15 },
);

has network => (
    isa     => 'Str',
    is      => 'ro',
    default => sub { 'MooseRoom' },
);

has ircd => (
    isa     => 'POE::Component::Server::IRC',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        POE::Component::Server::IRC->spawn(
            {
                servername => $_[0]->servername,
                nicklen    => $_[0]->nicklen,
                network
            }
        );
    },
);

has operators => (
    isa        => 'ArrayRef',
    is         => 'ro',
    auto_deref => 1,
    default    => sub {
        [ { username => 'perigrin', password => 'hobbit' }, ];
    },
);

sub BUILD {
    my ($self) = @_;
    POE::Session->create( object_states => [ $self => [qw(_start _default)], ],
    );

}

sub _start {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];
    $self->ircd->yield('register');

    # Anyone connecting from the loopback gets spoofed hostname
    $self->ircd->add_auth(
        mask     => '*@localhost',
        spoof    => $self->hostname,
        no_tilde => 1
    );

    # We have to add an auth as we have specified one above.
    $self->ircd->add_auth( mask => '*@*' );

    # Start a listener on the 'standard' IRC port.
    $self->ircd->add_listener( port => 6667 );

    # Add an operator who can connect from localhost
    $self->ircd->add_operator($_) for $self->operators;
    return;
}

sub _default {
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];
    print STDOUT "$event: ";
    foreach (@$args) {
      SWITCH: {
            if ( ref($_) eq 'ARRAY' ) {
                print STDOUT "[", join( ", ", @$_ ), "] ";
                last SWITCH;
            }
            if ( ref($_) eq 'HASH' ) {
                print STDOUT "{", join( ", ", %$_ ), "} ";
                last SWITCH;
            }
            print STDOUT "'$_' ";
        }
    }
    print STDOUT "\n";
    return 0;    # Don't handle signals.
}

before new  => sub { POE::Kernel->run(); };
after start => sub { POE::Kernel->run(); };

unless ( caller() ) {
    require Cwd;
    my $cmd = lc $ARGV[-1];
    my $app = MooseRoom->new_with_options( pidbase => Cwd::cwd() );
    print STDERR "trying to $cmd server\n";
    if ( $cmd eq 'start' ) {
        print STDERR qq{
        pidfile: @{ [ $app->pidfile ] }
        port:    @{ [ $app->Port ] }
        };
    }
    $app->$cmd;
}

no Moose;
1;    # Magic true value required at end of module
__END__

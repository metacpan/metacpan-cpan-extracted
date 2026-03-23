use strict;
use warnings;
use Test::More tests => 5;
use IO::Socket;

use_ok('Net::Daemon');

# Subclass that uses post_clone() to initialize cloned instances
{
    package CloneTest;
    our @ISA = qw(Net::Daemon);

    sub new {
        my ($class, $attr, $args) = @_;
        my $self = $class->SUPER::new($attr, $args);
        if ($self->{'options'} && $self->{'options'}->{'base'}) {
            $self->{'base'} = $self->{'options'}->{'base'};
        }
        $self->{'base'} ||= 'dec';
        $self;
    }

    sub post_clone {
        my $self = shift;
        $self->{'clone_initialized'} = 1;
        $self->{'inherited_base'} = $self->{'parent'}->{'base'};
    }
}

# Create a parent server object
my $server = CloneTest->new({
    'pidfile' => 'none',
    'mode'    => 'single',
    'base'    => 'hex',
    'localport' => 0,
}, []);

# Create a fake client socket for Clone
my $fake_socket = bless {}, 'IO::Socket';

# Clone the server
my $child = $server->Clone($fake_socket);

# post_clone() should have been called
ok($child->{'clone_initialized'},
    'post_clone() was called during Clone()');

is($child->{'inherited_base'}, 'hex',
    'post_clone() can access parent attributes');

is($child->{'parent'}, $server,
    'cloned object has parent reference');

is(ref($child), 'CloneTest',
    'cloned object is blessed into correct class');

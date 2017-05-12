package TestApp;
use Moose::Role;
use namespace::autoclean;
use MooseX::Types::Moose qw(ArrayRef HashRef);

has requests_received => (
    is => 'ro',
    isa => ArrayRef[HashRef],
    default => sub { [ ] },
    traits => [ 'Array' ],
    handles => {
        add_request => 'push',
        requests_count => 'count',
    },
);

sub psgi_test_app {
    my ($self) = @_;

    return sub {
        my ($env) = @_;

        my $body;
        (delete $env->{'psgi.input'})->read($body,1000000);
        $env->{'testapp.body'}=$body;

        if ($body eq 'error please') {
            $env->{'psgi.errors'}->print('your error');
        }

        delete $env->{'psgi.errors'};

        $self->add_request($env);

        if ($body eq 'die now') {
            die "I died\n";
        }

        if ($body eq 'please reply') {
            return [ 200, [
                'X-STOMP-foo' => 'something',
                'X-STOMP-Reply-Address' => 'reply_queue',
            ], [
                'hello',
            ] ];
        }

        return [ 200, [], ['response'] ];
    };
}

1;

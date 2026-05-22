use v5.20;

use Test::More;
use Net::Statsd::Lite;

use experimental qw( postderef );

{
    package Mock::Socket;

    use Moo;
    use asa 'IO::Socket';

    has buffer => (
        is      => 'ro',
        builder => sub { return [] },
    );

    sub send {
        my ( $self, $data ) = @_;
        push $self->buffer->@*, $data;
    }

    sub shift {
        my ($self) = @_;
        shift $self->buffer->@*;
    }

}

my $socket = Mock::Socket->new;

ok my $stats = Net::Statsd::Lite->new( socket => $socket ), "specify custom socket in the constructor";

$stats->increment( 'foo.bar', 1 );

is $socket->shift, "foo.bar:1|c\n", "received output";

done_testing;

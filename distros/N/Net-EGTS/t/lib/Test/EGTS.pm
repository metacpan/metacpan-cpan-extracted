package Test::EGTS;
use base qw(Exporter);

our @EXPORT = qw(tsocket);

sub tsocket {Test::EGTS::Socket->new(@_)}


package Test::EGTS::Socket;
use Mouse;

has last_send   => is => 'rw', isa => 'Str';
has last_recv   => is => 'rw', isa => 'Str';

sub send {
    use bytes;
    $_[0]->last_send( $_[1] );
    return length $_[1];
}

sub recv {
    use bytes;

    my $last    = $_[0]->last_recv // '';
    $_[1]       = substr $last, 0, $_[2], '';
    $_[0]->last_recv($last);

    return '';
}

1;

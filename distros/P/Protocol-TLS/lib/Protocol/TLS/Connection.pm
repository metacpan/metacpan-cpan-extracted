package Protocol::TLS::Connection;
use strict;
use warnings;
use Protocol::TLS::Trace qw(tracer bin2hex);

sub new {
    my ( $class, $ctx ) = @_;
    bless {
        input => '',
        ctx   => $ctx,
    }, $class;
}

sub next_record {
    my $self   = shift;
    my $record = $self->{ctx}->dequeue;
    tracer->debug( sprintf "send one record of %i bytes to wire\n",
        length($record) )
      if $record;
    return $record;
}

sub feed {
    my ( $self, $chunk ) = @_;
    $self->{input} .= $chunk;
    my $offset = 0;
    my $len;
    my $ctx = $self->{ctx};
    tracer->debug( "got " . length($chunk) . " bytes on a wire\n" );
    while ( $len = $ctx->record_decode( \$self->{input}, $offset ) ) {
        tracer->debug("decoded record at $offset, length $len\n");
        $offset += $len;
    }
    substr( $self->{input}, 0, $offset ) = '' if $offset;
}

sub shutdown {
    shift->{ctx}->shutdown;
}

1

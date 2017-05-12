package Net::YahooMessenger::SendMessage;
use base 'Net::YahooMessenger::Event';

use constant YMSG_SEPARATOR => "\xC0\x80";

sub code {
    return 6;
}

sub body {
    my ( $self, $message ) = @_;
    if ( defined $message ) {
        $message .=
            YMSG_SEPARATOR . '63'
          . YMSG_SEPARATOR . ';0'
          . YMSG_SEPARATOR . '64'
          . YMSG_SEPARATOR . '0'
          . YMSG_SEPARATOR . '1002'
          . YMSG_SEPARATOR . '1'
          . YMSG_SEPARATOR . '206'
          . YMSG_SEPARATOR . '0';
    }
    return $self->SUPER::body($message);
}

sub to {
    my ( $self, $to ) = @_;

    if ( defined $to ) {
        $to .= YMSG_SEPARATOR . '97' . YMSG_SEPARATOR . '1';
    }

    return $self->SUPER::to($to);

}

sub to_string {
    my $self = shift;
    sprintf "%s: %s", $self->{sender}, $self->{body};

}
1;
__END__

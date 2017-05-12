package Net::YahooMessenger::ReceiveMessage;
use base 'Net::YahooMessenger::Event';

sub source {
    my $self = shift;
    if (@_) {
        $self->{source} = shift;
        my $code = $self->_get_by_name('STATUS_CODE') || 0;
        if ( $code == 99 ) {
            require Net::YahooMessenger::NullEvent;
            bless $self, 'Net::YahooMessenger::NullEvent';
        }
    }
    $self->{source};
}

sub from {
    my $self = shift;
    $self->_set_by_name( 'RECV_FROM', shift ) if @_;
    if ( $self->_get_by_name('ERROR_MESSAGE') ) {
        return 'system';
    }
    $self->_get_by_name('RECV_FROM');
}

sub body {
    my $self = shift;
    $self->_set_by_name( 'MESSAGE', shift ) if @_;
    if ( $self->_get_by_name('ERROR_MESSAGE') ) {
        return $self->_get_by_name('ERROR_MESSAGE');
    }
    $self->_get_by_name('MESSAGE');
}

sub to_string {
    my $self = shift;
    sprintf "%s: %s", $self->{sender}, $self->{body};
}

1;
__END__

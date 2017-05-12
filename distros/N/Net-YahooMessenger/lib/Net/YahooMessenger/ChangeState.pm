package Net::YahooMessenger::ChangeState;
use base 'Net::YahooMessenger::Event';

sub source {
    my $self = shift;
    if (@_) {
        $self->SUPER::source(@_);
        my $yahoo = $self->get_connection;
        my $buddy = $yahoo->get_buddy_by_name( $self->from );
        return unless $buddy;

        $buddy->status( $self->status_code );
        if ( $self->status_code == 99 ) {
            $buddy->custom_status( $self->body );
            $buddy->busy( $self->busy );
        }
    }
    $self->SUPER::source();
}

sub from {
    my $self = shift;
    $self->_set_by_name( 'BUDDY_ID', shift ) if @_;
    $self->_get_by_name('BUDDY_ID');
}

sub body {
    my $self = shift;
    $self->_set_by_name( 'STATUS_MESSAGE', shift ) if @_;
    $self->_get_by_name('STATUS_MESSAGE');
}

sub busy {
    my $self = shift;
    $self->_set_by_name( 'BUSY_CODE', shift ) if @_;
    $self->_get_by_name('BUSY_CODE');
}

sub status_code {
    my $self = shift;
    $self->_set_by_name( 'STATUS_CODE', shift ) if @_;
    $self->_get_by_name('STATUS_CODE');
}

sub code {
    return 3;
}

sub to_string {
    my $self = shift;
    sprintf "%s: transit to '%s'", $self->{sender}, $self->{body};
}

1;
__END__

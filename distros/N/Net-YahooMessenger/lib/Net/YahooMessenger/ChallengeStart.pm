package Net::YahooMessenger::ChallengeStart;
use base 'Net::YahooMessenger::Event';
use strict;

sub id {
    my $self = shift;
    $self->_set_by_name( 'NICKNAME', shift ) if @_;
    $self->_get_by_name('NICKNAME');
}

sub body {
    my $self = shift;
    $self->_set_by_name( 'CHALLENGE_STRING', shift ) if @_;
    $self->_get_by_name('CHALLENGE_STRING');
}

sub code {
    return 87;
}

sub to_string {
    my $self = shift;
}

1;
__END__

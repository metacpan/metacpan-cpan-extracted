package Net::YahooMessenger::NewFriendAlert;
use base 'Net::YahooMessenger::Event';

sub from {
    my $self = shift;
    $self->_get_by_name('PROPOSERS_ID');
}

sub to {
    my $self = shift;
    $self->_get_by_name('NICKNAME');
}

sub to_string {
    my $self = shift;
    sprintf
"New Friend Alert: %s added %s as a Friend\nand also sent the following message:\n%s\n",
      $self->from, $self->to, $self->body;
}

1;
__END__

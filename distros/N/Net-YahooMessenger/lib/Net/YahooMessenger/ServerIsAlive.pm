package Net::YahooMessenger::ServerIsAlive;
use base 'Net::YahooMessenger::Event';
use strict;

sub to_string {
    my $self = shift;
    sprintf "Yahoo!Messenger server is alive";
}

1;
__END__

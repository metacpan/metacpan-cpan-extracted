package Net::YahooMessenger::UnImplementEvent;
use base 'Net::YahooMessenger::Event';
use strict;

sub to_string {
    my $self = shift;
    sprintf "Un Implement event(%d)", $self->code;
}

1;
__END__

package Net::YahooMessenger::NullEvent;
use base 'Net::YahooMessenger::Event';
use strict;

sub to_string {
    my $self = shift;
    sprintf "Null event(%d)", $self->code;
}

1;
__END__

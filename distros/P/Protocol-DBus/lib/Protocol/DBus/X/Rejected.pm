package Protocol::DBus::X::Rejected;

use strict;
use warnings;

use parent qw( Protocol::DBus::X::Base );

sub _new {
    my ($class, @mechs) = @_;

    my $msg = 'Authentication rejected.';

    if (@mechs) {
        $msg .= " Try: @mechs";
    }

    return $class->SUPER::_new(
        $msg,
        mechanisms => \@mechs,
    );
}

1;

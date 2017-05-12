package Net::WAMP::X::BadURI;

use strict;
use warnings;

use parent 'Net::WAMP::X::Base';

sub _new {
    my ($class, $reason, $specimen) = @_;

    return $class->SUPER::_new(
        "“$specimen” is not valid WAMP URI: $reason",
        reason => $reason,
        given => $specimen,
    );
}

1;

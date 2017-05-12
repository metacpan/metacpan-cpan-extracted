package Net::WAMP::X::ProcedureAlreadyExists;

use strict;
use warnings;

use parent 'X::Tiny::Base';

sub _new {
    my ($class, $realm, $procedure) = @_;

    return $class->SUPER::_new(
        "The realm “$realm” already has a registered procedure named “$procedure”.",
        realm => $realm,
        procedure => $procedure,
    );
}

1;

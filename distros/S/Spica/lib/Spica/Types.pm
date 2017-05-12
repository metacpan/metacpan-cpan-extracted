package Spica::Types;
use strict;
use warnings;
use utf8;

use MouseX::Types
    -declare => [
        qw(
            SpecClass
            SpecClassName
        ),
        qw(
            ParserClass
            ParserClassName
        )
    ];

use MouseX::Types::Mouse qw(
    Str
    Object
);

class_type SpecClass, { class => 'Spica::Spec' };

subtype SpecClassName,
    as Str;

coerce SpecClass,
    from SpecClassName,
        via { Mouse::Util::load_class($_)->instance };

class_type ParserClass, { class => 'Spica::Parser' };

subtype ParserClassName,
    as Str;

coerce ParserClass,
    from ParserClassName,
        via { Mouse::Util::load_class($_)->new };

1;

#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::PadX::Enum;

enum Colors {
   item RED  ( label => 'red',  hex => '#FF0000' );
   item BLUE ( label => 'blue', hex => '#0000FF' );

   field $label :param :reader;
   field $hex   :param :reader;

   method uc_label { return uc $label; }
}

is( Colors->RED->name,     'RED',     'RED->name auto-injected' );
is( Colors->RED->label,    'red',     'RED->label reader' );
is( Colors->RED->hex,      '#FF0000', 'RED->hex reader' );
is( Colors->RED->uc_label, 'RED',     'RED->uc_label method' );
is( Colors->RED->ordinal,  0,         'RED ordinal' );

is( Colors->BLUE->name,     'BLUE',     'BLUE->name auto-injected' );
is( Colors->BLUE->label,    'blue',     'BLUE->label reader' );
is( Colors->BLUE->hex,      '#0000FF',  'BLUE->hex reader' );
is( Colors->BLUE->uc_label, 'BLUE',     'BLUE->uc_label method' );
is( Colors->BLUE->ordinal,  1,          'BLUE ordinal' );

done_testing;

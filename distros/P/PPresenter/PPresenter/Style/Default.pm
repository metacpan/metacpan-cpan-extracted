# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Style::Default;

use strict;
use PPresenter::Style;
use base 'PPresenter::Style';

use constant ObjDefaults =>
{ -name    => 'default'
, -aliases => undef
};

sub InitObject(;)
{   my $style = shift;

    $style->SUPER::InitObject;

    $style->select(template   => 'default' );
    $style->select(fontset    => 'default' );
    $style->select(decoration => 'default' );
    $style->select(formatter  => 'default' );

    $style;
}

1;

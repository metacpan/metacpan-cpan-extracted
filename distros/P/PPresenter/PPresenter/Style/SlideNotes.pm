# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Style::SlideNotes;

use strict;
use PPresenter::Style;
use base 'PPresenter::Style';

use constant ObjDefaults =>
{ -name       => 'SlideNotes'
, -aliases    => [ 'slidenotes', 'slide notes', 'Slide Notes', 'slideNotes' ]
};

sub InitObject(;)
{   my $style = shift;

    $style->SUPER::InitObject;

    $style->select(template   => 'slidenotes');
    $style->select(fontset    => 'default'   );
    $style->select(decoration => 'default'   );
    $style->select(formatter  => 'simple'    );

    $style;
}

1;

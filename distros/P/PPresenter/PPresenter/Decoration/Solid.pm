# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Decoration::Solid;

use strict;
use PPresenter::Decoration;
use base 'PPresenter::Decoration';

use constant ObjDefaults =>
{ -name             => 'solid'
, -aliases          => [ 'default' ]

# All defaults do fine, for this simple background.
};

sub finish($$$)
{   my ($deco, $show, $slide, $view) = @_;

    $deco->SUPER::finish($show, $slide, $view);
    $view->canvas->configure
        ( -background => $deco->color($view,'BGCOLOR')
        );

    $deco;
}

1;


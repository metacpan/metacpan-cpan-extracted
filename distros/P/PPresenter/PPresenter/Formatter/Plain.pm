# Copyright (C) 2000-2002, Free Software Foundation FSF.

# The plain format is only a far-going simplification on the
# markup formatter.  The whole text is put in <PRE>

package PPresenter::Formatter::Plain;

use strict;
use PPresenter::Formatter::Markup;
use base 'PPresenter::Formatter::Markup';

use Tk;

use constant ObjDefaults =>
{ -name    => 'plain'
, -aliases => undef
};

sub strip($$$)
{   my ($self, $show, $slide, $string) = @_;
    $string =~ s/<[^>]*>//g;
    return $string ;
}

sub parse($$$)
{   my ($self, $slide, $view, $text) = @_;

    $self->SUPER::parse($slide, $view, <<PREFORMAT);
<PRE>
$text
<PRE>
PREFORMAT
}

sub titleFormat($$)
{   my ($self, $slide, $title) = @_;
    "<TITLE>$title</TITLE>";
}

sub footerFormat($$)
{   my ($self, $slide, $footer) = @_;
    "<FOOTER>$footer</FOOTER>";
}

1;

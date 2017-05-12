# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Template;

use strict;

use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant ObjDefaults =>
{ type            => 'template'
, -showTemplateOutlines => 0
, -place          => undef
, -footer         => undef
};

sub hasFooter()   { defined shift->{-footer} }


#
# PREPARATION
#

sub addPart2Make($@)
{   my ($templ, $x0, $y0, $x1, $y1, $text, $type) = @_;

    push @{$templ->{parts2make}},
    , { 'x' => $x0,    'y' => $y0
      , w   => $x1-$x0, h  => $y1-$y0
      , part     => $type
      , contents => $text
      };

    $templ;
}

sub prepareAbsolutePlacings($$)
{   my ($templ, $slide, $view) = @_;
    return unless defined $templ->{-place};

    foreach (ref $templ->{-place}[0] ? @{$templ->{-place}} : $templ->{-place})
    {   $templ->addPart2Make
        (   $view->decoration->boundingBox($view, @$_[0..3])
            , $_->[4], "place"
        )
    }

    $templ;
}

sub prepareFooter($$)
{   my ($templ, $slide, $view) = @_;
    return unless $templ->hasFooter;

    $templ->addPart2Make
    ( $view->decoration->footerBounds($view)
    , $view->formatter->footerFormat($view, $templ->{-footer})
    , "footer"
    );
}

# Not on all templates.
sub prepareTitle($$)
{   my ($templ, $slide, $view) = @_;

    my $deco = $view->decoration;
    $templ->addPart2Make($deco->titleBounds($view)
            , $view->formatter->titleFormat($view, $slide->title)
            , "title"
            );
}

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;

    $templ->prepareAbsolutePlacings($slide, $view);
    $templ->prepareFooter($slide, $view) if defined $templ->{-footer};
    $templ;
}

sub prepareSlide($$)
{   my ($templ, $show, $slide, $view) = @_;

    $view->decoration->prepare($show, $slide, $view);
    $templ->prepareParts($slide, $view);
}

#
# CREATION (realization of the slide)
#

sub createPart($$$$$)
{   my ($templ, $show, $slide, $view, $part, $dx) = @_;

    # Bound-line for debugging
    my $outline = $templ->{-showTemplateOutlines};
    if($outline)
    {   my ($x, $y, $w, $h) = @$part{qw/x y w h/};

        $view->canvas->createRectangle
        ( $x, $y, $x+$w, $y+$h
        , -outline => 'black'
        , -tags    => $part->{slidetag}
        , -width   => $outline
        );
    }

    my $contents = $part->{contents};
    unless(ref $contents)
    {    my $formatter = $view->formatter;

         my $parsed = $formatter->parse($slide, $view, $contents);
         return undef unless defined $parsed;

#print $former->parseTree($parsed), "\n";
         return $formatter->place($show, $slide, $view, $part, $dx, $parsed);
    }
 
    my ($x, $y, $w, $h) = @$part{qw/x y w h/};
    return $view->canvas->createImage
        ( $x+ $w/2, $y + $h
        , -image    => $contents
        , -tags     => $part->{slidetag}
        ) if $contents->isa('Tk::Photo');

    warn "Do not understand part of slide \"$slide\", type ",
         ref $contents, ".\n";
}

sub createSlide($$$$)
{   my ($templ, $show, $slide, $view, $dx) = @_;

    my $deco = $view->decoration;

    foreach my $part (@{$templ->{parts2make}})
    {   $part->{slidetag} = $view->id;
        $part->{parttag}  = $part->{slidetag} . '-' . $part->{part};

        $templ->createPart($show, $slide, $view, $part, $dx);
        $deco->createPart($show, $slide, $view
        , $part->{part}, $part->{parttag}, $dx);
    }

    $deco->finish($show, $slide, $view);

    $templ;
}

#
# Export
#

sub makeHTMLTable($$)
{   my ($templ, $slide, $view) = @_;

    if(@{$templ->{-place}})
    {   warn "Slide $slide contains placed items: cannot make table.\n" if $^W;
        return undef;
    }

    my $formatter = $view->formatter;
    unless ($formatter->can('toHTML'))
    {   warn "Formatter $formatter cannot produce HTML.\n";
        return undef;
    }

    $templ->make_HTML_table($slide, $view);
}

sub makeHTMLLinear($$)
{   my ($templ, $slide, $view) = @_;

    my $formatter = $view->formatter;
    unless ($formatter->can('toHTML'))
    {   warn "Formatter $formatter cannot produce HTML.\n";
        return undef;
    }

    $templ->make_HTML_linear($slide, $view);
}

sub toHTML($$$)
{   my ($templ, $slide, $view, $content) = @_;
    $view->formatter->toHTML($slide, $view, $content);
}

1;

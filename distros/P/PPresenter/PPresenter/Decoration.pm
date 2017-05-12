# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Decoration;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant ObjDefaults =>
{ type              => 'decoration'
, -bgcolor     => undef
, -fgcolor     => undef
, -bdcolor     => undef
, -backdrop    => undef

, -defaultBounds         => [ 0.05, 0.05, 0.97, 0.97 ]
, -notesBounds           => [ 0.02, 0.02, 0.98, 0.98 ]
, -defaultTitlebarHeight => 0.15
, -defaultFooterHeight   => 0.06
, -areaSeparation        => 0.03

, -titleBounds      => undef
, -mainBounds       => undef
, -mainBoundsNoTitle=> undef
, -footerBounds     => undef

, devices      =>
  # device       bgcolor      fgcolor   bdcolor  backdrop?
  { lcd     => [ 'dark blue', 'yellow', 'black', 1         ]
  , beamer  => [ 'white',     'black',  'gray',  0         ]
  , printer => [ 'white',     'black',  'gray',  0         ]
  }

, -nestImages  => ['640x480', 'greenball.gif', 'redball.gif', 'purpleball.gif' ]
};

sub InitObject()
{   my $deco = shift;

    $deco->check_nestImages(@{$deco->{-nestImages}});

    foreach (qw(-defaultTitlebarHeight -defaultFooterHeight -areaSeparation))
    {   next unless defined $deco->{$_};
        $deco->{$_} = $deco->toPercentage($deco->{$_});
    }

    foreach (qw(-defaultBounds -notesBounds -titleBounds -mainBounds
               -mainBoundsNoTitle -footerBounds))
    {   next unless defined $deco->{$_};
        $deco->{$_} = [ map {$deco->toPercentage($_)} @{$deco->{$_}} ];
    }
    
    $deco;
}

sub check_nestImages($@)
{   my ($deco, $geom) = (shift, shift);

    if(defined $geom)
    {   foreach (@_)
        {   next unless ref $_;
            next if $_->isa('PPresenter::Image::Magick');
            # Photo objects are already sized.
            die "-nestImages geometry only on filenames and Magick objects.\n";
        }
    }
    else
    {   foreach (@_)
        {   next unless ref @_;
            next if $_->isa('PPresenter::Image');
            die "-nestImages wants filenames or PPresenter::Image objects.\n";
        }
    }
}

sub addDevice($$$$)
{   my $deco = shift;
    unshift @{$deco->{devices}}, [ @_ ];
    $deco;
}

sub hasBackdrop($)
{   my ($deco,$device) = @_;

    return $deco->{-backdrop}
        if defined $deco->{-backdrop};

    my $spec = $deco->{devices}{$device} || undef;
    die "Undefined device $device.\n" unless defined $spec;
    $spec->[3];
}

sub color($$)
{   my ($deco, $view, $name) = @_;

    my $NAME   = uc $name;
    my $device = $view->device;
    my $spec   = $deco->{devices}{$device}
               || die "Undefined device $device\n";

    return $deco->{-bgcolor} || $spec->[0] if $NAME eq 'BGCOLOR';
    return $deco->{-fgcolor} || $spec->[1] if $NAME eq 'FGCOLOR';
    return $deco->{-bdcolor} || $spec->[2] if $NAME eq 'BDCOLOR';

    $name;
}

sub nestImageDef($$)
{   my ($deco, $nest) = @_;

    my $nr_images = @{$deco->{-nestImages}}-1;
    $nest = $nr_images-1 if $nest >= $nr_images;

    @{$deco->{-nestImages}}[0,$nest+1];
}

sub boundingBox($@)
{   my ($deco, $view) = (shift, shift);
    my ($w, $h) = $view->canvasDimensions;

    ( int(shift(@_) * $w), int(shift(@_) * $h)
    , int(shift(@_) * $w), int(shift(@_) * $h)
    );
}

sub separationX($)
{   my ($deco, $view) = @_;
    my ($w, $h) = $view->canvasDimensions;
    $deco->{-areaSeparation} * $w;
}

sub separationY($)
{   my ($deco, $view) = @_;
    my ($w, $h) = $view->canvasDimensions;
    $deco->{-areaSeparation} * $h;
}

sub separationXY($)
{   my ($deco, $view) = @_;
    my ($w, $h) = $view->canvasDimensions;

    ( $deco->{-areaSeparation} * $w , $deco->{-areaSeparation} * $h);
}

sub titlebarHeight($)
{   my ($deco, $view) = @_;
    my ($w, $h) = $view->canvasDimensions;

    defined $deco->{-titleBounds}
    ? (($deco->{-titleBounds}[3] - $deco->{-titleBounds}[1]) * $h)
    : ($deco->{-defaultTitlebarHeight} * $h);

}
    
sub titleBounds($)
{   my ($deco, $view) = @_;

    return $deco->boundingBox($view, @{$deco->{-titleBounds}})
         if defined $deco->{-titleBounds};

    my ($x0, $y0, $x1, $y1)
        = $deco->boundingBox($view, @{$deco->{-defaultBounds}});

    ($x0, $y0, $x1, $y0 + ($y1-$y0)*$deco->{-defaultTitlebarHeight});
}
 
sub mainBoundsNoTitle($$)
{   my ($deco, $view, $visible_footer) = @_;

    return $deco->boundingBox($view, @{$deco->{-mainBoundsNoTitle}} )
        if $deco->{-mainBoundsNoTitle};
    
    my ($defx0, $defy0, $defx1, $defy1) = @{$deco->{-defaultBounds}};

    my $sep = $deco->{-areaSeparation};

    my ($x0p, $x1p) = $deco->{-mainBounds}
            ? @{$deco->{-mainBounds}}[0,2]
            : defined $deco->{-titleBounds}
            ? $deco->{-titleBounds}[1]
            : ($defx0, $defx1);

    my $y0p = $deco->{-titleBounds} ? $deco->{-titleBounds}[1] : $defy0;

    my $y1p = $visible_footer && defined $deco->{-footerBounds}
            ? $deco->{-footerBounds}[1] - $sep
            : $visible_footer
            ? $defy1 - ($defy1-$defy0)*$deco->{-defaultFooterHeight} - $sep
            : $defy1;
 
    $deco->boundingBox($view, $x0p, $y0p, $x1p, $y1p);
}

sub mainBounds($$$)
{   my ($deco, $view, $visible_footer) = @_;

    return $deco->boundingBox($view, @{$deco->{-mainBounds}})
        if $deco->{-mainBounds};
 
    my ($defx0, $defy0, $defx1, $defy1) = @{$deco->{-defaultBounds}};

    my $sep = $deco->{-areaSeparation};

    my ($x0p, $x1p) = defined $deco->{-mainBounds}
            ? @{$deco->{-mainBounds}}[0,2]
            : ($defx0, $defx1);

    my $y0p = defined $deco->{-titleBounds}
            ? $deco->{-titleBounds}[3] + $sep
            : $defy0+ ($defy1-$defy0)*$deco->{-defaultTitlebarHeight} + $sep;

    my $y1p = $visible_footer && defined $deco->{-footerBounds}
            ? $deco->{-footerBounds}[1] - $sep
            : $visible_footer
            ? $defy1 - ($defy1-$defy0)*$deco->{-defaultFooterHeight} - $sep
            : $defy1;
 
    $deco->boundingBox($view, $x0p, $y0p, $x1p, $y1p);
}

sub footerBounds($)
{   my ($deco, $view) = @_;

    $deco->boundingBox($view, @{$deco->{-footerBounds}})
         if defined $deco->{-footerBounds};

    my ($x0, $y0, $x1, $y1) = @{$deco->{-defaultBounds}};
    $deco->boundingBox($view
    , $x0, $y1 - ($y1-$y0)*$deco->{-defaultFooterHeight}
    , $x1, $y1
    );
}
 
#
# Control over backgound production.
#

sub prepare($$$)
{   my ($deco, $show, $slide, $view) = @_;

    my $current = $show->{current_decoration};
    $current->cleanup($show, $slide, $view)
        if defined $current && "$current" ne "$deco";

    $deco;
}

sub createPart($$$$$$)
{   my ($deco, $show, $slide, $view, $part, $parttag, $dx) = @_;
    $deco;
}

sub finish($$$)
{   my ($deco, $show, $slide, $view) = @_;

    $show->{current_decoration} = $deco;
    $deco;
}

sub cleanup($$$)
{   my ($deco, $show, $slide, $view) = @_;
}

1;

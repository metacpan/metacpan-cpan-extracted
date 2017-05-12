# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Fontset::TkFonts;

use strict;
use PPresenter::Fontset;
use base 'PPresenter::Fontset';

use constant ObjDefaults =>
{ -name             => 'tkfonts'
, -aliases          => [ 'default', 'TkFonts', 'tkfont' ]
, -fixedFont        => 'Courier'
, -proportionalFont => 'Helvetica'
};

sub font($$$$)
{   my ($fontset, $viewport, $type, $weight, $slant, $size) = @_;
    #  type     : PROPORTIONAL, FIXED, or Tk-like
    #  weight   : bold, normal
    #  slant    : italic or roman
    #  size     : from -fontLabels or an actual fontsize

    my $real_size = $fontset->sizeToPixels($viewport, $size);

    my $fam = $type eq 'PROPORTIONAL'  ? $fontset->{-proportionalFont}
            : $type eq 'FIXED'         ? $fontset->{-fixedFont}
            : $type;

    # Create the font if it does not exist yet.

    my $fontname = "-$fam-$weight-$slant-$real_size-";
    $fontset->{$fontname} = $viewport->screen->fontCreate
    ( -family     => $fam,
      -slant      => $slant,
      -size       => $real_size
    ) unless exists $fontset->{$fontname};

    return $fontset->{$fontname};
}

1;

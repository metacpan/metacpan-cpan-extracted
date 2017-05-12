# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Fontset::XScaling;

use strict;
use PPresenter::Fontset;
use base 'PPresenter::Fontset';

#
# Used while initializing.
#

use constant ObjDefaults =>
{ -name             => 'xscaling'               # required
, -aliases          => [ 'scaling', 'scale', 'X' ]
, -fixedFont        => 'adobe-courier'
, -proportionalFont => 'adobe-utopia'
};

my $warned_package = 0;
sub getXScalingInfo($)
{   my ($fontset,$viewport) = @_;

    local $^W = 0;     # X11::Protocol modules is giving "use of undef" warns.
    eval 'require X11::Protocol';
    if($@)
    {   warn "You may improve use of scaling fonts with X11::Protocol\n"
           unless $warned_package++;
        return;
    }

    my $server = X11::Protocol->new;

    my @fonts = $server->ListFonts("*-0-0-0-0-m-*", 500);
    die "No scalable fixed-spacing X11 fonts available.\n" unless @fonts;
    my @selected = grep /^-$fontset->{-fixedFont}-/, @fonts;
    my $fixed;

    if(@selected)
    {   ($fixed) = $selected[0] =~ /^-(.*?-.*?)-/ }
    else
    {   ($fixed) = $fonts[0] =~ /^-(.*?-.*?)-/;
        warn "Fixed font $fontset->{-fixedFont} is not available: changed to $fixed.\n";
    }
    $fontset->{-fixedFont} = $fixed;

    unless(@selected)
    {   my ($fixed) = $fonts[0] =~ /^-(.*?-.*?)-/;
        $fontset->{-fixedFont} = $fixed;
    }

    @fonts = $server->ListFonts("*-0-0-0-0-p-*", 100);
    die "No scalable proportional X11 fonts available.\n" unless @fonts;
    @selected = grep /^-$fontset->{-proportionalFont}-/, @fonts;
    my $prop;

    if(@selected)
    {   ($prop) = $selected[0] =~ /^-(.*?-.*?)-/ }
    else
    {   ($prop) = $fonts[0] =~ /^-(.*?-.*?)-/;
        warn "Proportional font $fontset->{-proportionalFont} is not available: changed to $prop.\n"
    }
    $fontset->{-proportionalFont} = $prop;

    $fontset->{fontsChecked} = 1;
    $fontset;
}

sub font($$$$)
{   my ($fontset, $viewport, $type, $weight, $slant, $size) = @_;
    #  type     : PROPORTIONAL, FIXED or X11-like  fndry-fam
    #  weight   : bold, normal
    #  slant    : italic or roman
    #  size     : from -fontLabels or an actual fontsize

    $fontset->getXScalingInfo($viewport)
        unless defined $fontset->{fontsChecked};

    my $real_size = $fontset->sizeToPixels($viewport, $size);

    my $fam = $type eq 'PROPORTIONAL' ? $fontset->{-proportionalFont}
            : $type eq 'FIXED'        ? $fontset->{-fixedFont}
            : $type;
    my $sl  = $slant eq 'roman'       ? 'r'
            : $slant eq 'italic'      ? 'i'
            : $slant;

    my $fontname = "-$fam-$weight-$sl-normal--${real_size}-0-0-0-0-p-0-*";
    return $fontname;
}

1;

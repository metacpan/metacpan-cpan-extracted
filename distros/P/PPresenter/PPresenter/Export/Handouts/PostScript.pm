# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Export::Handouts::PostScript;

use strict;
use PPresenter::Export;
use base 'PPresenter::Export';

use Tk;
use Tk::Dialog;

use constant ObjDefaults =>
{ -name        => 'PostScript'
, -aliases     => [ 'Postscript', 'ps' ]

, -outputDir   => 'slideImages'

, -density     => 72
, -paperUnits  => 'in'
, -paperWidth  => ''
, -paperHeight => ''
, -colorMode   => 'gray'
, -orientation => 'Landscape'
};

sub view2postscript($$)
{   my ($export, $opts) = @_;

    my $orientation = $export->{-orientation};
    my $viewport    = $opts->{viewport};

    $orientation = $export->bestOrientation($viewport)
        if $orientation eq 'Best fit';

    my $rotate = $orientation eq 'Landscape' ? 1
               : $orientation eq 'Portrait'  ? 0
               : die "-orientation can be Landscape, Portrait, or "
                 . "`Best fit', not $orientation.\n";

    print PPresenter::TRACE
        "Postscript image for $opts->{view} in $orientation.\n";

    my $id  = $opts->{slide}->number;
    $export->makeTkPostscript
       ( $opts->{canvas}, $export->{-colorMode}, $rotate
       , "$export->{-outputDir}/$id-$viewport.eps"
       );

    $export;
}

sub bestOrientation($)
{   my ($export, $viewport) = @_;

    my ($pwidth, $pheight) = $export->paperSizePixels;
    my ($cwidth, $cheight) = $viewport->canvasDimensions;

    $pwidth>$cwidth && $pheight>$cheight ? 'Portrait' : 'Landscape';
}

sub makeTkPostscript($)
{   my ($export, $canvas, $mode, $rotate, $file) = @_;

    my $err = $canvas->postscript
    ( -colormode => $mode
    , -rotate    => $rotate
    , -file      => $file
    );
    print "$err\n" if $err;
}

#
# The user interface to this module.
#

sub popup($$)
{   my ($export, $show, $screen) = @_;
    return $export->{popup}
        if exists $export->{popup};

    $export->{popup} = my $popup = MainWindow->new(-screen => $screen
    , -title => 'Export slides with Tk Postscript'
    );
    $popup->withdraw;

    my $vp = $export->tkViewportSettings($show, $popup);
    my $ps = $export->tkPostscript($show, $popup);

    my $options = $popup->Frame;
    $options->Label
    ( -text     => 'export'
    , -anchor   => 'e'
    )->grid($export->tkSlideSelector($popup), -sticky => 'ew');

    $options->Label
    ( -text     => 'output dir'
    , -anchor   => 'e'
    )->grid($options->Entry(-textvariable => \$export->{-outputDir})
           , -sticky => 'ew');

    my $commands = $popup->Frame;
    $commands->Button
    ( -text      => 'Export'
    , -relief    => 'ridge'
    , -command   => sub {$export->exportPostscript($show, $popup)}
    )->grid($commands->Button
       ( -text      => 'Cancel'
       , -relief    => 'sunken'
       , -command   => sub {$popup->withdraw}
       )
    , -padx => 10, -pady => 10
    );

    if(defined $vp)
    {   $vp->grid($ps, -sticky => 'ewns');
        $options->grid('^', -sticky => 'ew');
    }
    else {$options->grid($ps, -sticky => 'ew')}
    $commands->grid(-columnspan => 2, -sticky => 'ew');

    if(grep {$_->device ne 'printer'} $show->viewports)
    {   my $warning = $popup->LabFrame
        ( -label     => 'warning'
        , -labelside => 'acrosstop'
        )->grid(-columnspan => 2, -sticky => 'ew');
        $warning->Label(-text => <<WARN
The background-color will be lost, so you better
specify `-device=>printer' for all viewports.
WARN
        )->grid(-sticky=>'nwsw');
    }

    return $popup;
}

sub tkPostscript($$)
{   my ($export, $show, $parent) = @_;
    
    my $ps = $parent->LabFrame
    ( -label     => 'Postscript'
    , -labelside => 'acrosstop'
    );

    $ps->Label
    ( -text     => 'Color-mode'
    , -anchor   => 'w'
    )->grid($export->optionlist($ps, qw/-colorMode color gray mono/ )
           , '-', -sticky => 'ew');

    $ps->Label
    ( -text     => 'Paper size'
    , -anchor   => 'w'
    )->grid($export->optionlist($ps, '-paperSize', map {$_->[0]} @papersizes)
           , '-', -sticky => 'ew');

    $ps->Label
    ( -text     => 'width'
    , -anchor   => 'e'
    )->grid( $ps->Entry( -textvariable => \$export->{-paperWidth})
           , $export->optionlist($ps, qw/-paperUnits in cm pt/ )
           , -sticky => 'nsew'
           );

    $ps->Label
    ( -text     => 'height'
    , -anchor   => 'e'
    )->grid( $ps->Entry( -textvariable => \$export->{-paperHeight})
           , '^', -sticky => 'ew'
           );

    $ps->Label
    ( -text     => 'Density'
    , -anchor   => 'w'
    )->grid( $ps->Entry( -textvariable => \$export->{-density})
           , $ps->Label( -anchor => 'w', -text => 'dpi' )
           , -sticky       => 'ew');

    $ps->Label
    ( -text     => 'Orientation'
    , -anchor   => 'w'
    )->grid($export->optionlist($ps, qw/-orientation Landscape Portrait/
           , 'Best fit') , '-', -sticky => 'ew');

    $ps;
}

sub paperSizePixels()
{   my $export = shift;
    my $size   = $export->{-paperSize};
print "Papersize - $size.\n";

    return (undef, undef) if $size eq 'no scaling';

    if($size eq 'own size:')
    {   my $units = $export->{-paperUnits};
        my $pts = $units eq 'pt' ? 1
                : $units eq 'in' ? 72
                : $units eq 'cm' ? (72/2.56)
                : die "-paperUnits of $units?\n";

        return ( int($export->{-paperWidth}*$pts)
               , int($export->{-paperHeight}*$pts));
    }

    return $export->paperSize($size);
}

sub exportPostscript($$)
{   my ($export, $show, $popup) = @_;

    $export->createDirectory($popup, $export->{-outputDir}) || return;
    $popup->withdraw;

    print PPresenter::TRACE "Exporting slides to postscript started.\n";

    my @viewports   = $export->selectedViewports;

    foreach ($export->selectedSlides($show))
    {   $export->makeSlideExports
        ( $show, $_, \@viewports
        , [ sub {shift->view2postscript(@_)}, $export ]
        )
    }

    print PPresenter::TRACE "Exporting slides to postscript ready.\n";

    $export;
}

1;


# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Export;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use Tk qw(DONT_WAIT ALL_EVENTS DoOneEvent);

use vars qw(@EXPORT @papersizes);
@EXPORT = qw/@papersizes/;

use constant ObjDefaults =>
{ -viewports      => 'ALL'      # NOTES, SLIDES, ALL or name or [ names ]
, -exportSlide    => 'ACTIVE'   # ACTIVE, CURRENT, or ALL
, -includeBorders => 0

, -imageFormat    => 'gif'
, -imageWidth     => 500
, -imageQuality   => 80
, -paperSize      => 'A4'
};

# sizes at 72dpi.
@papersizes =
( [ 'no scaling' => 0,0 ]
, [ 'own size:' => undef, undef ]
, [ Letter => 612,792 ], [ Legal => 612,1008 ], [ Executive => 537,720 ]
, [ A3 => 842,1190 ], [ A4 => 595,842 ], [ A5 => 421,595]
, [ B4 => 709,1002 ], [ B5 => 501,709 ]
);

sub paperSize(;$)
{   my $export = shift;
    my $name   = shift || $export->{-paperSize};
    foreach (@papersizes)
    {   return @$_[1,2] if $_->[0] eq $name;
    }
    die "Unknown paper size $name.\n";
}

sub mapExportedPhases($$)
{   my ($export, $show, $function) = @_;

    my @viewports = $export->selectedViewports;
    my @ret;

    foreach my $slide ($export->selectedSlides($show))
    {   $slide->prepare->show;          # slide must be shown first, otherwise
        $slide->startProgram($show);    # the program-info from callbacks and
                                        # content is not known.
        foreach ($slide->exportedPhases)
        {   $slide->gotoPhase($_);
            push @ret, $function->($export, $show, $slide, \@viewports)
        }
    }

    @ret;
}

sub mapSlideViewports
{   my ($export, $show, $slide, $viewports, $function) = @_;
    my @viewport_order = $show->viewports;
    my @ret;

    # Viewport-map is made in order of definition in show.
    foreach my $vp (@viewport_order)
    {   next unless grep {"$vp" eq $_} @$viewports;
        push @ret, $function->( $export, $show, $slide
                              , $slide->find(view_of_viewport => $vp));
    }

    @ret;
}

my $imgs_read = 0;
my $picture_taken;

sub windowImage($$$$)
{   my ($export, $show, $slide, $view) = @_;
    my $mainwindow = $view->viewport->screen;
    $mainwindow->raise;
    $mainwindow->update;

    if($show->runsOnX)
    {   # Problem: X11 has a-sync screen-updates, so we must give the
        # server some time to update the screen, before taking pictures.
        undef $picture_taken;
        $mainwindow->idletasks;

        $mainwindow->after(1000
        , [ sub {$export->get_x11_image(@_)}, $show, $slide, $view ]
        );
        $mainwindow->waitVariable(\$picture_taken);
        return $picture_taken;
    }

    die "Taking images only supported for X11.\n";
}

sub get_x11_image($$$)
{   my ($export, $show, $slide, $view) = @_;
    my $tmp      = ($ENV{TMPDIR} || '/tmp')."/gpp$$-$imgs_read.xwd";

    my $borders  = $export->{-includeBorders};
    my $viewport = $view->viewport;
    my $display  = $viewport->display;
    my $window   = $borders ? $viewport->screenId : $viewport->canvasId;

    my $cmd   = "xwd >$tmp -display $display -id $window -silent";
    $cmd     .= " -nobdrs" unless $borders;

    system($cmd)==0 or die "Cannot start $cmd.\n";

    my $image = $export->readImage($tmp);
    unlink $tmp;
    $imgs_read++;
    $picture_taken = $image;
}

sub readImage($)             # You shall override this.
{   my ($export, $file) = @_;
    die "You shall implement readImage for file $file";
}

sub polishImage($)           # You may override this.
{   my ($export, $img) = @_;
    $img;
}

sub tkImageSettings($$)
{   my ($export, $show, $parent) = @_;

    my $im = $parent->LabFrame
    ( -label     => 'images'
    , -labelside => 'acrosstop'
    );

    $im->Label
    ( -text     => 'Format'
    , -anchor   => 'e'
    )->grid($im->Entry(-textvariable => \$export->{-imageFormat})
           , -sticky => 'ew');

    $im->Label
    ( -text     => 'Width'
    , -anchor   => 'e'
    )->grid($im->Entry(-textvariable => \$export->{-imageWidth})
           , -sticky => 'ew');

    $im->Label
    ( -text     => 'Quality'
    , -anchor   => 'e'
    )->grid($im->Entry(-textvariable => \$export->{-imageQuality})
           , -sticky => 'ew');

    $im->Checkbutton
    ( -text     => 'Show window borders'
    , -relief   => 'flat'
    , -anchor   => 'w'
    , -variable => \$export->{-includeBorders}
    )->grid(-columnspan => 2, -sticky => 'ew');

    $im;
}

sub tkViewportSettings($$)
{   my ($export, $show, $parent) = @_;
    my @viewports = $show->viewports;

    if(@viewports==1)
    {   $export->{vp}{"$viewports[0]"} = 1;
        return undef;
    }

    my $vp = $parent->LabFrame
    ( -label     => 'viewports'
    , -labelside => 'acrosstop'
    );

    foreach (@viewports)
    {   my ($notes, $name) = ($_->showSlideNotes, "$_");
        $export->{vp}{$name} =
              ref $export->{-viewports} eq 'ARRAY'
            ? grep {$name eq $_} @{$export->{-viewports}}
            : $export->{-viewports} eq 'ALL'    ? 1
            : $export->{-viewports} eq 'SLIDES' ? ! $_->showSlideNotes
            : $export->{-viewports} eq 'NOTES'  ? $_->showSlideNotes
            : $export->{-viewports} eq $name;     # single name specified.

        $vp->Checkbutton
        ( -text     => ($notes ? "$name (notes)" : $name)
        , -relief   => 'flat'
        , -anchor   => 'w'
        , -variable => \$export->{vp}{$name}
        )->grid(-sticky => 'nsew');
    }

    $vp;
}

sub selectedViewports()
{   my $export = shift;
    map {$export->{vp}{$_} ? ("$_") : ()}
        keys %{$export->{vp}};
}

sub tkSlideSelector($)
{   my ($export, $parent) = @_;

    $parent->Optionmenu
    ( -options  => [ 'selected slides', 'current slide', 'all slides' ]
    , -command  => sub { $export->setSelectedSlide(shift) }
    );
}

sub setSelectedSlide($)
{   my ($export, $option) = @_;
    $export->{-exportSlide} = $option eq 'current slide'   ? 'CURRENT'
                            : $option eq 'selected slides' ? 'ACTIVE'
                            : $option eq 'all slides'      ? 'ALL'
      : die "Unknown export option `$option'.\n";
}

sub selectedSlides($)
{   my ($export, $show) = @_;

    my $slides = $export->{-exportSlide};
    return $show->current      if $slides eq 'CURRENT';
    return $show->activeSlides if $slides eq 'ACTIVE';
    return $show->slides       if $slides eq 'ALL';

    die "-exportSlide shall contain CURRENT, ACTIVE, or ALL, not $slides.\n";
}

sub createDirectory($$)
{   my ($export, $parent, $directory) = @_;
    return 1 if -d $directory || mkdir $directory, 0755;

    $parent->Dialog
    ( -title   => 'Export images'
    , -text    =>
      "Directory $directory does not exist, and it can not be created either."
    , -buttons => [ 'Bummer' ]
    , -bitmap  => 'error'
    )->Show('-global');

    return 0;
}

sub optionlist($$@)
{   my ($export, $parent, $flag) = splice @_, 0, 3;

    my $default = $export->{$flag};
    die "Cannot find default $default for flag $flag.\n"
        unless grep {$default eq $_} @_;

    $parent->Optionmenu
    ( -options => [ $default, grep {$_ ne $default} @_ ]
    , -variable => \$export->{$flag}
    );
}

sub popup($$)
{   my ($export, $show, $screen) = @_;
    $export->popup($show, $screen)
           ->Popup(-popover => 'cursor');
}

1;

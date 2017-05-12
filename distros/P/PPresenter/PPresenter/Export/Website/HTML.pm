# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Export::Website::HTML;

use strict;
use vars '@ISA';

use PPresenter::Export;
use base 'PPresenter::Export';

# Produce web-pages for the slides.
# The module contains a lot of small routines to simplify extention
# and adaptation to personal needs.

use constant ObjDefaults =>
{ -name         => 'Website producer'
, -aliases      => undef

, -slideAs      => 'IMAGE'        # IMAGE, TABLE, LINEAR, or SKIP
, -notesAs      => 'SKIP'         #     same

, -outputDir    => 'html'
, -indexFile    => 'index.html'
};

sub makeSlides($$)
{   my ($export, $show, $parent) = @_;

    return if 'Cancel' eq $parent->Dialog
    (   -title    => 'Starting Export'
    ,   -text     => <<TEXT
Starting the export of you presentation into a website.

Each of the slides will be shown, and then has its picture taken.

Do not touch your mouse while the processing is going on.
TEXT
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK', 'Cancel' ]
    )->Show;

    $show->busy(1);

    my $dir    = $export->{-outputDir};
    -d $dir || mkdir $dir, 0755
        or die "Cannot create directory $dir: $^E.\n";
 
    my @slides      = $export->selectedSlides($show);
    my @viewports   = $export->selectedViewports($show);

    my (@slidelinks, @mainlinks);
    $export->mapExportedPhases
    ( $show
    , sub { my ($export, $show, $slide, $viewports) = @_;
            push @slidelinks, $export->slide2slidelink($slide);
            push @mainlinks,  $export->main2slidelink($slide);
          }
    );

    my ($previous, $this, $next) = (undef, undef, shift @slidelinks);

    $export->mapExportedPhases
    ( $show
    , sub { my ($export, $show, $slide, $viewports) = @_;
            ($previous, $this, $next) = ($this, $next, shift @slidelinks);
            $export->makeSlide($show, $slide, $viewports
              , $export->slide2filename($slide), $previous, $next);
          }
    );

    $export->makeMainPage($show, $export->slide2filename, \@mainlinks );

    $show->busy(0);

    $parent->Dialog
    (   -title    => 'Ready'
    ,   -text     => 'The website is ready.'
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK' ]
    )->Show;

    $export;
}

sub slide2slidelink($)
{   my ($export, $slide) = @_;
    my $slidename = $export->slide2linkname($slide);
    my $link      = $export->slide2slide($slide);
    "<A HREF=$link>$slidename</A>";
}

sub main2slidelink($)
{   my ($export, $slide) = @_;
    my $slidename = $export->slide2linkname($slide);
    my $link      = $export->main2slide($slide);
    "<A HREF=$link>$slidename</A>";
}

my @views;
sub makeSlide($$$$$$)
{   my ($export, $show, $slide, $vps, $file, $previous, $next) = @_;

    print PPresenter::TRACE "Working on slide $slide, phase "
         , $slide->phase, ", file $file.\n";

    my ($slidename, $showname) = ("$slide", "$show");
    my $title  = $export->Title($show, $slide);
    my $chapter= $export->Chapter($show, $slide);

    my $logo   = $export->PageLogo($show, $slide);
    my $vindex = $export->VerticalIndex($show, $slide, $previous, $next);
    my $commer = $export->Commercial($show, $slide);

    open HTML, ">$file" or die "Cannot write to file $file.\n";
    my $oldout = select HTML;

    print $export->Header( $show, $slide, $logo, $title, $chapter
                         , $commer, $vindex);

    @views     = ();
    $export->mapSlideViewports($show, $slide, $vps
    , sub {shift->makeSlideView(@_)}
    );

    my $extra  = $export->ExtraText($show, $slide);
    my $hindex = $export->HorizontalIndex($show, $slide, $previous, $next);
    my $sig    = $export->Signature($show, $slide);
    my $footer = $export->Footer($show, $slide, $hindex, $sig);

    local $"   = "<P>";
    print "<CENTER>@views</CENTER>\n$extra\n$footer\n";

    select $oldout;
    close HTML;

    $export;
}

sub makeMainPage($$$)
{   my ($export, $show, $file, $links) = @_;

    my $logo   = $export->PageLogo($show, undef);
    my $commer = $export->Commercial($show, undef);
    my $vindex = $export->VerticalIndex($show, undef, undef, $links->[0]);
    my $header = $export->Header( $show, undef, $logo, "$show"
                                , "$show", $commer, $vindex);

    my $intro  = $export->ExtraText($show, undef);
    my $mindex = $export->MainPageIndex($show, $links);

    my $hindex = $export->HorizontalIndex($show, '', '', $links->[0]);
    my $sig    = $export->Signature($show, undef);
    my $footer = $export->Footer($show, undef, $hindex, $sig);

    open HTML, ">$file" or die "Cannot write to file $file.\n";
    print HTML "$header\n$intro\n<P>$mindex\n<P>\n$footer\n";
    close HTML;

    $export;
}

sub makeSlideView($$$)
{   my ($export, $show, $slide, $view) = @_;

    my $show_as = $export->{ $view->viewport->showSlideNotes
                           ? '-notesAs'
                           : '-slideAs'
                           };

    return undef if $show_as eq 'SKIP';

    if($show_as eq 'TABLE')
    {    die "View as table not implemented yet.\n";
    }
    elsif($show_as eq 'LINEAR')
    {    die "View as linear html not implemented yet.\n";
    }
    elsif($show_as eq 'IMAGE')
    {    my $image = $export->view2image($show, $slide, $view);
         push @views, $export->SlideImage($image, $slide, $view) if $image;
    }
}

#
# Extend the routines below.
#

sub slideDir($)
{   my ($export, $slide) = @_;
    $slide->number . '-' . $slide->phase;
}

sub slide2filename($)
{   my ($export, $slide) = @_;
    my $dir = $export->{-outputDir};
    $dir   .= '/' . $export->slideDir($slide) if $slide;

    -d $dir || mkdir $dir, 0755
        or die "Couldn't create directory $dir.\n";

    "$dir/$export->{-indexFile}";
}

sub slide2main()
{   my $export = shift;
    '../' . $export->{-indexFile};
}

sub slide2linkname($)
{   my ($export, $slide) = @_;
    $slide->inLastPhase ? "$slide" : ("$slide ;" . $slide->phase);
}

sub main2slide($)
{   my ($export, $slide) = @_;
    $export->slideDir($slide) . '/' . $export->{-indexFile};
}

sub slide2slide($)
{   my ($export, $slide) = @_;
    '../' . $export->slideDir($slide) . '/' . $export->{-indexFile};
}

sub Title($$)
{   my ($export, $show, $slide) = @_;
    my ($slidename, $showname) = ("$slide", "$show");
    $showname eq $slidename ? $showname : "$showname, $slidename";
}

sub Chapter($$)
{   my ($export, $show, $slide) = @_;
    my ($slidename, $showname) = ("$slide", "$show");

    $showname eq $slidename
    ? $slidename
    : "<FONT SIZE=-1>$showname</FONT><BR> $slidename";
}

sub Header($$$$$$$)
{   my ( $export, $show, $slide, $logo, $title
       , $chapter, $commercial, $index) = @_;

    <<header;
<HTML>
<HEAD><TITLE>$title</TITLE></HEAD>
<BODY BGCOLOR=#ffffff TEXT=#000000>
$commercial
<TABLE WIDTH=100%>
<TR><TD>$logo</TD>
    <TD ALIGN=center><H1>$chapter</H1></TD></TR>
<TR><TD VALIGN=top>
$index
    </TD><TD VALIGN=top>
header
}

sub Footer($$$$)
{   my ($export, $show, $slide, $index, $signature) = @_;

    <<footer;
    </TD></TR>
<TR><TD>&nbsp;</TD>
    <TD VALIGN=top>
$index
    <HR NOSHADE>
$signature
    </TD></TR>
</TABLE>
</HTML>
footer
}

sub Commercial($$)
{   my ($export, $show, $slide) = @_;

    my $date = localtime time;

    <<commercial;
<!-- Produced by Portable Presenter on $date
     PPresenter:  http://ppresenter.org
  -->
commercial
}

sub PageLogo($$)
{   my ($export, $show, $slide) = @_;
    '';
}

sub ExtraText($$)
{   my ($export, $show, $slide) = @_;
    '';
}

sub VerticalIndex($$$$)
{   my ($export, $show, $slide, $previous, $next) = @_;

    return '' unless $slide;

    my $index = "<A HREF=".$export->slide2main.">Main</A><BR>\n";

    $index   .= "back: $previous<BR>" if $previous;
    $index   .= "next: $next<BR>"     if $next;
    $index;
}

sub HorizontalIndex($$$$)
{   my ($export, $show, $slide, $previous, $next) = @_;

    if($slide)
    {   my $main  = "<A HREF=".$export->slide2main.">Main</A><BR>\n";
        $previous = $main unless $previous;
        $next     = $main unless $next;
    }

    <<index;
<CENTER>
<TABLE WIDTH=80% BORDER=0 CELLSPACING=5>
<TR><TD ALIGN=left  VALIGN=top>$previous</TD>
    <TD ALIGN=right VALIGN=top>$next</TD></TR>
</TABLE>
</CENTER>
index
}

sub MainPageIndex($$)
{   my ($export, $show, $links) = @_;

    my $length = int((@$links+1)/2);     # length 2 column list.

    my @rows;
    for(my ($row, $row2) = (0,$length); $row <$length; $row++, $row2++)
    {
        push @rows, <<col1, (defined $links->[$row+$length] ? <<col2 : <<empty);
<TR><TD ALIGN=right>$row.</TD>
    <TD>$links->[$row]</TD>
col1
    <TD ALIGN=right>$row2.</TD>
    <TD>$links->[$row2]</TD></TR>
col2
    <TD COLSPAN=2>&nbsp;</TD></TR>
empty

    }

    <<index;
<CENTER>
<TABLE WIDTH=80%>
<TR><TH COLSPAN=2 ALIGN=left>Slides:</TH></TR>
@rows
</TABLE>
</CENTER>
index

}

sub Signature($$)
{   my ($export, $show, $slide) = @_;
    my $date      = localtime;
    my $slidename = $slide ? "$slide" : '';
    my $showname  = "$show";

    my $title     = $slidename eq ''        ? $showname
                  : $slidename eq $showname ? $slidename
                  : "$showname, $slidename";

    <<signature;
<I>$title.<BR>
   Generated by <A HREF="http://ppresenter.org">ppresenter</A>
   on $date.</I><BR>
signature
}

sub SlideImage($$$)
{   my ($export, $image, $slide, $view) = @_;

    my $viewport = $view->viewport;
    $viewport    =~ s/\W/_/g;

    my $file     = $viewport . '.' . lc($export->{-imageFormat});
    my $path     = $export->{-outputDir} . '/'
                 . $export->slideDir($slide) . '/'
                 . $file;

    $export->writeImage($image, $path);
    my ($width, $height) = $image->Get('width', 'height');

    <<include;
<IMG SRC="$file" WIDTH=$width HEIGHT=$height
 BORDER=0 HSPACE=15 VSPACE=15 ALIGN=center><P>
include
}

#
# The user interface to this module.
#

sub popup($$)
{   my ($export, $show, $screen) = @_;
    return $export->{popup}
        if exists $export->{popup};

    if($show->hasImageMagick)
    {   require PPresenter::Export::Images::ImageMagick;
        unshift @ISA, 'PPresenter::Export::Images::ImageMagick';
    }
    else
    {   require PPresenter::Export::Images::Tk;
        unshift @ISA, 'PPresenter::Export::Images::Tk';
    }

    $export->{popup} = my $popup = MainWindow->new(-screen => $screen
    , -title => 'Create a Website'
    );
    $popup->withdraw;

    my $vp  = $export->tkViewportSettings($show, $popup);
    my $fmt = $export->tkImageSettings($show,$popup);

    my $options = $popup->LabFrame
        ( -label     => "Don't know"
        , -labelside => 'acrosstop'
        );

    $options->Label
    ( -text     => 'export'
    , -anchor   => 'e'
    )->grid( $export->tkSlideSelector($popup)
           , -sticky => 'ew');

    $options->Label
    ( -text     => 'output directory'
    , -anchor   => 'e'
    )->grid( $options->Entry(-textvariable => \$export->{-outputDir})
           , -sticky => 'ew');

    $options->Label
    ( -text     => 'index file'
    , -anchor   => 'e'
    )->grid( $options->Entry(-textvariable => \$export->{-indexFile})
           , -sticky => 'ew');

    $options->Label
    ( -text     => 'slides as'
    , -anchor   => 'e'
    )->grid( $export->tkSlideFormatting($options, $show, 'slideAs')
           , -sticky => 'ew');

    if($show->containsSlideNotes)
    {   $options->Label
        ( -text     => 'notes as'
        , -anchor   => 'e'
        )->grid( $export->tkSlideFormatting($options, $show, 'notesAs')
               , -sticky => 'ew');
    }

    my $commands = $popup->Frame;
    $commands->Button
    ( -text      => 'Export'
    , -relief    => 'ridge'
    , -command   => sub { $popup->withdraw;
                          $export->makeSlides($show, $popup);
                        }
    )->grid($commands->Button
       ( -text      => 'Cancel'
       , -relief    => 'sunken'
       , -command   => sub {$popup->withdraw}
       )
       , -padx => 10, -pady => 10
    );

    $vp->pack(-fill => 'x') if $vp;
    $options->pack(-fill => 'x');
    $fmt->pack(-fill => 'x');
    $commands->pack(-fill => 'x');

    $popup->Popup(popover => 'cursor');
}

sub tkSlideFormatting($$$)
{   my ($export, $parent, $show, $label) = @_;

    my @options;
    # first slide used as standard for show, which is incorrect... but it
    # is hard to decide differently.  I do not expect many people will
    # change to incompatible formatters or templates within the show.

    my $view    = $show->find(slide => 'FIRST')->view('FIRST');
    my $linear  = $view->formatter->can('makeHTMLLinear');
    my $table   = $view->template->can('makeHTMLTable');

    push @options, 'image'     if $export->can('view2image');
    push @options, 'table'     if $table && $view->formatter->can('toHTML');
    push @options, 'flat text' if $linear;
    push @options, 'skip';

    $parent->Optionmenu
    ( -options  => \@options
    , -variable => \$export->{$label}
    , -command  => sub { $export->setSlideFormatting($label, shift) }
    );
}

sub setSlideFormatting($$$)
{   my ($export, $label, $option) = @_;
    $export->{"-$label"}
        = $option eq 'table'     ? 'TABLE'
        : $option eq 'flat text' ? 'LINEAR'
        : $option eq 'image'     ? 'IMAGE'
        : $option eq 'skip'      ? 'SKIP'
        : die "Unknown export option `$option'.\n";
}

sub slideFormatting($$)
{   my ($export, $value) = @_;
      $value eq 'TABLE'  ? 'table'
    : $value eq 'LINEAR' ? 'flat text'
    : $value eq 'IMAGE'  ? 'image'
    : $value eq 'SKIP'   ? 'skip'
    : undef
}

1;

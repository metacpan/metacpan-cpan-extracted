# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Template::Default;

@INCLUDES  = qw(
    PPresenter::Template::Default::Empty
    PPresenter::Template::Default::FrontPage
    PPresenter::Template::Default::TitleMain
    PPresenter::Template::Default::TitleLeftRight
    PPresenter::Template::Default::BigLeftTitleRight
    PPresenter::Template::Default::BigRightTitleLeft
    PPresenter::Template::Default::TitleLeftMiddleRight
    PPresenter::Template::Default::Title
    PPresenter::Template::Default::Main
    PPresenter::Template::Default::SlideNotes
    );

use strict;
use PPresenter::Template;
use base 'PPresenter::Template';

sub make_HTML_Linear($$)
{   my ($templ, $slide, $view) = @_;

    my @parts;
    push @parts, $templ->{-left}     if exists $templ->{-left};
    push @parts, $templ->{-right}    if exists $templ->{-right};
    push @parts, $templ->{-main}     if exists $templ->{-main};
    push @parts, @{$templ->{-place}} if exists $templ->{-place};

    join "\n<P>\n",
       map {$templ->toHTML($view->formatter, $_)}
           @parts;
}

package PPresenter::Template::Default::BigLeftTitleRight;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default big-left title right'
, -aliases      => [ 'dbltr', 'big-left title right', 'bltr',
                     'dtrbl', 'title right big-left', 'trbl' ]
, -left         => undef
, -right        => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;

    $templ->SUPER::prepareParts($slide, $view);

    my $deco          = $view->decoration;
    my ($sepx, $sepy) = $deco->separationXY($view);
    my $titleh        = $deco->titlebarHeight($view);
    my $has_footer    = $templ->hasFooter;

    my ($x0, $y0, $x1, $y1) = $deco->mainBoundsNoTitle($view, $has_footer);
    my $colw = ($x1-$x0-$sepx)/2;

    $templ->addPart2Make($x0, $y0, $x0+$colw, $y1, $templ->{-left}, 'main')
          ->addPart2Make($x1-$colw, $y0, $x1, $y0+$titleh
            , $view->formatter->titleFormat($view, $slide->title) , 'main')
          ->addPart2Make($x1-$colw, $y0+$titleh+$sepy, $x1, $y1
            , $templ->{-right}, 'main');
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top ROWSPAN=2>"
    . $templ->toHTML($view->formatter, $templ->{-left})
    . "</TD><TD ALIGN=center WIDTH=50%><H1>"
    . $templ->toHTML($view->formatter, $slide->title)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top WIDTH=50%>"
    . $templ->toHTML($view->formatter, $templ->{-right})
    . "</TD></TR>\n</TABLE>\n";
}

package PPresenter::Template::Default::BigRightTitleLeft;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default big-right title left'
, -aliases      => [ 'dbrtl', 'big-right title left', 'brtl'
                   , 'dtlbr', 'title left big-right', 'tlbr' ]
, -left         => undef
, -right        => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;

    $templ->SUPER::prepareParts($slide, $view);

    my $deco          = $view->decoration;
    my ($sepx, $sepy) = $deco->separationXY($view);
    my $titleh        = $deco->titlebarHeight($view);
    my $has_footer    = $templ->hasFooter;

    my ($x0, $y0, $x1, $y1) = $deco->mainBoundsNoTitle($view, $has_footer);
    my $colw = ($x1-$x0-$sepx)/2;

    $templ->addPart2Make($x0, $y0, $x0+$colw, $y0+$titleh
            , $view->formatter->titleFormat($view, $slide->title), 'main')
          ->addPart2Make($x0, $y0+$titleh+$sepy, $x0+$colw, $y1
            , $templ->{-left}, 'main')
          ->addPart2Make($x1-$colw, $y0, $x1, $y1, $templ->{-right}, 'main');
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    my $formatter = $slide->formatter;
    "<TABLE WIDTH=100%>\n<TR><TD ALIGN=center WIDTH=50%><H1>"
    . $templ->toHTML($formatter, $slide->title)
    . "</H1></TD>\n<TD COLSPAN=2 VALIGN=top>"
    . $templ->toHTML($formatter, $templ->{-right})
    . "</TD></TR>\n<TR><TD VALIGN=top WIDTH=50%>"
    . $templ->toHTML($formatter, $templ->{-left})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::Empty;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default empty'
, -aliases      => [ 'de', 'empty', 'e' ]
};


package PPresenter::Template::Default::FrontPage;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default front page'
, -aliases      => [ 'dfp', 'front page', 'fp' ]
, -author       => undef
, -company      => undef
, -talk         => undef
, -date         => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;

    $templ->SUPER::prepareParts($slide, $view);

print "Not implemented yet.\n";

    $templ;
}


package PPresenter::Template::Default::Main;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default main'
, -aliases      => [ 'dm', 'main', 'm' ]
, -main         => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;

    $templ->SUPER::prepareParts($slide, $view);

    $templ->addPart2Make
    ( $view->decoration->mainBoundsNoTitle($view, $templ->hasFooter)
    , $templ->{-main}, 'main'
    );
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top>"
    . $templ->toHTML($view->formatter, $templ->{-main})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::SlideNotes;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default slidenotes'
, -aliases      => [ 'slidenotes', 'SlideNotes', 'sn' ]
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;

    # overrules super prepareParts: no footer nor title required.
    # $templ->SUPER::prepareParts($slide, $view);

    $templ->addPart2Make( @{$view->decoration->notesBounds}
        , $templ->{-notes}, 'notes' );
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top>"
    . $templ->toHTML($view->formatter, $templ->{-notes})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::Title;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default title'
, -aliases      => [ 'dt', 'title', 't' ]
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;
    $templ->SUPER::prepareParts($slide, $view);
    $templ->prepareTitle($slide, $view);
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD ALIGN=center><H1>"
    . $templ->toHTML($view->formatter, $slide->title)
    . "</H1></TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::TitleLeftMiddleRight;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default title left middle right'
, -aliases      => [ 'dtlmr', 'title left middle right', 'tlmr',
                     'dtrml', 'title right middle left', 'trml',
                     'default title right middle left' ]
, -left         => undef
, -middle       => undef
, -right        => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;
    $templ->SUPER::prepareParts($slide, $view);

    my $deco = $view->decoration;

    my ($x0, $y0, $x1, $y1) = $deco->mainBounds($view, $templ->hasFooter);

    my $sepx = $deco->separationX($view);
    my $colw = ($x1-$x0 - 2*$sepx)/3;

    $templ->prepareTitle($slide, $view)
          ->addPart2Make($x0, $y0, $x0+$colw, $y1, $templ->{-left}, 'main')
          ->addPart2Make($x0+$colw+$sepx, $y0, $x0-$colw-$sepx, $y1
            , $templ->{-middle}, 'main')
          ->addPart2Make($x1-$colw, $y0, $x1, $y1, $templ->{-right}, 'main');
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top ALIGN=center COLSPAN=2><H1>"
    . $templ->toHTML($view->formatter, $slide->title)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top WIDTH=33%>"
    . $templ->toHTML($view->formatter, $templ->{-left})
    . "</TD><TD VALIGN=top WIDTH=33%>"
    . $templ->toHTML($view->formatter, $templ->{-middle})
    . "</TD><TD VALIGN=top WIDTH=33%>"
    . $templ->toHTML($view->formatter, $templ->{-right})
    . "</TD></TR>\n</TABLE>\n";
}



package PPresenter::Template::Default::TitleLeftRight;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default title left right'
, -aliases      => [ 'dtlr', 'title left right', 'tlr',
                     'dtrl', 'title right left', 'trl',
                     'default title right left' ]
, -left         => undef
, -right        => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;
    $templ->SUPER::prepareParts($slide, $view);

    my $deco = $view->decoration;
    my ($x0, $y0, $x1, $y1) = $deco->mainBounds($view, $templ->hasFooter);
    my $colw = ($x1-$x0 - $deco->separationX($view))/2;

    $templ->prepareTitle($slide, $view)
          ->addPart2Make($x0, $y0, $x0+$colw, $y1, $templ->{-left} , 'main')
          ->addPart2Make($x1-$colw, $y0, $x1, $y1, $templ->{-right}, 'main');
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    my $formatter = $view->formatter;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top COLSPAN=2><H1>"
    . $templ->toHTML($formatter, $slide->title)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top WIDTH=50%>"
    . $templ->toHTML($formatter, $templ->{-left})
    . "</TD><TD ALIGN=center WIDTH=50%>"
    . $templ->toHTML($formatter, $templ->{-right})
    . "</TD></TR>\n</TABLE>\n";
}

package PPresenter::Template::Default::TitleMain;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant ObjDefaults =>
{ -name         => 'default title main'
, -aliases      => [ 'dtm', 'title main', 'tm', 'default' ]
, -main         => undef
};

sub prepareParts($$)
{   my ($templ, $slide, $view) = @_;
    $templ->SUPER::prepareParts($slide, $view);

    $templ->prepareTitle($slide, $view)
          ->addPart2Make
            ( $view->decoration->mainBounds($view, $templ->hasFooter)
            , $templ->{-main}, 'main'
            );
}

sub make_HTML_table($$)
{   my ($templ, $slide, $view) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD ALIGN=center><H1>"
    . $templ->toHTML($view->formatter, $slide->title)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top>"
    . $templ->toHTML($view->formatter, $templ->{-main})
    . "</TD></TR>\n</TABLE>\n";
}

1;

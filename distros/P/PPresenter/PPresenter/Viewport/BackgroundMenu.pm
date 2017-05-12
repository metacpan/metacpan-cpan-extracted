# Copyright (C) 2000-2002, Free Software Foundation FSF.

# Viewport::BackgroundMenu
#
# A special version of a viewport: a viewport with controls.
#

package PPresenter::Viewport::BackgroundMenu;

use Tk;
use strict;

sub new($$$;)
{   my ($class, $show, $viewport, $screen, $has_popup) = @_;

    my $self = bless {}, $class;

    my $menu = $screen->Menu
    ( -tearoff   => 1
    , -menuitems => [ [ command => '  Control  ', -state => 'disabled'] ]
    );

    my $phases = $menu->Menu
    ( -tearoff   => 0
    , -menuitems =>
        [ [ command      => 'next phase'
          , -accelerator => 'Space'
          , -command     => sub {$show->addPhase(1); } ]
        , [ command      => 'flush phase'
          , -accelerator => 'Shift-Space'
          , -command     => sub {$show->addPhase(9); } ]
        ]
    );

    $phases->checkbutton
    ( -label   => 'Only finals'
    , -variable=> \$show->{-flushPhases}
    );

    $phases->checkbutton
    ( -label   => 'Start callbacks'
    , -variable=> \$show->{-enableCallbacks}
    );

    $menu->add
    ( 'cascade'
    , -label   => 'phases'
    , -menu    => $phases
    );

    $screen->bind("<Key-space>", sub {$show->addPhase(1);} );
    $screen->bind("<Shift-Key-space>", sub {$show->addPhase(9);} );

    my $steps = $menu->Menu
    ( -tearoff   => 0
    , -menuitems =>
        [ [ command      => 'next selected'
          , -underline   => 0
          , -accelerator => 'n'
          , -command     => sub {$show->showSlide('NEXT_SELECTED'); } ]
        , [ command      => 'previous in list'
          , -underline   => 0
          , -accelerator => 'p'
          , -command     => sub {$show->showSlide('PREVIOUS'); } ]
        , [ command      => 'back in history'
          , -underline   => 0
          , -accelerator => 'b'
          , -command     => sub {$show->showSlide('BACK'); } ]
        , [ command      => 'forward from history'
          , -underline   => 0
          , -accelerator => 'f'
          , -command     => sub {$show->showSlide('FORWARD'); } ]
        , [ command      => 'first in list'
          , -accelerator => '0'
          , -command     => sub {$show->showSlide('FIRST'); } ]
        , [ command      => 'Next in list'
          , -underline   => 0
          , -accelerator => 'N'
          , -command     => sub {$show->showSlide('NEXT'); } ]
        , [ command      => 'last in list'
          , -accelerator => '$'
          , -command     => sub {$show->showSlide('LAST'); } ]
        , '-'
        , [ command      => 'go'
          , -underline   => 0
          , -accelerator => 'g'
          , -command     => sub {$show->setRunning(1); } ]
        , [ command      => 'halt'
          , -underline   => 0
          , -accelerator => 'h'
          , -command     => sub {$show->setRunning(0); } ]
        ]
    );

    $screen->bind("<Key-0>", sub {$show->showSlide('FIRST');} );
    $screen->bind("<Key-dollar>", sub {$show->showSlide('LAST');} );
    $screen->bind("<Key-b>", sub {$show->showSlide('BACK');} );
    $screen->bind("<Key-f>", sub {$show->showSlide('FORWARD');} );
    $screen->bind("<Key-g>", sub {$show->setRunning(1);} );
    $screen->bind("<Key-h>", sub {$show->setRunning(0);} );
    $screen->bind("<Key-n>", sub {$show->showSlide('NEXT_SELECTED');} );
    $screen->bind("<Key-N>", sub {$show->showSlide('NEXT');} );
    $screen->bind("<Key-p>", sub {$show->showSlide('PREVIOUS');} );

    $menu->add('cascade'
    , -label   => 'steps'
    , -menu    => $steps
    );

    if($has_popup)
    {   $menu->command
        ( -label       => 'slides'
        , -underline   => 0
        , -command     => sub {$viewport->showControl}
        , -accelerator => 's'
        );

        $screen->bind("<Key-s>", sub {$viewport->showControl});
    }

    # Exporters

    my @exporters = $show->exporters;
    if(@exporters)
    {   my $export = $menu->Menu
        ( -tearoff     => 0
        );

        foreach (sort {"$a" cmp "$b"} @exporters)
        {   $export->add('command'
            , -label   => "$_"
            , -command => [sub {$_[0]->popup($show, $viewport->{-display})},$_ ]
            );
        }

        $menu->add('cascade'
        , -label       => 'export'
        , -menu        => $export
        );
    }

    $menu->command
    ( -label       => 'Iconify'
    , -accelerator => 'I'
    , -command     => sub {$show->iconifyControl}
    );
    $screen->bind("<Key-I>", sub {$show->iconifyControl} );

    # Control controls on control viewport ;)

    $menu->separator;

    $menu->checkbutton
    ( -label   => 'phases to go'
    , -variable=> \$viewport->{-showPhases}
    , -command => sub {$show->showSlide('THIS')}
    );

    $menu->checkbutton
    ( -label   => 'progress bar'
    , -variable=> \$viewport->{-showProgressBar}
    , -command => sub {$viewport->packViewport}
    );

    $menu->checkbutton
    ( -label   => 'progress buttons'
    , -variable=> \$viewport->{-showSlideButtons}
    , -command => sub {$viewport->packViewport}
    );

    $menu->checkbutton
    ( -label   => 'neighbour names'
    , -variable=> \$viewport->{-showNeighbours}
    , -command => sub {$viewport->packViewport}
    );
 
    $menu->command
    ( -label       => 'add controls'
    , -underline   => 5
    , -command     => sub {$viewport->showControls(1)}
    , -accelerator => 'c'
    );

    $menu->command
    ( -label       => 'remove controls'
    , -command     => sub {$viewport->showControls(0)}
    , -accelerator => 'C'
    );

    $screen->bind("<Key-c>", sub {$viewport->showControls(1)} );
    $screen->bind("<Key-C>", sub {$viewport->showControls(0)} );

    $menu->separator;
    $menu->command
        ( -label       => 'exit'
        , -underline   => 1
        , -command     => sub {$show->stop}
        , -accelerator => 'x/q'
        );

    $screen->bind("<Key-x>", sub {$show->stop} );
    $screen->bind("<Key-q>", sub {$show->stop} );

    $screen->bind("<Button-3>", sub {$menu->Popup(-popover => 'cursor') });

    return $self;
}

1;

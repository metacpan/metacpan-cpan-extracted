#!/usr/bin/perl -w

use strict; 

package AnimatedThingy;

use Qt;
use Qt::isa "Qt::Label";
use Qt::attributes qw[
    label
    step
    ox  oy
    x0  x1
    y0  y1
    dx0 dx1
    dy0 dy1
];

use constant nqix => 10;

sub NEW
{
    shift->SUPER::NEW($_[0]);
    label= $_[1]."\n... and wasting CPU\nwith this animation!\n";
    ox = [];
    oy = [];
    step = 0;
    for (my $i=0; $i<nqix; $i++)
    { ox->[0][$i] = oy->[0][$i] = ox->[1][$i] = oy->[1][$i] = 0 }
    x0 = y0 = x1 = y1 = 0;
    dx0 = rand(8)+2;
    dy0 = rand(8)+2;
    dx1 = rand(8)+2;
    dy1 = rand(8)+2;
    setBackgroundColor(&black);
}

sub show
{
    startTimer(150) unless isVisible();
    SUPER->show;
}

sub hide
{
    SUPER->hide;
    killTimers()
}

sub sizeHint
{
    Qt::Size(120,100)
}

sub timerEvent
{
    my $p = Qt::Painter(this);
    my $pn= $p->pen;
    $pn->setWidth(2);
    $pn->setColor(backgroundColor());
    $p->setPen($pn);

    step = (step + 1) % nqix;

    $p->drawLine(ox->[0][step], oy->[0][step], ox->[1][step], oy->[1][step]);

    (x0, dx0) = inc(x0, dx0, width());
    (y0, dy0) = inc(y0, dy0, height());
    (x1, dx1) = inc(x1, dx1, width());
    (y1, dy1) = inc(y1, dy1, height());
    ox->[0][step] = x0;
    oy->[0][step] = y0;
    ox->[1][step] = x1;
    oy->[1][step] = y1;

    my $c = Qt::Color;
    $c->setHsv( (step*255)/nqix, 255, 255 ); # rainbow effect
    $pn->setColor($c);
    $pn->setWidth(2);
    $p->setPen($pn);
    $p->drawLine(ox->[0][step], oy->[0][step], ox->[1][step], oy->[1][step]);
    $p->setPen(&white);
    $p->drawText(rect(), &AlignCenter, label);
}

sub paintEvent
{
    my $ev = shift;
    my $p = Qt::Painter(this);
    my $pn= $p->pen;
    $pn->setWidth(2);
    $p->setPen($pn);
    $p->setClipRect($ev->rect);
        for (my $i=0; $i<nqix; $i++) {
            my $c = Qt::Color;
            $c->setHsv( ($i*255)/nqix, 255, 255 ); # rainbow effect
            $pn->setColor($c);
            $p->setPen($pn);
            $p->drawLine(ox->[0][$i], oy->[0][$i], ox->[1][$i], oy->[1][$i]);
        }
        $p->setPen(&white);
        $p->drawText(rect(), &AlignCenter, label);
}

sub inc
{
    my ($x, $dx, $b)= @_;
    $x += $dx;
    if ($x<0) { $x=0; $dx=rand(8)+2; }
    elsif ($x>=$b) { $x=$b-1; $dx=-(rand(8)+2); }
    return ($x, $dx)
}

1;

package CPUWaster;

use Qt;
use Qt::isa "Qt::Widget";
use Qt::attributes qw[
    menubar
    file
    options
    rects
    pb
    td_id
    ld_id
    dl_id
    cl_id
    md_id
    got_stop
    timer_driven
    default_label
];
use Qt::slots
    drawItemRects  => ['int'],
    doMenuItem     => ['int'],
    stopDrawing    => [     ],
    timerDriven    => [     ],
    loopDriven     => [     ],
    defaultLabel   => [     ],
    customLabel    => [     ],
    toggleMinimumDuration
                   => [     ];
use AnimatedThingy;

use constant first_draw_item => 1000;
use constant last_draw_item  => 1006;

sub NEW
{
    shift->SUPER::NEW(@_);

    menubar = MenuBar( this, "menu" );
    pb = 0;

    file = Qt::PopupMenu;
    menubar->insertItem( "&File", file );
    for (my $i=first_draw_item; $i<=last_draw_item; $i++)
    { file->insertItem( drawItemRects($i)." Rectangles", $i) }
    Qt::Object::connect( menubar, SIGNAL "activated(int)", this, SLOT "doMenuItem(int)" );
    file->insertSeparator;
    file->insertItem( "Quit", Qt::app(),  SLOT "quit()" );
    options = Qt::PopupMenu;
    menubar->insertItem( "&Options", options );
    td_id = options->insertItem( "Timer driven", this, SLOT "timerDriven()" );
    ld_id = options->insertItem( "Loop driven", this, SLOT "loopDriven()" );
    options->insertSeparator;
    dl_id = options->insertItem( "Default label", this, SLOT "defaultLabel()" );
    cl_id = options->insertItem( "Custom label", this, SLOT "customLabel()" );
    options->insertSeparator;
    md_id = options->insertItem( "No minimum duration", this, SLOT "toggleMinimumDuration()" );
    options->setCheckable( 1 );
    loopDriven();
    customLabel();

    setFixedSize( 400, 300 );

    setBackgroundColor( &black );
}


sub drawItemRects
{
    my $id = shift;
    my $n = $id - first_draw_item;
    my $r = 100;
    while($n--)
    { $r *= $n%3 ? 5:4 }
    return $r
}


sub doMenuItem
{
    my $id = shift;
    draw(drawItemRects($id)) if ($id >= first_draw_item && $id <= last_draw_item)
}

sub stopDrawing
{ got_stop = 1 }

sub timerDriven()
{
    timer_driven = 1;
    options->setItemChecked( td_id, 1 );
    options->setItemChecked( ld_id, 0 );
}

sub loopDriven
{
    timer_driven = 0;
    options->setItemChecked( ld_id, 1 );
    options->setItemChecked( td_id, 0 );
}

sub defaultLabel
{
    default_label = 1;
    options->setItemChecked( dl_id, 1 );
    options->setItemChecked( cl_id, 0 );
}

sub customLabel
{
    default_label = 0;
    options->setItemChecked( dl_id, 0 );
    options->setItemChecked( cl_id, 1 );
}

sub toggleMinimumDuration
{
    options->setItemChecked( md_id,
       !options->isItemChecked( md_id ) );
}

sub timerEvent
{
    pb->setProgress( pb->totalSteps - rects ) if(!(rects%100));
    rects--;

    {
        my $p = Qt::Painter(this);

        my $ww = width();
        my $wh = height();

        if ( $ww > 8 && $wh > 8 )
        {
            my $c = Qt::Color(rand(255), rand(255), rand(255));
            my $x = rand($ww-8);
            my $y = rand($wh-8);
            my $w = rand($ww-$x);
            my $h = rand($wh-$y);
            $p->fillRect( $x, $y, $w, $h, Brush($c) );
        }
    }

    if (!rects || got_stop)
    {
        pb->setProgress( pb->totalSteps );
        my $p = Qt::Painter(this);
        $p->fillRect(0, 0, width(), height(), Brush(backgroundColor()));
        enableDrawingItems(1);
        killTimers();
        pb = 0;
    }
}

sub newProgressDialog
{
    my($label, $steps, $modal) = @_;
    my $d = ProgressDialog($label, "Cancel", $steps, this,
                           "progress", $modal);
    if ( options->isItemChecked( md_id ) )
    {  $d->setMinimumDuration(0)  }
    if ( !default_label )
    {  $d->setLabel( AnimatedThingy($d,$label) )  }
    return $d;
}

sub enableDrawingItems
{
    my $yes = shift;
    for (my $i=first_draw_item; $i<=last_draw_item; $i++)
    {
        menubar->setItemEnabled($i, $yes);
    }
}

sub draw
{
    my $n = shift;
    if ( timer_driven )
    {
        if ( pb ) {
            warn("This cannot happen!");
            return;
        }
        rects = $n;
        pb = newProgressDialog("Drawing rectangles.\n".
                               "Using timer event.", $n, 0);
        pb->setCaption("Please Wait");
        Qt::Object::connect(pb, SIGNAL "cancelled()", this, SLOT "stopDrawing()");
        enableDrawingItems(0);
        startTimer(0);
        got_stop = 0;
    }
    else
    {
        my $lpb = newProgressDialog("Drawing rectangles.\n".
                                    "Using loop.", $n, 1);
        $lpb->setCaption("Please Wait");

        my $p = Qt::Painter(this);
        for (my $i=0; $i<$n; $i++)
        {
            if(!($i%100))
            {
              $lpb->setProgress($i);
              last if ( $lpb->wasCancelled );
            }
            my ($cw, $ch) = (width(), height());
            my $c = Qt::Color(rand(255), rand(255), rand(255));
            my $x = rand($cw-8);
            my $y = rand($cw-8);
            my $w = rand($cw-$x);
            my $h = rand($cw-$y);
            $p->fillRect($x, $y, $w, $h, Brush($c));
        }
        $lpb->cancel;
        $p->fillRect(0, 0, width(), height(), Brush(backgroundColor()));
    }
}

1;

package main;

use Qt;
use CPUWaster;

my $a=Qt::Application(\@ARGV);
my $w=CPUWaster;

$w->show;
$a->setMainWidget($w);
exit $a->exec;

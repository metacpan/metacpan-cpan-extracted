# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Viewport::Neighbours;

use strict;
use Tk;

sub new($$;)
{   my ($class, $show, $viewport) = @_;

    my $font       = $viewport->font('PROPORTIONAL', 'regular',
        'roman', $viewport->{-neighbourNameSize});

    my $fontheight = 10;

    my $background = $viewport->{-progressBackground};
    my $foreground = $viewport->{-neighbourNameColor};

    my $display  = $viewport->screen->Canvas
        ( -background => $background
        , -height     => $fontheight +4
        );

    my $self = bless
    { display    => $display
    , foreground => $foreground
    , background => $background
    , fontheight => $fontheight
    }, $class;

    my $halveheight = ($fontheight+4)/2;

    $show->{prevslide_point} = $display->createLine
	( 5, $halveheight, 25, $halveheight,
        , -width    => 1
        , -arrow    => 'first'
        , -fill     => $background
        , -arrowshape=> [6,10,3]
        , -tags     => 'arrowleft'
        );

    $show->{prevslide} = $display->createText
        ( 30, 2
        , -text     => ''
        , -fill     => $foreground
        , -anchor   => 'nw'
        , -width    => 0     # no linebreaking
        , -tags     => 'left'
        );

    $show->{thisslide} = $display->createText
        ( $display->width/2, 2
        , -text     => ''
        , -fill     => $foreground
        , -anchor   => 'n'
        , -width    => 0
        , -tags     => 'curr'
        );

    $show->{nextslide} = $display->createText
        ( $display->width-30, 2
        , -text     => ''
        , -fill     => $foreground
        , -anchor   => 'ne'
        , -width    => 0
        , -tags     => 'right'
        );

    $show->{nextslide_point} = $display->createLine
	( $display->width-25, $halveheight, $display->width-5, $halveheight,
        , -width    => 1
        , -arrow    => 'last'
        , -fill     => $background
        , -arrowshape=> [6,10,3]
        , -tags     => 'arrowright'
        );

    return $self;
}

sub getBar() {$_[0]->{display}}

sub update($$$)
{   my ($self, $left, $current, $right) = @_;

    my $display    = $self->{display};

    $display->itemconfigure('left',       -text => $left );
    $display->itemconfigure('arrowleft',  -fill =>
        ( $left ? $self->{foreground} : $self->{background}) );

    $display->itemconfigure('curr',       -text => $current);
    $display->coords('curr', $display->width/2, 2);

    $display->itemconfigure('right',      -text => $right );
    $display->coords('right', $display->width-30, 2);

    $display->itemconfigure('arrowright', -fill =>
        ( $right ? $self->{foreground} : $self->{background}) );

    my ($width, $halveheight) = ($display->width, ($self->{fontheight}+4)/2);
    $display->coords('arrowright',$width-25,$halveheight,$width-5,$halveheight);

    $self;
}

1;

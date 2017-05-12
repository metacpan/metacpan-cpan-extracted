# Copyright (C) 2000-2002, Free Software Foundation FSF.

# PPresenter::Viewport::Phases with sub-classes.

use strict;
my $space = 5;

package PPresenter::Viewport::Phases::Circle;

sub new($$)
{   my ($class, $diameter, $color) = @_;
    bless {diameter => $diameter, color => $color}, $class;
}

sub dimensions($)
{   my $diameter = shift->{diameter};
    ($diameter, $diameter);
}

sub put($$$$)
{   my ($self, $viewport, $canvas, $x, $y) = @_;
    my ($diameter, $color) = @$self{'diameter', 'color'};

    $x += $space; $y += $space;
    $canvas->createOval($x, $y, $x+$diameter, $y+$diameter
        , -outline => $color
        );
}

sub remove($$)
{   my ($self, $canvas, $object) = @_;
    $canvas->delete($object);
}

package PPresenter::Viewport::Phases::Bullet;
use base 'PPresenter::Viewport::Phases::Circle';

sub put($$$$)
{   my ($self, $viewport, $canvas, $x, $y) = @_;
    my $object = $self->SUPER::put($viewport, $canvas, $x, $y);
    $canvas->itemconfigure($object, -fill => $self->{color});
    $object;
}

package PPresenter::Viewport::Phases::Box;
use base 'PPresenter::Viewport::Phases::Circle';

sub put($$$$)
{   my ($self, $viewport, $canvas, $x, $y) = @_;
    my $diameter = $self->{diameter};

    $x += $space; $y += $space;
    $canvas->createRectangle($x, $y, $x+$diameter, $y+$diameter
        , -outline => $self->{color}
        );
}

package PPresenter::Viewport::Phases::Square;
use base 'PPresenter::Viewport::Phases::Box';

sub put($$$)
{   my ($self, $viewport, $canvas, $x, $y) = @_;
    my $object = $self->SUPER::put($viewport, $canvas, $x, $y);
    $canvas->itemconfigure($object, -fill => $self->{color});
    $object;
}

package PPresenter::Viewport::Phases::Image;

sub new($$)
{   my ($class, $show, $file, $color, $viewport, $canvas) = @_;
    my $image = $show->image(-file => $file);

    die "Cannot find image $file for phase symbol.\n"
        unless defined $image;

    $image->prepare($viewport, $canvas);
    bless {image => $image, color => $color}, $class;
}

sub dimensions($)
{   my ($self, $viewport) = @_;
    $self->{image}->dimensions($viewport);
}

sub put($$$$)
{   my ($self, $viewport, $canvas, $x, $y) = @_;

    my $tag = "$viewport-$x,$y";
    $self->{image}->show($viewport, $canvas
    , $x+$space, $y+$space
    , -anchor => 'nw'
    , -tag    => $tag
    );

    $tag;
}

sub remove($$)
{   my ($self, $canvas, $object) = @_;
    $canvas->delete($object);
}

package PPresenter::Viewport::Phases;

use strict;
use Tk;

sub new($$)
{   my ($class, $show, $viewport) = @_;

    my $canvas = $viewport->canvas;
    my $self   = bless
    { viewport   => $viewport
    , canvas     => $canvas
    , show       => $show
    }, $class;

    $self->{horizontal} = $viewport->{-phaseDirection} eq 'horizontal' ? 1
                        : $viewport->{-phaseDirection} eq 'vertical'   ? 0
             : die "-phaseDirection must be 'horizontal' or 'vertical'\n";

    die "-phaseLocation must be ne, nw, se, or sw.\n"
        unless @$self{'vstart', 'hstart'}
            = $viewport->{-phaseLocation} =~ /^\s*([ns])([ew])\s*$/;

    $self;
}

sub setPhase($$)
{   my ($self, $phase, $nr_phases) = @_;

    my ($canvas, $viewport) = @$self{qw/canvas viewport/};

    my $symbol = $self->{symbol};
    $self->{symbol} = $symbol
        = $self->initSymbol($self->{show}, $viewport->{-phaseSymbol})
             unless defined $symbol;

    $self->{locations} = $self->getLocations($self->{symbol})
        unless defined $self->{locations};

    my $required = $nr_phases - $phase;

    foreach (0..9)
    {   if($_ < $required)
        {   next if defined $self->{shown}[$_];
            my ($x, $y) = @{$self->{locations}[$_]};
            $self->{shown}[$_] = $symbol->put($viewport, $canvas, $x,$y);
        }
        else
        {   next unless $self->{shown}[$_];
            $symbol->remove($canvas, $self->{shown}[$_]);
            $self->{shown}[$_] = undef;
        }
    }

    $self;
}

sub initSymbol($)
{   (my $self, my $show, local $_) = @_;

    my ($s, $c) = (10, 'yellow');
    return new PPresenter::Viewport::Phases::Circle($1||$s, $2||$c)
        if /^\s*circle\s*(\d+)?\s*(.*)$/;

    return new PPresenter::Viewport::Phases::Bullet($1||$s, $2||$c)
        if /^\s*bullet\s*(\d+)?\s*(.*)$/;

    return new PPresenter::Viewport::Phases::Box($1||$s, $2||$c)
        if /^\s*box\s*(\d+)?\s*(.*)$/;

    return new PPresenter::Viewport::Phases::Square($1||$s, $2||$c)
        if /^\s*square\s*(\d+)?\s*(.*)$/;

    return new PPresenter::Viewport::Phases::Image($show
        , $1||'redball.gif', $2||$c, $self->{viewport}, $self->{canvas})
            if /^\s*image\s*(\S+)\s*(.*)?$/;

    die "Do not know how to show phases with `$_'.\n";
}

sub getLocations($$)
{   my ($self, $symbol) = @_;
    my $viewport     = $self->{viewport};
    my ($sw, $sh)    = $symbol->dimensions($viewport);
    my ($cw, $ch)    = $viewport->canvasDimensions;
    my ($top, $left) = ($self->{vstart} eq 'n', $self->{hstart} eq 'w');

    my @locs;
    foreach (0..9)
    {   my ($x, $y) = ($left?0:$cw-$sw-2*$space, $top?0:$ch-$sh-2*$space);
        if($self->{horizontal}) {   $x += ($_ * ($sw+$space)) * ($left?1:-1); }
        else                    {   $y += ($_ * ($sh+$space)) * ($top ?1:-1);  }
        push @locs, [ $x, $y ];
    }

    \@locs;
}

1;

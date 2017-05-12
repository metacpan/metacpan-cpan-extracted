package SDL::Tutorial::Tetris::Model::Grid;

use strict;
use warnings;

use base 'SDL::Tutorial::Tetris::Base';

use Carp;
use Data::Dumper;

use SDL::Tutorial::Tetris::Model::Pieces;

sub new {
    my ($class, %params) = (@_);

    my $self  = $class->SUPER::new(%params);

    $self->evt_manager->reg_listener($self);
    $self->init(%params);

    return $self;
}

sub init {
    my ($self,%param) = @_;

    #TODO: Get the following from @_ (DONE!)

    $self->{board_line_width} ||= 6;
    $self->{block_size}       ||= 20;
    $self->{board_position}   ||= 300;
    $self->{screen_height}    ||= 480;

    $self->{width}  ||= 10;
    $self->{height} ||= 23;

    # used to test delete_line
    # my $arr_ref = [];
    # for my $x (0..18)
    # {
    #		$arr_ref->[$x][19] = 1;
    #  }

    $self->{grid} ||= [];
}

sub store_piece {
    my $self = shift;
    confess 'Expecting 4 parameters' if ($#_ != 3);
    my ($x, $y, $piece, $rotation) = @_;

    for (my $i1 = $x, my $i2 = 0; $i1 < $x + 5; $i1++, $i2++) {
        for (my $j1 = $y, my $j2 = 0; $j1 < $y + 5; $j1++, $j2++) {
            if (!($i1 < 0 || $j1 < 0)) {
                $self->{grid}->[$i1][$j1] = 1
                  if (
                    SDL::Tutorial::Tetris::Model::Pieces->block_color($piece, $rotation, $j2, $i2) != 0);
            }
        }
    }
}

sub is_game_over {
    my $self = shift;
    for (my $i = 0; $i < $self->{width}; $i++) {
        if (defined $self->{grid}->[$i][0]) {
            return 1 if ($self->{grid}->[$i][0] == 1);
        }
    }
    return 0;
}

#removes a line and moves everything one row down
sub delete_line {
    my $self  = shift;
    my $dline = shift;
    for (my $j = $dline; $j > 0; $j--) {

        for (my $i = 0; $i < $self->{width}; $i++) {
            $self->{grid}->[$i][$j] = $self->{grid}->[$i][$j - 1];
        }
    }
    return 1;
}

sub delete_possible_lines {

    my $self          = shift;
    my $deleted_lines = 0;
    for (my $j = 0; $j < $self->{height}; $j++) {


        my $i = 0;
        while ($i < $self->{width}) {
            last if !(defined($self->{grid}->[$i][$j]));
            $i++;
        }
        $deleted_lines += $self->delete_line($j) if $i == $self->{width};
    }
    return $deleted_lines;
}

sub is_free_loc {
    my $self = shift;
    confess 'Expecting 2 parameters' if $#_ != 1;

    #die 'got '.$_[0].' '.$_[1];
    my $grid = $self->{grid};

    #die Dumper $grid;
    return 1 if !defined($grid->[$_[0]][$_[1]]);
    return 0 if ($grid->[$_[0]][$_[1]] == 1);

}

sub get_x_pos_in_pixels {
    my $self = shift;
    confess 'Expecting 1 parameter got ' . $_[0] if (!defined($_[0]));
    return (
        (   $self->{board_position}
              - ($self->{block_size} * ($self->{width} / 2))
        ) + ($_[0] * $self->{block_size}) + 3
    );
}

sub get_y_pos_in_pixels {
    my $self = shift;
    confess 'Expecting 1 parameter got ' . $_[0] if (!defined($_[0]));
    return (($self->{screen_height} - ($self->{block_size} * $self->{height}))
        + ($_[0] * $self->{block_size}));

}

sub is_possible_movement {
    my $self = shift;
    confess 'Expecting 4 parameters' if $#_ != 3;
    my ($x, $y, $piece, $rotation) = @_;

    for (my $i1 = $x, my $i2 = 0; $i1 < $x + 5; $i1++, $i2++) {
        for (my $j1 = $y, my $j2 = 0; $j1 < $y + 5; $j1++, $j2++) {

            #check if block goes outside limits
            if (   $i1 < 0
                || $i1 > ($self->{width} - 1)
                || $j1 > ($self->{height} - 1))
            {
                return 0
                  if (
                    SDL::Tutorial::Tetris::Model::Pieces->block_color($piece, $rotation, $j2, $i2) != 0);
            }

            #check collision with blocks already on board
            if ($j1 >= 0) {
                return 0
                  if (
                    (SDL::Tutorial::Tetris::Model::Pieces->block_color($piece, $rotation, $j2, $i2) != 0)
                    && !($self->is_free_loc($i1, $j1)));
            }
        }
    }

    #no collision
    return 1;
}

sub notify {
    my ($self, $event) = (@_);

    print "Notify in Grid \n" if $self->{EDEBUG};

    if (defined $event && $event->{name} eq 'Tick') {
        #do checks
    }
}

1;

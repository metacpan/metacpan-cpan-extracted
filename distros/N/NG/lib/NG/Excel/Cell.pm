package Excel::Cell;

use 5.010;
use strict;
use warnings;
use base qw(Object);

sub new {
    my ( $pkg, @config ) = @_;
    my $cell = {
        value => "",
        width => 10,

        border_left => {
            width => 0,
            style => 'none',
            color => 0x0000ff,
        },
        border_bottom => {
            width => 0,
            style => 'none',
            color => 0x0000ff,
        },

        #end of default config
        @config,
    };
    return bless $cell, $pkg;
}

sub value {
    my ( $self, $new_val ) = @_;
    if ( defined $new_val ) {
        $self->{value} = $new_val;
        return $self;
    }
    else {
        return $self->{value};
    }
}

sub border_left {
    my ( $self, $width, $style, $color ) = @_;
    if ( scalar(@_) > 1 ) {
        $self->{border_left} = {
            width => $width,
            style => $style,
            color => $color,
        };
        return $self;
    }
    else {
        my $border_left = $self->{border_left};
        return
            $border_left->{width} . ', '
          . $border_left->{style} . ', '
          . sprintf( "0x%.6x", $border_left->{color} );
    }

}

sub border_bottom {

    my ( $self, $width, $style, $color ) = @_;
    if ( scalar(@_) > 1 ) {
        $self->{border_bottom} = {
            width => $width,
            style => $style,
            color => $color,
        };
        return $self;
    }
    else {
        my $border_bottom = $self->{border_bottom};
        return
            $border_bottom->{width} . ', '
          . $border_bottom->{style} . ', '
          . sprintf( "0x%.6x", $border_bottom->{color} );
    }
}

sub width {
    my ( $self, $new_val ) = @_;
    if ( defined $new_val ) {
        $self->{width} = $new_val;
        return $self;
    }
    else {
        return $self->{width};
    }
}

sub english_to_num {
    my ( $class, $width, $style ) = @_;
    given ( lc $style ) {
        when ('solid') {
            given ($width) {
                when (0) { return 7; }
                when (1) { return 1; }
                when (2) { return 2; }
                when (3) { return 5; }
                default  { return 7; }
            }
        }
        when ('dash') {
            given ($width) {
                when (1) { return 3; }
                when (2) { return 8; }
                default  { return 3; }
            }
        }
        when ('dash dot') {
            given ($width) {
                when (1) { return 9; }
                when (2) { return 10; }
                default  { return 9; }
            }
        }
        when ('dash dot dot') {
            given ($width) {
                when (1) { return 11; }
                when (2) { return 12; }
                default  { return 11; }
            }
        }
        when ('dot') {
            return 4;
        }
        when ('slantdash dot') {
            return 13;
        }
        when ('double') {
            return 6;
        }
        default { return 0; }    #none
    }
}

sub num_to_english {
    my ( $class, $index ) = @_;
    given ($index) {
        when (0)  { return ( 'none',          0 ); }
        when (1)  { return ( 'solid',         1 ); }
        when (2)  { return ( 'solid',         2 ); }
        when (3)  { return ( 'dash',          1 ); }
        when (4)  { return ( 'dot',           1 ); }
        when (5)  { return ( 'solid',         3 ); }
        when (6)  { return ( 'double',        3 ); }
        when (7)  { return ( 'solid',         0 ); }
        when (8)  { return ( 'dash',          2 ); }
        when (9)  { return ( 'dash dot',      1 ); }
        when (10) { return ( 'dash dot',      2 ); }
        when (11) { return ( 'dash dot dot',  1 ); }
        when (12) { return ( 'dash dot dot',  2 ); }
        when (13) { return ( 'slantdash dot', 2 ); }
        default   { return ( 'none',          0 ); }
    }
}
1;

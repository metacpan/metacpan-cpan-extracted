# -*-perl-*-

# $Id: 01_tie.t,v 3.2 2004/02/26 02:02:30 lachoy Exp $

use strict;
use Test::More  tests => 21;

# Test the SPOPS::Tie interface and the various pieces of it

do "t/config.pl";

# Simple require

{
    require_ok( 'SPOPS::Tie' );
    SPOPS::Tie->import( qw( IDX_CHANGE IDX_LAZY_LOADED ) );
}

# Basic operations

{
    my ( $obj, $data ) = do_tie();
    is( $obj->{ IDX_CHANGE() }, 0, 'Initial change flag' );
    $data->{sleepy} = 'sloopy';
    is( $data->{sleepy}, 'sloopy', 'Basic equivalency' );
    isnt( $obj->{ IDX_CHANGE() }, 0, 'Modified change flag' );
}

# Multivalue fields

{
    my ( $obj, $data ) = do_tie({ multivalue => { 'sleepy' => 1, 'dopey' => 2 } });
    ok( ! $obj->{ IDX_CHANGE() }, 'Initial change flag (multivalue)' );
    $data->{sleepy} = 'sloopy';
    ok( $obj->{ IDX_CHANGE() }, 'Modified change flag (multivalue)' );
    my $info = $data->{sleepy};
    is( scalar @{ $info }, 1, 'Multivalue set (number)' );
    is( $info->[0], 'sloopy',  'Multivalue set (content)' );
    $data->{sleepy} = 'snarly';
    $info = $data->{sleepy};
    is( scalar @{ $info }, 2, 'Multivalue set (second)' );
    $data->{sleepy} = { remove => 'snarly' };
    $info = $data->{sleepy};
    is( scalar @{ $info }, 1, 'Multivalue remove (number)' );
    is( $info->[0], 'sloopy', 'Multivalue remove (content)' );
    $data->{sleepy} = { modify => { sloopy => 'slocum' } };
    $info = $data->{sleepy};
    is( scalar @{ $info }, 1, 'Multivalue modify (number)' );
    is( $info->[0], 'slocum', 'Multivalue modify (content)' );
    $data->{slimey} = 'goo';
    is( $data->{slimey}, 'goo', 'Basic equivalency (multivalue)' );
}


# Field mapping

{
    my ( $obj, $data ) = do_tie({ field_map => { dopey => 'snarly', sleepy => 'smelly' } });
    ok( ! $obj->{ IDX_CHANGE() }, 'Initial change flag (field map)' );
    $data->{sleepy} = 'sloopy';
    ok( $obj->{ IDX_CHANGE() }, 'Modified change flag (field map)' );
    is( $data->{smelly}, 'sloopy', 'Field map (alias set)' );
    $data->{snarly} = 'growl';
    is( $data->{dopey}, 'growl', 'Field map (alias read)' );
}

# Lazy loading

{
    my ( $obj, $data ) = do_tie({ is_lazy_load  => 1,
                                  field         => [ qw/ fee fi fum / ],
                                  lazy_load_sub => \&get_lazy_field });
    $data->{fee} = 'manual - fee';
    is( $obj->{ IDX_LAZY_LOADED() }->{fee}, 1, 'Lazy load status (normal set)' );
    ok( ! $obj->{ IDX_LAZY_LOADED() }->{fum}, 'Lazy load status (lazy unset)' );
    is( $data->{fum}, 'muf', 'Lazy load (field value loaded)' );
}


# Simple routine to retrieve a SPOPS::Tie hashref plus its object so
# we can do various comparisons

sub do_tie {
    my ( $params ) = @_;
    my ( %data );
    my $obj = tie %data, 'SPOPS::Tie', 'My::Tie', $params;
    return ( $obj, \%data );
}


# Dumb routine to do 'lazy loading'

sub get_lazy_field {
    my ( $class, $data, $field ) = @_;
    return scalar( reverse $field );
}

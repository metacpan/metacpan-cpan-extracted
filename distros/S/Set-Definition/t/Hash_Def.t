#!/usr/bin/perl -w
use strict;

use Set::Definition;
use Test::More qw(no_plan);

my $set = test( "AND", { a => [ 1,2,3 ], b => [ 2,3,4 ] }, "a & b", [2,3] );
is( $set->contains(2) ? 1 : 0, 1, 'AND - Contains 2' );
is( $set->contains(4) ? 1 : 0, 0, 'AND - Does not contain 4' );

test( "Single group", { a => [ 1,2,3 ] }, "a", [1,2,3] );
test( "Group", { a => [1,2,3], b => [2,3], c => [4] }, "(a&b)|c", [2,3,4] );

sub test {
    my ( $name, $hash, $def, $checkmem ) = @_;
    my $set = Set::Definition->new( text => $def, ingroup_callback => \&in_group, hash => $hash );
    my $members = $set->members();
    is( aeq( $members, $checkmem ), 1, "$name - Membership accurate" );
    return $set;
}

# arrays equal
sub aeq {
    my ( $a1, $a2 ) = @_;
    my @s1 = sort @$a1;
    my @s2 = sort @$a2;
    my $ok = 1;
    for( my $i=0;$i<=$#s1;$i++ ) {
        my $m1 = $s1[$i];
        my $m2 = $s2[$i];
        $ok = 0 if( $m1 != $m2 );
    }
    if( !$ok ) {
        use Data::Dumper;
        print Dumper( $a1 );
        print Dumper( $a2 );
    }
    return 1;
}

sub in_group {
    my ( $group_name, $item, $options ) = @_;
    my $hash = $options->{'hash'};
    my $gp = $hash->{ $group_name };
    if( !$item ) {
        return $gp if( defined $gp );
        return [];
    }
    for my $member ( @$gp ) {
        return 1 if( $member eq $item );
    }
}


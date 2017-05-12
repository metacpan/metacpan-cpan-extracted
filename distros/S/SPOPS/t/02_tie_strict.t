# -*-perl-*-

# $Id: 02_tie_strict.t,v 3.0 2002/08/28 01:16:32 lachoy Exp $

use strict;
use Test::More  tests => 4;

# SPOPS::Tie was tested in a separate file, so just do the basics here

{
    require_ok( 'SPOPS::Tie::StrictField' );
}

{
    local $SIG{__WARN__} = sub {}; # Get rid of carp() messages
    my ( $obj, $data ) = do_tie({ field => [ qw/ fee fum / ] });
    $data->{fee}  = 'house';
    is( $data->{fee}, 'house', 'Normal field set' );
    $data->{fum}  = 'pancakes';
    is( $data->{fum}, 'pancakes', 'Strict field set' );    
    $data->{fuum} = 'blueberry';
    isnt( $data->{fum}, 'blueberry', 'Strict field incorrectly set' );
}

# Simple routine to retrieve a SPOPS::Tie hashref plus its object so
# we can do various comparisons

sub do_tie {
    my ( $params ) = @_;
    my ( %data );
    my $obj = tie %data, 'SPOPS::Tie::StrictField', 'My::Tie', $params;
    return ( $obj, \%data );
}




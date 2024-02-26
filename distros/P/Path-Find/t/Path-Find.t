#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

BEGIN { use_ok('Path::Find') }


####
my $m = Path::Find::matchable( "*.t" );
isa_ok( $m, 'CODE', "glob->coderef" );

my $re = Path::Find::matchable( qr/\.t$/ );
isa_ok( $re, 'CODE', "Regexp->coderef" );

my $sub = sub {1};
$m = Path::Find::matchable( $sub );
is( $m, $sub, "coderef->coderef" );

my $o = bless {}, 'bidon';
$m = Path::Find::matchable( $o );
isa_ok( $m, 'CODE', "obj->coderef" );

$m = Path::Find::matchable( "*" );

#####
my @list;

@list = path_find( "t", "honk" );
is_deeply( [ sort @list ], [ 't/1/2/3/honk', 't/honk' ], "honk" );

@list = path_find( "t", "h?nk" );
is_deeply( [ sort @list ], [ 't/1/2/3/honk', 't/honk' ], "h?nk" );

@list = path_find( "t", "*nk" );
is_deeply( [ sort @list ], [ 't/1/2/3/honk', 't/3/bonk', 't/bonk', 't/honk' ], "*nk" );

@list = path_find( "t", qr/\.t$/ );
is_deeply( [ sort @list ], [ 't/Path-Find.t' ], "Regex" );

@list = path_find( "t/1", $o );
is_deeply( [ sort @list ], [ 't/1/2/3/honk', 't/1/2/HONK.T' ], "object" );
@list = path_find( "t", qr/\.t$/i );
is_deeply( [ sort @list ], [ 't/1/2/HONK.T', 't/Path-Find.t' ], "Regex" );

@list = path_find( "t/1" );
is_deeply( [ sort @list ], [ 't/1/2/3/honk', 't/1/2/HONK.T' ], "*" ) or die join ', ', @list ;

my $obj = bless {}, 'bidon2';
@list = path_find( "t", $obj, qr/onk$/i );
is_deeply( [ sort @list ], [ 't/3/bonk', 't/bonk', 't/honk'], "object" );


my @d;
path_find( "t", sub { 
        my( $entry, $dir, $full, $depth ) = @_;
        # diag( "full=$full depth=$depth" );
        push @d, $full;
        return 1;
    }, "*" );

is( 0+@d, 5, "5 directories" ) or diag join ', ', @d;
is_deeply( [sort @d], [ qw( t/1 t/1/2 t/1/2/3 t/2 t/3 ) ], "Depth gauge" ) or diag join ', ', sort @d;

@list = path_find( "t", sub{1}, sub {
        my( $entry, $dir, $full, $depth ) = @_;
        # warn "full=$full depth=$depth";
        return $depth > 2;
    } );
is_deeply( [ sort @list ], [ 't/1/2/3/honk' ], "coderef" );


##########################################
package bidon;

sub match { 1 }


package bidon2;

sub match
{
    my( $self, $entry, $dir, $full ) = @_;
    my $depth = ( $dir =~ s(/)(/)g );
    # warn "depth=$depth dir=$dir";
    return $depth < 2;
}

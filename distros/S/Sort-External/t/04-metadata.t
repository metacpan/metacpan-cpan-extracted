#!perl -T
use strict;
use warnings;

use Test::More tests => 3;
use File::Spec;

use lib 'lib';
use Sort::External;

my ( $sortex, $item, @sorted );

# We supply curdir as a working_dir instead of allowing the default because
# File::Spec->tmpdir, used by the File::Temp constructor, returns different
# values under perl -T.  
my $curdir = File::Spec->curdir;

my @orig = 'a' .. 'y';

my $valid_utf8 = "z\xf0\x9d\x84\x9e";
Sort::External::_utf8_on($valid_utf8);
push @orig, $valid_utf8;

my @reversed = reverse @orig;

$sortex = Sort::External->new( cache_size => 5, working_dir => $curdir );
$sortex->feed($_) for @reversed;
$sortex->finish;
while ( defined( $item = $sortex->fetch ) ) {
    push @sorted, $item;
}
is_deeply( \@sorted, \@orig, "UTF-8 flag gets preserved" );
@sorted = ();

opendir( CURDIR, $curdir ) or die "couldn't opendir '$curdir': $!";
my @tainted = readdir CURDIR;
closedir CURDIR;
ok( is_tainted( $tainted[0] ), "test the test" );

@orig = sort( @orig, @tainted );
@reversed = reverse @orig;

$sortex = Sort::External->new( cache_size => 5, working_dir => $curdir );
$sortex = Sort::External->new( working_dir => $curdir );
$sortex->feed($_) for @reversed;
$sortex->finish;
while ( defined( $item = $sortex->fetch ) ) {
    push @sorted, $item;
}

my $num_tainted = grep { is_tainted($_) } @sorted;
is( $num_tainted, scalar @tainted, "taint flag should be preserved" );

# This function is taken from perlsec.
sub is_tainted {
    return !eval { eval( "#" . substr( join( "", @_ ), 0, 0 ) ); 1 };
}

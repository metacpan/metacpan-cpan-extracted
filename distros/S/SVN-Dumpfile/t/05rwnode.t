# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Dumpfilter.t'

#########################

use 5.008;
use Test::More tests => 39;
use strict;
use warnings;

use SVN::Dumpfile;
ok( 1, 'Module loading' );

#use Data::Dumper;
#open( LOG, ">/home/martin/log.txt" );

my $TESTDUMP = 't/test.dump';

my $df;
my $df2;

my $outfh;
my $output;

my $infh;
my $input;

ok(
open(IN, '<', $TESTDUMP) &&
($input = join ('', <IN>)) &&
close(IN)
, 'Could read test dumpfile.' );

open( $outfh, '>', \$output );
$df  = new SVN::Dumpfile($TESTDUMP);

ok( defined $df );
ok( $df->open );

ok( $df->version_supported );
is( $df->version, 2 );
is( $df->uuid, '9455fc8f-b1e6-4153-aa4f-ffbcff6ea47d' );

$df2 = $df->copy->create($outfh);
ok( defined $df2 );

ok( $df2->version_supported );
is( $df2->version, 2 );
is( $df2->uuid, '9455fc8f-b1e6-4153-aa4f-ffbcff6ea47d' );

while ( my $node = $df->read_node ) {
    ok( $df2->write_node($node), 'write node' );
}

close($outfh);

ok ( $input eq $output, 'Null-filter doesn\'t change file' );

#########################

$df = undef;
$df2 = undef;
#$output = undef;
open( $outfh, '>', \$output );
$df  = new SVN::Dumpfile($TESTDUMP);
$df->open;
$df2 = $df->copy->create($outfh);
ok( defined $df2 );
ok( $df2->{fh}->opened );

while ( my $node = $df->read_node ) {
    $node->changed;
    ok( $node->has_changed );
    ok( $df2->write_node($node), 'write node' );
}

close($outfh);

ok ( $input eq $output, 'Null-filter with recalc doesn\'t change file' );

# Debug output
#open (IN,  '>input');
#open (OUT, '>output');
#print IN  $input;
#print OUT $output;

1;
__END__

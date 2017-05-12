# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Dumpfilter.t'

#########################

use 5.008;
use Test::More tests => 12;
use strict;
use warnings;

use SVN::Dumpfile;
ok( 1, 'Module loading' );

#use Data::Dumper;
#open( LOG, ">/home/martin/log.txt" );


my $df;

my $outfh;
my $output;

my $infh;
my $input;

my $TESTDUMP = 't/test2.dump';

#### Test dumpfile version 1 without UUID
$df  = new SVN::Dumpfile($TESTDUMP);

ok( defined $df );
ok( $df->open );

ok( $df->version_supported );
is( $df->version, 1, 'Version');
is( $df->uuid, undef, 'UUID' );

$df = undef;


#### Test dumpfile version 2 without UUID
$TESTDUMP = 't/test3.dump';

$df  = new SVN::Dumpfile($TESTDUMP);

ok( defined $df );

my $warning;
ok( eval { local $SIG{__WARN__} = sub { $warning = shift }; $df->open } );

like ( $warning,
    qr/^Error: Dumpfile looks invalid. Couldn't find valid 'UUID' header/);
ok( $df->version_supported );
is( $df->version, 2, 'Version');
is( $df->uuid, undef, 'UUID' );

$df = undef;


1;
__END__

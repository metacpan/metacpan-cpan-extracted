# -*- Perl -*-
use Test::More tests => 21;
use Data::Dumper;
use strict;
use warnings;
use PDL::Lite ();

BEGIN { use_ok('PDL::NetCDF'); };
my $isNetCDF = PDL::NetCDF::isNetcdf4();
ok(($isNetCDF == 0 or $isNetCDF == 1), "isNetcdf4 function defined");

my $dir = -d "t" ? "t/" : "./";
SKIP: {
    skip "no netcdf4 support", 19 unless PDL::NetCDF::isNetcdf4;
    is(PDL::NetCDF::defaultFormat(), PDL::NetCDF::NC_FORMAT_CLASSIC, "classic format is default");
    is(PDL::NetCDF::defaultFormat(), PDL::NetCDF::NC_FORMAT_CLASSIC, "classic format is still default");
    my $nc4 = new PDL::NetCDF($dir . "foo.nc4", {REVERSE_DIMS => 1});
    isa_ok($nc4, 'PDL::NetCDF');
    is ($nc4->getFormat, PDL::NetCDF::NC_FORMAT_NETCDF4, "foo.nc4 is netcdf4");
    is($nc4->getatt('text_attribute'), "Text Attribute");
    print Dumper($nc4->{VARIDS});
    my ($deflate, $shuffle) = $nc4->getDeflateShuffle('var1');
    is($deflate, 0, 'uncompressed variable');
    is($shuffle, 0, 'unshuffled variable');

    # tests on a new file
    my $bar = $dir.'bar.nc4';
    unlink $bar if -f $bar;
    my $format = PDL::NetCDF::defaultFormat(PDL::NetCDF::NC_FORMAT_NETCDF4_CLASSIC);
    is($format, PDL::NetCDF::NC_FORMAT_CLASSIC, "got old format");
    is(PDL::NetCDF::defaultFormat(), PDL::NetCDF::NC_FORMAT_NETCDF4_CLASSIC, "switching default-format");
    my $nc = new PDL::NetCDF($bar, {REVERSE_DIMS => 1});
    isa_ok($nc, 'PDL::NetCDF');
    is ($nc->getFormat, PDL::NetCDF::NC_FORMAT_NETCDF4_CLASSIC, $bar ." is netcdf4");
    $nc->close;
    unlink $bar if -f $bar;
    $nc = new PDL::NetCDF($bar, {REVERSE_DIMS => 1, NC_FORMAT => PDL::NetCDF::NC_FORMAT_NETCDF4});
    is ($nc->getFormat, PDL::NetCDF::NC_FORMAT_NETCDF4, $bar ." is netcdf4");
    my $pdl = PDL::Basic::sequence(3, 2);
    $nc->put ('var1', ['dim1', 'dim2'], $pdl, {DEFLATE => 7, SHUFFLE => 1});
    ok(1, "put with deflate");
    ok(eq_array([7,1], [$nc->getDeflateShuffle('var1')]), "deflateShuffle for var1");
    $nc->putslice('var2', ['dim1','dim2','dim3'],[3,2,2],[0,0,0],[3,2,1],$pdl, {DEFLATE => 8, SHUFFLE => 1});
    ok(1, "putslice with deflate");
    $nc->sync();
    ok(1, "sync on nc4");
    ok(eq_array([8,1], [$nc->getDeflateShuffle('var2')]), "deflateShuffle for var2");
    my $outPdl = $nc->get('var1');
    ok(1, 'get deflated variable');
    ok(eq_array([$outPdl->list], [$pdl->list]), "write/read equal");
    unlink $bar if -f $bar;
}

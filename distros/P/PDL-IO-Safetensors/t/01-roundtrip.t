use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use PDL;
use PDL::IO::Safetensors qw(rsafetensors wsafetensors safetensors_header);

my (undef, $path) = tempfile(SUFFIX => '.safetensors', UNLINK => 1);

my $w = float([[1.5, 2.5, 3.5], [4.5, 5.5, 6.5]]);
my $b = double([0.25, -0.75]);
my $i = long([10, 20, 30, 40]);

ok(wsafetensors($path, { weight => $w, bias => $b, ids => $i }, { source => 'pdl' }), 'wsafetensors succeeded');

my $hdr = safetensors_header($path);
is($hdr->{__metadata__}{source}, 'pdl', 'metadata round-tripped');
is_deeply($hdr->{weight}{shape}, [2, 3], 'row-major shape recorded');
is($hdr->{weight}{dtype}, 'F32', 'F32 dtype recorded');
is($hdr->{bias}{dtype}, 'F64', 'F64 dtype recorded');
is($hdr->{ids}{dtype}, 'I32', 'I32 dtype recorded');

my $loaded = rsafetensors($path);
is_deeply([ $loaded->{weight}->dims ], [ $w->dims ], 'weight dims match');
ok(all(approx($loaded->{weight}, $w)), 'weight values match');
ok(all(approx($loaded->{bias}, $b)), 'bias values match');
ok(all($loaded->{ids} == $i), 'ids values match');

done_testing();

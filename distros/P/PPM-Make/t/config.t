use Test::More;
use strict;
use FindBin;
use PPM::Make;

$ENV{PPM_CFG} = "$FindBin::Bin/ppm.cfg";
my $ppm = PPM::Make->new(arch => 'foo');
ok($ppm);
is(ref($ppm), 'PPM::Make');
my $opts = $ppm->{opts};
ok($opts);
is( $opts->{upload}->{user}, 'sarah');
is( $opts->{upload}->{passwd}, 'justina');
is( $opts->{upload}->{ppd}, '/home/to/wherever');
is( $opts->{upload}->{host}, 'a.galaxy.far.far.away');
is( $opts->{upload}->{ar}, undef);
is( $opts->{binary}, 'http://www.foo.com/bar');
is( $opts->{vs}, 1);
$ppm = PPM::Make->new(arch => 'bar');
$opts = $ppm->{opts};
is( $opts->{binary}, 'http://www.foo.com/bar');
is( $opts->{vs}, undef);
is( $opts->{upload}->{ppd}, '/path/to/ppds');
is( $opts->{upload}->{ar}, 'x86');
$ppm = PPM::Make->new(arch => 'harry');
$opts = $ppm->{opts};
is( $opts->{binary}, 'http://www.foo.com/bar');
is( $opts->{vs}, 1);
is( $opts->{upload}->{host}, undef);
$ppm = PPM::Make->new(arch => 'foo', vs => 0, binary => 'http://localhost',
                      upload => {ppd => '/another/path', user => 'lianne'});
$opts = $ppm->{opts};
is( $opts->{binary}, 'http://localhost');
is( $opts->{vs}, 0);
is( $opts->{upload}->{ppd}, '/another/path');
is( $opts->{upload}->{user}, 'lianne');

done_testing;

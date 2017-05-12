
use ExtUtils::testlib;
use Test::More 'tests' => 27;
BEGIN { use_ok('Net::Address::Ethernet', qw( :all ), ) };

my $sOS = $^O;
my $s = get_address;
ok(defined($s), 'defined');
isnt($s, '', 'not empty');
my $iIsAnAddress = ok(is_address($s), 'looks like an address');
if (0 && ! $iIsAnAddress)
  {
  # I'd like to repeat the test with debugging turned on, to see what
  # it's trying to parse.  (Unfortunately, the module caches its
  # parsed results!)
  $s = get_address(88);
  } # if
is($s, canonical($s), 'is canonical');
diag(qq{FYI, your ethernet address is $s});
# Test for array context:
my @a = get_address(0);
diag(qq{in integer bytes, that's }. join(',', @a));
is(scalar(@a), 6, 'got 6 bytes');
my @arh = get_addresses();
ok(@arh, 'got an array');
my $rh = shift @arh;
isa_ok($rh, 'HASH', 'got a hashref');
$s = $rh->{sEthernet};
# Some adapters (e.g. loopback) have no Ethernet address, so don't do this:
# ok(is_address($s), "got Ethernet address =$s=");
# is($s, canonical($s), 'is canonical');
is($rh->{rasIP}->[0], $rh->{sIP}, 'IP matches');

# Low-level tests of basic functionality:
ok(! is_address(undef));
ok(! is_address(''));
ok(! is_address('not an address'));
ok(is_address('1:2:3:a:b:c'));
ok(is_address('1:22:3:a:Bb:C'));
ok(is_address('01:20:03:0a:0b:0c'));
ok(is_address('11:22:33:aa:bb:cc'));
ok(is_address('11:22:33:AA:BB:CC'));
ok(is_address('11,22.33 A/BB;C'));
is(canonical(undef), '');
is(canonical(''), '');
is(canonical('not a number'), '');
is(canonical('1:2:3:a:B:c'), '01:02:03:0A:0B:0C');
is(canonical('1:22:3:a:bb:c'), '01:22:03:0A:BB:0C');
is(canonical('11:22:33:aa:Bb:CC'), '11:22:33:AA:BB:CC');
is(canonical('1-2-3-a-B-c'), '01:02:03:0A:0B:0C');
is(canonical('1 22 3 a bb c'), '01:22:03:0A:BB:0C');
is(canonical('11;22,3 aa.Bb/CC'), '11:22:03:AA:BB:CC');

__END__


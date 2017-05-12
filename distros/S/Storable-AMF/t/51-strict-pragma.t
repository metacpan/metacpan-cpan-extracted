use lib 't';
# vim: ts=8 et sw=4 sts=4
use ExtUtils::testlib;
use strict;
use warnings;
use Storable::AMF0 qw(freeze thaw);
use Test::More tests=>8;

my $s = freeze( bless {}, 'testlib');
ok(thaw $s, 1);
is(ref (thaw $s, 1), 'testlib');
$s=~s/testlib/nooplib/;
is( ref( thaw $s, 1), 'HASH');
is( ref thaw($s), 'nooplib');

$s = Storable::AMF3::freeze( my $obj = bless {}, 'testlib');
#~ print Dumper(length($s), $obj);
#~ (my $a=$s)=~s/(\W)/"\\x".unpack("H*",$1)/ge;
#~ print Dumper($a);
ok(Storable::AMF3::thaw $s, 1);
is(ref (Storable::AMF3::thaw $s, 1), 'testlib');
$s=~s/testlib/noopPPP/;
is( ref( Storable::AMF3::thaw $s, 1), 'HASH');
is( ref Storable::AMF3::thaw($s), 'noopPPP');
our $TODO;
*{TODO} = *Test::More::TODO;




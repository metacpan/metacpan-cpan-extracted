use strict;
# vim: ts=8 et sw=4 sts=4
use warnings;
use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw parse_option);
use Scalar::Util qw(dualvar);
eval 'use Test::More tests => 6;';
my $pref_number_minus = parse_option( '-prefer_number' );
my $pref_number_plus  = parse_option( '+prefer_number' );
my $s0 = freeze dualvar(15, "Hello World!!!");
my $s1 = freeze dualvar(15, "Hello World!!!"), $pref_number_minus;
my $s2 = freeze dualvar(15, "Hello World!!!"), $pref_number_plus ;

my $s3 = Storable::AMF3::freeze dualvar(15, "Hello World!!!");
my $s4 = Storable::AMF3::freeze dualvar(15, "Hello World!!!"), $pref_number_minus;
my $s5 = Storable::AMF3::freeze dualvar(15, "Hello World!!!"), $pref_number_plus ;

printf STDERR "      ord(+-)=%d %d. -number=%d\n", ord("+"), ord("-"), $pref_number_minus;
is(Storable::AMF0::thaw($s0), 15, "Dual var is number (D)");
is(Storable::AMF0::thaw($s1), "Hello World!!!", "Dual var is string(-N)");
is(Storable::AMF0::thaw($s2), 15, "Dual var is number (+N)");

is(Storable::AMF3::thaw($s3), 15, "Dual var is number (D)");
is(Storable::AMF3::thaw($s4), "Hello World!!!", "Dual var is string (-N)");
is(Storable::AMF3::thaw($s5), 15, "Dual var is number (+N)");



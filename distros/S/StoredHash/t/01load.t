# Test that code loada and compiles OK.
# Running Coverage test:
# - cd to module root
# - Run: cover -delete;cover -test
# - View in browser: cover_db/coverage.html
use strict;
use warnings;
use Test::More;
use lib '..';
# Test availability of ARS
# Store test counts instead of flags
my $tcnt = 23;
my ($have_ars, $have_ldap) = (10, 10);
eval("use ARS;");
if ($@) {$have_ars = 0;$@=undef;note("No ARS");} # plan(tests => 23);
eval("use Net::LDAP;");
if ($@) {$have_ldap = 0;$@=undef;note("No Net::LDAP");} # plan(tests => 23);
# Plan
my $total = $tcnt + $have_ars + $have_ldap; # 32
plan(tests => $total); # 11, 22

use_ok('StoredHash');
#use Scalar::Util ('reftype');
ok($StoredHash::VERSION, "StoredHash Has VERSION String ($StoredHash::VERSION)");
my $p = StoredHash->new('table' => 'product', 'pkey' => ['id'],);
#if( $^O eq 'MacOS' ) {}
ok(ref($p) eq 'StoredHash', "Got Instance of persister (as ref)");
isa_ok($p, 'StoredHash');
my @shouldbeabletodo = ('new','insert','exists','update','delete','load','loadset','count');
map({can_ok($p, $_);} @shouldbeabletodo);
# Limit to loading only
if ($have_ars) {
  test_class_abilities('StoredHash::ARS');
}
if ($have_ldap) {
   test_class_abilities('StoredHash::LD');
}
use_ok('StoredHash::Bulk');
ok($StoredHash::Bulk::VERSION, "StoredHash::Bulk Has VERSION String ($StoredHash::Bulk::VERSION)");
my @bmeths = ('insert','update','store', 'ins_or_upd', 'makeidcache',
   '_exists', 'prepare', );
map({can_ok('StoredHash::Bulk', $_);} @bmeths);
# Must do StoredHash::ISA low level
#NOT:use_ok('StoredHash::ISA');
eval("use StoredHash::ISA;");
ok($@, "Got Exception with missing class context and missing persister info");
ok($StoredHash::ISA::VERSION, "... However StoredHash::ISA loaded fine ($StoredHash::ISA::VERSION)");

sub test_class_abilities {
   my ($class) = @_;
   no strict ('refs');
   use_ok($class);
   my $vv = "$class\:\:VERSION";
   ok(${$vv}, "$class Has VERSION String (${$vv})");
   map({can_ok($class, $_);} @shouldbeabletodo);
}

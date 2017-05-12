use strict;
use warnings;

use Test::More 0.96;
use lib 't/lib';
our $TODO;
use Requires::CCAPI \$TODO;
use mocktest;

my $mock = mocktest->new();

#
# This test tests the behaviour of Changes files with {{$NEXT}} in them.
# Prior to CPAN::Changes 0.17, CPAN::Changes emitted extra whitespace.
#
# This tests for this behaviour being sufficient to cause a problem.
#
# However, as of 0.17 it is no longer a problem, but this test is still
# here in case other inconsitencies crop up.
#
use Test::CPAN::Changes::ReallyStrict::Object;

my $obj = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    filename            => "corpus/Changes_03.txt",
    delete_empty_groups => undef,
    keep_comparing      => 1,
    next_token          => qr/\{\{\$NEXT\}\}/
  }
);

my $need_diag;

if ( not ok( $obj->changes_ok, "Expected {NEXT} file is good ( Fixed in CPAN::Changes 0.17 )" ) ) {
  $need_diag = 1;
}
if ( not is( $mock->num_events, 423, 'There are 423 events sent to the test system with this option on' ) ) {
  $need_diag = 1;
}
if ($need_diag) {
  diag $_ for $mock->ls_events;
}
done_testing;

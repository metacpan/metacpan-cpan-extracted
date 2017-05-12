use strict;
use warnings;

use Test::More 0.96;
use lib 't/lib';
our $TODO;
use Requires::CCAPI \$TODO;
use mocktest;

my $mock = mocktest->new();

use Test::CPAN::Changes::ReallyStrict::Object;

my $x = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    filename            => "corpus/Changes_02.txt",
    delete_empty_groups => undef,
    keep_comparing      => 1,
  }
);

my $diag_needed;

if ( not ok( !$x->changes_ok, "Expected bad file is bad ( In progress )" ) ) {
  $diag_needed = 1;
}
if ( not is( $mock->num_events, 708, "There is 708 events sent to the test system with this option on" ) ) {
  $diag_needed = 1;
}
if ($diag_needed) {
  diag $_ for $mock->ls_events;
}

done_testing;

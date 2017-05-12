use strict;
use warnings;

use Test::More 0.96;
use lib 't/lib';

our $TODO;
use Requires::CCAPI \$TODO;
use mocktest;

my $mock = mocktest->new();

use Test::CPAN::Changes::ReallyStrict ();
my $res = Test::CPAN::Changes::ReallyStrict::_real_changes_file_ok(
  $mock,
  {
    delete_empty_groups => undef,
    keep_comparing      => 1,
    filename            => "corpus/Changes_02.txt",
  }
);

my $need_diag;

if ( not ok( !$res, "Expected bad file is bad ( In progress )" ) ) {
  $need_diag = 1;
}
if ( not is( $mock->num_events, 708, "There is 708 events sent to the test system with this option on" ) ) {
  $need_diag = 1;
}
if ($need_diag) {
  diag $_ for $mock->ls_events;
}

done_testing;

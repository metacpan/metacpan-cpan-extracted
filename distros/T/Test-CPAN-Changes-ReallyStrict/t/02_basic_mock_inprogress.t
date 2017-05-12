use strict;
use warnings;

use Test::More 0.96;
use lib "t/lib";
use mocktest;
my $mock = mocktest->new();

use Test::CPAN::Changes::ReallyStrict;

#
# This tests for the behaviour that, a file with a {{NEXT}}
# token in it is deemed "invalid" if the next-token option is
# not parsed to the validator.

my $result = Test::CPAN::Changes::ReallyStrict::_real_changes_file_ok(
  $mock,
  {
    delete_empty_groups => undef,
    keep_comparing      => undef,
    filename            => "corpus/Changes_02.txt",
  }
);

if ( not ok( !$result, "Expected bad file is bad ( In progress )" ) ) {
  note $_ for $mock->ls_events;
}

done_testing;

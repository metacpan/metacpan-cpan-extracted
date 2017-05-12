use strict;
use warnings;

use Test::More 0.96;
use lib "t/lib";
use mocktest;

my $mock = mocktest->new();

use Test::CPAN::Changes::ReallyStrict::Object;

#
# This tests for the behaviour that, a file with a {{NEXT}}
# token in it is deemed "invalid" if the next-token option is
# not parsed to the validator.
#

my $obj = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    delete_empty_groups => undef,
    keep_comparing      => undef,
    next_token          => '__',
    filename            => "corpus/Changes_02.txt",
  }
);

if ( not ok( !$obj->changes_ok, "Expected bad file is bad ( In progress )" ) ) {
  note $_ for $mock->ls_events;
}

done_testing;

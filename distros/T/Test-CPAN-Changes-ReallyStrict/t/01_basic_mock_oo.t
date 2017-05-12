use strict;
use warnings;

use Test::More 0.96;
use lib 't/lib';

our $TODO;
use Requires::CCAPI \$TODO;
use mocktest;

my $mock = mocktest->new();

use Test::CPAN::Changes::ReallyStrict::Object;

my $obj = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    delete_empty_groups => undef,
    keep_comparing      => undef,
    filename            => "corpus/Changes_01.txt"
  }
);

if ( not ok( $obj->changes_ok, "Expected good file is good" ) ) {
  note $_ for $mock->ls_events;
}

done_testing;

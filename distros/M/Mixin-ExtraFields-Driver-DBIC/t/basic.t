use strict;
use warnings;

use lib 't/lib';

use File::Spec;
use File::Temp qw(tempdir);
use Test::More 'no_plan';

use SQL::Translator 0.11016; # needed for deployment
use TestSchema;

my $tempdir = tempdir(CLEANUP => 1);
my $dbfile  = File::Spec->catfile($tempdir, 'mefddbic.db');
my $schema = TestSchema->connect(
  "dbi:SQLite:$dbfile",
  undef,
  undef,
);

$schema->deploy;

my $o_rs = $schema->resultset('TestObject');

my %obj = (
  1 => $o_rs->create({ object_name => 'Object 1' }),
  2 => $o_rs->create({ object_name => 'Object 2' }),
);

for (1 .. 2) {
  is_deeply(
    { $obj{ $_ }->get_all_extra },
    { },
    "no extras yet for object $_",
  );
}

$obj{1}->set_extra(foo => 10);

is_deeply(
  { $obj{1}->get_all_extra },
  { foo => 10 },
  "set extra for obj 1",
);

is_deeply(
  { $obj{2}->get_all_extra },
  { },
  "obj 2 still has no extras",
);

pass('all done');

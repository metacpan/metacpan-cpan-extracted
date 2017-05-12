use strict;
use warnings;
use Python::Serialize::Pickle::InlinePython;
use Test::More tests => 4;
use File::Temp;

my $tmp = File::Temp->new(UNLINK => 1);

my $pickle = Python::Serialize::Pickle::InlinePython->new(">$tmp");
$pickle->dump([qw/a b c/]);
$pickle->dump([qw/d e f/]);
$pickle->close();

my $reader = Python::Serialize::Pickle::InlinePython->new("$tmp");
is_deeply $reader->load, [qw/a b c/];
is_deeply $reader->load, [qw/d e f/];
is_deeply $reader->load, undef;

ok 1;


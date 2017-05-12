use strict;
use warnings;
use Python::Serialize::Pickle::InlinePython;
use Test::More tests => 4;

my $pickle = Python::Serialize::Pickle::InlinePython->new('t/sampledata.pickle');
is_deeply $pickle->load, [1,2,3];
is_deeply $pickle->load, [4,5,6];
is_deeply $pickle->load, undef;
ok 1;


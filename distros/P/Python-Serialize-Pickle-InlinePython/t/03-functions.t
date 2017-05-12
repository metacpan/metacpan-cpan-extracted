use strict;
use warnings;
use Python::Serialize::Pickle::InlinePython::Functions;
use Test::More tests => 4;
use File::Temp;

is_deeply LoadFile('t/sampledata.pickle'), [1,2,3];

my $tmp = File::Temp->new(UNLINK => 1);
DumpFile("$tmp", {a => 1, b => 2});
is_deeply LoadFile("$tmp"), {a => 1, b => 2};

my $dat = do {
    local $/;
    open my $fh, "<", "t/sampledata.pickle" or die $!;
    <$fh>;
};
is_deeply Load($dat), [1,2,3];
is_deeply Load(Dump([1,2,3])), [1,2,3];


use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Table::Readable 'read_table';

my $scalar = <<EOF;
a: b
c: d

a: e
c: f

EOF
my @t = read_table ($scalar, scalar => 1);
ok (@t == 2, "Two entries");
is ($t[0]->{a}, 'b', "Spot check on an entry is OK");
done_testing ();

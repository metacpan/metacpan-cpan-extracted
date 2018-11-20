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
my $input =<<'EOF';
x: \   3   \
%%a:
\


3


\
%%

x: \\   3   \\
%%a:
\\


3


\\
%%
EOF

my @entries = read_table (\$input);
ok (@entries == 2, "Got two entries");
is ($entries[0]{x}, '   3   ', "Got whitespace before and after");
is ($entries[0]{a}, "\n\n\n3\n\n\n", "Got whitespace before and after");
is ($entries[1]{x}, '\\   3   \\', "Got slash/whitespace before and after");
is ($entries[1]{a}, "\\\n\n\n3\n\n\n\\", "Got slash/whitespace before and after");

done_testing ();

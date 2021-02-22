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
use Table::Trans 'read_trans';
my $tin = <<EOF;
id: baby
en: babystuff
ja: be-bi-

id: face
en: face
ja: {{baby}}

EOF
my $trans = read_trans ($tin, scalar => 1);
my $jface = $trans->{face}{ja};
is ($jface, 'be-bi-');
done_testing ();

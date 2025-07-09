use v5.16;
use Test::More;
use Query::Tags qw(parse_query);

my $s = "abc def_ghi  jkl-mn0   123.456";
my @vals = split /\s+/, $s;

my $q = parse_query($s)->tree;
for my $p ($q->pairs) {
    state $i;
    ok !defined $p->key, 'key undefined';
    is "". $p->value, $vals[$i++], 'correct value';
}

done_testing;

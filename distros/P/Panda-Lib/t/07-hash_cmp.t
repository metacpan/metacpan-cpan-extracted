use 5.012;
use warnings;
use blib;
use Panda::Lib 'compare';
use Test::More;
use Test::Deep;

# check hashes and arrays
my $h1d = {a => 1, b => 2, c => 3, d => 4};
my $h1s = {c => 'c', d => 'd', e => 'e', f => 'f'};
my $s1 = '{"max_qid"=>11,"clover"=>{"fillup_multiplier"=>"1.3","finish_date"=>12345676}}';
my $s2 = '{"clover"=>{"finish_date"=>12345676,"fillup_multiplier"=>"1.3"},"max_qid"=>11}';
my $s3 = '{"clover"=>{"finish_date"=>12345676,"fillup_multiplier"=>1.3},"max_qid"=>11}';
my $s4 = '{"max_qid"=>11}';
my $s5 = '{"max_qid"=>11,"no_arrays_yet"=>[1,2,3]}';
my $s6 = '{"max_qid"=>11,"no_arrays_yet"=>[1,2,3]}';
my $s7 = '{"max_qid"=>11,"no_arrays_yet"=>[1,undef,3]}';
my $s8 = '{"max_qid"=>11,"no_arrays_yet"=>[1,{"fuck"=>"dick"},3]}';
my $s9 = '{"max_qid"=>11,"no_arrays_yet"=>[1,{"fuck"=>"dick"},3]}';

my $s10 = '{"hours"=>[15],"templ"=>{"marker"=>"nf1","subjects"=>"{\\"l10n\\"=>\\"test [% l10n.col.auto.5 %]\\"}","bodies"=>"{\\"l10n\\"=>\\"test\\"}","title"=>"Templ Name","l10n"=>1},"mode"=>0,"active"=>1,"type"=>9,"condition"=>"{\\"lastvisit\\"=>[0,1],\\"level\\"=>[2,50],\\"custom\\"=>\\"game.recipient.return_bonus_date != undef\\",\\"regago\\"=>[2,4]}"}';

my $s11 = '{"hours"=>[15],"templ"=>{"marker"=>"nf1","subjects"=>"{\\"l10n\\"=>\\"test [% l10n.col.auto.5 %]\\"}","bodies"=>"{\\"l10n\\"=>\\"test2\\"}","title"=>"Templ Name","l10n"=>1},"mode"=>0,"active"=>1,"type"=>9,"condition"=>"{\\"lastvisit\\"=>[0,1],\\"level\\"=>[2,50],\\"custom\\"=>\\"game.recipient.return_bonus_date != undef\\",\\"regago\\"=>[2,4]}"}';

is compare($h1d,$h1s), "";
is compare($h1d,$h1d), 1;

is compare(eval($s1), eval($s2)), 1;
is compare(eval($s1), eval($s3)), 1, "type float against type string";

# check primitive VS ref
is compare("FUCK",{}), "";

# check more
is compare({},{}), 1;
is compare(eval($s1), eval($s4)), "";
is compare(eval($s1), eval($s5)), "";
is compare(eval($s5), eval($s6)), 1;
is compare(eval($s6), eval($s7)), "";
is compare(eval($s8), eval($s9)), 1;
is compare({a => \'a1'}, {a=>\'a1'}), 1;
is compare({a => \1}, {a=>\1}), 1;
is compare({a => \1.1}, {a=>\1.1}), 1;
is compare(eval($s10), eval($s11)), '';

# check arrayrefs
my $arr1 = [1,2,3];
my $arr2 = [1,2,3];
my $arr3 = [1,2,4];
my $arr4 = ["1", 2, 3.0];
is compare($arr1, $arr2), 1;
is compare($arr1, $arr4), 1;
is compare($arr1, $arr3), "";

# check empty slots
my $arr5 = [1..10];
my $arr6 = [1..10];
$#$arr5 = 1000;
$#$arr6 = 1000;
$arr5->[500] = 1;
is compare($arr5, $arr6), ""; # must not core dump

# check primitives
is compare(1, 1), 1;
is compare(1, "1"), 1;
is compare(1, "1.0"), "";
is compare(1, "1a"), "";
is compare(1.1, "1.1"), 1;
is compare(1.1 - 0.1, 1), 1;

# check coderefs
my $sub = sub {};
my $sub2 = $sub;
is compare($sub, sub {}), "";
is compare($sub, $sub2), 1;

# check globs
is compare(*compare, *compare), 1;
is compare(\*compare, \*compare), 1;
is compare(*compare, *is), "";

# check regexps
is compare(qr/abc/, qr/abc/), 1;
is compare(qr/abc/, qr/abc1/), "";
is compare(qr/abc/, qr/abc/i), "";

# check IO
my $io1 = *STDIN{IO};
my $io2 = *STDIN{IO};
my $io3 = *STDOUT{IO};
is compare($io1, $io2), 1;
is compare($io1, $io3), "";

# undefs
is compare(undef, undef), 1;
is compare(undef, 0), "";
is compare(undef, ""), "";
is compare(0, undef), "";
is compare("", undef), "";

# refs
is compare(\1, \1), 1;
is compare(\\1, \\1), 1;
is compare(\\\1, \\\1), 1;
is compare(\\\1, \\1), "";
is compare(\1, \\1), "";
is compare(1, \1), "";
my $a = [];
my $b = [];
is compare([\\\\\\\\\\\\\\\\\\\\\\\$a], [\\\\\\\\\\\\\\\\\\\\\\\$b]), 1;

# objects without overloads
{
    package O1;
}
my $o1 = bless {a => 1, b => 2}, 'O1';
my $o2 = bless {a => 1, b => 2}, 'O1';
my $o3 = bless {a => 1, b => 3}, 'O1';
my $o4 = bless {a => 1, b => 2}, 'O0';
my $no = {a => 1, b => 2};
is compare($o1, $o2), 1;
is compare($o1, $o3), "";
is compare($o1, $o4), "";
is compare($o1, $no), "";

# objects with overloads
{
    package O2;
    use overload '==' => \&myeq;
    sub myeq { return $_[0][0] == $_[1][0] }
}
my $oo1 = bless [1, 2], 'O2';
my $oo2 = bless [1, 2], 'O2';
my $oo3 = bless [1, 3], 'O2';
my $oo4 = bless [2, 2], 'O2';
my $oo5 = bless [1, 2], 'O1';
my $noo = [1, 2];
is compare($oo1, $oo2), 1;
is compare($oo1, $oo3), 1;
is compare($oo1, $oo4), "";
is compare($oo1, $oo5), "";
is compare($oo1, $noo), "";

done_testing;

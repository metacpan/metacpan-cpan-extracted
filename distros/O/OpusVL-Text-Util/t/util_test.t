use Test::Most;
use OpusVL::Text::Util qw/missing_array_items not_blank split_words line_split/;

sub test_split_words
{
    my $string = shift;
    my $expected = shift;
    my @vals = split_words($string);
    eq_or_diff \@vals, $expected, 'Split list correctly';
}

sub test_line_split
{
    my $string = shift;
    my $expected = shift;
    my @lines = line_split($string);
    eq_or_diff \@lines, $expected, "Line split";
}


my @mandatory = qw/a b c/;
my @cols = qw/a b d e f/;
eq_or_diff missing_array_items(\@mandatory, \@cols), [ 'c' ];
ok !missing_array_items(\@mandatory, \@mandatory);

ok not_blank(1);
ok not_blank('1');
ok not_blank('0');
ok not_blank(0);
ok !not_blank('');
ok !not_blank(undef);
ok !not_blank();
ok not_blank('a');
ok not_blank(' ');

test_split_words('', []);
test_split_words('one', [ 'one' ]);
test_split_words('veh1,veh2,veh3', [qw/veh1 veh2 veh3/]);
test_split_words('veh1 veh2  veh3', [qw/veh1 veh2 veh3/]);
test_split_words("veh1\nveh2\n veh3 ", [qw/veh1 veh2 veh3/]);

test_line_split("", []);
test_line_split("a", ["a"]);
test_line_split("a\n", ["a"]);
test_line_split("a\nb", ["a", 'b']);
test_line_split("a\rd", ["a",'d']);
test_line_split("a\r\nd", ["a",'d']);
test_line_split("a\n\nd", ["a",'','d']);
test_line_split("word\n\nsecond", ["word",'','second']);
test_line_split("word\n\n\nsecond", ["word",'','','second']);

done_testing;


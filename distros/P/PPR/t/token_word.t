use strict;
use warnings;

use Test::More;

use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A \s* (?&PerlStatement) \s* \Z $PPR::GRAMMAR/xo => "FAIL: $str";
        }
        else {
            ok $str =~ m/\A \s* (?&PerlStatement) \s* \Z $PPR::GRAMMAR/xo => "MATCH: $str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
$bar->method_with_parentheses($a ? $b : $c);
####
pack'H*',$data;
####
unpack'H*',$data;
####
Foo'Bar;
####
Foo::Bar;
####
F;
####
indirect $foo;
####
indirect_class_with_colon Foo::;
####
$bar->method_with_parentheses;
####
$bar->method_with_parentheses();
####
$bar->method_with_parentheses(1,'2',qr{3});
####
print SomeClass->method_without_parentheses + 1;
####
sub_call();
####
$baz->chained_from->chained_to;
####
a_first_thing a_middle_thing a_last_thing;
####
(first_list_element, second_list_element, third_list_element);
####
first_comma_separated_word, second_comma_separated_word, third_comma_separated_word;
####
single_bareword_statement;
####
{ bareword_no_semicolon_end_of_block }
####
$buz{hash_key};
####
fat_comma_left_side => $thingy;
####
$foo eq'bar';
####
$foo ne'bar';
####
$foo ge'bar';
####
$foo le'bar';
####
$foo gt'bar';
####
$foo lt'bar';
####
q'foo';
####
qq'foo';
####
qx'foo';
####
qw'foo';
####
qr'foo';
####
m'foo';
####
s'foo'bar';
####
tr'fo'ba';
####
y'fo'ba';
####

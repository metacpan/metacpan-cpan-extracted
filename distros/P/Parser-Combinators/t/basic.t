use strict;
use Test::More  tests => 20;

use Parser::Combinators;

use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;

sub test_combinator {
    (my $comb, my $str, my $ref) =@_;
    my @res = $comb->($str);
    my $assertion = Dumper(@res) eq $ref;
    print STDERR "<$assertion>\n";
    if (not $assertion) {
        print STDERR Dumper(@res),'<>',$ref,"\n";
    };
    return $assertion;
}

ok( test_combinator( word, 'hello', "1'''hello'" , 'word 1'));
ok( test_combinator( word, 'Hello!', "1'!''Hello'" , 'word 2'));
ok( test_combinator( word, ' Hello!', "0' Hello!'undef" , 'word 3'));

ok( test_combinator( natural, '42', "1'''42'" ,'natural 1'));
ok( test_combinator( natural, '42.0', "1'.0''42'" ,'natural 2'));
ok( test_combinator( natural, ' 42.0', "0' 42.0'undef" ,'natural 3'));

ok( test_combinator( symbol('int'), 'int', "1'''int'" ,'symbol 1'));
ok( test_combinator( symbol('int'), 'int*', "1'*''int'" ,'symbol 2'));
ok( test_combinator( symbol('int'), ' int', "1'''int'" ,'symbol 3'));
ok( test_combinator( symbol('int'), ' int*', "1'*''int'" ,'symbol 4'));
ok( test_combinator( symbol('int'), ' float*', "0' float*'undef" ,'symbol 5'));
ok( test_combinator( symbol('float*'), ' float* ', "1'''float\\\\*'" ,'symbol 6'));

ok( test_combinator( whiteSpace, "\t", "1'''\t'"  ,'whiteSpace 1'));
ok( test_combinator( whiteSpace, "  \n  ", "1'''  \n  '"  ,'whiteSpace 1'));
ok( test_combinator( whiteSpace, "    ", "1'''    '" ,'whiteSpace 1' ));

ok( test_combinator( char('a'), "alfalfa",qw(1'lfalfa''a') ,'char 1'));
ok( test_combinator( char('b'), "alfalfa",qw(0'alfalfa'undef) ,'char 2'));

ok( test_combinator( comma, " , intent(IN) ", "1'intent(IN) 'undef" , 'comma'));
ok( test_combinator( greedyUpto(')'), ' integer(8), intent(IN) :: v', "1':: v'' integer(8), intent(IN'", 'greedyUpto' ));
ok( test_combinator( upto(')'), ' integer(8), intent(IN) :: v', "1', intent(IN) :: v'' integer(8'" , 'upto'));

done_testing;

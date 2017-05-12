use 5.014;
use Test::More;
use Object::Result;
use Carp;

sub is_ex (&$$$) {
    my ($block, $expected_err, $line, $desc) = @_;

    my $file = (caller 0)[1];

    is eval{ $block->(); }, undef()  => "$desc (threw exception)";
    like $@, qr{\Q$expected_err\E}   => "$desc (right error message)";
    like $@, qr{at $file line $line} => "$desc (right error location)";
}

sub code { return 'subroutine' }

sub get_result {
    result { <FAIL> };
}

my $CALL_LOC = __FILE__.' line '.__LINE__; my $result = get_result();

ok !$result => 'Boolean coercion';

my $error_msg = "Call to main::get_result() at $CALL_LOC failed\n"
              . "Failure detected";

is_ex { $result + 1   } $error_msg => __LINE__, 'No <NUM>';
is_ex { int($result)  } $error_msg => __LINE__, 'No <INT>';
is_ex { "$result"     } $error_msg => __LINE__, 'No <STR>';
is_ex { ${$result}    } $error_msg => __LINE__, 'No <SCALAR>';
is_ex { \@{$result}   } $error_msg => __LINE__, 'No <ARRAY>';
is_ex { \%{$result}   } $error_msg => __LINE__, 'No <HASH>';
is_ex { $result->()   } $error_msg => __LINE__, 'No <CODE>';
is_ex { "" =~ $result } $error_msg => __LINE__, 'No <REGEXP>';
is_ex { *{$result}    } $error_msg => __LINE__, 'No <GLOB>';

is_ex { $result->no_such_method(); 1 } $error_msg => __LINE__, 'Non-existent method called';

done_testing();






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
    result {
        <BOOL> { return 0 }
        <SUB>  { return \&code    }
    };
}

my $CALL_LOC = __FILE__.' line '.__LINE__; my $result = get_result();

ok !$result             => 'Boolean coercion';
is $result->(), code()  => 'Code deref';

my $error_msg = "Object returned by call to main::get_result() at $CALL_LOC\ncan't be used as ";

is_ex { ${$result}    } $error_msg . '<SCALAR>' => __LINE__, 'No <SCALAR>';
is_ex { \@{$result}   } $error_msg . '<ARRAY>'  => __LINE__, 'No <ARRAY>';
is_ex { \%{$result}   } $error_msg . '<HASH>'   => __LINE__, 'No <HASH>';
is_ex { "" =~ $result } $error_msg . '<REGEXP>' => __LINE__, 'No <REGEXP>';
is_ex { *{$result}    } $error_msg . '<GLOB>'   => __LINE__, 'No <GLOB>';
is_ex { $result + 1   } $error_msg . '<NUM>'    => __LINE__, 'No <NUM>';
is_ex { int($result)  } $error_msg . '<INT>'    => __LINE__, 'No <INT>';
is_ex { "$result"     } $error_msg . '<STR>'    => __LINE__, 'No <STR>';

done_testing();





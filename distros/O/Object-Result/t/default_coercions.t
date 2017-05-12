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
        <BOOL>                    { return 0 }
        <SUB>                     { return \&code    }
        <DEFAULT> ($what, $where) { croak "Can't use result of $where as $what" }
    };
}

my $call_desc = 'call to main::get_result() at '.__FILE__.' line '.__LINE__; my $result = get_result();

ok !$result             => 'Boolean coercion';
is $result->(), code()  => 'Code deref';

is_ex { ${$result}    } "Can't use result of $call_desc as <SCALAR>" => __LINE__, 'No <SCALAR>';
is_ex { \@{$result}   } "Can't use result of $call_desc as <ARRAY>"  => __LINE__, 'No <ARRAY>';
is_ex { \%{$result}   } "Can't use result of $call_desc as <HASH>"   => __LINE__, 'No <HASH>';
is_ex { "" =~ $result } "Can't use result of $call_desc as <REGEXP>" => __LINE__, 'No <REGEXP>';
is_ex { *{$result}    } "Can't use result of $call_desc as <GLOB>"   => __LINE__, 'No <GLOB>';
is_ex { $result + 1   } "Can't use result of $call_desc as <NUM>"    => __LINE__, 'No <NUM>';
is_ex { int($result)  } "Can't use result of $call_desc as <INT>"    => __LINE__, 'No <INT>';
is_ex { "$result"     } "Can't use result of $call_desc as <STR>"    => __LINE__, 'No <STR>';

done_testing();




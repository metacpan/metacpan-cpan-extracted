use 5.014;
use Test::More;
use Object::Result;

sub is_ex (&$$) {
    my ($block, $expected_err, $desc) = @_;

    my ($file, $line) = (caller 0)[1,2];

    is eval{ $block->(); }, undef()  => "$desc (threw exception)";
    like $@, qr{\Q$expected_err\E}   => "$desc (right error message)";
    like $@, qr{at $file line $line} => "$desc (right error location)";
}

sub get_result {
    result {
        check          { return "checked" }
        test_it  ()    { return "test"    }
        verify ($word) { return "verified $word" }
    };
}

my $CALL_LOC = __FILE__.' line '.__LINE__; my $result = get_result();

isa_ok $result, 'Object::Result::Object'  =>  'Correct return type';

ok $result => 'Boolean coercion';

is $result->check,   'checked' => '->check';
is $result->check(), 'checked' => '->check()';
is_ex { $result->check(1) } "In call to Object::Result::Object::check(), was given too many arguments; it expects 0" => '->check(1)';

is $result->test_it,   'test' => '->test_it';
is $result->test_it(), 'test' => '->test_it()';
is_ex { $result->test_it(1) } "In call to Object::Result::Object::test_it(), was given too many arguments; it expects 0" => '->test_it(1)';

is_ex { $result->verify } "In call to Object::Result::Object::verify(), missing required argument \$word" => '->verify';
is_ex { $result->verify() } "In call to Object::Result::Object::verify(), missing required argument \$word" => '->verify()';
is $result->verify('outcome'), 'verified outcome' => '->verify(outcome)';

is_ex { $result->no_such_method(); 1 } qq{Object returned by call to main::get_result() at $CALL_LOC\ndoesn't have method no_such_method()} => 'Non-existent method called';


done_testing();


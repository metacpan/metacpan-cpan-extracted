use 5.010;
use warnings;
use Test::More tests => 2;

my $actions_should_be_active = 0;

{ 
    package MyAction;

    sub new {
        return bless {}, shift;
    }

    sub text  {
        my ($self, $result) = @_;
        ::ok $actions_should_be_active, 'Text action executed';
        return $result;
    }
}

my $test_grammar = do {
    use Regexp::Grammars;
    qr{
        <text>
        <rule: text> \w+
    }x;

};

$actions_should_be_active = 1;
"abc_test" =~ $test_grammar->with_actions(MyAction->new);

$actions_should_be_active = 0;
"abc_test" =~ $test_grammar;

$actions_should_be_active = 1;
'$$$$$$$$'         =~ $test_grammar->with_actions(MyAction->new);
'$$$$$$$$abc_test' =~ $test_grammar->with_actions(MyAction->new);

$actions_should_be_active = 0;
"abc_test" =~ $test_grammar;

done_testing();

use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params;

    has 'question' => (
        is      => 'ro',
        isa     => 'Str',
        default => 'Why?',
    );

    sub test :Args(self: Int answer=) {
        $_{answer}
    }

    sub selfish :Args(self: Str =statement) {
        $_{statement}
    }

    sub parametric :Args(self: Int =answer, Str statement = _build_my_statement) {
        $_{statement}
    }

    sub _build_param_answer {
        42
    }

    sub _build_param_statement {
        "The question is '" . $_{self}->question . "'"
    }

    sub _build_my_statement {
        "The answer is '$_{answer}'"
    }

    no MooseX::Params;
}

my $object = TestExecute->new;
is( $object->test(41), 41, 'lazy with supplied value');
is( $object->test, 42, 'lazy without supplied value' );
is( $object->selfish, "The question is 'Why?'", 'lazy with $self' );
is( $object->parametric, "The answer is '42'", 'lazy with another parameter' );

done_testing();


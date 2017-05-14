use strict;
use warnings;

use Test::More;

{
    package Test::Patterns::ChainOfResponsibility::Role::Handler::one;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler';
    sub handle {
        my ($self, $arg) = @_;
        if ($arg == 1) {
            return 'one';
        } else {
            return;
        }
    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::two;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler';
    sub handle {
        my ($self, $arg) = @_;
        if ($arg == 2) {
            return 'two';
        } else {
            return;
        }

    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::three;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler';
    sub handle {
        my ($self, $arg) = @_;
        if ($arg == 3) {
            return 'three';
        } else {
            return;
        }
    }
}

my ($one, $two, $three) = (
    Test::Patterns::ChainOfResponsibility::Role::Handler::one->new,
    Test::Patterns::ChainOfResponsibility::Role::Handler::two->new,
    Test::Patterns::ChainOfResponsibility::Role::Handler::three->new,
);

ok $one->next_handlers($two, $three),
  'Added Handlers';

is_deeply [$one->process(1)], ['one'],
  'Correct Handler';

is_deeply [$one->process(2)], ['two'],
  'Correct Handler';

is_deeply [$one->process(3)], ['three'],
  'Correct Handler';

done_testing();

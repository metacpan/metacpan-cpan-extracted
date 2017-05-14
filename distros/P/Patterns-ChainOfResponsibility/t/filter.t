use strict;
use warnings;

use Test::More;

{
    package Test::Patterns::ChainOfResponsibility::Role::Handler::one;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler' => {dispatcher => '::Filter'};
    sub handle {
        my ($self, $arg) = @_;
        return "$arg$arg";
    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::two;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler' => {dispatcher => '::Filter'};
    sub handle {
        my ($self, $arg) = @_;
        return "$arg$arg";
    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::three;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler' => {dispatcher => '::Filter'};
    sub handle {
        my ($self, $arg) = @_;
        return "$arg$arg";
    }
}

my ($one, $two, $three) = (
    Test::Patterns::ChainOfResponsibility::Role::Handler::one->new,
    Test::Patterns::ChainOfResponsibility::Role::Handler::two->new,
    Test::Patterns::ChainOfResponsibility::Role::Handler::three->new,
);

ok $one->next_handlers($two, $three),
  'Added Handlers';

is_deeply [$one->process(1)], [11111111],
  'Correct Handler';

is_deeply [$one->process(2)], [22222222],
  'Correct Handler';

is_deeply [$one->process(3)], [33333333],
  'Correct Handler';

done_testing();

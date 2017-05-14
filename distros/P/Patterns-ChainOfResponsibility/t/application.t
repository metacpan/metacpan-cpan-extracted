use strict;
use warnings;

use Test::More;

{
    package Test::Patterns::ChainOfResponsibility::Role::Handler::one;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler';
    sub handle {
        my ($self, $arg1, $arg2) = @_;
        if ($arg1 == 1) {
            return "one:$arg2";
        } else {
            return;
        }
    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::two;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler';
    sub handle {
        my ($self, $arg1, $arg2) = @_;
        if ($arg1 == 2) {
            return "two:$arg2";
        } else {
            return;
        }

    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::three;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler';
    sub handle {
        my ($self, $arg1, $arg2) = @_;
        if ($arg1 == 3) {
            return "three:$arg2";
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

use Patterns::ChainOfResponsibility::Application;

ok my $app = Patterns::ChainOfResponsibility::Application->new(handlers=>[$one, $two, $three]),
  'made applications';

is_deeply [$app->process(1,'x')], ['one:x'],
  'Correct Handler';

is_deeply [$app->process(2,'y')], ['two:y'],
  'Correct Handler';

is_deeply [$app->process(3,'z')], ['three:z'],
  'Correct Handler';

done_testing();

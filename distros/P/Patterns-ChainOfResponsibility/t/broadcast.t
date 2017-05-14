use strict;
use warnings;

use Test::More;

{
    package Test::Patterns::ChainOfResponsibility::Role::Handler::Logger;
    use Moose;
    has 'log' => (is=>'rw', isa=>'ArrayRef', default=>sub {+[]},traits=>['Array'], handles=>{log_item=>'push'});
    
    package Test::Patterns::ChainOfResponsibility::Role::Handler::one;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler' => {dispatcher => '::Broadcast'};
    has 'logger' => (is=>'ro', handles=>['log_item']);
    sub handle {
        my ($self, $arg) = @_;
        $self->log_item($arg ."1");
        return 'one';
    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::two;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler' => {dispatcher => '::Broadcast'};
    has 'logger' => (is=>'ro', handles=>['log_item']);
    sub handle {
        my ($self, $arg) = @_;
        $self->log_item($arg ."2");
        return 'two';

    }

    package Test::Patterns::ChainOfResponsibility::Role::Handler::three;
    use Moose;
    with 'Patterns::ChainOfResponsibility::Role::Handler' => {dispatcher => '::Broadcast'};
    has 'logger' => (is=>'ro', handles=>['log_item']);
    sub handle {
        my ($self, $arg) = @_;
        $self->log_item($arg ."3");
        return 'three';
    }
}

ok my $logger = Test::Patterns::ChainOfResponsibility::Role::Handler::Logger->new,
  'Made a logger';

my ($one, $two, $three) = (
    Test::Patterns::ChainOfResponsibility::Role::Handler::one->new(logger=>$logger),
    Test::Patterns::ChainOfResponsibility::Role::Handler::two->new(logger=>$logger),
    Test::Patterns::ChainOfResponsibility::Role::Handler::three->new(logger=>$logger),
);

ok $one->next_handlers($two, $three),
  'Added Handlers';

ok $one->process(100),
  'correctly processed';

is_deeply $logger->log, ['1001','1002','1003'],
  'got expected broadcast';

done_testing();

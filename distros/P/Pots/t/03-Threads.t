use Test::More qw(no_plan);

use strict;
use warnings;

use threads;
use threads::shared;

package MyThread;

use base qw(Pots::Thread);

MyThread->mk_shared_accessors(qw(field1));

sub new {
    my $class = shift;
    my %p = @_;

    my $self = $class->SUPER::new(%p);
    return $self;
}

sub initialize {
    my $self = shift;
    my %p = @_;

    $self->SUPER::initialize(%p);

    $self->field1($p{field1}) if defined($p{field1});

    return 1;
}

sub pre_run {
    return 1;
}

sub run {
    my $self = shift;
    my $quit = 0;
    my $msg;

    while (!$quit) {
        $msg = $self->getmsg();

        for ($msg->type()) {
            if (/quit/) {
                $quit = 1;
            } elsif (/setfield1/) {
                my $val = $self->field1($msg->get('field1'));
                $msg->type("field1 set to $val");
                $self->postmsg($msg);
            }
        }
    }
}

1;

package main;

use_ok('Pots::Thread');
can_ok('Pots::Thread',
       qw(new start stop postmsg getmsg)
);

my @th;
my $msg;

for my $i (1..10) {
    $th[$i] = MyThread->new(field1 => $i);
    is($th[$i]->start(), 1, "Thread start");
}

for my $i (1..10) {
    $msg = $th[$i]->sendmsg(
        Pots::Message->new(
            'setfield1',
            { field1 => $i * 2 }
        )
      );
    is($msg->type(), sprintf("field1 set to %d", $i * 2), "Communication");
    is($th[$i]->field1(), $i * 2, "Shared accessor");
    $th[$i]->stop();
}

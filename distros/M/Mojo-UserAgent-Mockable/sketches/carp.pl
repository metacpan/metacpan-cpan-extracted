use 5.014;

package Foo;
use Carp;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub bar {
    my $self = shift;

    $self->_boo;
}

sub _boo {
    croak q{Oh no!};
}

package main;

my $bar = Foo->new;

$bar->bar;
say 'OK';

package Mock::Foo;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub say { 'foo' }

1;


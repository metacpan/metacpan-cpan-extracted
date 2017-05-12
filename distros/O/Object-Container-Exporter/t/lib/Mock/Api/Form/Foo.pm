package Mock::Api::Form::Foo;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub fillin { 'filled' }

1;

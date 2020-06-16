package Module::Load::Util::Test::Class;

use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub foo {
    my $self = shift;
    "foo:".(shift || "");
}

sub new_array {
    my $class = shift;
    bless [@_], $class;
}

1;

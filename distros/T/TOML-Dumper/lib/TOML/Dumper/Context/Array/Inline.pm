package TOML::Dumper::Context::Array::Inline;
use strict;
use warnings;

use parent -norequire => qw/TOML::Dumper::Context::Array/;

sub priority { 2 }

sub as_string {
    my $self = shift;
    my @body;
    for my $object (@{ $self->objects }) {
        push @body => $object->as_string;
    }
    my $body = join ', ', @body;
    return "[$body]";
}

1;

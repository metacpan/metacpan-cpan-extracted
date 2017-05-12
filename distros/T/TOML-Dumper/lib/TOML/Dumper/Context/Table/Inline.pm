package TOML::Dumper::Context::Table::Inline;
use strict;
use warnings;

use parent -norequire => qw/TOML::Dumper::Context::Table/;

use TOML::Dumper::Name;

sub priority { 2 }

sub as_string {
    my $self = shift;
    my $body = join ', ', map { $_->as_string() } $self->objects;
    return $body ? "{ $body }" : '{}';
}

1;

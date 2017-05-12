package TOML::Dumper::Context::Value::Inline;
use strict;
use warnings;

use parent -norequire => 'TOML::Dumper::Context::Value';

use TOML::Dumper::String;

sub as_string {
    my $self = shift;
    my $type = $self->{type};
    my $atom = $self->{atom};
    my $body = $type eq 'string' ? TOML::Dumper::String::quote($atom)
             : $type eq 'number' ? "$atom"
             : $type eq 'bool'   ? $atom
             : die "Unknown type: $type";
    return $body;
}

1;

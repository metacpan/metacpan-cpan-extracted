package Spica::Parser::XML;
use strict;
use warnings;
use utf8;

use Mouse;

extends 'Spica::Parser';

has parser => (
    is => 'ro',
    isa => 'XML::Simple',
    lazy_build => 1,
);

override parse => sub {
    my ($self, $body) = @_;
    return $self->parser->XMLin($body);
};

no Mouse;

use XML::Simple;
sub _build_parser {
    my $self;
    return XML::Simple->new();
}

1;

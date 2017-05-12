package Spica::Parser::JSON;
use strict;
use warnings;

use Mouse;

extends 'Spica::Parser';

has parser => (
    is         => 'ro',
    isa        => 'JSON',
    lazy_build => 1,
);

override parse => sub {
    my ($self, $body) = @_;
    return $self->parser->decode($body);
};

no Mouse;

use JSON;
sub _build_parser {
    my $self = shift;
    return JSON->new->utf8;
}

1;

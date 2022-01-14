package Regex::Object::Matches;

use 5.20.0;
use strict;
use warnings qw(FATAL);
use utf8;

use Moo;
use namespace::clean;

has collection => (
    is       => 'ro',
    required => 1,
);

has count => (
    is => 'rwp',
);

sub BUILD {
    my $self = shift;
    $self->_set_count(scalar @{$self->collection});
}

sub match_all {
    my $self = shift;
    return [map { $_->match } @{$self->collection}];
}

sub captures_all {
    my $self = shift;
    return [map { $_->captures } @{$self->collection}];
}

1;
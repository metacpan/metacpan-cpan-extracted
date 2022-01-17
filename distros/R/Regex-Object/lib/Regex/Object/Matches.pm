package Regex::Object::Matches;

use 5.20.0;

use utf8;
use English;
use feature qw(signatures);

use Moo;

no warnings qw(experimental::signatures);
use namespace::clean;

has collection => (
    is       => 'ro',
    required => 1,
);

has count => (
    is => 'rwp',
);

sub BUILD($self, $) {
    $self->_set_count(scalar @{$self->collection});
}

sub match_all($self) {
    return [map { $_->match } @{$self->collection}];
}

sub captures_all($self) {
    return [map { $_->captures } @{$self->collection}];
}

1;
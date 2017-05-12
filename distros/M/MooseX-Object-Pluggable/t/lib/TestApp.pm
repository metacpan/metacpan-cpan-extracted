package TestApp;

use strict;
use warnings;
use Moose;

with 'MooseX::Object::Pluggable';

has bee => (is => 'rw', isa => 'Int', required => 1, default => '100');

sub foo{ 'original foo' }

sub bar{ 'original bar' }

sub bor{ 'original bor' }

__PACKAGE__->meta->make_immutable;

1;

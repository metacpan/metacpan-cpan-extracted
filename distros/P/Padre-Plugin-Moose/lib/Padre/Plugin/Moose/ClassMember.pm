package Padre::Plugin::Moose::ClassMember;

use Moose;

our $VERSION = '0.21';

has 'name' => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

no Moose;
1;


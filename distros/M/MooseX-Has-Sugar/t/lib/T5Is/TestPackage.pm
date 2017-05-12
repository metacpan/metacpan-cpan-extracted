package T5Is::TestPackage;

# $Id:$
use strict;
use warnings;
use Moose;
use MooseX::Has::Sugar::Minimal;
use namespace::clean -except => 'meta';

has roattr => ( isa => 'Str', is => ro, required => 1, );

has rwattr => ( isa => 'Str', is => rw, required => 1, );

has bareattr => ( isa => 'Str', is => bare, required => 1, );

__PACKAGE__->meta->make_immutable;

1;


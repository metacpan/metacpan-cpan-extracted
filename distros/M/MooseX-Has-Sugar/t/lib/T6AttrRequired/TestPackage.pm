package T6AttrRequired::TestPackage;

# $Id:$
use strict;
use warnings;
use Moose;
use MooseX::Has::Sugar;

use namespace::clean -except => 'meta';

has roattr => ( isa => 'Str', is => 'ro', required, );

has rwattr => ( isa => 'Str', is => 'rw', required, );

has bareattr => ( isa => 'Str', is => 'bare', required, );

__PACKAGE__->meta->make_immutable;

1;


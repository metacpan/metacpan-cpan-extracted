package T8Saccharin::TestPackage;

# $Id:$
use strict;
use warnings;
use Moose;
use MooseX::Has::Sugar::Saccharin;
use namespace::clean -except => 'meta';

has roattr => lazy_build ro 'Str';

has rwattr => lazy_build rw 'Str';

sub _build_rwattr {
  return 'y';
}

sub _build_roattr {
  return 'y';
}

__PACKAGE__->meta->make_immutable;

1;


package T10Saccharin::TestPackage;

# $Id:$
use strict;
use warnings;
use Moose;
use MooseX::Has::Sugar::Saccharin;
use MooseX::Types::Moose qw( :all );
use namespace::clean -except => 'meta';

has roattr => required ro Str;

has rwattr => required rw Str, init_arg "MONSTER";

has bareattr => required bare Str;

has lazyroattr => lazy ro Str, default { 1 }
,;

__PACKAGE__->meta->make_immutable;

1;


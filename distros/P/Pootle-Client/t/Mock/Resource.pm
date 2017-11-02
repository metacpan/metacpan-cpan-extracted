# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package t::Mock::Resource;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 init

=cut

sub init($class, $responseDump, $targetClass) {
  my $objects = [];
  my $lookup = {};

  foreach my $hash (@$responseDump) {
    my $o = $targetClass->new($hash);
    push @$objects, $o;
    $lookup->{$o->resource_uri} = $o;
  }
  return ($objects, $lookup);
}

1;

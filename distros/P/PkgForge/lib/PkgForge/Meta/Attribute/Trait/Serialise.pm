package PkgForge::Meta::Attribute::Trait::Serialise;
use strict;
use warnings;

use Moose::Role;

has 'pack' => (
  is        => 'ro',
  isa       => 'Str|CodeRef',
  predicate => 'has_pack_method',
);

has 'unpack' => (
  is        => 'ro',
  isa       => 'Str|CodeRef',
  predicate => 'has_unpack_method',
);

no Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::PkgForge::Serialise;

sub register_implementation { 'PkgForge::Meta::Attribute::Trait::Serialise' };

1;
__END__

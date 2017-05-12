package PkgForge::Meta::Attribute::Trait::Directory;
use strict;
use warnings;

use Moose::Role;

no Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::PkgForge::Directory;

sub register_implementation { 'PkgForge::Meta::Attribute::Trait::Directory' };

1;
__END__


#############
# Created By: setitesuk
# Created On: 2010-02-15

package TestExtraNewAttributeCloner;
use Moose;
use Carp;
use English qw{-no_match_vars};
use TestNewAttributeCloner;

extends qw{TestAttributeCloner};

has q{attr8}  => (isa => q{Str}, is => q{ro});
has q{attr9}  => (isa => q{Str}, is => q{ro});
has q{attr10} => (isa => q{Str}, is => q{ro});

sub test_package {
  my ($self) = @_;
  return TestNewAttributeCloner->new_with_cloned_attributes($self);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

TestExtraNewAttributeCloner

=head1 VERSION

0.19

=head1 SYNOPSIS

=head1 DESCRIPTION

This is purely a test case class. Nothing in here should be considered production worthy! Use any of it at your own risk!

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

setitesuk

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Andy Brown (setitesuk@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

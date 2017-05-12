#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Tangence::Meta::Argument;

use strict;
use warnings;

our $VERSION = '0.23';

=head1 NAME

C<Tangence::Meta::Argument> - structure representing one C<Tangence>
method or event argument

=head1 DESCRIPTION

This data structure object stores information about one argument to a
L<Tangence> class method or event. Once constructed, such objects are
immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $argument = Tangence::Meta::Argument->new( %args )

Returns a new instance initialised by the given arguments.

=over 8

=item name => STRING

Name of the argument

=item type => STRING

Type of the arugment as a L<Tangence::Meta::Type> reference

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   bless \%args, $class;
}

=head1 ACCESSORS

=cut

=head2 $name = $argument->name

Returns the name of the class

=cut

sub name
{
   my $self = shift;
   return $self->{name};
}

=head2 $type = $argument->type

Return the type as a L<Tangence::Meta::Type> reference.

=cut

sub type
{
   my $self = shift;
   return $self->{type};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

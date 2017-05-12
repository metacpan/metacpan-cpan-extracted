#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Nick Shipp, 2016 -- nick@shipp.ninja

package POEx::Tickit::Driver;

use strict;
use warnings;
use base qw( POE::Driver::SysRW );

our $VERSION = '0.04';

use Carp;

=head1 NAME

C<POEx::Tickit::Driver> - Wrap L<POE::Driver::SysRW> with a C<write()> for Tickit

=head1 DESCRIPTION

This module is used internally to provide a C<write()> for L<Tickit::Term> based
on L<POEx::Driver::SysRW>.

=cut

use constant OUTPUT_HANDLE => 5;

sub new
{
   my $class = shift;
   my %args = @_;

   defined( my $handle = delete $args{Handle} ) or
      croak "$class requires Handle";

   my $self = $class->SUPER::new( %args );

   $self->[OUTPUT_HANDLE] = $handle;

   return $self;
}

sub write
{
   my $self = shift;
   my ( $record ) = @_;

   $self->put( [ $record ] );
   $self->flush( $self->[OUTPUT_HANDLE] );
}

0x55AA;

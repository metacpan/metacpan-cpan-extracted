#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::IO::Impl::POE;

use strict;
use warnings;
use base qw( Future::IO::ImplBase );

=head1 NAME

C<Future::IO::Impl::POE> - implement C<Future::IO> using C<POE>

=head1 DESCRIPTION

This module provides an implemention for L<Future::IO> which uses L<POE>.

There are no additional methods to use in this module; it simply has to be
loaded, and will provide the C<Future::IO> implementation methods.

   use Future::IO;
   use Future::IO::Impl::POE;

   my $f = Future::IO->sleep(5);
   ...

=cut

use POE;

__PACKAGE__->APPLY;

sub sleep
{
   shift;
   my ( $secs ) = @_;

   return POE::Future->new_delay( $secs );
}

my $iosession;
sub _mk_iosession
{
   return $iosession //= POE::Session->create(
      inline_states => {
         _start => sub {
            $_[KERNEL]->alias_set( __PACKAGE__ );
         },

         invoke => sub { $_[-1]->() },

         select_read => sub {
            $_[KERNEL]->select_read( $_[ARG0], invoke => $_[ARG1] );
         },
         unselect_read => sub {
            $_[KERNEL]->select_read( $_[ARG0] );
         },
         select_write => sub {
            $_[KERNEL]->select_write( $_[ARG0], invoke => $_[ARG1] );
         },
         unselect_write => sub {
            $_[KERNEL]->select_write( $_[ARG0] );
         },
      },
   );
}

my %watching_read_by_fileno; # {fileno} => [@futures]

sub ready_for_read
{
   shift;
   my ( $fh ) = @_;

   my $watching = $watching_read_by_fileno{ $fh->fileno } //= [];
   my $f = POE::Future->new;

   my $was = scalar @$watching;
   push @$watching, $f;

   return $f if $was;

   my $session = _mk_iosession;
   POE::Kernel->call( $session, select_read => $fh, sub {
      $watching->[0]->done;
      shift @$watching;

      return if scalar @$watching;

      POE::Kernel->call( $session, unselect_read => $fh );
      delete $watching_read_by_fileno{ $fh->fileno };
   } );

   return $f;
}

my %watching_write_by_fileno; # {fileno} => [@futures]

sub ready_for_write
{
   shift;
   my ( $fh ) = @_;

   my $watching = $watching_write_by_fileno{ $fh->fileno } //= [];
   my $f = POE::Future->new;

   my $was = scalar @$watching;
   push @$watching, $f;

   return $f if $was;

   my $session = _mk_iosession;
   POE::Kernel->call( $session, select_write => $fh, sub {
      $watching->[0]->done;
      shift @$watching;

      return if scalar @$watching;

      POE::Kernel->call( $session, unselect_write => $fh );
      delete $watching_write_by_fileno{ $fh->fileno };
   } );

   return $f;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

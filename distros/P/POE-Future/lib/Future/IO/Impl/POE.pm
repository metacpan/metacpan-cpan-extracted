#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::POE 0.06;

use v5.14;
use warnings;
use base qw( Future::IO::ImplBase );
BEGIN { Future::IO::ImplBase->VERSION( '0.19' ); }

use Future::IO qw( POLLIN POLLOUT POLLHUP );

=head1 NAME

C<Future::IO::Impl::POE> - implement C<Future::IO> using C<POE>

=head1 DESCRIPTION

=for highlighter language=perl

This module provides an implemention for L<Future::IO> which uses L<POE>.

There are no additional methods to use in this module; it simply has to be
loaded, and will provide the C<Future::IO> implementation methods.

   use Future::IO;
   use Future::IO::Impl::POE;

   my $f = Future::IO->sleep(5);
   ...

=head1 LIMITATIONS

This module only provides a limited subset of the L<Future::IO/poll> method
API. It fully handles C<POLLIN> and C<POLLOUT> conditions, but is not able to
report on C<POLLHUP> and C<POLLERR> events.

When a filehandle is at hangup condition it is reported as only C<POLLIN>, and
when at error condition it is reported as only C<POLLOUT>. This I<should> be
sufficient for most purposes, and works fine for internally providing
asynchronous reading and writing on regular filehandles, but may cause some
odd behaviours if you are attempting to detect those conditions directly.

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

my %futures_read_by_fileno; # {fileno} => [@futures]
my %futures_write_by_fileno; # {fileno} => [@futures]

sub poll
{
   shift;
   my ( $fh, $events ) = @_;

   my $fileno = $fh->fileno;

   my $f = POE::Future->new;
   my $session = _mk_iosession;

   if( $events & (POLLIN|POLLHUP) ) {
      my $futures = $futures_read_by_fileno{$fileno} //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      POE::Kernel->call( $session, select_read => $fh, sub {
         $futures->[0]->done( POLLIN ); # we can't distinguish IN from HUP
         shift @$futures;

         return if scalar @$futures;

         POE::Kernel->call( $session, unselect_read => $fh );
         delete $futures_read_by_fileno{$fileno};
      } ) if !$was;
   }
   if( $events & POLLOUT ) {
      my $futures = $futures_write_by_fileno{$fileno} //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      POE::Kernel->call( $session, select_write => $fh, sub {
         $futures->[0]->done( POLLOUT ); # we can't distinguish OUT from ERR
         shift @$futures;

         return if scalar @$futures;

         POE::Kernel->call( $session, unselect_write => $fh );
         delete $futures_write_by_fileno{$fileno};
      } ) if !$was;
   }

   return $f;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

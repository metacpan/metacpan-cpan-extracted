#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package POE::Wheel::TermKey;

use strict;
use warnings;
use base qw( POE::Wheel );

our $VERSION = '0.02';

use Carp;

use POE;
use Term::TermKey;

=head1 NAME

C<POE::Wheel::TermKey> - terminal key input using C<libtermkey> with C<POE>

=head1 SYNOPSIS

 use Term::TermKey qw( FORMAT_VIM KEYMOD_CTRL );
 use POE qw(Wheel::TermKey);
 
 POE::Session->create(
    inline_states => {
       _start => sub {
          $_[HEAP]{termkey} = POE::Wheel::TermKey->new(
             InputEvent => 'got_key',
          );
       },
       got_key => sub {
          my $key     = $_[ARG0];
          my $termkey = $_[HEAP]{termkey};
 
          print "Got key: ".$termkey->format_key( $key, FORMAT_VIM )."\n";
 
          # Gotta exit somehow.
          delete $_[HEAP]{termkey} if $key->type_is_unicode and
                                      $key->utf8 eq "C" and
                                      $key->modifiers & KEYMOD_CTRL;
       },
    }
 );

 POE::Kernel->run;

=head1 DESCRIPTION

This class implements an asynchronous perl wrapper around the C<libtermkey>
library, which provides an abstract way to read keypress events in
terminal-based programs. It yields structures that describe keys, rather than
simply returning raw bytes as read from the TTY device.

This class is a subclass of L<POE::Wheel>, which internally uses an instance
of L<Term::TermKey> to access the underlying C library. For details of on
general operation, including the representation of keypress events as objects,
see the documentation on C<Term::TermKey> instead.

Proxy methods exist for normal acessors of C<Term::TermKey>, and the usual
behaviour of C<getkey> or other methods is instead replaced by the
C<InputEvent>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $wheel = POE::Wheel::TermKey->new( %args )

Returns a new instance of a C<POE::Wheel::TermKey> object. It takes the
following named parameters:

=over 8

=item Term => IO or INT

Optional. File handle or POSIX file descriptor number for the filehandle to
use as the connection to the terminal. If not supplied C<STDIN> will be used.

=item Flags => INT

C<libtermkey> flags to pass to the C<Term::TermKey> constructor.

=item InputEvent => STRING

Name of the session event to emit when a key is received. The event will be
given a single argument, the C<Term::TermKey::Key> event object, as
C<$_[ARG0]>.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   # TODO: Find a better algorithm to hunt my terminal
   my $term = delete $args{Term} || \*STDIN;

   my $termkey = Term::TermKey->new( $term, delete $args{Flags} || 0 );
   if( !defined $termkey ) {
      croak "Cannot construct a termkey instance\n";
   }

   my $self = bless {
      inputevent => $args{InputEvent},
      id         => POE::Wheel::allocate_wheel_id,
      term       => $term,
      termkey    => $termkey,
   }, $class;

   $self->{states}{read}    = ref($self) . "($self->{id}) -> select read";
   $self->{states}{timeout} = ref($self) . "($self->{id}) -> timeout";
   my $state_timeout = $self->{states}{timeout};

   my $inputeventr = \$self->{inputevent};
   $poe_kernel->state( $self->{states}{read} => sub {
      my ( $kernel, $session ) = @_[KERNEL, SESSION];

      return unless $termkey->advisereadable == RES_AGAIN;

      $kernel->alarm( $state_timeout => undef );

      my $key;

      my $ret;
      while( ( $ret = $termkey->getkey( $key ) ) == RES_KEY ) {
         $kernel->call( $session, $$inputeventr, $key );
      }

      if( $ret == RES_AGAIN ) {
         $kernel->delay( $state_timeout => $termkey->get_waittime / 1000 );
      }
   } );
   $poe_kernel->state( $self->{states}{timeout} => sub {
      my ( $kernel, $session ) = @_[KERNEL, SESSION];

      if( $termkey->getkey_force( my $key ) == RES_KEY ) {
         $kernel->call( $session, $$inputeventr, $key );
      }
   } );

   $poe_kernel->select_read( $self->{term}, $self->{states}{read} );

   return $self;
}

sub DESTROY
{
   my $self = shift;

   $poe_kernel->select( $self->{term}, undef );

   $poe_kernel->state( $_ => undef ) for values %{ $self->{states} };

   POE::Wheel::free_wheel_id( $self->{id} );
}

=head1 METHODS

=cut

=head2 $tk = $wheel->termkey

Returns the C<Term::TermKey> object being used to access the C<libtermkey>
library. Normally should not be required; the proxy methods should be used
instead. See below.

=cut

sub termkey
{
   my $self = shift;
   return $self->{termkey};
}

=head2 $flags = $wheel->get_flags

=head2 $wheel->set_flags( $flags )

=head2 $canonflags = $wheel->get_canonflags

=head2 $wheel->set_canonflags( $canonflags )

=head2 $msec = $wheel->get_waittime

=head2 $wheel->set_waittime( $msec )

=head2 $str = $wheel->get_keyname( $sym )

=head2 $sym = $wheel->keyname2sym( $keyname )

=head2 ( $ev, $button, $line, $col ) = $wheel->interpret_mouse( $key )

=head2 $str = $wheel->format_key( $key, $format )

=head2 $key = $wheel->parse_key( $str, $format )

=head2 $key = $wheel->parse_key_at_pos( $str, $format )

=head2 $cmp = $wheel->keycmp( $key1, $key2 )

These methods all proxy to the C<Term::TermKey> object, and allow transparent
use of the C<POE::Wheel::TermKey> object as if it was a subclass. Their
arguments, behaviour and return value are therefore those provided by that
class. For more detail, see the L<Term::TermKey> documentation.

=cut

# Proxy methods for normal Term::TermKey access
foreach my $method (qw(
   get_flags
   set_flags
   get_canonflags
   set_canonflags
   get_waittime
   set_waittime
   get_keyname
   keyname2sym
   interpret_mouse
   format_key
   parse_key
   parse_key_at_pos
   keycmp
)) {
   no strict 'refs';
   *{$method} = sub {
      my $self = shift;
      $self->termkey->$method( @_ );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

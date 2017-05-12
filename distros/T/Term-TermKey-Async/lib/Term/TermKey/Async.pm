#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2013 -- leonerd@leonerd.org.uk

package Term::TermKey::Async;

use strict;
use warnings;
use base qw( IO::Async::Handle );

our $VERSION = '0.08';

use Carp;

use IO::Async::Timer::Countdown;
use Term::TermKey qw( RES_EOF RES_KEY RES_AGAIN );

=head1 NAME

C<Term::TermKey::Async> - terminal key input using C<libtermkey> with
C<IO::Async>

=head1 SYNOPSIS

 use Term::TermKey::Async qw( FORMAT_VIM KEYMOD_CTRL );
 use IO::Async::Loop;
 
 my $loop = IO::Async::Loop->new();
 
 my $tka = Term::TermKey::Async->new(
    term => \*STDIN,

    on_key => sub {
       my ( $self, $key ) = @_;
 
       print "Got key: ".$self->format_key( $key, FORMAT_VIM )."\n";
 
       $loop->loop_stop if $key->type_is_unicode and
                           $key->utf8 eq "C" and
                           $key->modifiers & KEYMOD_CTRL;
    },
 );
 
 $loop->add( $tka );
 
 $loop->loop_forever;

=head1 DESCRIPTION

This class implements an asynchronous perl wrapper around the C<libtermkey>
library, which provides an abstract way to read keypress events in
terminal-based programs. It yields structures that describe keys, rather than
simply returning raw bytes as read from the TTY device.

This class is a subclass of C<IO::Async::Handle>, allowing it to be put in an
C<IO::Async::Loop> object and used alongside other objects in an C<IO::Async>
program. It internally uses an instance of L<Term::TermKey> to access the
underlying C library. For details on general operation, including the
representation of keypress events as objects, see the documentation on that
class.

Proxy methods exist for normal accessors of C<Term::TermKey>, and the usual
behaviour of the C<getkey> or other methods is instead replaced by the
C<on_key> event.

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_key $key

Invoked when a key press is received from the terminal. The C<$key> parameter
will contain an instance of C<Term::TermKey::Key> representing the keypress
event.

=cut

# Forward any requests for symbol imports on to Term::TermKey
sub import {
   shift; unshift @_, "Term::TermKey";
   my $import = $_[0]->can( "import" );
   goto &$import; # So as not to have to fiddle with Sub::UpLevel
}

=head1 CONSTRUCTOR

=cut

=head2 $tka = Term::TermKey::Async->new( %args )

This function returns a new instance of a C<Term::TermKey::Async> object. It
takes the following named arguments:

=over 8

=item term => IO or INT

Optional. File handle or POSIX file descriptor number for the file handle to
use as the connection to the terminal. If not supplied C<STDIN> will be used.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   # TODO: Find a better algorithm to hunt my terminal
   my $term = delete $args{term} || \*STDIN;

   my $termkey = Term::TermKey->new( $term, delete $args{flags} || 0 );
   if( !defined $termkey ) {
      croak "Cannot construct a termkey instance\n";
   }

   my $self = $class->SUPER::new(
      read_handle => $term,
      %args,
   );

   $self->can_event( "on_key" ) or
      croak 'Expected either a on_key callback or an ->on_key method';

   $self->{termkey} = $termkey;

   $self->add_child( $self->{timer} = IO::Async::Timer::Countdown->new(
      notifier_name => "force_key",
      on_expire => $self->_capture_weakself( "_force_key" ),
   ) );

   return $self;
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item flags => INT

C<libtermkey> flags to pass to constructor or C<set_flags>.

=item on_key => CODE

CODE reference for the C<on_key> event.

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_key} ) {
      $self->{on_key} = delete $params{on_key};
   }

   if( exists $params{flags} ) {
      $self->termkey->set_flags( delete $params{flags} );
   }

   $self->SUPER::configure( %params );
}

sub on_read_ready
{
   my $self = shift;

   my $timer = $self->{timer};
   $timer->stop;

   my $termkey = $self->{termkey};

   return unless $termkey->advisereadable == RES_AGAIN;

   my $key;

   my $ret;
   while( ( $ret = $termkey->getkey( $key ) ) == RES_KEY ) {
      $self->invoke_event( on_key => $key );
   }

   if( $ret == RES_AGAIN ) {
      $timer->configure( delay => $termkey->get_waittime / 1000 );
      $timer->start;
   }
   elsif( $ret == RES_EOF ) {
      $self->close;
   }
}

sub _force_key
{
   my $self = shift;

   my $termkey = $self->{termkey};

   my $key;
   if( $termkey->getkey_force( $key ) == RES_KEY ) {
      $self->invoke_event( on_key => $key );
   }
}

=head1 METHODS

=cut

=head2 $tk = $tka->termkey

Returns the C<Term::TermKey> object being used to access the C<libtermkey>
library. Normally should not be required; the proxy methods should be used
instead. See below.

=cut

sub termkey
{
   my $self = shift;
   return $self->{termkey};
}

=head2 $flags = $tka->get_flags

=head2 $tka->set_flags( $flags )

=head2 $canonflags = $tka->get_canonflags

=head2 $tka->set_canonflags( $canonflags )

=head2 $msec = $tka->get_waittime

=head2 $tka->set_waittime( $msec )

=head2 $str = $tka->get_keyname( $sym )

=head2 $sym = $tka->keyname2sym( $keyname )

=head2 ( $ev, $button, $line, $col ) = $tka->interpret_mouse( $key )

=head2 $str = $tka->format_key( $key, $format )

=head2 $key = $tka->parse_key( $str, $format )

=head2 $key = $tka->parse_key_at_pos( $str, $format )

=head2 $cmp = $tka->keycmp( $key1, $key2 )

These methods all proxy to the C<Term::TermKey> object, and allow transparent
use of the C<Term::TermKey::Async> object as if it was a subclass.
Their arguments, behaviour and return value are therefore those provided by
that class. For more detail, see the L<Term::TermKey> documentation.

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

package POE::Component::AIO;

use IO::AIO qw( poll_fileno poll_cb );
use POE;

use strict;
use warnings;
use Carp qw( croak );

our %callback_ids;
our $VERSION = '1.00';

use vars qw( $poco_aio );

sub import {
    my ( $class, $args ) = @_;
    my $package = caller();

    croak "PoCo::AIO expects its arguments in a hash ref"
        if ( $args && ref( $args ) ne 'HASH' );

    unless ( delete $args->{no_auto_export} ) {
        {
            no strict 'refs';
            *{ $package . '::poco_aio' } = \$poco_aio;
        }

        eval( "package $package; use IO::AIO qw( 2 );" );
        if ( $@ ) {
            croak "could not export IO::AIO into $package (is it installed?)";
        }
    }

    return if ( $args->{no_auto_bootstrap} );

    # bootstrap
    POE::Component::AIO->new( %$args );
    
    return;
}

sub new {
    my $class = shift;
    return $poco_aio if ( $poco_aio );

    my $self = $poco_aio = bless({
        session_id => undef,
        postback => undef,
        @_
    }, ref $class || $class );

    POE::Session->create(
        object_states =>  [
            $self => [qw(
                _start
                _stop
                poll_cb
                do_postback
                _shutdown
            )]
        ],
    );

    return $self;
}

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    
    $self->{session_id} = $_[ SESSION ]->ID();
    
    $kernel->alias_set( "$self" );
    
    open( my $fh, "<&=".poll_fileno() ) or die "$!";
    $kernel->select_read( $fh, 'poll_cb' );
    $self->{_fh} = $fh;
   
    return unless( $self->{postback} );
  
    # XXX undocumented
    if ( ref( $self->{postback} ) eq 'ARRAY' ) {
        $kernel->post( @{$self->{postback}}, $self->{session_id}, "$self" );
    } elsif ( ref( $self->{postback} ) eq 'CODE' ) {
        $kernel->yield( 'do_postback' );
    }
  
    return;
}

sub do_postback {
    my $self = $_[ OBJECT ];
    
    $self->{postback}->( $self->{session_id}, "$self" );
    
    return;
}

sub _stop { }

sub callback {
    my ($self, $event, @etc) = @_;

    my $id;
    if ( ref( $event ) eq 'ARRAY' ) {
        ( $id, $event ) = @$event;
    } else {
        my $ses = $poe_kernel->get_active_session();
        if ( $ses ) {
            $id = $ses->ID();
        } else {
            warn 'no active session in call to PoCo::AIO::callback';
            return undef;
        }
    }

    my $callback = POE::Component::AIO::AnonCallback->new(sub {
        $poe_kernel->call( $id => $event => @etc => @_ );
    });

    $callback_ids{$callback} = $id;

    $poe_kernel->refcount_increment( $id, 'anon_event' );

    return $callback;
}

sub postback {
    my ($self, $event, @etc) = @_;

    my $id;
    if ( ref( $event ) eq 'ARRAY' ) {
        ( $id, $event ) = @$event;
    } else {
        my $ses = $poe_kernel->get_active_session();
        if ( $ses ) {
            $id = $ses->ID();
        } else {
            warn 'no active session in call to PoCo::AIO::callback';
            return undef;
        }
    }
    
    my $postback = POE::Component::AIO::AnonCallback->new(sub {
        $poe_kernel->post( $id => $event => @etc => @_ );
    });

    $callback_ids{$postback} = $id;

    $poe_kernel->refcount_increment( $id, 'anon_event' );

    return $postback;
}

sub shutdown {
    $poe_kernel->call( shift->{session_id} => '_shutdown' );
}

sub _shutdown {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $kernel->alias_remove( "$self" );
    $kernel->select_read( delete $self->{_fh} );

    $poco_aio = undef;

    return;
}

1;

=pod

=head1 NAME

POE::Component::AIO - Asynchronous Input/Output for POE

=head1 SYNOPSIS

 use POE qw( Component::AIO );

 ...

 aio_read( $fh, 0, 1024, $buffer, 0, $poco_aio->callback( 'open_done' ) );
 
 aio_read( $fh, 0, 1024, $buffer, 0, sub {
   ...
 } );

=head1 DESCRIPTION

 This component adds support for L<IO::AIO> use in POE

=head2 EXAMPLE

  use POE;

  Foo->new();

  $poe_kernel->run();

  package Foo;

  use POE qw( Component::AIO );
  use Fcntl;

  use strict;
  use warnings;

  sub new {
      my $class = shift;

      my $self = bless( {}, $class );

      POE::Session->create(
          object_states => [
              $self => [qw(
                  _start
                  _stop

                  open_done
                  read_done
              )]
          ]
      );
    
      return $self;
  }

  sub _start {
      my $file = '/etc/passwd';
      
      aio_open( $file, O_RDONLY, 0, $poco_aio->callback( 'open_done', $file ) );
  }
  
  sub open_done {
      my ( $self, $session, $file, $fh ) = @_[ OBJECT, SESSION, ARG0, ARG1 ];
      
      unless ( defined $fh ) {
          die "aio open failed on $file: $!";
      }
      
      my $buffer = '';
      # read 1024 bytes from $fh
      aio_read( $fh, 0, 1024, $buffer, 0, $poco_aio->postback( 'read_done', \$buffer ) );
  }
  
  sub read_done {
      my ( $self, $buffer, $bytes ) = @_[ OBJECT, ARG0, ARG1 ];
  
      unless( $bytes > 0 ) {
          die "aio read failed: $!";
      }
      
      print $$buffer;
  }
  
  sub _stop {
      $poco_aio->shutdown();
  }

=head1 NOTES

This module automaticly bootstraps itself on use().  $poco_aio is imported into your
namespace for easy use.  Just like $poe_kernel when using L<POE>.  There are two
import options available:  no_auto_bootstrap and no_auto_export.

Example:

  use POE::Component::AIO { no_auto_bootstrap => 1, no_auto_export => 1 };

Also, use of this modules' callback and postback methods are completely optional.
They are included for convenience, but note that they don't work the same as the
postback and callback methods from L<POE::Session>.

=head1 METHODS

=over 4

=item new()

Call this to get the singleton object, which is the same as $poco_aio.  See the notes
above.  You do not need to call this unless you have disabled auto bootstrapping.

=item shutdown()

Stop the session used by this module.

=item callback( $event [, $params ] )

Returns a callback.  Params are optional and are stacked before params passed to the callback
at call time.  This differs from L<POE::Session>'s callback because the params are not wrapped
in array references.  It uses the current session to latch the callback to.  If you want to
use another session, you can pass an array ref of the session id and event name as the event
param.

Examples:

  $cb = $poco_aio->callback( 'foo' );
  $cb = $poco_aio->callback( 'foo', $bar );
  $cb = $poco_aio->callback( [ $session->ID(), 'foo' ] );
  $cb = $poco_aio->callback( [ $session->ID(), 'foo' ], $bar );

=item postback( $event [, $params ] );

See the callback method.  The only difference is that it uses a post instead of call

=head1 SEE ALSO

L<IO::AIO>, L<POE>

=head1 AUTHOR

David Davis <xantus@cpan.org>
L<http://xantus.org/>

=head1 LICENSE

Artistic License

=head1 COPYRIGHT AND LICENSE

Copyright 2007 David Davis, and The Dojo Foundation.
Code was shared from the Cometd project L<http://cometd.com/>

=cut

package POE::Component::AIO::AnonCallback;

use POE;

sub new {
    my $class = shift;

    bless( shift, ref $class || $class );
}

sub DESTROY {
    my $self = shift;
    my $session_id = delete $POE::Component::AIO::callback_ids{"$self"};

    if ( defined $session_id ) {
        $poe_kernel->refcount_decrement( $session_id, 'anon_event' );
    } else {
        warn "connection callback DESTROY without session_id to refcount_decrement";
    }

    return;
}


1;


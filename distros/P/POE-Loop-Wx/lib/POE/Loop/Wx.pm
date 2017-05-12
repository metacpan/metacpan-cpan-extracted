#############################################################################
## Name:        Wx.pm
## Purpose:     POE::Loop::Wx, wxPerl event loop for POE
## Author:      Mattia Barbon, 
## Created:     26/05/2003
## Updated by:  Mike Schroeder - to be compatible with POE 3.003
## Updated:     21/12/2004
## RCS-ID:      $Id: Wx.pm,v 1.9 2007/11/29 16:33:19 mike Exp $
## Copyright:   (c) 2003 Mattia Barbon
## Note:        Part of the code comes almost straight from
##              POE::Loop::Gtk and POE::Loop::Select
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package POE::Loop::Wx;

use Wx;
use strict;
use vars qw($VERSION); 
use POE::Loop::PerlSignals;

$VERSION = "0.04";

package POE::Kernel;

use strict;

# Declare which event loop bridge is being used, but first ensure that
# no other bridge has been loaded.

BEGIN {
  die( "POE can't use Wx and " . &POE_LOOP_NAME . "\n" )
    if defined &POE_LOOP;
};

sub POE_LOOP () { LOOP_WX }

my @loop_vectors = ("", "", "");
my %loop_filenos;
my $time_watcher_timer;
my $file_watcher_timer;

###############################################################################
# Administrative functions
###############################################################################

sub loop_initialize {
    my $self = shift;

    # Initialize the vectors as vectors.
    @loop_vectors = ( "", "", "" );
    vec($loop_vectors[MODE_RD], 0, 1) = 0;
    vec($loop_vectors[MODE_WR], 0, 1) = 0;
    vec($loop_vectors[MODE_EX], 0, 1) = 0;

    # start file polling timer
    $file_watcher_timer = POE::Loop::Wx::PollTimer->new;
    $file_watcher_timer->Start( 50, 0 );
}

sub loop_finalize {
    my $self = shift;

    # This is "clever" in that it relies on each symbol on the left to
    # be stringified by the => operator.
    my %kernel_modes =
      ( MODE_RD => MODE_RD,
        MODE_WR => MODE_WR,
        MODE_EX => MODE_EX,
      );

    while (my ($mode_name, $mode_offset) = each(%kernel_modes)) {
        my $bits = unpack("b*", $loop_vectors[$mode_offset]);
        if (index($bits, "1") >= 0) {
            warn "<rc> LOOP VECTOR LEAK: $mode_name = $bits\a\n";
        }
    }

    $time_watcher_timer->Destroy;
    $file_watcher_timer->Destroy;
    undef $time_watcher_timer;
    undef $file_watcher_timer;
}

sub loop_do_timeslice {
    die "doing timeslices currently not supported in the Wx loop";
}

sub loop_run {
    Wx::wxTheApp()->MainLoop;
}

sub loop_halt {
    Wx::wxTheApp->ExitMainLoop if Wx::wxTheApp;
}

sub loop_attach_uidestroy {
    my( $self, $window ) = @_;

    # Don"t bother posting the signal if there are no sessions left.  I
    # think this is a bit of a kludge: the situation where a window
    # lasts longer than POE::Kernel should never occur.
    Wx::Event::EVT_CLOSE( $window,
                          sub {
                              if( $self->_data_ses_count() ) {
                                  $self->_dispatch_event
                                    ( $self, $self,
                                      EN_SIGNAL, ET_SIGNAL, [ "UIDESTROY" ],
                                      __FILE__, __LINE__, time(), -__LINE__
                                    );
                              }
                              return undef;
                          }
                        );
}

###############################################################################
# Alarm or timer functions
###############################################################################

sub loop_reset_time_watcher {
    my( $self, $next_time ) = @_;

    if( $time_watcher_timer ) {
        $time_watcher_timer->Destroy;
        undef $time_watcher_timer;
    }

    $time_watcher_timer = POE::Loop::Wx::Timer->new;
    $self->loop_resume_time_watcher( $next_time );
}

BEGIN {
    if( $^O eq "MSWin32" or $^O eq 'darwin'  ) {
        eval "sub MIN_TIME() { 1 }";
    } else {
        eval "sub MIN_TIME() { 0 }";
    }
}

sub loop_resume_time_watcher {
    my( $self, $next_time ) = @_;
    $time_watcher_timer = POE::Loop::Wx::Timer->new
        unless $time_watcher_timer;

    $next_time -= time();
    $next_time *= 1000;
    $next_time = MIN_TIME if $next_time <= MIN_TIME;

    $time_watcher_timer->Start( $next_time, 1 );
}

sub loop_pause_time_watcher {
    $time_watcher_timer->Stop;
}

###############################################################################
# File activity functions; similar to POE::Loop::Select
###############################################################################

#------------------------------------------------------------------------------
# Maintain filehandle watchers.

sub loop_watch_filehandle {
    my( $self, $handle, $mode ) = @_;
    my $fileno = fileno( $handle );

    vec( $loop_vectors[$mode], $fileno, 1 ) = 1;
    $loop_filenos{$fileno} |= ( 1 << $mode );
}

sub loop_ignore_filehandle {
    my( $self, $handle, $mode ) = @_;
    my $fileno = fileno( $handle );

    vec( $loop_vectors[$mode], $fileno, 1 ) = 0;
    $loop_filenos{$fileno} &= ~ ( 1 << $mode );
}

sub loop_pause_filehandle {
    my( $self, $handle, $mode ) = @_;
    my $fileno = fileno( $handle );

    vec( $loop_vectors[$mode], $fileno, 1 ) = 0;
    $loop_filenos{$fileno} &= ~ ( 1 << $mode );
}

sub loop_resume_filehandle {
    my( $self, $handle, $mode ) = @_;
    my $fileno = fileno( $handle );

    vec( $loop_vectors[$mode], $fileno, 1 ) = 1;
    $loop_filenos{$fileno} |= ( 1 << $mode );
}

# End of stuff similar to POE::Loop::Select

package POE::Loop::Wx::Timer;

use strict;
use base "Wx::Timer";

sub Notify {
    package POE::Kernel;

    my $self = $poe_kernel;

    $self->_data_ev_dispatch_due();
    $self->_test_if_kernel_is_idle();

    # Register the next timeout if there are events left.
    if( $self->get_event_count() ) {
        $self->loop_resume_time_watcher( $self->get_next_event_time() );
    }
}

package POE::Loop::Wx::PollTimer;

use strict;
use base "Wx::Timer";

sub Notify {
    package POE::Kernel;

    my $self = $poe_kernel;

    # Determine which files are being watched.
    my @filenos = ();
    while( my( $fd, $mask ) = each( %loop_filenos ) ) {
        push( @filenos, $fd ) if $mask;
    }

    return unless @filenos;

    # Check filehandles, or wait for a period of time to elapse.
    my $hits = CORE::select( my $rout = $loop_vectors[MODE_RD],
                             my $wout = $loop_vectors[MODE_WR],
                             my $eout = $loop_vectors[MODE_EX],
                             0,
                           );

    return unless $hits > 0;

    # This is where they"re gathered.  It"s a variant on a neat
    # hack Silmaril came up with.
    my( @rd_selects, @wr_selects, @ex_selects );
    foreach ( @filenos ) {
        push( @rd_selects, $_ ) if vec( $rout, $_, 1 );
        push( @wr_selects, $_ ) if vec( $wout, $_, 1 );
        push( @ex_selects, $_ ) if vec( $eout, $_, 1 );
    }

    @rd_selects and
      $self->_data_handle_enqueue_ready( MODE_RD, @rd_selects );
    @wr_selects and
      $self->_data_handle_enqueue_ready( MODE_WR, @wr_selects );
    @ex_selects and
      $self->_data_handle_enqueue_ready( MODE_EX, @ex_selects );
}

1;

__END__

=head1 NAME

POE::Loop::Wx - a bridge that supports wxPerl's event loop from POE

=head1 SYNOPSIS

See L<POE::Loop>.

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface.
It follows POE::Loop's public interface exactly.  Therefore, please
see L<POE::Loop> for its documentation.

=head1 EXAMPLES

See the examples directory for a simple Wx/POE application that demonstrates
subscribe/publish data amongst frames as well as use PoCoCl::UserAgent for
non-blocking parallel data fetching that cooperates with Wx.

=head1 TODO

More examples, add tests.

=head1 SEE ALSO

L<POE>, L<POE::Loop>, L<Wx>

=head1 AUTHORS

Mike Schroeder <mike-cpan@donorware.com>
Ed Heil <ed-cpan@donorware.com>

=head1 ACKNOWLEGEMENTS

Special thanks to Mattia Barbon for getting the initial version of this
put together and encouraging me to get this onto CPAN.

Please see L<POE> for more information about authors, contributors,
and POE's licensing.  Please see L<Wx> for more information about wxPerl
and wxWidgets.

=cut


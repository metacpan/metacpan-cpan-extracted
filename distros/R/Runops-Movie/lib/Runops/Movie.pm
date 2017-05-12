package Runops::Movie;
use strict;
use warnings;
use feature ':5.10';

use Runops::Trace ();
use Internals::DumpArenas ();

our $VERSION = '0.03';

our $Frame;
sub tracer {
    $Frame = 1 if ! defined $Frame;

    say { *STDERR } "Runops::Movie frame $Frame " . $_[0]->name
        or warn "Can't write to STDERR: $!";
    ++ $Frame;
    Internals::DumpArenas::DumpArenas();

    return;
}

sub import {
    my ( $class, %options ) = @_;

    # mask_op
    if ( exists $options{mask_op} ) {
        if ( defined $options{mask_op} ) {
            Runops::Trace::mask_op( @{ $options{mask_op} } );
        }
        else {
            # User passed undef so do nothing.
        }
    }
    else {
        # Apply the default mask.
        Runops::Trace::mask_op( @{ $options{mask_op} } );
    }

    # frame => #
    if ( exists $options{frame} ) {
        if ( defined $options{frame} ) {
            $Frame = $options{frame};
        }
        else {
            # User passed undef so do nothing.
        }
    }
    else {
        # Apply the default frame
        $Frame = 1;
    }

    # STDERR should be buffered if I'm going to use it as a target for a movie
    # script.
    if ( exists $options{unbuffer}
         ? $options{unbuffer}
         : 1 ) {
        my $old = select STDERR;
        $| = 0;
        select $old;
    }

    # Runops::Trace tracer
    if ( exists $options{tracer} ) {
        if ( defined $options{tracer} ) {
            Runops::Trace::set_tracer( $options{tracer} );
        }
        else {
            # Do nothing, I guess
        }
    }
    else {
        Runops::Trace::set_tracer( \ &Runops::Movie::tracer );
    }

    # Roll movie!
    if ( exists $options{run}
         ? $options{run}
         : 1 ) {
        Runops::Trace::enable_tracing();
    }

    return;
}

q(Go drinking with mst);

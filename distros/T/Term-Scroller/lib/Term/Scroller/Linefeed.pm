package Term::Scroller::Linefeed;

use 5.020;
use strict;
use warnings;

=head1 NAME

Term::Scroller::Linefeed - Utility function for L<Term::Scroller>, used to read
lines from a pseudoterminal, allowing for non-terminated lines.

=head1 SYNOPSIS

    use IO::Pty;
    use Term::Scroller::Linefeed qw(linefeed);

    my $pty = IO::Pty->new();

    # (Set up something to write to the $pty however you like)

    while( my $line = linefeed($pty) ) {

        if ($line =~ /\n$/) {
            print "Pty printed a complete line"
        }
        else {
            print "Pty printed a partial line"
        }

    }

=head1 DESCRIPTION

This module exports the C<linefeed> function which takes an IO::Pty instance and
returns the next line of text from read from the slave. The key difference
between this (as opposed to simply '<$pty->slave>') is that it will not wait
for a newline character at the end of input. So if a sequence of text I<not>
ending in a newline is written to the pty master, then it will be available
immediately as a "line" returned by this function.

B<NOTE:> This stores an internal buffer of lines alongside the IO::Pty instance,
adding an arrayref 'term_scroller_linefeed' in the Pty's typeglob.

=cut

use Carp;
use IO::Handle;
use Exporter;
use Scalar::Util qw(blessed);

use IO::Pty;

use constant BUFFERNAME => 'term_scroller_linefeed';

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(linefeed);


sub linefeed {
    my $pty = shift;

    unless (blessed($pty) && $pty->isa('IO::Pty')) {
        croak "Must specify an IO::Pty instance";
    }

    # Add buffer to Pty typeglob
    # if it doesn't exist already
    if (!exists ${*$pty}{BUFFERNAME}) {
        ${*$pty}{BUFFERNAME} = [];
    }

    my $buffer = ${*$pty}{BUFFERNAME};

    if ( @$buffer ) {
        # Return next line if one is in the buffer
        return shift @$buffer;
    }
    else {
        # If buffer is empty, read more data then return next line
        my $ptymask = '';
        vec($ptymask, fileno($pty->slave), 1) = 1;

        my $ready = select($ptymask, undef, undef, undef);
        croak "Error select(2)'ing on pty: $!" if $ready == -1;

        my $read = sysread($pty->slave, my $chunk, 4096);

        return undef unless $read; # EOF

        push @$buffer, split /^/m, $chunk;
        return shift @$buffer;
    }

}


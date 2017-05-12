package POE::Component::IKC::Timing;

############################################################
# $Id$
# Copyright 2011-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.

package     # Hide from the CPAN indexer
    T;

use strict;
use warnings;

use POSIX qw( strftime );
use Time::HiRes qw( gettimeofday tv_interval );
use Carp;

sub TIMING { 0 }

our %PARTS;
our $fh = *STDERR;


#######################################
sub open
{
    my( $package, $file ) = @_;
    return unless TIMING;
    my $t = IO::File->new( ">> $file" );
    croak "Unable to open $file: $!" unless $t;
    $fh = $t;
    $fh->print( strftime( "$$: %H:%M%S.0000 +0 OPEN\n", localtime ) );
    return;
}

#######################################
sub start
{
    my( $package, $part ) = @_;
    return unless TIMING;
    if( $PARTS{$part} ) {
        $package->point( $part, '+++' );
        $PARTS{ $part }{start} = $PARTS{ $part }{'last'};
        return;
    }

    my $now = [ gettimeofday ];
    $PARTS{ $part } = { start=>$now, last=>$now };
    $package->point( $part, '{{{' );
    return;
}

#######################################
sub point
{
    my( $package, $part, $msg ) = @_;
    return unless TIMING;
    unless( $PARTS{ $part } ) {
        # carp "Timing part $part doesn't exist";
        return;
    }

    my $time = strftime( "%H:%M:%S" , localtime );

    my $now = [ gettimeofday ];
    $time .= sprintf ".%04i", int $now->[1]/100;

    my $last = $PARTS{ $part }{'last'};
    $time .= __delta( $last, $now );
    $PARTS{ $part }{'last'} = $now;
    $fh->print("$$: $time [$part] $msg\n");
    return;
}


sub __delta
{
    my( $last, $now ) = @_;

    my $el = tv_interval( $last, $now );
    if( int($el*1000) == 0 ) {
        return " +0";
    }
    elsif( $el > 1 ) {
        return sprintf( " +%.3fs", $el);
    } else {
        $el *= 1000;            # microseconds -> milliseconds
        if( $el > 10 ) {
            return sprintf( " +%ims", int $el);
        } else {
            return sprintf( " +%.1fms", $el);  
        }
    }
    return '';
}

#######################################
sub end
{
    my( $package, $part ) = @_;
    return unless TIMING;
    unless( $PARTS{ $part } ) {
        carp "Timing part $part doesn't exist";
        return;
    }
    my $now = [ gettimeofday ];
    my $last = $PARTS{ $part }{start};
    my $elapsed = __delta( $last, $now );
    $elapsed =~ s/ \+//;

    $package->point( $part, "}}} total=$elapsed" );
    delete $PARTS{ $part };
}

1;
__END__

=head1 NAME

POE::Component::IKC::Timing - POE Inter-kernel Communication timing helper

=head1 SYNOPSIS

    use POE::Component::IKC::Timing;
    T->start( 'part' )
    T->point( part => $msg );
    T->end( 'part' );

=head1 DESCRIPTION

This module provides a crude form of application profiling.  It is not currently stable enough
to be documented nor used.  In fact, it will probably become its own module at some point.

=head1 SEE ALSO

L<POE::Component::IKC>

=cut

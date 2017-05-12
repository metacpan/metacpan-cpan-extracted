package Runops::Movie::Util;
use strict;
use warnings;
use Exporter qw( import );
our @EXPORT_OK = qw( pretty_size rood printf_pretty_size );

sub rood {
    my ( $fn ) = @_;

    print "Read $fn (@{[ pretty_size( -s $fn ) ]})\n"
        or warn "Can't write to STDOUT: $!";
    open my($fh), '<', $fn
        or die "Can't open $fn for reading: $!";
    return $fh;
}

use constant { GIGABYTE => 1<<30, MEGABYTE => 1<<20, KILIBYTE => 1<<10 };
sub pretty_size {
    my ( $bytes ) = @_;

    if ( $bytes > GIGABYTE ) {
        return sprintf '%0.2fGB', $bytes / GIGABYTE;
    }
    elsif ( $bytes > MEGABYTE ) {
        return sprintf '%0.2fMB', $bytes / MEGABYTE;
    }
    elsif ( $bytes > KILIBYTE ) {
        return sprintf '%0.2fKB', $bytes / KILIBYTE;
    }
    else {
        return "$bytes bytes";
    }
}

sub printf_pretty_size {
    my ( $format, @args ) = @_;

    my @reformatted_args =
	map { pretty_size( $_ ) }
        @args;

    printf "$format\n", @reformatted_args;
}

'Go drinking with mst';

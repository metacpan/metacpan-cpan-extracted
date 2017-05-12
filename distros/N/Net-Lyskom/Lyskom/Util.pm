package Net::Lyskom::Util;

use strict;
use warnings;
use base qw{Exporter};

our (@EXPORT_OK, %EXPORT_TAGS, $debug);

@EXPORT_OK = qw{
		holl
		debug
		deholl
		parse_array_stream
	       };
%EXPORT_TAGS = (
		all => [qw {
			    holl
			    debug
			    deholl
			    parse_array_stream
			   }]
	       );


=head1 NAME

  Net::Lyskom::Util - Utility functions for Net::Lyskom objects

=head1 SYNOPSIS

  use Net::Lyskom::Util qw{:all};

=head1 DESCRIPTION

Holds a handful of utility functions. They are all exported via the :all tag.

=head2 Functions

=over

=item holl($arg)

Returns its argument Hollerith-encoded.

=item deholl($arg)

Returns its argument with Hollerith-encoding removed. Almost totally useless
since the network processing also removes Hollerith encoding.

=item debug(@arg)

Prints its arguments to STDERR if the variable $debug is set.

=item parse_array_stream($cref,$aref)

Helper function for parsing arrays out of the stream returned from the
Kom server. First argument should be a reference to a function that slurps
items from an array given as reference argument to it, the second argument
should be a reference to the array that should be slurped.

=back

=cut

sub holl {
    return length($_[0])."H".$_[0];
}

sub deholl {
    my $r = shift;

    $r =~ s/^\d+H//;
    return $r;
}

sub debug {
    return unless $debug;
    print @_,"\n";
}

sub parse_array_stream {
    my $proc = shift;
    my @res;
    my $count = shift @{$_[0]};

    my $sign = shift @{$_[0]};		# Get the intial brace
    return () unless $sign eq "{";

    while ($count-- > 0) {
	push @res, &$proc(@_);
    }
    shift @{$_[0]};		# Lose the closing brace
    return @res;
}


return 1;

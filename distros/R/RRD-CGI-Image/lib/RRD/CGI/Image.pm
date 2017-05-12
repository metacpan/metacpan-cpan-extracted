package RRD::CGI::Image;

use warnings;
use strict;
use Spiffy '-base';
use RRDs;
use Carp;
use HTML::Entities;
use URI::Escape;
use POSIX 'tzset';

our $VERSION = '0.01';

field 'output_file'		=> '-';  # STDOUT
field 'params'			=> ();
field 'rrd_base'  		=> '/var/rrd/';
field 'error_img' 		=> '/var/www/graphing_error.png';
field 'logging'			=> 0;

sub print_graph {
	my $self = shift;
	carp "print_graph( %cgi_params_with_values ) called without args" unless @_;
	croak "rrd_base: " . $self->rrd_base . " does not exist." unless -d $self->rrd_base;

	$self->params( \@_ );
	$self->normalize_params;

	WWW $self if $self->logging;
		
	RRDs::graph( $self->output_file, @{ $self->params } );
	$self->print_error_img if RRDs::error();
}

sub normalize_params {
	my $self = shift;

	# User is not allowed to submit an output filename via query string. 
	# It must be set using output_file() instead.
	#
	$self->print_error_img( "Bad first argument" ) unless $self->params->[0] =~ /^\s*--?\w/;

	my @rrd_args;
 	my @params = @{ $self->params };

	while ( my ($k, $v) = splice @params, 0, 2 ) {		
		# translate &nbsp; &#230, etc.
		$k = decode_entities( $k );
		$v = decode_entities( $v ) if defined $v;

		# translate %20, %3a, etc.
		$k = uri_unescape( $k );
		$v = uri_unescape( $v ) if defined $v;

		# User not allowed to poke around above the rrd_base() dir.
		$self->print_error_img( "Bad DEF path" ) if $k =~ /^DEF .* \.\./x;
		$self->print_error_img( "Bad DEF path" ) if defined $v && $v =~ /^DEF .* \.\./x;

		# Insert rrd_base() into the DEF statement
		if ( $k =~ /^DEF/ ) {
			$v = $self->rrd_base . $v;
		}

		# Set and strip any timezone params - it's not a valid RRDs::graph() argument
		if ( $k =~ /tz/i ) {
			$self->tz( $v );
			next;
		}
		
		# Some of the keypair args will be split by CGI's param handler. We need to join the
		# args like "DEF:ds0=..." back together.
		#
		# Args like --height=120 should turn into a Perl key-value tuple instead. 
		if ( $k =~ /^-/ ) {
			push @rrd_args, defined $v && $v ne '' ? ( $k => $v ) : $k;
		}
		else {
			push @rrd_args, defined $v && $v ne '' ? "$k=$v" : $k;
		}
	}

	return $self->params( \@rrd_args );
}

sub tz {
	my $self = shift;
	$self->{tz} = shift if $_[0];

	if ( $self->{tz} ) {
		$ENV{TZ} = $self->{tz};
		tzset();
	}

	return $self->{tz};
}

sub print_error_img {
	my $self = shift;
	
	my $errmsg = shift || RRDs::error() || "Unknown error";
	warn $errmsg;
	
	open F, $self->error_img or warn "error_img: " . $self->error_img . " not found";
	print <F>;
	close F;
}

=head1 NAME

RRD::CGI::Image - accept CGI-style rrdgraph args to build and print image

=head1 NOTICE

This is development code - the API may change!

=head1 SYNOPSIS

    use RRD::CGI::Image;
	use CGI qw[Vars header];

    my $image = RRD::CGI::Image->new(
		rrd_base  => '/var/rrd',
		error_img => '/var/www/.../path/to/graphing_error.png',
	);

	print header( 'image/png' );
	$image->print_graph( Vars() );

=head1 METHODS

=head2 new() - create new object to handle your bidding

Behaves like any other new(), really.

=head2 print_graph() - accepts CGI params, parses them, and prints a graph

The graph will be sent to the location specified by output_file(); STDOUT by default.

In addition to the regular rrdgraph options, you can also add a B<tz=timezone> param which will render the graph in the given timezone.

The key-value pairs need a little translation to get them successfully passed through the URL. Your URL or CGI library will probably handle most of this automatically. Here's the full examplanation.

Let's convert a fairly standard set of args for RRDs::graph() to GET-style CGI params, starting with:

	RRDs::graph(
		'/path/to/output/file.png',
		'--start' => '-1d',
		'--end' => 'now',
		'--height' => 200,
		'--width' => 600,
		'--imgformat' => 'PNG',
		'--lower-limit' => 0,
		'--title' => 'This is a title',
		'--vertical-label' => 'bps',
		'DEF:ds0' => '/var/rrd/router/data/router.example.com/gigabitethernet101.rrd:ds0:MAX',
		'DEF:ds1' => '/var/rrd/router/data/router.example.com/gigabitethernet101.rrd:ds1:MAX',
		'CDEF:in:ds0,8,*',  # convert bytes to bits
		'CDEF:out:ds1,8,*',
		'LINE1:in#33ee33:Input',
		'LINE1:out#0000ff:Output',
	);

First, completely drop the first argument. We don't need an output filename anymore - that's handled by output_file() instead.

Next, change the Perl hash-style key-value params to from B<key E<gt> value> to CGI-style: B<key=value>;

Next, delete the first half of the path - the rrd_base() - from your DEF statements. That will change the DEF lines to:

	'DEF:ds0' => 'router.example.com/gigabitethernet101.rrd:ds0:MAX',
	'DEF:ds1' => 'router.example.com/gigabitethernet101.rrd:ds1:MAX',

Finally, make sure your params are encoded so they pass through the CGI interface. URI::Escape::uri_escape() will, for example, convert the hashmarks in LINE1 statements from # to %23. Here's what the LINE1 entries should look like after encoding:

	'LINE1:in%2333ee33:Input',
	'LINE1:out%230000ff:Output',

Many of these will be handled automatically if you're relying on a CGI or URL module to construct the URL for you.

=head2 output_file() - where will the new graph be created? 

Defaults to STDOUT (-).

=head2 rrd_base() - pathname to your RRD files.

Users will be able to specify partial paths to the RRDs beneath this directory in their DEF declarations but they
will be sandboxed into this directory. Don't be too permissive - it's a security risk.

Must end with "/".

=head2 error_img() - pathname (not URL) to an image that says "an error happened".

Check your webserver's logs to see what went wrong.

=head2 tz() - get/set the timezone for the graph.

Pertinent if you have RRDs in different timezones.

=head2 normalize_params() - clean up and reassemble the input params

Called internally.

=head2 print_error_img( $opt_errmsg ) - prints the error_img() file to output_file() location (STDOUT by default) and writes the error to log

=head2 logging() - if true, will print the normalized (processed) params to log

=head1 AUTHOR

Joshua Keroes, C<< <joshua at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rrd-cgi-image at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RRD-CGI-Image>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RRD::CGI::Image

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RRD-CGI-Image>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RRD-CGI-Image>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RRD-CGI-Image>

=item * Search CPAN

L<http://search.cpan.org/dist/RRD-CGI-Image>

=back

=head1 SEE ALSO

L<RRDs>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Joshua Keroes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of RRD::CGI::Image

__END__

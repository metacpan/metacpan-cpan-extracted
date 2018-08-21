use 5.006; use strict; use warnings;

package Parse::MIME;

our $VERSION = '1.005';

use Exporter ();
our @ISA = 'Exporter';
our @EXPORT_OK = qw(
	&parse_mime_type &parse_media_range &parse_media_range_list 
	&fitness_and_quality_parsed &quality_parsed &quality
	&best_match
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _numify($) { no warnings 'numeric'; 0 + shift }

# takes any number of args and returns copies stripped of surrounding whitespace
sub _strip { s/\A +//, s/ +\z// for my @s = @_; @s[ 0 .. $#s ] }

# check whether first two args are equal or one of them is a wildcard
sub _match { $_[0] eq $_[1] or grep { $_ eq '*' } @_[0,1] }

sub parse_mime_type {
	my ( $mime_type ) = @_;

	my @part      = split /;/, $mime_type;
	my $full_type = _strip shift @part;
	my %param     = map { _strip split /=/, $_, 2 } @part;

	# Java URLConnection class sends an Accept header that includes a single "*"
	# Turn it into a legal wildcard.
	$full_type = '*/*' if $full_type eq '*';

	my ( $type, $subtype ) = _strip split m!/!, $full_type;

	return ( $type, $subtype, \%param );
}

sub parse_media_range {
	my ( $range ) = @_;

	my ( $type, $subtype, $param ) = parse_mime_type $range;

	$param->{'q'} = 1
		unless defined $param->{'q'}
		and length  $param->{'q'}
		and _numify $param->{'q'} <= 1
		and _numify $param->{'q'} >= 0;

	return ( $type, $subtype, $param );
}

sub parse_media_range_list {
	my ( $media_range_list ) = @_;
	return map { parse_media_range $_ } split /,/, $media_range_list;
}

sub fitness_and_quality_parsed {
	my ( $mime_type, @parsed_ranges ) = @_;

	my ( $best_fitness, $best_fit_q ) = ( -1, 0 );

	my ( $target_type, $target_subtype, $target_param )
		= parse_media_range $mime_type;

	while ( my ( $type, $subtype, $param ) = splice @parsed_ranges, 0, 3 ) {

		if ( _match( $type, $target_type ) and _match( $subtype, $target_subtype ) ) {

			my $fitness
				= ( $type    eq $target_type    ? 100 : 0 )
				+ ( $subtype eq $target_subtype ?  10 : 0 )
				;

			while ( my ( $k, $v ) = each %$param ) {
				++$fitness
					if $k ne 'q'
					and exists $target_param->{ $k }
					and $target_param->{ $k } eq $v;
			}

			( $best_fitness, $best_fit_q ) = ( $fitness, $param->{'q'} )
				if $fitness > $best_fitness;
		}
	}

	return ( $best_fitness, _numify $best_fit_q );
}

sub quality_parsed {
	return +( fitness_and_quality_parsed @_ )[1];
}

sub quality {
	my ( $mime_type, $ranges ) = @_;
	my @parsed_range = parse_media_range_list $ranges;
	return quality_parsed $mime_type, @parsed_range;
}

sub best_match {
	my ( $supported, $header ) = @_;
	my @parsed_header = parse_media_range_list $header;

	# fitness_and_quality_parsed will return fitness -1 on failure,
	# so we want to start with an invalid value greater than that
	my ( $best_fitness, $best_fit_q, $match ) = ( -.5, 0 );

	for my $type ( @$supported ) {
		my ( $fitness, $fit_q ) = fitness_and_quality_parsed $type, @parsed_header;
		next if $fitness < $best_fitness;
		next if $fitness == $best_fitness and $fit_q < $best_fit_q;
		( $best_fitness, $best_fit_q, $match ) = ( $fitness, $fit_q, $type );
	}

	return if not defined $match;
	return $match;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::MIME - Parse mime-types, match against media ranges

=head1 SYNOPSIS

 use Parse::MIME qw( best_match );
 print best_match( [ qw( application/xbel+xml text/xml ) ], 'text/*;q=0.5,*/*; q=0.1' );
 # text/xml

=head1 DESCRIPTION

This module provides basic functions for handling mime-types. It can handle
matching mime-types against a list of media-ranges. See section 14.1 of the
HTTP specification [RFC 2616] for a complete explanation:
L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1>

=head1 INTERFACE

None of the following functions are exported by default. You can use the
C<:all> tag to import all of them into your package:

 use Parse::MIME ':all';

=head2 parse_mime_type

Parses a mime-type into its component parts and returns type, subtype and
params, where params is a reference to a hash of all the parameters for the
media range:

 parse_mime_type 'application/xhtml;q=0.5'
 # ( 'application', 'xhtml', { q => 0.5 } )

=head2 parse_media_range

Media-ranges are mime-types with wild-cards and a C<q> quality parameter. This
function works just like L</parse_mime_type>, but also guarantees that there is
a value for C<q> in the params hash, supplying the default value if necessary.

 parse_media_range 'application/xhtml'
 # ( 'application', 'xhtml', { q => 1 } )

=head2 parse_media_range_list

Media-range lists are comma-separated lists of media ranges. This function
works just like L</parse_media_range>, but accepts a list of media ranges and
returns for all of media-ranges.

 my @l = parse_media_range_list 'application/xhtml, text/html;q=0.7'
 # ( 'application', 'xhtml', { q => 1 }, 'text', 'html', { q => 0.7 } )

=head2 fitness_and_quality_parsed

Find the best match for a given mime-type (passed as the first parameter)
against a list of media ranges that have already been parsed by
L</parse_media_range> (passed as a flat list). Returns the fitness value and
the value of the C<q> quality parameter of the best match, or C<( -1, 0 )> if
no match was found.

 # for @l see above
 fitness_and_quality_parsed( 'text/html', @l )
 # ( 110, 0.7 )

=head2 quality

Determines the quality (C<q>) of a mime-type (passed as the first parameter)
when compared against a media-range list string. F.ex.:

 quality( 'text/html', 'text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5' )
 # 0.7

=head2 quality_parsed

Just like L</quality>, except the second parameter must be pre-parsed by
L</parse_media_range_list>.

=head2 best_match

Choose the mime-type with the highest quality (C<q>) from a list of candidates.
Takes an array of supported mime-types as the first parameter and finds the
best match for all the media-ranges listed in header, which is passed as the
second parameter. The value of header must be a string that conforms to the
format of the HTTP C<Accept> header. F.ex.:

 best_match( [ qw( application/xbel+xml text/xml ) ], 'text/*;q=0.5,*/*; q=0.1' )
 # 'text/xml'

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

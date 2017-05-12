#
# This file is part of POE-Component-Client-SimpleFTP
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::Client::SimpleFTP::Utils;
$POE::Component::Client::SimpleFTP::Utils::VERSION = '0.004';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Miscellaneous FTP utility functions

use parent 'Exporter';
our @EXPORT_OK = qw(
	code_preliminary code_success code_intermediate code_failure code_tls
	EOL
	mdtm_parser feat_parser
);
our %EXPORT_TAGS = (
	'code' => [
		qw( code_preliminary code_success code_intermediate code_failure code_tls ),
	],
);

#pod =func code_preliminary
#pod
#pod Tests whether the code is a 1yz code ( Positive Preliminary reply ) and returns a boolean value.
#pod
#pod =cut

#pod =func code_success
#pod
#pod Tests whether the code is a 2yz code ( Positive Completion reply ) and returns a boolean value.
#pod
#pod =cut

#pod =func code_intermediate
#pod
#pod Tests whether the code is a 3yz code ( Positive Intermediate reply ) and returns a boolean value.
#pod
#pod =cut

#pod =func code_failure
#pod
#pod Tests whether the code is a 4yz or 5yz code ( Transient/Permanent Negative Completion reply ) and returns a boolean value.
#pod
#pod =cut

#pod =func code_tls
#pod
#pod Tests whether the code is a 6yz code ( Protected reply ) and returns a boolean value.
#pod
#pod =cut

# helper sub to validate a code before doing the actual comparison
sub _check_code {
	return if ! defined $_[0];
	return if length( $_[0] ) != 3;
	return if $_[0] !~ /^\d+$/;
	return 1;
}

# helper subs to figure out what a code is
sub code_preliminary { return if ! _check_code( $_[0] ); return substr( $_[0], 0, 1 ) == 1 }
sub code_success { return if ! _check_code( $_[0] ); return substr( $_[0], 0, 1 ) == 2 }
sub code_intermediate { return if ! _check_code( $_[0] ); return substr( $_[0], 0, 1 ) == 3 }
sub code_failure { return if ! _check_code( $_[0] ); return $_[0] =~ /^[45]/ }
sub code_tls { return if ! _check_code( $_[0] ); return substr( $_[0], 0, 1 ) == 6 }

#pod =func EOL
#pod
#pod Returns the end-of-line terminator as specified in RFC 959
#pod
#pod =cut

sub EOL () { "\015\012" }

#pod =func mdtm_parser
#pod
#pod Returns a L<DateTime> object representing the modification timestamp of a file. Useful for parsing L<POE::Component::Client::SimpleFTP/mdtm> replies!
#pod
#pod NOTE: The MDTM format does not supply a timezone, you have to process that yourself!
#pod
#pod On an error returns undef.
#pod
#pod =cut

sub mdtm_parser {
	my $mdtm = shift;

	# check to see if we received microseconds
	my $microseconds;
	if ( $mdtm =~ /^(\d+)\.(\d+)$/ ) {
		$mdtm = $1;
		$microseconds = $2;
	}

	require DateTime::Format::Strptime;
	my $strp = DateTime::Format::Strptime->new(
		# RFC 3659 pattern: YYYYMMDDHHMMSS.sss
		pattern => "%Y%m%d%H%M%S",
		on_error => 'undef',
	);
	my $dt = $strp->parse_datetime( $mdtm );
	if ( defined $dt ) {
		if ( defined $microseconds ) {
			# add it to the object!
			$dt->set_nanosecond( $microseconds * 1000 );
		}
		return $dt;
	} else {
		return;
	}
}

#pod =func feat_parser
#pod
#pod Returns an array of FEAT capabilities present on the server. Useful for parsing L<POE::Component::Client::SimpleFTP/feat> replies!
#pod
#pod On an error returns an empty array.
#pod
#pod =cut

sub feat_parser {
	my $feat = shift;

	# validation
	return () if ! defined $feat;
	return () if ! length( $feat );

	# it should be a string with newlines in it separating the FEAT replies
	my @data = split( "\n", $feat );
	return () if scalar @data <= 1;

	# remove the first/last elements as they are informational text
	shift @data;
	pop @data;

	# remove any whitespace
	foreach my $f ( @data ) {
		$f =~ s/^\s+//;
		$f =~ s/\s+$//;
	}

	# all done!
	return @data;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=head1 NAME

POE::Component::Client::SimpleFTP::Utils - Miscellaneous FTP utility functions

=head1 VERSION

  This document describes v0.004 of POE::Component::Client::SimpleFTP::Utils - released November 04, 2014 as part of POE-Component-Client-SimpleFTP.

=head1 SYNOPSIS

	use POE::Component::Client::SimpleFTP::Utils qw( :code );

	# in an event handler
	my $code = shift;
	if ( code_success( $code ) ) {
		print "FTP command OK\n";
	} else {
		warn "FTP command error!";
	}

=head1 DESCRIPTION

This module provides the various utility functions for use in your FTP application. You can import any sub listed in the POD or those tags:

=head2 code

Imports all of the code_* subs

=head1 FUNCTIONS

=head2 code_preliminary

Tests whether the code is a 1yz code ( Positive Preliminary reply ) and returns a boolean value.

=head2 code_success

Tests whether the code is a 2yz code ( Positive Completion reply ) and returns a boolean value.

=head2 code_intermediate

Tests whether the code is a 3yz code ( Positive Intermediate reply ) and returns a boolean value.

=head2 code_failure

Tests whether the code is a 4yz or 5yz code ( Transient/Permanent Negative Completion reply ) and returns a boolean value.

=head2 code_tls

Tests whether the code is a 6yz code ( Protected reply ) and returns a boolean value.

=head2 EOL

Returns the end-of-line terminator as specified in RFC 959

=head2 mdtm_parser

Returns a L<DateTime> object representing the modification timestamp of a file. Useful for parsing L<POE::Component::Client::SimpleFTP/mdtm> replies!

NOTE: The MDTM format does not supply a timezone, you have to process that yourself!

On an error returns undef.

=head2 feat_parser

Returns an array of FEAT capabilities present on the server. Useful for parsing L<POE::Component::Client::SimpleFTP/feat> replies!

On an error returns an empty array.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::Client::SimpleFTP|POE::Component::Client::SimpleFTP>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

## RRSIG time stamp for T and T6
package Net::DNS::Extlang::Time;

our $VERSION = '0.1';
=head1 NAME

Net::DNS::Extlang::Time - Helper routines for timestamps

Called only from Extlang generated code.  No user servicable parts.

=cut
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(_encodetime _string2time);

use strict;
use Carp;
use Time::Local;
use constant UTIL => defined eval 'require Scalar::Util';

my $y1998 = timegm( 0, 0, 0, 1, 0, 1998 );
my $y2026 = timegm( 0, 0, 0, 1, 0, 2026 );
my $y2082 = $y2026 << 1;
my $y2054 = $y2082 - $y1998;
my $m2026 = int( 0x80000000 - $y2026 );
my $m2054 = int( 0x80000000 - $y2054 );
my $t2082 = int( $y2082 & 0x7FFFFFFF );
my $t2100 = 1960058752;

sub _string2time {			## parse time specification string
	my $arg = shift;
	croak 'undefined time' unless defined $arg;
	return int($arg) if length($arg) < 12;
	my ( $y, $m, @dhms ) = unpack 'a4 a2 a2 a2 a2 a2', $arg . '00';
	unless ( $arg gt '20380119031407' ) {			# calendar folding
		return timegm( reverse(@dhms), $m - 1, $y ) if $y < 2026;
		return timegm( reverse(@dhms), $m - 1, $y - 56 ) + $y2026;
	} elsif ( $y > 2082 ) {
		my $z = timegm( reverse(@dhms), $m - 1, $y - 84 );    # expunge 29 Feb 2100
		return $z < 1456790400 ? $z + $y2054 : $z + $y2054 - 86400;
	}
	return ( timegm( reverse(@dhms), $m - 1, $y - 56 ) + $y2054 ) - $y1998;
}

# return encoded time
sub _encodetime {
	my $time = shift;

	return undef unless $time;
	return UTIL ? Scalar::Util::dualvar( $time, _time2string($time) ) : _time2string($time);
}

sub _time2string {			## format time specification string
	my $arg = shift;
	croak 'undefined time' unless defined $arg;
	my $ls31 = int( $arg & 0x7FFFFFFF );
	if ( $arg & 0x80000000 ) {

		if ( $ls31 > $t2082 ) {
			$ls31 += 86400 unless $ls31 < $t2100;	# expunge 29 Feb 2100
			my ( $yy, $mm, @dhms ) = reverse( ( gmtime( $ls31 + $m2054 ) )[0 .. 5] );
			return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1984, $mm + 1, @dhms;
		}

		my ( $yy, $mm, @dhms ) = reverse( ( gmtime( $ls31 + $m2026 ) )[0 .. 5] );
		return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1956, $mm + 1, @dhms;


	} elsif ( $ls31 > $y2026 ) {
		my ( $yy, $mm, @dhms ) = reverse( ( gmtime( $ls31 - $y2026 ) )[0 .. 5] );
		return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1956, $mm + 1, @dhms;
	}

	my ( $yy, $mm, @dhms ) = reverse( ( gmtime $ls31 )[0 .. 5] );
	return sprintf '%d%02d%02d%02d%02d%02d', $yy + 1900, $mm + 1, @dhms;
}
1;
__END__

=head1 COPYRIGHT

Copyright 2016 John R. Levine. 

Parts Copyright 2007,2008 NLnet Labs.  Olaf M. Kolkman.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

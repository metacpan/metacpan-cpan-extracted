## NSEC and NSEC3 bitmaps and base32
package Net::DNS::Extlang::Nsechelp;

our $VERSION = '0.1';
=head1 NAME

Net::DNS::Extlang::Nsechelp - Helper routines for compiled NSEC and
NSEC3 resource records

Called only from Extlang generated code.  No user servicable parts.

=cut

use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(_type2bm _bm2type _encode_base32 _decode_base32);

use strict;
use Net::DNS::Parameters qw(typebyname typebyval);
   
sub _type2bm {
	my @typearray;
	foreach my $typename ( map split(), @_ ) {
		my $number = typebyname($typename);
		my $window = $number >> 8;
		my $bitnum = $number & 255;
		my $octet  = $bitnum >> 3;
		my $bit	   = $bitnum & 7;
		$typearray[$window][$octet] |= 0x80 >> $bit;
	}

	my $bitmap = '';
	my $window = 0;
	foreach (@typearray) {
		if ( my $pane = $typearray[$window] ) {
			my @content = map $_ || 0, @$pane;
			$bitmap .= pack 'CC C*', $window, scalar(@content), @content;
		}
		$window++;
	}

	return $bitmap;
}


sub _bm2type {
	my @typelist;
	my $bitmap = shift || return @typelist;

	my $index = 0;
	my $limit = length $bitmap;

	while ( $index < $limit ) {
		my ( $block, $size ) = unpack "\@$index C2", $bitmap;
		my $typenum = $block << 8;
		foreach my $octet ( unpack "\@$index xxC$size", $bitmap ) {
			my $i = $typenum += 8;
			my @name;
			while ($octet) {
				--$i;
				unshift @name, typebyval($i) if $octet & 1;
				$octet = $octet >> 1;
			}
			push @typelist, @name;
		}
		$index += $size + 2;
	}

	return @typelist;
}

sub _decode_base32 {
	local $_ = shift || '';
	tr [0-9a-vA-V] [\000-\037\012-\037];
	$_ = unpack 'B*', $_;
	s/000(.....)/$1/g;
	my $l = length;
	$_ = substr $_, 0, $l & ~7 if $l & 7;
	pack 'B*', $_;
}


sub _encode_base32 {
	local $_ = unpack 'B*', shift;
	s/(.....)/000$1/g;
	my $l = length;
	my $x = substr $_, $l & ~7;
	my $n = length $x;
	substr( $_, $l & ~7 ) = join '', '000', $x, '0' x ( 5 - $n ) if $n;
	$_ = pack( 'B*', $_ );
	tr [\000-\037] [0-9a-v];
	return $_;
}
1;
__END__

=head1 COPYRIGHT

Copyright 2016 John R. Levine. 

Parts Copyright 2007,2008 NLnet Labs.  Author Olaf M. Kolkman

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

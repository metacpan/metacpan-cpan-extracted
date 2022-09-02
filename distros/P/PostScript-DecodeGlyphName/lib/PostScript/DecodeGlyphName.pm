use 5.008001; use strict; use warnings;

package PostScript::DecodeGlyphName;

our $VERSION = '0.002';

use Exporter::Tidy all => [qw( decode_glyph parse_adobeglyphlist )];

sub _croak { require Carp; goto &Carp::croak }

sub _utf8ify { no warnings 'utf8'; map { pack "U", hex } @_ }

my $uni_notation = qr{
	\A uni
	(
		(?:
			[0-9ABCEF] [\dA-F] {3}
			|
			D [0-7] [\dA-F] {2}
		)+
	)
	\z
}x;

# this is a sexeger
my $u_notation = qr{
	\A
	(
		[\dA-F] {2}
		(?:
			[0-7] D 0? 0?
			|
			[\dA-F] [\dABCEF] [\dA-F] {0,2}
		)
	)
	u \z
}x;

my %agl;

sub decode_glyph {
	my $digits;
	return join '', map {
		exists $agl{ $_ }
			? $agl{ $_ }
			: ( ( $digits ) =            m/$uni_notation/ ) ? _utf8ify $digits =~ /(....)/g
			: ( ( $digits ) = reverse =~ m/$u_notation/   ) ? _utf8ify scalar reverse $digits
			: '';
	}
	map { split /_/ }
	map { /\A(.+?)\./ ? $1 : $_ }
	map { split } @_;
}

sub parse_adobeglyphlist {
	my ( $input_method, $data ) = @_;

	my %reader = (
		array => sub { $_[0] },
		data  => sub { [ split /^/m, shift ] },
		fh    => sub { [ <$_[0]> ] },
		file  => sub {
			open my $fh, '<', $_[0]
				or _croak( "Error opening $_[0]: $!" );
			[ <$fh> ];
		},
	);

	_croak( "No such input type '$input_method'" )
		unless exists $reader{ $input_method };

	my $lines = $reader{ $input_method }->( $data );

	@$lines = grep !/\A \s* (?: \# | \z)/x, @$lines;

	chomp @$lines;

	%agl = map {
		my ( $code_pt, $glyph ) = split /;/;
		( $glyph => _utf8ify $code_pt );
	} @$lines;

	delete $agl{ '.notdef' };

	return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PostScript::DecodeGlyphName - PostScript glyph name to Unicode conversion

=head1 SYNOPSIS

 use PostScript::GlyphToUnicode file => '/usr/doc/PostScript/aglfn13.txt';
 print PostScript::GlyphToUnicode::map('Euro'), "\n";

=head1 DESCRIPTION

This module implements (most of) the PostScript glyph name to Unicode codepoint
conversion algorithm as described by Adobe at
L<http://partners.adobe.com/asn/tech/type/unicodegn.jsp>.

To do something more than marginally useful with this module you will need to
download the S<Adobe Glyph List> from
L<http://partners.adobe.com/asn/tech/type/glyphlist.txt>.

=head1 INTERFACE

=head2 parse_adobeglyphlist

This function parses an S<Adobe Glyph List> file and returns true on success.
On failure, it returns false and supplies an error message in the package
variable C<$ERROR>. It expects its first argument to specify how to retrieve
the data. The following options exist:

=over 4

=item C<file>

Takes the name of a file containing the S<Adobe Glyph List>.

=item C<fh>

Takes a filehandle reference that should be open on a file containing the
S<Adobe Glyph List>.

=item C<array>

Takes an array reference. Each array element is expected to contain one line
from the S<Adobe Glyph List>.

=item C<data>

Takes a scalar that is expected to contain the entire S<Adobe Glyph List> file.

=back

For convenience, you can pass the same parameters to the module's C<import()>
function, as exemplified in L</"SYNOPSIS">. It will croak if it encounters any
errors.

=head2 C<decode_glyph>

This function takes a list of strings, each containing whitespace separated
PostScript glyphs, and returns them concatenated as a single character string.

(You may want to memoize this function when processing large PostScript
documents.)

=head1 LIMITATIONS

The C<decode_glyph> function does not take the font into account and therefore
will produce incorrect results for glyphs from the I<ZapfDingbats> font.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

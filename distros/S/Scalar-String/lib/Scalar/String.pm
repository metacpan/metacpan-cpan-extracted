=head1 NAME

Scalar::String - string aspects of scalars

=head1 SYNOPSIS

	use Scalar::String
		qw(sclstr_is_upgraded sclstr_is_downgraded);

	if(sclstr_is_upgraded($value)) { ...
	if(sclstr_is_downgraded($value)) { ...

	use Scalar::String qw(
		sclstr_upgrade_inplace sclstr_upgraded
		sclstr_downgrade_inplace sclstr_downgraded
	);

	sclstr_upgrade_inplace($value);
	$value = sclstr_upgraded($value);
	sclstr_downgrade_inplace($value);
	$value = sclstr_downgraded($value);

=head1 DESCRIPTION

This module is about the string part of plain Perl scalars.  A scalar has
a string value, which is notionally a sequence of Unicode codepoints, but
may be internally encoded in either ISO-8859-1 or UTF-8.  In places, and
more so in older versions of Perl, the internal encoding shows through.
To fully understand Perl strings it is necessary to understand these
implementation details.

This module provides functions to classify a string by encoding and to
encode a string in a desired way.

This module is implemented in XS, with a pure Perl backup version for
systems that can't handle XS.

=head1 STRING ENCODING

ISO-8859-1 is a simple 8-bit character encoding, which represents the
first 256 Unicode characters (codepoints 0x00 to 0xff) in one octet each.
This is how strings were historically represented in Perl.  A string
represented this way is referred to as "downgraded".

UTF-8 is a variable-width character encoding, which represents all
possible Unicode codepoints in differing numbers of octets.  A design
feature of UTF-8 is that ASCII characters (codepoints 0x00 to 0x7f)
are each represented in a single octet, identically to their ISO-8859-1
encoding.  Perl has its own variant of UTF-8, which can handle a wider
range of codepoints than Unicode formally allows.  A string represented
in this variant UTF-8 is referred to as "upgraded".

A Perl string is physically represented as a string of octets along with
a flag that says whether the string is downgraded or upgraded.  At this
level, to determine the Unicode codepoints that are represented requires
examining both parts of the representation.  If the string contains only
ASCII characters then the octet sequence is identical in either encoding,
but Perl still maintains an encoding flag on such a string.  A string
is always either downgraded or upgraded; it is never both or neither.

When handling string input, it is good form to operate only on the Unicode
characters represented by the string, ignoring the manner in which they
are encoded.  Basic string operations such as concatenation work this way
(except for a bug in perl 5.6.0), so simple code written in pure Perl is
generally safe on this front.  Pieces of character-based code can pass
around strings among themselves, and always get consistent behaviour,
without worrying about the way in which the characters are encoded.

However, due to an historical accident, a lot of C code that interfaces
with Perl looks at the octets used to represent a string without also
examining the encoding flag.  Such code gives inconsistent behaviour for
the same character sequence represented in the different ways.  In perl
5.6, many pure Perl operations (such as regular expression matching)
also work this way, though some of them can be induced to work correctly
by using the L<utf8> pragma.  In perl 5.8, regular expression matching
is character-based by default, but many I/O functions (such as C<open>)
are still octet-based.

Where code that operates on the octets of a string must be used by code
that operates on characters, the latter needs to pay attention to the
encoding of its strings.  Commonly, the octet-based code expects its
input to be represented in a particular encoding, in which case the
character-based code must oblige by forcing strings to that encoding
before they are passed in.  There are other usage patterns too.

You will be least confused if you think about a Perl string as a character
sequence plus an encoding flag.  You should normally operate on the
character sequence and not care about the encoding flag.  Occasionally you
must pay attention to the flag in addition to the characters.  Unless you
are writing C code, you should try not to think about a string the other
way round, as an octet sequence plus encoding flag.

=cut

package Scalar::String;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(
	sclstr_is_upgraded sclstr_is_downgraded
	sclstr_upgrade_inplace sclstr_upgraded
	sclstr_downgrade_inplace sclstr_downgraded
);

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
};

if($@ eq "") {
	close(DATA);
} else {
	(my $filename = __FILE__) =~ tr# -~##cd;
	local $/ = undef;
	my $pp_code = "#line 128 \"$filename\"\n".<DATA>;
	close(DATA);
	{
		local $SIG{__DIE__};
		eval $pp_code;
	}
	die $@ if $@ ne "";
}

1;

__DATA__

use Carp qw(croak);
BEGIN { require utf8 if "$]" >= 5.008; }

=head1 FUNCTIONS

Each "sclstr_" function takes one or more scalar string arguments to
operate on.  These arguments must be strings; giving non-string arguments
will cause mayhem.  See L<Params::Classify/is_string> for a way to
check for stringness.  Only the string value of the scalar is used;
the numeric value is completely ignored, so dualvars are not a problem.

=head2 Classification

=over

=item sclstr_is_upgraded(VALUE)

Returns a truth value indicating whether the provided string I<VALUE>
is in upgraded form.

=cut

sub sclstr_is_upgraded($);

if(defined &utf8::is_utf8) {
	*sclstr_is_upgraded = sub($) { &utf8::is_utf8 };
} else {
	*sclstr_is_upgraded = sub($) {
		# In perl 5.6, an upgraded string can be detected
		# (even if it contains no non-ASCII characters) by the
		# fact that concatenation with it will upgrade another
		# string.  If the probe string contains a non-ASCII
		# character, its upgrading can be consistently detected
		# by examining the resulting byte sequence.
		return unpack("C", "\xaa".$_[0]) != 170;
	};
}

=item sclstr_is_downgraded(VALUE)

Returns a truth value indicating whether the provided string I<VALUE>
is in downgraded form.

=cut

sub sclstr_is_downgraded($) { !&sclstr_is_upgraded }

=back

=head2 Regrading

=over

=item sclstr_upgrade_inplace(VALUE)

Modifies the string I<VALUE> in-place, so that it is in upgraded form,
regardless of how it was encoded before.  The character sequence that
it represents is unchanged.

A cleaner interface to this operation is the non-mutating
L</sclstr_upgraded>.

=cut

sub sclstr_upgrade_inplace($);

if("$]" >= 5.008) {
	*sclstr_upgrade_inplace = sub($) { &utf8::upgrade };
} else {
	# In perl 5.6, upgrade of a string can be forced by
	# concatenation with an upgraded string.
	chop(my $upgraded_empty_string = "\x{100}");
	*sclstr_upgrade_inplace = sub($) { $_[0] .= $upgraded_empty_string; };
}

=item sclstr_upgraded(VALUE)

Returns a string that represents the same character sequence as the string
I<VALUE>, and is in upgraded form (regardless of how I<VALUE> is encoded).

=cut

sub sclstr_upgraded($) {
	my($str) = @_;
	sclstr_upgrade_inplace($str);
	return $str;
}

=item sclstr_downgrade_inplace(VALUE[, FAIL_OK])

Modifies the string I<VALUE> in-place, so that it is in downgraded form,
regardless of how it was encoded before.  The character sequence that it
represents is unchanged.  If the string cannot be downgraded, because it
contains a non-ISO-8859-1 character, then by default the function C<die>s,
but if I<FAIL_OK> is present and true then it will return leaving I<VALUE>
unmodified.

A cleaner interface to this operation is the non-mutating
L</sclstr_downgraded>.

=cut

sub sclstr_downgrade_inplace($;$);

if("$]" >= 5.008) {
	*sclstr_downgrade_inplace = sub($;$) {
		utf8::downgrade($_[0], $_[1] || 0);
	};
} else {
	# In perl 5.6, there are very few operations that will
	# downgrade a string.  One of the few is regexp submatch
	# capturing, with the match operator in array context.
	# Note: retrieving the submatch with $1 will *not*
	# downgrade.
	*sclstr_downgrade_inplace = sub($;$) {
		return unless sclstr_is_upgraded($_[0]);
		my ($down) = do {
			use if "$]" < 5.008, "bytes";
			$_[0] =~ /\A[\x00-\x7f\x80-\xbf\xc2\xc3]*\z/;
		} ? do {
			use if "$]" < 5.008, "utf8";
			($_[0] =~ /\A([\x00-\xff]*)\z/);
		} : (undef);
		if(defined $down) {
			$_[0] = $down;
		} else {
			croak "Wide character prevents downgrading"
				unless $_[1];
		}
	};
}

=item sclstr_downgraded(VALUE[, FAIL_OK])

Returns a string that represents the same character sequence as the
string I<VALUE>, and is in downgraded form (regardless of how I<VALUE>
is encoded).  If the string cannot be represented in downgraded form,
because it contains a non-ISO-8859-1 character, then by default the
function C<die>s, but if I<FAIL_OK> is present and true then it will
return I<VALUE> in its original upgraded form.

=cut

sub sclstr_downgraded($;$) {
	my($str, $fail_ok) = @_;
	sclstr_downgrade_inplace($str, $fail_ok);
	return $str;
}

=back

=head1 SEE ALSO

L<utf8>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

package String::Dirify;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows the declaration	use String::Dirify ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	dirify
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.03';

# ------------------------------------------------

my(%high_ASCII_char) =
(
    "\xc0" => 'A',  # A`
    "\xe0" => 'a',  # a`
    "\xc1" => 'A',  # A'
    "\xe1" => 'a',  # a'
    "\xc2" => 'A',  # A^
    "\xe2" => 'a',  # a^
    "\xc4" => 'A',  # A:
    "\xe4" => 'a',  # a:
    "\xc5" => 'A',  # Aring
    "\xe5" => 'a',  # aring
    "\xc6" => 'AE', # AE
    "\xe6" => 'ae', # ae
    "\xc3" => 'A',  # A~
    "\xe3" => 'a',  # a~
    "\xc8" => 'E',  # E`
    "\xe8" => 'e',  # e`
    "\xc9" => 'E',  # E'
    "\xe9" => 'e',  # e'
    "\xca" => 'E',  # E^
    "\xea" => 'e',  # e^
    "\xcb" => 'E',  # E:
    "\xeb" => 'e',  # e:
    "\xcc" => 'I',  # I`
    "\xec" => 'i',  # i`
    "\xcd" => 'I',  # I'
    "\xed" => 'i',  # i'
    "\xce" => 'I',  # I^
    "\xee" => 'i',  # i^
    "\xcf" => 'I',  # I:
    "\xef" => 'i',  # i:
    "\xd2" => 'O',  # O`
    "\xf2" => 'o',  # o`
    "\xd3" => 'O',  # O'
    "\xf3" => 'o',  # o'
    "\xd4" => 'O',  # O^
    "\xf4" => 'o',  # o^
    "\xd6" => 'O',  # O:
    "\xf6" => 'o',  # o:
    "\xd5" => 'O',  # O~
    "\xf5" => 'o',  # o~
    "\xd8" => 'O',  # O/
    "\xf8" => 'o',  # o/
    "\xd9" => 'U',  # U`
    "\xf9" => 'u',  # u`
    "\xda" => 'U',  # U'
    "\xfa" => 'u',  # u'
    "\xdb" => 'U',  # U^
    "\xfb" => 'u',  # u^
    "\xdc" => 'U',  # U:
    "\xfc" => 'u',  # u:
    "\xc7" => 'C',  # ,C
    "\xe7" => 'c',  # ,c
    "\xd1" => 'N',  # N~
    "\xf1" => 'n',  # n~
    "\xdd" => 'Y',  # Yacute
    "\xfd" => 'y',  # yacute
    "\xdf" => 'ss', # szlig
    "\xff" => 'y'   # yuml
);

my($high_ASCII_re) = join '|', keys %high_ASCII_char;

# ------------------------------------------------

sub convert_high_ascii
{
	# require MT::I18N;
	# MT::I18N::convert_high_ascii(@_);

	my($self, $s) = @_;
	$s            =~ s/($high_ASCII_re)/$high_ASCII_char{$1}/g;

	return $s;

} # End of convert_high_ascii.

# ------------------------------------------------
# Re-use just the parts we need of Movable Type's 'dirify' function.
# The purpose is to take any string and make it a valid directory name.

sub dirify
{
	# ($MT::VERSION && MT->instance->{cfg}->PublishCharset =~ m/utf-?8/i)
	# ? utf8_dirify(@_) : iso_dirify(@_);

	my($self);

	if (ref $_[0]) # Handle calls like $o = String::Dirify -> new(); $d = $o -> dirify($s).
	{
		$self = shift;
	}
	elsif ($_[0] eq __PACKAGE__) # Handle calls like $d = String::Dirify -> dirify($s).
	{
		$self = new(shift @_);
	}
	else # Handle calls like $d = dirify($s).
	{
		$self = new(__PACKAGE__);
	}

	return $self -> iso_dirify(@_);

} # End of dirify.

# ------------------------------------------------

sub iso_dirify
{
	my($self, $s, $sep) = @_;

    return '' if (! defined $s);

    $sep = defined($sep) && ($sep ne '1') ? $sep : '_';
	$s   = $self -> convert_high_ascii($s); # Convert high-ASCII chars to 7-bit.
	$s   = $self -> remove_html(lc $s);     # Lower case, and remove HTML tags.
	$s   =~ s!&[^;\s]+;!!gs;                # Remove HTML entities.
	$s   =~ s![^\w\s-]!!gs;                 # Remove non-word/space chars.
	$s   =~ s!\s+!$sep!gs;                  # Change runs of spaces to the separator char.

	return $s;

} # End of iso_dirify.

# ------------------------------------------------

sub new
{
	my($class) = @_;

	return bless {}, $class;

} # End of new.

# ------------------------------------------------

sub remove_html
{
	my($self, $text) = @_;

	return $text if (! defined $text);          # Suppress warnings.
	return $text if $text =~ m/^<\!\[CDATA\[/i; # We need /i because lc() has been called.

	$text =~ s!<[^>]+>!!gs; # Remove all '<'s which have matching '>'s.
	$text =~ s!<!&lt;!gs;   # Make remaining '<'s into entities, for iso_dirify() to zap.

	return $text;

} # End of remove_html.

# ------------------------------------------------

1;

__END__

=head1 NAME

String::Dirify - Convert a string into a directory name

=head1 Synopsis

	use String::Dirify;

	my($dir_1) = String::Dirify -> dirify('frobnitz');

Or:

	use String::Dirify ':all';

	my($dir_2) = dirify('bar baz');

Or even:

	use String::Dirify;

	my($sd)    = String::Dirify -> new();
	my($dir_3) = $sd -> dirify('!Q@W#E$R%T^Y');

=head1 Description

C<String::Dirify> is a pure Perl module.

This module allows you to convert a string (possibly containing high ASCII characters,
and even HTML) into another, lower-cased, string which can be used as a directory name.

For usage, see the Synopsis.

This code is derived from similar code in Movable Type.

=head1 Method: dirify($string [, $separator])

Returns a string, which can be used as a directory name.

The default separator is '_'.

Each run of spaces in the string is replaced by this separator.

=head1 Algorithm

=over 4

=item 1: Each high ASCII character is replaced by its normal equivalent

=item 2: The string is converted to lower case

=item 3: Any HTML (including HTML entities) in the string is removed

=item 4: Any characters which are not (Perl) words, spaces or hyphens, are removed

=item 5: Runs of spaces are converted to the separator character

For more details about this character, see the discussion of the dirify() method (above).

=back

=head1 Melody 'v' Movable Type

See http://openmelody.org for details.

=head1 Backwards Compatibility with Movable Type

Unfortunately, the way Movable Type uses dirify() allows a fake separator - '1' - to be used for
the second parameter in the call to dirify().

The '1' triggered usage of '_' as the separator, rather than the '1' provided.

This 'feature' has been preserved in C<String::Dirify>, but is discouraged. Instead, simply drop
the second parameter and let the code default to '_'.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

=head1 REPOSITORY

L<https://github.com/ronsavage/String-Dirify>

=head1 Authors

C<String::Dirify> started out as part of the Movable Type code.

Then, Mark Stosberg cut down the original code to provide just the English/ISO/ASCII features.

Lastly, the code was cleaned up, tests added, and all packaged, by
Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Homepage: http://savage.net.au/index.html

=head1 Copyright

Copyright (c) 2009, Mark Stosberg, Ron Savage.

Copyright (c) 2010, 2011, Ron Savage.

=cut

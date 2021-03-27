package String::Util;

use strict;
use warnings;
use Carp;
use 5.014;

# version
our $VERSION = '1.32';


#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

String::Util -- String processing utility functions

=head1 DESCRIPTION

String::Util provides a collection of small, handy functions for processing
strings in various ways.

=head1 INSTALLATION

  cpanm String::Util

=head1 USAGE

No functions are exported by default, they must be specified:

  use String::Util qw(trim eqq contains)

alternately you can use C<:all> to export B<all> of the functions

  use String::Util qw(:all)

=head1 FUNCTIONS

=cut

#
# opening POD
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# export
#
use base 'Exporter';
use vars qw[@EXPORT_OK %EXPORT_TAGS];

# the following functions accept a value and return a modified version of
# that value
push @EXPORT_OK, qw[
	collapse     crunch     htmlesc    trim      ltrim
	rtrim        define     repeat     unquote   no_space
	nospace      fullchomp  randcrypt  jsquote   cellfill
	crunchlines  file_get_contents
];

# the following functions return true or false based on their input
push @EXPORT_OK, qw[
	hascontent  nocontent eqq equndef neqq neundef
	startswith  endswith  contains    sanitize
];

# the following function returns a random string of some type
push @EXPORT_OK, qw[ randword ];

# the following function returns the unicode values of a string
push @EXPORT_OK, qw[ ords deords ];

%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# export
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# collapse
#

=head2 collapse($string)

C<collapse()> collapses all whitespace in the string down to single spaces.
Also removes all leading and trailing whitespace.  Undefined input results in
undefined output.

B<Note:> C<crunch()> is an alias to this function. It is considered deprecated.
It may be removed in future versions.

  $var = collapse("  Hello     world!    "); # "Hello world!"

=cut

sub collapse {
	my ($val) = @_;

	if (defined $val) {
		$val =~ s|^\s+||s;
		$val =~ s|\s+$||s;
		$val =~ s|\s+| |sg;
	}

	return $val;
}

sub crunch {
	return collapse(@_);
}
#
# collapse
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# hascontent
#

=head2 hascontent($scalar), nocontent($scalar)

hascontent() returns true if the given argument is defined and contains
something besides whitespace.

An undefined value returns false.  An empty string returns false.  A value
containing nothing but whitespace (spaces, tabs, carriage returns, newlines,
backspace) returns false.  A string containing any other characters (including
zero) returns true.

C<nocontent()> returns the negation of C<hascontent()>.

  $var = hascontent("");  # False
  $var = hascontent(" "); # False
  $var = hascontent("a"); # True

  $var = nocontent("");   # True
  $var = nocontent("a");  # False

=cut

sub hascontent {
	my $val = shift();

	if (!defined($val)) {
		return 0;
	}

	# If there are ANY non-space characters in it
	if ($val =~ m|\S|s) {
		return 1;
	}

	return 0;
}

sub nocontent {
	my $str = shift();

	# nocontent() is just the inverse to hascontent()
	my $ret = !(hascontent($str));

	return $ret;
}

#
# hascontent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# trim
#

=head2 trim($string), ltrim($string), rtrim($string)

Returns the string with all leading and trailing whitespace removed.
Trim on undef returns "".

  $var = trim(" my string  "); # "my string"

ltrim() trims B<leading> whitespace only.

rtrim() trims B<trailing> whitespace only.

=cut

sub trim {
	my $s = shift();

	if (!defined($s)) {
		return undef;
	}

	$s =~ s/^\s*//u;
	$s =~ s/\s*$//u;

	return $s;
}
#
# trim
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ltrim, rtrim
#

sub ltrim {
	my $s = shift();

	if (!defined($s)) {
		return undef;
	}

	$s =~ s/^\s*//u;

	return $s;
}

sub rtrim {
	my $s = shift();

	if (!defined($s)) {
		return undef;
	}

	$s =~ s/\s*$//u;

	return $s;
}

#
# ltrim, rtrim
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# no_space
#

=head2 nospace($string)

Removes B<all> whitespace characters from the given string. This includes spaces
between words.

  $var = nospace("  Hello World!   "); # "HelloWorld!"

=cut

sub no_space {
	return nospace(@_);
}

# alias nospace to no_space
sub nospace {
	my $val = shift();

	if (defined $val) {
		$val =~ s|\s+||gs;
	}

	return $val;
}

#
# no_space
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# htmlesc
#

=head2 htmlesc($string)

Formats a string for literal output in HTML.  An undefined value is returned as
an empty string.

htmlesc() is very similar to CGI.pm's escapeHTML.  However, there are a few
differences. htmlesc() changes an undefined value to an empty string, whereas
escapeHTML() returns undefs as undefs.

=cut

sub htmlesc {
	my ($val) = @_;

	if (defined $val) {
		$val =~ s|\&|&amp;|g;
		$val =~ s|\"|&quot;|g;
		$val =~ s|\<|&lt;|g;
		$val =~ s|\>|&gt;|g;
	} else {
		$val = '';
	}

	return $val;
}
#
# htmlesc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# cellfill
#

sub cellfill{
	my ($val) = @_;

	carp("cellfill() is deprecated and will be removed in future versions");

	if (hascontent($val)) {
		$val = htmlesc($val);
	} else {
		$val = '&nbsp;';
	}

	return $val;
}
#
# cellfill
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# jsquote
#

=head2 jsquote($string)

Escapes and quotes a string for use in JavaScript.  Escapes single quotes and
surrounds the string in single quotes.  Returns the modified string.

=cut

sub jsquote {
	my ($str) = @_;

	if (!defined($str)) {
		return undef;
	}

	# Escape single quotes.
	$str =~ s|'|\\'|gs;

	# Break up anything that looks like a closing HTML tag.  This modification
	# is necessary in an HTML web page.  It is unnecessary but harmless if the
	# output is used in a JavaScript document.
	$str =~ s|</|<' + '/|gs;

	# break up newlines
	$str =~ s|\n|\\n|gs;

	# surround in quotes
	$str = qq|'$str'|;

	# return
	return $str;
}
#
# jsquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unquote
#

=head2 unquote($string)

If the given string starts and ends with quotes, removes them. Recognizes
single quotes and double quotes.  The value must begin and end with same type
of quotes or nothing is done to the value. Undef input results in undef output.
Some examples and what they return:

  unquote(q|'Hendrix'|);   # Hendrix
  unquote(q|"Hendrix"|);   # Hendrix
  unquote(q|Hendrix|);     # Hendrix
  unquote(q|"Hendrix'|);   # "Hendrix'
  unquote(q|O'Sullivan|);  # O'Sullivan

B<option:> braces

If the braces option is true, surrounding braces such as [] and {} are also
removed. Some examples:

  unquote(q|[Janis]|, braces=>1);  # Janis
  unquote(q|{Janis}|, braces=>1);  # Janis
  unquote(q|(Janis)|, braces=>1);  # Janis

=cut

sub unquote {
	my ($val, %opts) = @_;

	if (defined $val) {
		my $found = $val =~ s|^\`(.*)\`$|$1|s or
			$val =~ s|^\"(.*)\"$|$1|s or
			$val =~ s|^\'(.*)\'$|$1|s;

		if ($opts{'braces'} && ! $found) {
			$val =~ s|^\[(.*)\]$|$1|s or
			$val =~ s|^\((.*)\)$|$1|s or
			$val =~ s|^\{(.*)\}$|$1|s;
		}
	}

	return $val;
}
#
# unquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# define
#

sub define {
	carp("define() is deprecated and may be removed in future version");

	my ($val) = @_;

	# if overloaded object, get return value and
	# concatenate with string (which defines it).
	if (ref($val) && overload::Overloaded($val)) {
		local $^W = 0;
		$val = $val . '';
	}

	defined($val) or $val = '';
	return $val;
}
#
# define
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# repeat
#

=head2 repeat($string, $count)

Returns the given string repeated the given number of times. The following
command outputs "Fred" three times:

  print repeat('Fred', 3), "\n";

Note that repeat() was created a long time based on a misunderstanding of how
the perl operator 'x' works.  The following command using 'x' would perform
exactly the same as the above command.

  print 'Fred' x 3, "\n";

Use whichever you prefer.

=cut

sub repeat {
	my ($val, $count) = @_;
	return ($val x int($count));
}
#
# repeat
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# randword
#

=head2 randword($length, %options)

Returns a random string of characters. String will not contain any vowels (to
avoid distracting dirty words). First argument is the length of the return
string. So this code:

  foreach my $idx (1..3) {
      print randword(4), "\n";
  }

would output something like this:

  kBGV
  NCWB
  3tHJ

If the string 'dictionary' is sent instead of an integer, then a word is
randomly selected from a dictionary file.  By default, the dictionary file
is assumed to be at /usr/share/dict/words and the shuf command is used to
pull out a word.  The hash %String::Util::PATHS sets the paths to the
dictionary file and the shuf executable.  Modify that hash to change the paths.
So this code:

  foreach my $idx (1..3) {
      print randword('dictionary'), "\n";
  }

would output something like this:

  mustache
  fronds
  browning

B<option:> alpha

If the alpha option is true, only alphabetic characters are returned, no
numerals. For example, this code:

  foreach my $idx (1..3) {
      print randword(4, alpha=>1), "\n";
  }

would output something like this:

  qrML
  wmWf
  QGvF

B<option:> numerals

If the numerals option is true, only numerals are returned, no alphabetic
characters. So this code:

  foreach my $idx (1..3) {
      print randword(4, numerals=>1), "\n";
  }

would output something like this:

  3981
  4734
  2657

B<option:> strip_vowels

This option is true by default.  If true, vowels are not included in the
returned random string. So this code:

  foreach my $idx (1..3) {
      print randword(4, strip_vowels=>1), "\n";
  }

would output something like this:

  Sk3v
  pV5z
  XhSX

=cut

# path information for WC
our %PATHS = (
	wc    => '/usr/bin/wc',
	shuf  => '/usr/bin/shuf',
	words => '/usr/share/dict/words',
	head  => '/usr/bin/head',
	tail  => '/usr/bin/tail',
);

sub randword {
	my ($count, %opts) = @_;
	my ($rv, $char, @chars, $paths);
	$rv = '';

	# check syntax
	defined($count) or croak 'syntax: randword($count)';

	# dictionary word
	if ($count =~ m|^dict|si) {
		# loop until acceptable word is found
		DICTIONARY:
		while (1) {
			my ($cmd, $line_count, $line_num, $word);

			# use Encode module
			require Encode;

			# get line count
			$cmd = qq|$PATHS{'wc'} -l "$PATHS{'words'}"|;
			($line_count) = `$cmd`;
			$line_count =~ s|\s.*||s;

			# get random line
			$line_num = rand($line_count);

			# untaint line number
			unless ($line_num =~ m|^([0-9]+)$|s) { die "invalid line number: $line_num" }
			$line_num = $1;

			# get random word
			$cmd = qq[$PATHS{'head'} -$line_num "$PATHS{'words'}" | $PATHS{'tail'} -1];
			($word) = `$cmd`;
			$word =~ s|\s.*||si;
			$word =~ s|'.*||si;
			$word = lc($word);

			# only allow words that are all letters
			if ($opts{'letters_only'}) {
				unless ($word =~ m|^[a-z]+$|s)
					{ next DICTIONARY }
			}

			# check for max length
			if ($opts{'maxlength'}) {
				if ( length($word) > $opts{'maxlength'} )
					{ next DICTIONARY }
			}

			# encode unless specifically opted not to do so
			unless ( defined($opts{'encode'}) && (! $opts{'encode'}) )
				{ $word = Encode::encode_utf8($word) }

			# return
			return $word;
		}
	}

	# alpha only
	if ($opts{'alpha'})
		{ @chars = ('a' .. 'z', 'A' .. 'Z') }

	# else alpha and numeral
	else
		{ @chars = ('a' .. 'z', 'A' .. 'Z', '0' .. '9') }

	# defaults
	defined($opts{'strip_vowels'}) or $opts{'strip_vowels'} = 1;

	while (length($rv) < $count) {
		$char = rand();

		# numerals only
		if ($opts{'numerals'}) {
			$char =~ s|^0.||;
			$char =~ s|\D||g;
		}

		# character random word
		else {
			$char = int( $char * ($#chars + 1) );
			$char = $chars[$char];
			next if($opts{'strip_vowels'} && $char =~ m/[aeiouy]/i);
		}

		$rv .= $char;
	}

	return substr($rv, 0, $count);
}
#
# randword
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# eqq
# formerly equndef
#

=head2 eqq($scalar1, $scalar2)

Returns true if the two given values are equal.  Also returns true if both
are undef.  If only one is undef, or if they are both defined but different,
returns false. Here are some examples and what they return.

  $var = eqq('x', 'x');     # True
  $var = eqq('x', undef);   # False
  $var = eqq(undef, undef); # True

B<Note:> equndef() is an alias to this function. It is considered deprecated.
It may be removed in future versions.

=cut

# alias equndef to eqq
sub equndef { return eqq(@_) }

sub eqq {
	my ($str1, $str2) = @_;

	# if both defined
	if ( defined($str1) && defined($str2) ) {
		return $str1 eq $str2
	}

	# if neither are defined
	if ( (!defined($str1)) && (!defined($str2)) ) {
		return 1
	}

	# only one is defined, so return false
	return 0;
}
#
# eqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# neqq
# formerly neundef
#

=head2 neqq($scalar1, $scalar2)

The opposite of neqq, returns true if the two values are *not* the same.
Here are some examples and what they return.

  $var = neqq('x', 'x');     # False
  $var = neqq('x', undef);   # True
  $var = neqq(undef, undef); # False

B<Note:> neundef() is an alias to this function. It is considered deprecated.
It may be removed in future versions.

=cut

sub neundef {
	return eqq(@_) ? 0 : 1;
}

sub neqq {
	return eqq(@_) ? 0 : 1;
}
#
# neqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# fullchomp
#

sub fullchomp {
	carp("fullchomp() is deprecated and may be removed in future versions");

	my ($line) = @_;
	defined($line) and $line =~ s|[\r\n]+$||s;
	defined(wantarray) and return $line;
	$_[0] = $line;
}
#
# fullchomp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# randcrypt
#

sub randcrypt {
	carp("randcrypt() is deprecated and may be removed in future versions");

	my $pw = shift();
	my $ret;
	$ret = crypt($pw, randword(2));

	return $ret;
}
#
# randcrypt
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ords
#

=head2 ords($string)

Returns the given string represented as the ascii value of each character.

  $var = ords('Hendrix'); # {72}{101}{110}{100}{114}{105}{120}

B<options>

=over 4

=item * convert_spaces=>[true|false]

If convert_spaces is true (which is the default) then spaces are converted to
their matching ord values. So, for example, this code:

  $var = ords('a b', convert_spaces=>1); # {97}{32}{98}

This code returns the same thing:

  $var = ords('a b');                    # {97}{32}{98}

If convert_spaces is false, then spaces are just returned as spaces. So this
code:

  ords('a b', convert_spaces=>0);        # {97} {98}


=item * alpha_nums

If the alpha_nums option is false, then characters 0-9, a-z, and A-Z are not
converted. For example, this code:

  $var = ords('a=b', alpha_nums=>0); # a{61}b

=back

=cut

sub ords {
	my ($str, %opts) = @_;
	my (@rv, $show_chars);

	# default options
	%opts = (convert_spaces=>1, alpha_nums=>1, %opts);

	# get $show_chars option
	$show_chars = $opts{'show_chars'};

	# split into individual characters
	@rv = split '', $str;

	# change elements to their unicode numbers
	CHAR_LOOP:
	foreach my $char (@rv) {
		# don't convert space if called so
		if ( (! $opts{'convert_spaces'}) && ($char =~ m|^\s$|s) )
			{ next CHAR_LOOP }

		# don't convert alphanums
		if (! $opts{'alpha_nums'}) {
			if ( $char =~ m|^[a-z0-9]$|si) {
				next CHAR_LOOP;
			}
		}

		my $rv = '{';

		if ($show_chars)
			{ $rv .= $char . ':' }

		$rv .= ord($char) . '}';

		$char = $rv;
	}

	# return words separated by spaces
	return join('', @rv);
}
#
# ords
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# deords
#

=head2 deords($string)

Takes the output from ords() and returns the string that original created that
output.

  $var = deords('{72}{101}{110}{100}{114}{105}{120}'); # 'Hendrix'

=cut

sub deords {
	my ($str) = @_;
	my (@tokens, $rv);
	$rv = '';

	# get tokens
	@tokens = split(m|[\{\}]|s, $str);
	@tokens = grep {length($_)} @tokens;

	# build return string
	foreach my $token (@tokens) {
		$rv .= chr($token);
	}

	# return
	return $rv;
}
#
# deords
#------------------------------------------------------------------------------

=head2 contains($string, $substring)

Checks if the string contains substring

  $var = contains("Hello world", "Hello");   # true
  $var = contains("Hello world", "llo wor"); # true
  $var = contains("Hello world", "QQQ");     # false

  # Also works with grep
  @arr = grep { contains("cat") } @input;

=cut

sub contains {
	my ($str, $substr) = @_;

	if (!defined($str)) {
		return undef;
	}

	if (!$substr) {
		$substr = $str;
		$str    = $_;
	}

	my $ret = index($str, $substr, 0) != -1;

	return $ret;
}

=head2 startswith($string, $substring)

Checks if the string starts with the characters in substring

  $var = startwith("Hello world", "Hello"); # true
  $var = startwith("Hello world", "H");     # true
  $var = startwith("Hello world", "Q");     # false

  # Also works with grep
  @arr = grep { startswith("X") } @input;

=cut

sub startswith {
	my ($str, $substr) = @_;

	if (!defined($str)) {
		return undef;
	}

	if (!$substr) {
		$substr = $str;
		$str    = $_;
	}

	my $ret = index($str, $substr, 0) == 0;

	return $ret;
}

=head2 endswith($string, $substring)

Checks if the string ends with the characters in substring

  $var = endswith("Hello world", "world");   # true
  $var = endswith("Hello world", "d");       # true
  $var = endswith("Hello world", "QQQ");     # false

  # Also works with grep
  @arr = grep { endswith("z") } @input;

=cut

sub endswith {
	my ($str, $substr) = @_;

	if (!defined($str)) {
		return undef;
	}

	if (!$substr) {
		$substr = $str;
		$str    = $_;
	}

	my $len   = length($substr);
	my $start = length($str) - $len;

	my $ret = index($str, $substr, $start) != -1;

	return $ret;
}

#------------------------------------------------------------------------------
# crunchlines
#

=head2 crunchlines($string)

Compacts contiguous newlines into single newlines.  Whitespace between newlines
is ignored, so that two newlines separated by whitespace is compacted down to a
single newline.

  $var = crunchlines("x\n\n\nx"); # "x\nx";

=cut

sub crunchlines {
	my ($str) = @_;

	if (!defined($str)) {
		return undef;
	}

	while($str =~ s|\n[ \t]*\n|\n|gs)
		{}

	$str =~ s|^\n||s;
	$str =~ s|\n$||s;

	return $str;
}
#
# crunchlines
#------------------------------------------------------------------------------

=head2 sanitize($string, $separator = "_")

Sanitize all non alpha-numeric characters in a string to underscores.
This is useful to take a URL, or filename, or text description and know
you can use it safely in a URL or a filename.

B<Note:> This will remove any trailing or leading '_' on the string

  $var = sanitize("http://www.google.com/") # http_www_google_com
  $var = sanitize("foo_bar()";              # foo_bar
  $var = sanitize("/path/to/file.txt");     # path_to_file_txt
  $var = sanitize("Big yellow bird!", "."); # Big.yellow.bird

=cut

sub sanitize {
    my $str = shift();
    my $sep = shift() // "_";

    if (!defined($str)) {
        return undef;
    }

    # Convert multiple non-word sequences to the separator
    $str =~ s/[\W_]+/$sep/g;

    # The separator is a literal character so we quotemeta it
    $sep = quotemeta($sep);
    # Remove any separators at the beginning and end
    $str =~ s/\A$sep+//;
    $str =~ s/$sep+\z//;

    return $str;
}

###########################################################################

=head2 file_get_contents($string, $boolean)

Read an entire file from disk into a string. Returns undef if the file
cannot be read for any reason. Can also return the file as an array of
lines.

  $str   = file_get_contents("/tmp/file.txt");    # Return a string
  @lines = file_get_contents("/tmp/file.txt", 1); # Return an array

=cut

sub file_get_contents {
	my ($file, $ret_array) = @_;

	open (my $fh, "<", $file) or return undef;

	my $ret;
	while (<$fh>) {
		$ret .= $_;
	}

	if ($ret_array) {
		return split(/\r?\n/,$ret);
	}

	return $ret;
}

# return true
1;


__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan <miko@idocs.com>

Scott Baker <scott@perturb.org>

=cut



#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN builder. Please leave it as it is.
#
{
	// include in CPAN distribution
	include : 1,

	// test scripts
	test_scripts : {
		'Util/tests/test.pl' : 1,
	},
}
#
# module info
#------------------------------------------------------------------------------

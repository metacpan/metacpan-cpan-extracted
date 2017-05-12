package Regexp::English;

use strict;
use warnings;

use Exporter 'import';
use vars qw( @export @EXPORT_OK %EXPORT_TAGS $VERSION );

$VERSION = '1.01';

use overload '""' => \&compile;
use Scalar::Util 'blessed';

# REGEX: storage for the raw regex
# STORE: storage for bound references (see remember())
# STACK: used to nest groupings
use constant REGEX => 0;
use constant STORE => 1;
use constant STACK => 2;

# the key is the name of the method to create
# 	symbol is the regex token this represents
#	plural is the name of the shortcut method for $symbol+, i.e. \w+
#	non is the name of the negated token, its shortcut, and a plural, if needed
my %chars = (
	word_char =>
	{
		symbol => '\w',
		plural => 'word_chars',
		non    => [ 'non_word_char', '\W', 'non_word_chars' ],
	},
	whitespace_char =>
	{
		symbol => '\s',
		plural => 'whitespace_chars',
		non    => [ 'non_whitespace_char', '\S', 'non_whitespace_chars' ],
	},
	digit =>
	{
		symbol => '\d',
		plural => 'digits',
		non    => [ 'non_digit', '\D', 'non_digits' ],
	},
	word_boundary =>
	{
		symbol => '\b',
		non    => [ 'non_word_boundary', '\B' ],
	},
	end_of_string =>
	{
		symbol => '\Z',
		non    => [ 'very_end_of_string', '\z' ],
	},
	beginning_of_string   => { symbol => '\A', },
	end_of_previous_match => { symbol => '\G', },

	# XXX: non for these ?
	tab =>
	{
		symbol => '\t',
		plural => 'tabs',
		non    => [ 'non_tab', '[^\t]' ],
	},

	# implies /s modifier
	newline =>
	{
		symbol => '\n',
		plural => 'newlines',
		non    => [ 'non_newline', '(?s)[^\n]' ],
	},

	carriage_return =>
	{
		symbol => '\r',
		plural => 'carriage_returns',
		non    => [ 'non_carriage_return', '[^\r]' ],
	},

	form_feed =>
	{
		symbol => '\f',
		plural => 'form_feeds',
		non    => [ 'non_form_feed', '[^\f]' ],
	},

	'alarm' =>
	{
		symbol => '\a',
		plural => 'alarms',
		non    => [ 'non_alarm', '[^\a]' ],
	},
	escape =>
	{
		symbol => '\e',
		plural => 'escapes',
		non    => [ 'non_escape', '[^\e]' ],
	},
	start_of_line => { symbol => '^', },
	end_of_line   => { symbol => '$', },
);

sub _chars
{
	my $symbol = shift;

	return sub
	{
		# cannot use $_[0] here, as it trips the overload
		# that can mess with remember/end groups
		return $symbol unless @_;

		my $self = shift;
		$self    = $self->new() unless blessed( $self );

		$self->[REGEX] .= $symbol;
		return $self;
	};
}

my @char_tags;

for my $char ( keys %chars )
{
	push @char_tags, $char;
	_install( $char, _chars( $chars{$char}{symbol} ) );

	if ( $chars{$char}{plural} )
	{
		_install( $chars{$char}{plural}, _chars( $chars{$char}{symbol} . '+' ));
		push @char_tags, $chars{$char}{plural};
	}

	if ( $chars{$char}{non} )
	{
		my ( $nonname, $symbol, $pluralname ) = @{ $chars{$char}{non} };
		_install( $nonname, _chars($symbol) );
		push @char_tags, $nonname;
		if ($pluralname)
		{
			_install( $pluralname, _chars( $symbol . '+' ) );
			push @char_tags, $pluralname;
		}
	}
}

# tested in t/quantifiers
# XXX:
#	the syntax for minimal/optional is slightly awkward
my %quantifiers =
(
	zero_or_more => '*',
	multiple     => '+',
	minimal      => '?',
	optional     => '?',
);

for my $quantifier ( keys %quantifiers )
{
	_install( $quantifier,
		_standard( '(?:', '', $quantifiers{$quantifier} . ')' ), 1 );
}

# tested in t/groupings
my %groupings =
(
	after           => '(?<=',
	group           => '(?:',
	comment         => '(?#',
	not_after       => '(?<!',
	followed_by     => '(?=',
	not_followed_by => '(?!',
);

for my $group ( keys %groupings )
{
	_install( $group, _standard( $groupings{$group}, '', '' ), 1 );
}

sub _standard
{
	my ( $group, $sep, $symbol ) = @_;

	$symbol ||= ')';

	return sub
	{
		if ( eval { $_[0]->isa( 'Regexp::English' ) } )
		{
			my $self        = shift;
			$self->[REGEX] .= $group;

			if (@_)
			{
				$self->[REGEX] .= join( "$sep", @_ ) . $symbol;
			}
			else
			{
				push @{ $self->[STACK] }, $symbol;
			}
			return $self;
		}
		return $group . join( $sep, @_ ) . $symbol;
	};
}

# can't be used with standard because of quotemeta()
sub literal
{
	my $self        = shift;
	$self->[REGEX] .= quotemeta( +shift );
	return $self;
}

sub _install
{
	my ( $name, $sub, $export ) = @_;
	no strict 'refs';
	*{$name} = $sub;
	push @export,    "&$name" if $export;
	push @EXPORT_OK, "&$name";
}

_install(
	'or',
	sub {
		if ( eval { $_[0]->isa( 'Regexp::English' ) } )
		{
			my $self = shift;
			if (@_)
			{
				$self->[REGEX] .= '(?:' . join( '|', @_ ) . ')';
			}
			else
			{
				$self->[REGEX] .= '|';
			}
			return $self;
		}
		return '(?:' . join( '|', @_ ) . ')';
	},
	1
);

_install( 'class', _standard( '[', '', ']' ), 1 );

# XXX - not()

sub remember
{
	my $self = shift;
	$self    = $self->new() unless blessed( $self );

	# the first element may be a reference, so stick it in STORE
	if ( ref( $_[0] ) eq 'SCALAR' )
	{
		push @{ $self->[STORE] }, shift;
	}

	# if there are other arguments, add them to REGEX
	if (@_)
	{
		$self->[REGEX] .= '(' . join( '', @_ ) . ')';

		# otherwise, this is the opening op of a multi-call remember block
		# XXX: might store calling line for verbose debugging
	}
	else
	{
		$self->[REGEX] .= '(';
		push @{ $self->[STACK] }, ')';
	}

	return $self;
}

sub end
{
	my ( $self, $levels ) = @_;
	$levels               = 1 unless defined $levels;

	unless ( @{ $self->[STACK] } )
	{
		require Carp;
		Carp::confess( 'end() called without remember()' );
	}

	$self->[REGEX] .= pop @{ $self->[STACK] } for 1 .. $levels;

	return $self;
}

sub new
{
	bless( [ '', [], [] ], $_[0] );
}

sub match
{
	my $self       = shift;
	$self->[REGEX] = $self->compile();

	if ( @{ $self->[STORE] } )
	{
		return $self->capture( $_[0] =~ $self->[REGEX] );
	}
	else
	{
		if ( wantarray() )
		{
			return $_[0] =~ $self->[REGEX];
		}
		else
		{
			return ( $_[0] =~ $self->[REGEX] )[0];
		}
	}
}

sub capture
{
	my $self = shift;

	for my $ref ( @{ $self->[STORE] } )
	{
		$$ref = shift @_;
	}
	if ( wantarray() )
	{
		return map { $$_ } @{ $self->[STORE] };
	}
	else
	{
		return ${ ${ $self->[STORE] }[0] };
	}
}

sub compile
{
	my $self = shift;

	if ( my $num = @{ $self->[STACK] } )
	{
		$self->end($num);
	}
	return qr/$self->[REGEX]/;
}

sub debug
{
	my $self = shift;
	return $self->[REGEX];
}

%EXPORT_TAGS =
(
	all      => [ @char_tags, @export ],
	chars    => \@char_tags,
	standard => \@export,
);

1;

__END__

=head1 NAME

Regexp::English - Perl module to create regular expressions more verbosely

=head1 SYNOPSIS

	use Regexp::English;

	my $re = Regexp::English
		-> start_of_line
		-> literal('Flippers')
		-> literal(':')
		-> optional
			-> whitespace_char
		-> end
		-> remember
			-> multiple
				-> digit;

	while (<INPUT>) {
		if (my $match = $re->match($_)) {
			print "$match\n";
		}
	}

=head1 DESCRIPTION

Regexp::English provides an alternate regular expression syntax, one that is
slightly more verbose than the standard mechanisms.  In addition, it adds a few
convenient features, like incremental expression building and bound captures.

You can access almost every regular expression available in Regexp::English can
through a method, though some are also (or only) available as functions.  These
methods fall into several categories: characters, quantifiers, groupings, and
miscellaneous.  The division wouldn't be so rough if the latter had a better
name.

All methods return the Regexp::English object, so you can chain method calls as
in the example above.  Though there is a C<new()> method, you can use any
character method, or C<remember()>, to create an object.

To perform a match, use the C<match()> method.  Alternately, if you use a
Regexp::English object as if it were a compiled regular expression, the module
will automatically compile it behind the scenes.

=head2 Characters

Character methods correspond to standard regular expression characters and
metacharacters, for the most part.  As a little bit of syntactic sugar, most of
these methods have plurals, negations, and negated plurals.  This is more clear
looking at them.  Though the point of these is to be available as calls on a
new Regexp::English object while building up larger regular expressions, you
may also used them as class methods to access regular expression atoms which
you then use in larger regular expressions.  This isn't entirely pretty, but it
ought to work just about everywhere.

=over 4

=item * C<literal( $string )>

Matches the provided literal string.  This method passes C<$string> through
C<quotemeta()> automatically.  If you receive strange results, it's probably
because of this.

=item * C<class( @characters )>

Creates and matches a character class of the provided C<@characters>.  Note
that there is currently no validation of the character class, so you can create
an uncompilable regular expression if you're not careful.

=item * C<word_char()>

Matches any word character, respecting the current locale.  By default, this
matches alphanumerics and the underscore, corresponding to the C<\w> token.

=item * C<word_chars()>

Matches at least one word character.

=item * C<non_word_char()>

Matches any non-word character.

=item * C<non_word_chars()>

Matches at least one non-word character.

=item * C<whitespace_char()>

Matches any whitespace character, corresponding to the C<\s> token.

=item * C<whitespace_chars()>

Matches at least one whitespace characters.

=item * C<non_whitespace_char()>

Matches a single non-whitespace character.

=item * C<non_whitespace_chars()>

Matches at least one non-whitespace characters.

=item * C<digit()>

Matches any numeric digit, corresponding to the C<\d> token.

=item * C<digits()>

Matches at least one numeric digits.

=item * C<non_digit()>

Matches a character that is not a digit.

=item * C<non_digits()>

Matches at least one non-digit characters.

=item * C<tab()>

Matches a tab character (C<\t>)

=item * C<tabs()>

Matches at least one tab characters.

=item * C<non_tab()>

Matches any character that is not a tab.

=item * C<newline()>

Matches a newline character (C<\n>).  This implies the C</s> modifier.

=item * C<newlines()>

Matches at least one newline characters.  This also implies the C</s> modifier.

=item * C<non_newline()>

Matches any character that is not a newline.

=item * C<carriage_return()>

Matches a carriage return character (C<\r>).

=item * C<carriage_returns()>

Matches at least one carriage return characters.

=item * C<non_carriage_return()>

Matches any character that is not a carriage return.

=item * C<form_feed()>

Matches a form feed character (C<\f>).

=item * C<form_feeds()>

Matches at least one form feed characters.

=item * C<non_form_feed()>

Matches any character that is not a form feed character.

=item * C<alarm()>

Matches an alarm character (C<\a>).

=item * C<alarms()>

Matches more than one alarm character.

=item * C<non_alarm()>

Matches anything but an alarm character.

=item * C<escape()>

Matches an escape character (C<\e>).

=item * C<escapes()>

Matches at least one escape characters.

=item * C<non_escape()>

Matches a single non-escape character.

=item * C<start_of_line()>

Matches the start of a line, just like the C<^> anchor.

=item * C<beginning_of_string()>

Matches the beginning of a string, much like the C<^> anchor.

=item * C<end_of_line()>

Matches the end of a line, just like the C<$> anchor.

=item * C<end_of_string()>

Matches the end of a string, much like the C<$> anchor, treating newlines
appropriately depending on the C</s> or C</m> modifier.

=item * C<very_end_of_string()>

Matches the very end of a string, just as the C<\z> token.  This does not
ignore a trailing newline (if it exists).

=item * C<end_of_previous_match()>

Matches the point at which a previous match ended, in a C<\g>lobally-matched
regular expression.  This corresponds to the C<\G> token and relates to
C<pos()>.

=item * C<word_boundary()>

Matches the zero-width boundary between a word character and a non-word
character, corresponding to the C<\b> token.

=item * C<non_word_boundary()>

Matches anything that is not a word boundary.

=back

=head2 Quantifiers

Quantifiers provide a mechanism to specify how many items to expect, in general
or specific terms.  You may have these exported into the calling package's
namespace with the C<:standard> argument to the C<use()> call, but the
preferred interface is to use them as method calls.  This is slightly more
complicated, but cleaner conceptually.  The interface may change slightly in
the future, if someone comes up with something even better.

By default, quantifiers operate on the I<next> arguments, not the previous
ones.  (It is much easier to program this way.)  For example, to match multiple
digits, you might write:

	my $re = Regexp::English->new()
		->multiple()
			->digits();

The indentation should make this more clear.

Quantifiers persist until something attempts a match or something calls the
corresponding C<end()> method.  As C<match()> calls C<end()> internally,
attempting a match closes all active quantifiersThere is currently no way to
re-open a quantifier even if you add to a Regexp::English object.  This is a
non-trivial problem (as the author understands it), and there's no good
solution for it in normal regular expressions anyway.

If you have imported the quantifiers, you can pass the quantifiables as
arguments:

	use Regexp::English ':standard';

	my $re = Regexp::English->new()
		->multiple('a');

This closes the open quantifier for you automatically.  Though this syntax is
slightly more visually appealing, it does involve exporting quite a few methods
into your namespace, so it is not the default behavior.  Besides that, if you
get in this habit, you'll eventually have to use the C<:all> tag.  It's better
to make a habit of using the method calls, or to push Vahe to write
Regexp::Easy.  :)

=over 4

=item * C<zero_or_more()>

Matches as many items as possible.  Note that "possible" includes matching zero
items.  Note also that "item" means "whatever you told it to match".  By
default, this is greedy.

=item * C<multiple()>

Matches I<at least one> item, but as many as possible.  By default, this is
greedy.

=item * C<optional()>

Marks an item as optional so that the pattern will match with or without the
item.

=item * C<minimal()>

This quantifier modifies either C<zero_or_more()> or C<multiple()>, and
disables greediness, asking for as few matches as possible.

=back

=head2 Groupings

Groupings function much the same as quantifiers, though they have semantic
differences.  The most important similarity is that you can use them with the
function or the method interface.  The method interface is nicer, but see the
documentation for C<end()> for more information.

Groupings generally correspond to advanced Perl regular expression features
like lookaheads and lookbehinds.  If you find yourself using them on a regular
basis, you're probably ready to graduate to hand-rolled regular expressions (or
to contribute code to improve Regexp::English.

=over 4

=item * C<comment()>

Marks the item as a comment, which has no bearing on the match and really
doesn't give you anything here either.  Don't let that stop you, though.

=item * C<group()>

Groups items together (often to use a single quantifier on them) without
actually capturing them.  This isn't very useful either, because the
Quantifiers handle this for you.

=item * C<followed_by()>

Marks the item as a zero-width positive look-ahead assertion.  This means that
the pattern must match the item after the previous bits, but the item is not
part of the matched string as far as captures and C<pos()> care.

=item * C<not_followed_by()>

Marks the item as a zero-width negative look-ahead assertion.  This means that
the pattern must not match the item after the previous bits.  Again, the item
is not part of the matched string.

=item * C<after()>

Marks the item as a zero-width positive look-behind assertion.  This means the
pattern must match the item before the following bits.  This is super funky,
and may have subtle bugs -- look-behinds tend to need fixed width items, and
Regexp::English currently doesn't enforce this.

=item * C<not_after()>

Marks the item as a zero-width negative look-behind assertion.  This means the
pattern must not match the item before the following bits.  The fixed-width
rule also applies here.

=back

=head2 Miscellaneous

These subroutines don't really fit anywhere else.  They're useful, and mostly
cool.

=over 4

=item * C<new()>

Creates a new Regexp::English object.  Though some methods do this for you
automagically if you need one, this is the best way to start a regular
expression.

=item * C<match()>

Compiles and attempts to match the Regexp::English object against a passed-in
regular expression.  This will return any captured variables if they exist and
if the match succeeds.  If there are no captures, this will return a true or
false value depending on whether the match succeeds.

=item * C<remember()>

Causes Regexp::English to remember an item which C<match()> will capture and
return (or otherwise make available).  Normally, C<match()> returns these items
are in order of their declaration within the regular expression.  You can also
bind them to variables.  Pass in a reference to a scalar as the first argument,
and C<match()> will automagically populate the scalar with the matched value on
each subsequent match.  That means you can write:

	my ($first, $second);

	my $re = Regexp::English->new()
		->remember(\$first)
			->multiple('a')
			->remember(\$second)
				->word_char();

	for my $match (qw( aab aaac ad ))
	{
		print "$second\t$first\n" if $re->match($match);
	}

This will print:

	b	aaab
	c	aac
	d	ad

=item * C<end()>

Ends an open Quantifier or Grouping.  If you pass no arguments, it will end
only the most recently opened item.  If you pass a numeric argument, it will
end that many recently opened items.  It does not currently check to see if you
pass in a number, so only pass in numbers, or be ready to handle odd results.

=item * C<compile()>

Compiles and returns the pattern-in-progress, ending any and all open
Quantifier or Groupings.  This uses C<qr//>.  Note that any operation which
stringifies the object will call this method.  This appears to include treating
a Regexp::English object as a regular expression.  Nifty.

=item * C<or()>

Provides alternation capabilities.  The preferred interface is very similar to
Grouping calls:

	my $re = Regexp::English->new()
		->group()
			->digit()
			->or()
			->word_char();

Wrapping the entire alternation in C<group()> or some other Grouping method is
a very good idea, as you might want to use a Quantifier or something more
complex:

	my $re = Regexp::English->new()
		->remember()
				->literal('root beer')
			->or
				->literal('milkshake')
		->end();

If you find this onerous, you can also pass arguments to C<or()>, which will
group them together in non-capturing braces.  Note that you will have to import
the appropriate functions or fully qualify them.  Calling these functions as
class methods may not work reliably anyway.  It may never work reliably.
Properly indented, the method interface looks nicer anyway, but you have two
options:

	my $functionre = Regexp::English->new()
		->or( Regexp::English::digit(), Regexp::English::word_char() );

	my $classmethodre = Regexp::English->new()
		->or( Regexp::English->digit(), Regexp::English->word_char() );

=item * C<debug()>

Returns the regular expression so far.  This can be handy if you know what
you're doing.

=item * C<capture()>

Performs the capturing logic.  You probably don't need to know about this, but
it's fairly cool.

=back

=head1 EXPORTS

By default, there are no exports.  This is an object oriented module, and this
is how it should be.  You can import the Quantifier and Grouping subroutines by
providing the C<:standard> argument to the C<use()> line and the Character
methods with the C<:chars> tag.

	use Regexp::English qw( :standard :chars );

You can also use the C<:all> tag:

	use Regexp::English ':all';

This interface may change slightly in the future.  If you find yourself
exporting things, you should look into Vahe Sarkissian's upcoming Regexp::Easy
module.  This is probably news to him, too.

=head1 TODO

=over 4

=item * Add C<not()>

=item * More error checking

=item * Add a few tests here and there

=item * Add POSIX character classes ?

=item * Delegate to Regexp::Common ?

=item * Allow other language backends (probably just add documentation for this)

=item * Improve documentation

=back

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>, with many suggestions from Vahe
Sarkissian and Damian Conway.

=head1 COPYRIGHT

Copyright (c) 2001-2002, 2005, 2011 by chromatic.  Most rights reserved.

This program is free software; you can use, modify, and redistribute it under
the same terms as Perl 5.12 itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

L<perlre>

=cut

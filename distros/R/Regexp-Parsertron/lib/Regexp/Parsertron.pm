package Regexp::Parsertron;

use v5.10;
use strict;
use warnings;
#use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use Marpa::R2;

use Moo;

use Scalar::Does '-constants'; # For does().

use Tree;

use Try::Tiny;

use Types::Standard qw/Any Int Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has current_node =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has re =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has test_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has tree =>
(
	default  => sub{return Tree -> new('Root')},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has uid =>
(
	default  => sub {return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has verbose =>
(
	default  => sub {return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has warning_str =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '0.81';

# ------------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($bnf)	= get_data_section('V 5.20');

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);
	$self -> reset;

} # End of BUILD.

# ------------------------------------------------

sub append
{
	my($self, %opts) = @_;

	for my $param (qw/text uid/)
	{
		die "Method append() takes a hash with these keys: text, uid\n" if (! defined($opts{$param}) );
	}

	my($meta);
	my($uid);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta	= $node -> meta;
		$uid	= $$meta{uid};

		if ($opts{uid} == $uid)
		{
			$$meta{text} .= $opts{text};
		}
	}

} # End of append.

# ------------------------------------------------

sub _add_daughter
{
	my($self, $event_name, $attributes)	= @_;
	$$attributes{uid}					= $self -> uid($self -> uid + 1);
	my($node)							= Tree -> new($event_name);

	$node -> meta($attributes);

	say "Adding $event_name to tree. " if ($self -> verbose > 1);

	if ($event_name =~ /^close_(?:bracket|parenthesis)$/)
	{
		$self -> current_node($self -> current_node -> parent);
	}

	$self -> current_node -> add_child($node);

	if ($event_name =~ /^open_(?:bracket|parenthesis)$/)
	{
		$self -> current_node($node);
	}

} # End of _add_daughter.

# ------------------------------------------------

sub as_string
{
	my($self)	= @_;
	my($string)	= '';

	my($meta);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta	= $node -> meta;
		$string .= $$meta{text};
	}

	return $string;

} # End of as_string.

# ------------------------------------------------

sub find
{
	my($self, $target) = @_;

	die "Method find() takes a defined value as the parameter\n" if (! defined $target);

	my(@found);
	my($meta);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta = $node -> meta;

		if (index($$meta{text}, $target) >= 0)
		{
			push @found, $$meta{uid};
		}
	}

	return [@found];

} # End of find.

# ------------------------------------------------

sub get
{
	my($self, $wanted_uid)	= @_;
	my($max_uid)			= $self -> uid;

	if (! defined($wanted_uid) || ($wanted_uid < 1) || ($wanted_uid > $self -> uid) )
	{
		die "Method get() takes a uid parameter in the range 1 .. $max_uid\n";
	}

	my($meta);
	my($text);
	my($uid);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta	= $node -> meta;
		$uid	= $$meta{uid};

		if ($wanted_uid == $uid)
		{
			$text = $$meta{text};
		}
	}

	return $text;

} # End of get.

# ------------------------------------------------

sub _next_few_chars
{
	my($self, $stringref, $offset) = @_;
	my($s) = substr($$stringref, $offset, 20);
	$s     =~ tr/\n/ /;
	$s     =~ s/^\s+//;
	$s     =~ s/\s+$//;

	return $s;

} # End of _next_few_chars.

# ------------------------------------------------

sub parse
{
	my($self, %opts) = @_;

	# Emulate parts of new(), which makes things a bit earier for the caller.

	$self -> re($opts{re})				if (defined $opts{re});
	$self -> verbose($opts{verbose})	if (defined $opts{verbose});
	$self -> warning_str('');

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			exhaustion     => 'event',
			grammar        => $self -> grammar,
			ranking_method => 'high_rule_only',
		})
	);

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		if (defined (my $value = $self -> _process) )
		{
			$self -> print_cooked_tree if ($self -> verbose > 1);
		}
		else
		{
			$result = 1;

			my($message) = "Error: Marpa parse failed. ";

			say $message if ($self -> verbose);

			die $message;
		}
	}
	catch
	{
		my($message) = "Error: Marpa parse failed. $_";

		say $message if ($self -> verbose);

		die $message;
	};

	# Return 0 for success and 1 for failure.

	return $result;

} # End of parse.

# ------------------------------------------------

sub prepend
{
	my($self, %opts) = @_;

	for my $param (qw/text uid/)
	{
		die "Method append() takes a hash with these keys: text, uid\n" if (! defined($opts{$param}) );
	}

	my($meta);
	my($uid);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta	= $node -> meta;
		$uid	= $$meta{uid};

		if ($opts{uid} == $uid)
		{
			$$meta{text} = "$opts{text}$$meta{text}";
		}
	}

} # End of prepend.

# ------------------------------------------------

sub _process
{
	my($self)		= @_;
	my($raw_re)		= $self -> re;
	my($test_count)	= $self -> test_count($self -> test_count + 1);

	# This line is 'print', not 'say'!

	print "Test count: $test_count. Parsing (in qr/.../ form): " if ($self -> verbose);

	my($string_re)	= $self -> _string2re($raw_re);

	if ($string_re eq '')
	{
		say '' if ($self -> verbose);

		return undef;
	}

	say "'$string_re'. " if ($self -> verbose);

	my($ref_re)		= \"$string_re"; # Use " in comment for UltraEdit.
	my($length)		= length($string_re);

	my($child);
	my($event_name);
	my($lexeme);
	my($pos);
	my($span, $start);

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.

	for
	(
		$pos = $self -> recce -> read($ref_re);
		($pos < $length);
		$pos = $self -> recce -> resume($pos)
	)
	{
		($start, $span)				= $self -> recce -> pause_span;
		($event_name, $span, $pos)	= $self -> _validate_event($ref_re, $start, $span, $pos,);

		# If the input is exhausted, we exit immediately so we don't try to use
		# the values of $start, $span or $pos. They are ignored upon exit.

		last if ($event_name eq "'exhausted"); # Yes, it has a leading quote.

		$lexeme	= $self -> recce -> literal($start, $span);
		$pos	= $self -> recce -> lexeme_read($event_name);

		die "Marpa lexeme_read($event_name) rejected lexeme '$lexeme'\n" if (! defined $pos);

		say "event_name: $event_name. lexeme: $lexeme. " if ($self -> verbose > 1);

		$self -> _add_daughter($event_name, {text => $lexeme});
   }

	my($message);

	if (my $status = $self -> recce -> ambiguous)
	{
		my($terminals)	= $self -> recce -> terminals_expected;
		$terminals		= ['(None)'] if ($#$terminals < 0);
		$message		= "Marpa warning. Parse ambiguous. Status: $status. Terminals expected: " . join(', ', @$terminals);
	}
	elsif ($self -> recce -> exhausted)
	{
		# See https://metacpan.org/pod/distribution/Marpa-R2/pod/Exhaustion.pod#Exhaustion
		# for why this code is exhaustion-loving.

		$message = 'Marpa parse exhausted';
	}

	if ($message)
	{
		$self -> warning_str($message);

		say $message if ($self -> verbose);
	}

	$self -> print_raw_tree if ($self -> verbose);

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub print_cooked_tree
{
	my($self)	= @_;
	my($format)	= '%-30s  %3s  %s';

	say sprintf($format, 'Name', 'Uid', 'Text');
	say sprintf($format, '----', '---', '----');

	my($meta);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta = $node -> meta;

		say sprintf($format, $node -> value, $$meta{uid}, $$meta{text});
	}

} # End of print_cooked_tree.

# ------------------------------------------------

sub print_raw_tree
{
	my($self) = @_;

	say map("$_\n", @{$self -> tree -> tree2string});

} # End of print_raw_tree.

# ------------------------------------------------

sub reset
{
	my($self) = @_;

	$self -> tree(Tree -> new('Root') );
	$self -> tree -> meta({text => 'Root', uid => 0});
	$self -> current_node($self -> tree);
	$self -> uid(0);
	$self -> warning_str('');

} # End of reset.

# ------------------------------------------------

sub set
{
	my($self, %opts) = @_;

	for my $param (qw/text uid/)
	{
		die "Method set() takes a hash with these keys: text, uid\n" if (! defined($opts{$param}) );
	}

	my($meta);
	my($uid);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta	= $node -> meta;
		$uid	= $$meta{uid};

		if ($opts{uid} == $uid)
		{
			$$meta{text} = $opts{text};
		}
	}

} # End of set.

# ------------------------------------------------

sub _string2re
{
	my($self, $raw_re) = @_;

	my($re);

	try
	{
		$re = does($raw_re, 'Regexp') ? $raw_re : qr/$raw_re/;
	}
	catch
	{
		my($message) = "Error: Perl cannot convert $raw_re into qr/.../ form";

		say $message if ($self -> verbose);

		die $message;
	};

	return $re;

} # End of _string2re.

# ------------------------------------------------

sub _validate_event
{
	my($self, $stringref, $start, $span, $pos) = @_;
	my(@event)       = @{$self -> recce -> events};
	my($event_count) = scalar @event;
	my(@event_name)  = sort map{$$_[0]} @event;
	my($event_name)  = $event_name[0]; # Default.

	# If the input is exhausted, we return immediately so we don't try to use
	# the values of $start, $span or $pos. They are ignored upon return.

	if ($event_name eq "'exhausted") # Yes, it has a leading quote.
	{
		return ($event_name, $span, $pos);
	}

	my($lexeme)        = substr($$stringref, $start, $span);
	my($line, $column) = $self -> recce -> line_column($start);
	my($literal)       = $self -> _next_few_chars($stringref, $start + $span);
	my($message)       = "Location: ($line, $column). Lexeme: |$lexeme|. Next few chars: |$literal|";
	$message           = "$message. Events: $event_count. Names: ";

	say $message, join(', ', @event_name) if ($self -> verbose > 1);

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Regexp::Parsertron> - Parse a Perl regexp into a data structure of type L<Tree>

Warning: Development version. See L</Version Numbers> for details.

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use v5.10;
	use strict;
	use warnings;

	use Regexp::Parsertron;

	# ---------------------

	my($re)		= qr/Perl|JavaScript/i;
	my($parser)	= Regexp::Parsertron -> new(verbose => 1);

	# Return 0 for success and 1 for failure.

	my($result) = $parser -> parse(re => $re);

	say "Calling append(text => '|C++', uid => 6)";

	$parser -> append(text => '|C++', uid => 6);
	$parser -> print_raw_tree;
	$parser -> print_cooked_tree;

	my($as_string) = $parser -> as_string;

	say "Original:  $re. Result: $result. (0 is success)";
	say "as_string: $as_string";

And its output:

	Test count: 1. Parsing (in qr/.../ form): '(?^i:Perl|JavaScript)'.
	Root. Attributes: {text => "Root", uid => "0"}
	    |--- open_parenthesis. Attributes: {text => "(", uid => "1"}
	    |    |--- question_mark. Attributes: {text => "?", uid => "2"}
	    |    |--- caret. Attributes: {text => "^", uid => "3"}
	    |    |--- flag_set. Attributes: {text => "i", uid => "4"}
	    |    |--- colon. Attributes: {text => ":", uid => "5"}
	    |    |--- character_set. Attributes: {text => "Perl|JavaScript", uid => "6"}
	    |--- close_parenthesis. Attributes: {text => ")", uid => "7"}
	Calling append(text => '|C++', uid => 6)
	Root. Attributes: {text => "Root", uid => "0"}
	    |--- open_parenthesis. Attributes: {text => "(", uid => "1"}
	    |    |--- question_mark. Attributes: {text => "?", uid => "2"}
	    |    |--- caret. Attributes: {text => "^", uid => "3"}
	    |    |--- flag_set. Attributes: {text => "i", uid => "4"}
	    |    |--- colon. Attributes: {text => ":", uid => "5"}
	    |    |--- character_set. Attributes: {text => "Perl|JavaScript|C++", uid => "6"}
	    |--- close_parenthesis. Attributes: {text => ")", uid => "7"}
	Name                  Uid  Text
	----                  ---  ----
	open_parenthesis        1  (
	question_mark           2  ?
	caret                   3  ^
	flag_set                4  i
	colon                   5  :
	character_set           6  Perl|JavaScript|C++
	close_parenthesis       7  )
	Original:  (?^i:Perl|JavaScript). Result: 0. (0 is success)
	as_string: (?^i:Perl|JavaScript|C++)

Note: The 1st tree is printed due to verbose => 1 in the call to L</new([%opts])>, while the 2nd
is due to the call to L</print_raw_tree()>. The columnar output is due to the call to
L</print_cooked_tree()>.

=head2 The Edit Methods

The I<edit methods> simply means any one or more of these methods, which can all change the text of
a node:

=over 4

=item o L</append(%opts)>

=item o L</prepend(%opts)>

=item o L</set(%opts)>

=back

The edit methods are exercised in t/get.set.t, as well as scripts/synopsis.pl (above).

=head1 Description

Parses a regexp into a tree object managed by the L<Tree> module, and provides various methods for
updating and retrieving that tree's contents.

This module uses L<Marpa::R2> and L<Moo>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<Regexp::Parsertron> as you would any C<Perl> module:

Run:

	cpanm Regexp::Parsertron

or run:

	sudo cpan Regexp::Parsertron

or unpack the distro, and then use:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Regexp::Parsertron -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Regexp::Parsertron>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</re([$regexp])>]):

=over 4

=item o re => $regexp

The C<does()> method of L<Scalar::Does> is called to see what C<re> is. If it's already of the
form C<qr/$re/>, then it's processed as is, but if it's not, then it's transformed using C<qr/$re/>.

Warning: Currently, the input is expected to have been pre-processed by Perl via qr/$regexp/.

Default: ''.

=item o verbose => $integer

Takes values 0, 1 or 2, which print more and more progress reports.

Used for debugging.

Default: 0 (print nothing).

=back

=head1 Methods

=head2 append(%opts)

Append some text to the text of a node.

%opts is a hash with these (key => value) pairs:

=over 4

=item o text => $string

The text to append.

=item o uid => $uid

The uid of the node to update.

=back

The code calls C<die()> if %opts does not have these 2 keys, or if either value is undef.

See scripts/synopsis.pl for sample code.

Note: Calling C<append()> never changes the uids of nodes, so repeated calling of C<append()> with
the same C<uid> will apply more and more updates to the same node.

See also L</prepend(%opts)>, L</set(%opts)> and t/get.set.t.

=head2 as_string()

Returns the parsed regexp as a string. The string contains all edits applied with methods such as
L</append(%opts)>.

=head2 find($string)

Returns an arrayref of node uids whose text contains the given string.

The code calls C<die()> if $target is undef.

If the arrayref is empty, there were no matches.

This method uses the Perl C<index()> function to test if $string is a substring of the text of each
node. Regexps are not used by this method.

See scripts/play.pl and t/get.set.t for sample usage of C<find()>.

See also L</get($uid)>.

=head2 get($uid)

Get the text of the node with the given $uid.

The code calls C<die()> if $uid is undef, or outside the range 1 .. $self -> uid. The latter value
is the highest uid so far assigned to any node.

Returns undef if the given $uid is not found.

See also L</find($string)>.

=head2 new([%opts])

Here, '[]' indicate an optional parameter.

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 parse([%opts])

Here, '[]' indicate an optional parameter.

Parses the regexp supplied with the parameter C<re> in the call to L</new()> or in the call to
L</re($regexp)>, or in the call to C<< parse(re => $regexp) >> itself. The latter takes precedence.

The hash C<%opts> takes the same (key => value) pairs as L</new()> does.

See L</Constructor and Initialization> for details.

=head2 prepend(%opts)

Prepend some text to the text of a node.

%opts is a hash with these (key => value) pairs:

=over 4

=item o text => $string

The text to prepend.

=item o uid => $uid

The uid of the node to update.

=back

The code calls C<die()> if %opts does not have these 2 keys, or if either value is undef.

Note: Calling C<prepend()> never changes the uids of nodes, so repeated calling of C<prepend()> with
the same C<uid> will apply more and more updates to the same node.

See also L</append(%opts)>, L</set(%opts)>, and t/get.set.t.

=head2 print_cooked_tree()

Prints, in a pretty format, the tree built from parsing.

See the </Synopsis> for sample output.

See also L</print_raw_tree>.

=head2 print_raw_tree()

Prints, in a simple format, the tree built from parsing.

See the </Synopsis> for sample output.

See also L</print_cooked_tree>.

=head2 re([$regexp])

Here, '[]' indicate an optional parameter.

Gets or sets the regexp to be processed.

Note: C<re> is a parameter to L</new([%opts])>.

=head2 reset()

Resets various internal things, except test_count.

Used basically for debugging.

=head2 set(%opts)

Set the text of a node to $opt{text}.

%opts is a hash with these (key => value) pairs:

=over 4

=item o text => $string

The text to use to overwrite the text of the node.

=item o uid => $uid

The uid of the node to update.

=back

The code calls C<die()> if %opts does not have these 2 keys, or if either value is undef.

See also L</append(%opts)> and L</prepend(%opts)>.

=head2 tree()

Returns an object of type L<Tree>. Ignore the root node.

Each node's C<meta> method returns a hashref of information about the node. See the L</FAQ> for
details.

See also the source code for L</print_cooked_tree()> and L</print_raw_tree()> for ideas on how to
use this object.

=head2 uid()

Returns the last-used uid.

Each node in the tree is given a uid, which allows methods like L</append(%opts)> to work.

=head2 verbose([$integer])

Here, '[]' indicate an optional parameter.

Gets or sets the verbosity level, within the range 0 .. 2. Higher numbers print more progress
reports.

Used basically for debugging.

Note: C<verbose> is a parameter to L</new([%opts])>.

=head2 warning_str()

Returns the last Marpa warning.

In short, Marpa will always report 'Marpa parse exhausted' in warning_str() if the parse is not
ambiguous, but do not worry - I<this is not an error>.

See L<After calling parse(), warning_str() contains the string '... Parse ambiguous ...'|/FAQ> and
L<Is this a (Marpa) exhaustion-hating or exhaustion-loving app?|/FAQ>.

=head1 FAQ

=head2 How do I use this module?

Herewith a brief tutorial.

=over 4

=item o Start with a simple program and a simple regexp

This code, scripts/tutorial.pl, is a cut-down version of scripts/synopsis.pl:

	#!/usr/bin/env perl

	use v5.10;
	use strict;
	use warnings;

	use Regexp::Parsertron;

	# ---------------------

	my($re)		= qr/Perl|JavaScript/i;
	my($parser)	= Regexp::Parsertron -> new(verbose => 1);

	# Return 0 for success and 1 for failure.

	my($result) = $parser -> parse(re => $re);

	say "Original:  $re. Result: $result. (0 is success)";

Running it outputs:

	Test count: 1. Parsing (in qr/.../ form): '(?^i:Perl|JavaScript)'.
	Root. Attributes: {text => "Root", uid => "0"}
	    |--- open_parenthesis. Attributes: {text => "(", uid => "1"}
	    |    |--- question_mark. Attributes: {text => "?", uid => "2"}
	    |    |--- caret. Attributes: {text => "^", uid => "3"}
	    |    |--- flag_set. Attributes: {text => "i", uid => "4"}
	    |    |--- colon. Attributes: {text => ":", uid => "5"}
	    |    |--- character_set. Attributes: {text => "Perl|JavaScript", uid => "6"}
	    |--- close_parenthesis. Attributes: {text => ")", uid => "7"}

	Original:  (?^i:Perl|JavaScript). Result: 0. (0 is success)

=item o Examine the tree and determine which nodes you wish to edit

The nodes are uniquely identified by their uids.

=item o Proceed as does scripts/synopsis.pl

Add these lines to the end of the tutorial code, and re-run:

	$parser -> append(text => '|C++', uid => 6);
	$parser -> print_raw_tree;

The extra output, showing node uid == 6, is:

	Root. Attributes: {text => "Root", uid => "0"}
	    |--- open_parenthesis. Attributes: {text => "(", uid => "1"}
	    |    |--- question_mark. Attributes: {text => "?", uid => "2"}
	    |    |--- caret. Attributes: {text => "^", uid => "3"}
	    |    |--- flag_set. Attributes: {text => "i", uid => "4"}
	    |    |--- colon. Attributes: {text => ":", uid => "5"}
	    |    |--- character_set. Attributes: {text => "Perl|JavaScript|C++", uid => "6"}
	    |--- close_parenthesis. Attributes: {text => ")", uid => "7"}

=item o Test also with L</prepend(%opts)> and L</set(%opts)>

See t/get.set.t for sample code.

=item o Since everything works, make a cup of tea

=back

=head2 Does this module ever use \Q...\E to quote regexp metacharacters?

No.

=head2 What is the format of the nodes in the tree build by this module?

Each node's C<name> is the name of the Marpa-style event which was triggered by detection of
some C<text> within the regexp.

Each node's C<meta()> method returns a hashref with these (key => value) pairs:

=over 4

=item o text => $string

This is the text within the regexp which triggered the event just mentioned.

=item o uid => $integer

This is the unqiue id of the 'current' node.

This C<uid> is often used by you to specify which node to work on.

=back

See also the source code for L</print_cooked_tree()> and L</print_raw_tree()> for ideas on how to
use the tree.

See the L</Synopsis> for sample code and a report after parsing a tiny regexp.

=head2 Does the root node in the tree ever hold useful information?

No. Always ignore it.

=head2 Does this module interpret regexps in any way?

No. You have to run your own Perl code to do that. This module just parses them into a data
structure.

And that really means this module does not match the regexp against anything. If I appear to do that
while debugging new code, you can't rely on that appearing in production versions of the module.

=head2 Does this module re-write regexps?

No, unless you call one of L</The Edit Methods>.

=head2 Does this module handle both Perl 5 and Perl 6?

No. It will only handle Perl 5 syntax.

=head2 Does this module handle regexps for various versions of Perl5?

Not yet. Version-dependent regexp syntax will be supported for recent versions of Perl. This is
done by having tokens within the BNF which are replaced at start-up time with version-dependent
details.

There are no such tokens at the moment.

All debugging is done assuming the regexp syntax as documented online. See L</References> for the
urls in question.

=head2 So which version of Perl is supported?

I'm (2018-01-14) using Perl V 5.20.2 and making the BNF match the Perl regexp docs listed in
L</References> below.

=head2 After calling parse(), warning_str() contains the string '... Parse ambiguous ...'

This is almost certainly a error with the BNF, although of course it may be an error will an
exceptionally-badly formed regexp.

Report it via L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Parsertron>, and please
 include the regexp in the report. Thanx!

=head2 Is this a (Marpa) exhaustion-hating or exhaustion-loving app?

Exhaustion-loving.

See L<https://metacpan.org/pod/distribution/Marpa-R2/pod/Exhaustion.pod#Exhaustion>

=head2 Will this code be modified to run under L<Marpa::R3> when the latter is stable?

Yes.

=head2 What is the purpose of this module?

=over 4

=item o To provide a stand-alone parser for regexps

=item o To help me learn more about regexps

=item o To become, I hope, a replacement for the horrendously complex L<Regexp::Assemble>

=back

=head1 Scripts

This diagram indicates the flow of logic from script to script:

	xt/author/re_tests
	|
	V
	xt/author/generate.tests.pl
	|
	V
	xt/authors/perl-5.21.11.tests
	|
	V
	perl -Ilib t/perl-5.21.11.t > xt/author/perl-5.21.11.log 2>&1

If xt/author/perl-5.21.11.log only contains lines starting with 'ok', then all Perl and Marpa
errors have been hidden, so t/perl-5.21.11.t is ready to live in t/. Before that time it lives in
xt/author/.

=head1 TODO

=over 4

=item o How to best define 'code' in the BNF.

=item o Things to be aware of:

=over 4

=item o Regexps of the form: /.../aa

=item o Pragmas for the form: use re '/aa'; ...

=back

=item o I could traverse the tree and store a pointer to each node in an array

This would mean fast access to nodes in random order.

=back

=head1 References

L<http://www.pcre.org/>. PCRE - Perl Compatible Regular Expressions.

L<http://perldoc.perl.org/perlre.html>. This is the definitive document.

L<http://perldoc.perl.org/perlrecharclass.html#Extended-Bracketed-Character-Classes>.

L<http://perldoc.perl.org/perlretut.html>. Samples with commentary.

L<http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators>

L<http://perldoc.perl.org/perlrequick.html>

L<http://perldoc.perl.org/perlrebackslash.html>

L<http://www.nntp.perl.org/group/perl.perl5.porters/2016/02/msg234642.html>

L<https://code.activestate.com/lists/perl5-porters/209610/>

L<https://stackoverflow.com/questions/46200305/a-strict-regular-expression-for-matching-chemical-formulae>

=head1 See Also

L<Graph::Regexp>

L<Regexp::Assemble>

L<Regexp::Debugger>

L<Regexp::ERE>

L<Regexp::Keywords>

L<Regexp::Lexer>

L<Regexp::List>

L<Regexp::Optimizer>

L<Regexp::Parser>

L<Regexp::SAR>. This is vaguely a version of L<Set::FA::Element>.

L<Regexp::Stringify>

L<Regexp::Trie>

And many others...

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Regexp-Parsertron>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp::Parsertron>.

=head1 Author

L<Regexp::Parsertron> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

L<My homepage|http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2016, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut

__DATA__
@@ V 5.20

:default						::= action => [values]

lexeme default					= latm => 1

:start							::= regexp

# G1 stuff.

regexp							::= open_parenthesis question_mark caret flag_sequence colon entire_pattern close_parenthesis

flag_sequence					::= positive_flags negative_flag_set

positive_flags					::=
positive_flags					::= flag_set

negative_flag_set				::=
negative_flag_set				::= minus negative_flags

negative_flags					::= flag_set

# Extended patterns from http://perldoc.perl.org/perlre.html:

entire_pattern					::= comment_thingy					#  1.
									| flag_thingy					#  2.
									| colon_thingy					#  3.
									| vertical_bar_thingy			#  4.
									| equals_thingy					#  5.
									| exclamation_mark_thingy		#  6.
									| less_or_equals_thingy			#  7.
									| less_exclamation_mark_thingy	#  8.
									| named_capture_group_thingy	#  9.
									| named_backreference_thingy	# 10.
									| single_code_thingy			# 11.
									| double_code_thingy			# 12.
									| recursive_subpattern_thingy	# 13.
									| recurse_thingy				# 14.
									| conditional_thingy			# 15.
									| greater_than_thingy			# 16.
									| extended_bracketed_thingy		# 17.
									| pattern_thingy				# 99.

# 1: (?#text)

comment_thingy					::= open_parenthesis question_mark hash comment close_parenthesis

comment							::= non_close_parenthesis*

# 2: (?adlupimnsx-imnsx)
#  & (?^alupimnsx)

flag_thingy						::= open_parenthesis question_mark flag_set_1
									| open_parenthesis question_mark caret flag_set_2 close_parenthesis

flag_set_1						::= flag_sequence

flag_set_2						::= flag_sequence

# 3: (?:pattern)	Eg: (?:(?<n>foo)|(?<n>bar))\k<n>
#  & (?adluimnsx-imnsx:pattern)
#  & (?^aluimnsx:pattern)

colon_thingy					::= open_parenthesis question_mark colon pattern_sequence close_parenthesis

pattern_sequence				::= pattern_set*

pattern_set						::= pattern_item
									| pattern_item '|'

pattern_item					::= bracket_pattern
									| parenthesis_pattern
									| slash_pattern
									| character_sequence

bracket_pattern					::= open_bracket characters_in_set close_bracket

# Perl accepts /()/.
# Perl does not accept /[]/.

characters_in_set				::= character_in_set+

character_in_set				::= escaped_close_bracket
									| non_close_bracket

character_sequence				::= simple_character_sequence+

simple_character_sequence		::= escaped_close_parenthesis
									| escaped_open_parenthesis
									| escaped_slash
									| caret
									| character_set

parenthesis_pattern				::= open_parenthesis pattern_sequence close_parenthesis

slash_pattern					::= slash pattern_sequence slash

# 4: (?|pattern)

vertical_bar_thingy				::= open_parenthesis question_mark vertical_bar pattern_sequence close_parenthesis

# 5: (?=pattern)

equals_thingy					::= open_parenthesis question_mark equals pattern_sequence close_parenthesis

# 6: (?!pattern)

exclamation_mark_thingy			::= open_parenthesis question_mark exclamation_mark pattern_sequence close_parenthesis

# 7: (?<=pattern
#  & \K

less_or_equals_thingy			::= open_parenthesis question_mark less_or_equals close_parenthesis
									| escaped_K

# 8: (?<!pattern)

less_exclamation_mark_thingy	::= open_parenthesis question_mark less_exclamation_mark close_parenthesis

# 9: (?<NAME>pattern)
#  & (?'NAME'pattern)

named_capture_group_thingy		::= open_parenthesis question_mark named_capture_group close_parenthesis

named_capture_group				::= single_quote capture_name single_quote
									| less_than capture_name greater_than

capture_name					::= word

# 10: \k<NAME>
#  & \k'NAME'

named_backreference_thingy		::= named_backreference

named_backreference				::= escaped_k single_quote capture_name single_quote
									| escaped_k less_than capture_name greater_than

# 11: (?{ code })

single_code_thingy				::= open_parenthesis question_mark open_brace code close_brace close_parenthesis

code							::= [[:print:]] # TODO: ATM.

# 12: (??{ code })

double_code_thingy				::= open_parenthesis question_mark question_mark open_brace code close_brace close_parenthesis

# 13: (?PARNO) || (?-PARNO) || (?+PARNO) || (?R) || (?0)

recursive_subpattern_thingy		::= open_parenthesis question_mark parameter_number close_parenthesis

parameter_number				::= natural_number # 1, 2, ...
									| minus natural_number
									| plus natural_number
									| R
									| zero

natural_number					::= non_zero_digit digit_sequence

digit_sequence					::= digit_set*

# 14: (?&NAME)

recurse_thingy					::= open_parenthesis question_mark ampersand capture_name close_parenthesis
									| open_parenthesis question_mark P greater_than capture_name close_parenthesis

# 15: (?(condition)yes-pattern|no-pattern)
#  & (?(condition)yes-pattern)

conditional_thingy				::= open_parenthesis question_mark condition close_parenthesis
condition						::= open_parenthesis natural_number close_parenthesis
									| open_parenthesis named_capture_group close_parenthesis
									| equals_thingy
									| exclamation_mark_thingy
									| less_or_equals_thingy # Includes \K.
									| less_exclamation_mark_thingy
									| single_code_thingy
									| an_R_sequence
									| an_R_name
									| DEFINE

an_R_sequence					::= a_single_R
									| open_parenthesis R_pattern close_parenthesis

a_single_R						::= open_parenthesis R close_parenthesis

R_pattern						::= R R_suffix

R_suffix						::= natural_number

an_R_name						::= open_parenthesis R ampersand capture_name close_parenthesis

# 16: (?>pattern)

greater_than_thingy				::= open_parenthesis question_mark greater_than close_parenthesis

# 17: (?[ ])

extended_bracketed_thingy		::= open_parenthesis question_mark open_bracket character_classes close_bracket close_parenthesis

character_classes				::= [[:print:]]

# 99.

pattern_thingy					::= pattern_set*

# L0 stuff, in alphabetical order.
#
# Policy: Event names are always the same as the name of the corresponding lexeme.
#
# Note:   Tokens of the form '_xxx_', if any, are replaced with version-dependent values.

:lexeme						~ ampersand				pause => before		event => ampersand
ampersand					~ '^'

:lexeme						~ caret					pause => before		event => caret
caret						~ '^'

:lexeme						~ character_set			pause => before		event => character_set
character_set				~ [^()/]*

:lexeme						~ close_brace			pause => before		event => close_brace
close_brace					~ '}'

:lexeme						~ close_bracket			pause => before		event => close_bracket
close_bracket				~ ']'

:lexeme						~ close_parenthesis		pause => before		event => close_parenthesis
close_parenthesis			~ ')'

:lexeme						~ colon					pause => before		event => colon
colon						~ ':'

:lexeme						~ DEFINE				pause => before		event => DEFINE
DEFINE						~ 'DEFINE'

:lexeme						~ digit_set				pause => before		event => digit_set
digit_set					~ [0-9] # We avoid \d to avoid Unicode digits.

:lexeme						~ equals				pause => before		event => equals
equals						~ '='

:lexeme						~ escaped_close_bracket	pause => before		event => escaped_close_bracket
escaped_close_bracket		~ '\\' ']'

:lexeme						~ escaped_close_parenthesis	pause => before		event => escaped_close_parenthesis
escaped_close_parenthesis	~ '\\)'

:lexeme						~ escaped_k				pause => before		event => escaped_k
escaped_k					~ '\\k'

:lexeme						~ escaped_K				pause => before		event => escaped_K
escaped_K					~ '\\K'

:lexeme						~ escaped_open_parenthesis	pause => before		event => escaped_open_parenthesis
escaped_open_parenthesis	~ '\\)'

:lexeme						~ escaped_slash			pause => before		event => escaped_slash
escaped_slash				~ '\\\\'

:lexeme						~ exclamation_mark		pause => before		event => exclamation_mark
exclamation_mark			~ '!'

:lexeme						~ flag_set				pause => before		event => flag_set
flag_set					~ [a-z]+

:lexeme						~ greater_than			pause => before		event => greater_than
greater_than				~ '>'

:lexeme						~ hash					pause => before		event => hash
hash						~ '#'

:lexeme						~ less_or_equals		pause => before		event => less_or_equals
less_or_equals				~ '<='

:lexeme						~ less_exclamation_mark	pause => before		event => less_exclamation_mark
less_exclamation_mark		~ '<!'

:lexeme						~ less_than				pause => before		event => less_than
less_than					~ '<'

:lexeme						~ minus					pause => before		event => minus
minus						~ '-'

:lexeme						~ non_close_bracket		pause => before		event => non_close_bracket
non_close_bracket			~ [^\]]+

:lexeme						~ non_close_parenthesis	pause => before		event => non_close_parenthesis
non_close_parenthesis		~ [^)]

:lexeme						~ non_zero_digit		pause => before		event => non_zero_digit
non_zero_digit				~ [1-9]

:lexeme						~ open_brace			pause => before		event => open_brace
open_brace					~ '{'

:lexeme						~ open_bracket			pause => before		event => open_bracket
open_bracket				~ '['

:lexeme						~ open_parenthesis		pause => before		event => open_parenthesis
open_parenthesis			~ '('

:lexeme						~ P						pause => before		event => P
P							~ 'P'

:lexeme						~ plus					pause => before		event => plus
plus						~ '+'

:lexeme						~ question_mark			pause => before		event => question_mark
question_mark				~ '?'

:lexeme						~ R						pause => before		event => R
R							~ 'R'

:lexeme						~ single_quote			pause => before		event => single_quote
single_quote				~ [\'] # The '\' is for UltraEdit's syntax hiliter.

:lexeme						~ slash					pause => before		event => slash
slash						~ '/'

:lexeme						~ vertical_bar			pause => before		event => vertical_bar
vertical_bar				~ '|'

:lexeme						~ word					pause => before		event => word
word						~ [\w]+

:lexeme						~ zero					pause => before		event => zero
zero						~ '0'

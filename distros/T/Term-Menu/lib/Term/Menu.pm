package Term::Menu;

use 5.000;
use strict;
use warnings;
use Carp;

our $VERSION = '0.10';

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = {
		delim 		=> ") ",
		spaces		=> 7,
		beforetext 	=> "Please choose one of the following options.",
		aftertext	=> "Please enter a letter or number corresponding to the option you want to choose: ",
		nooptiontext	=> "That's not one of the available options.",
		moreoptions	=> " or ",
		tries		=> 0,
		toomanytries	=> "You've tried too many times.",
		hidekeys	=> 0,
		@_,
		lastval 	=> undef,
		tried		=> 0,
		};
	
	bless $self, $class;
	return $self;
}

sub setcfg {
	my $self = shift;
	croak("Error: setcfg is an instance method!") if(!ref $self);
	%$self = (%$self, @_);
}

sub menu {
	my $self = shift;

	# Create a default self if we didn't get one
	$self = Term::Menu->new() if(!defined($self) or !ref($self));

	# Options by name
	my %options = @_;

	# Options in order
	my $i = 0;
	my @options = grep { ++$i % 2 } @_;
	
	my $delim = $self->{delim}; # The delimiter between keys and label
	
	my @lines;	# The lines of the options that need to be printed
	my %keyvals;	# A hash that holds what keys should return what values.
	my $maxoptlen = 0; # Max length of keys that correspond to this value.
	
	foreach(@options) {
		my $value = $_;
		my @keys  = @{$options{$_}};
		my $label = shift @keys;
		my $options = join ($self->{moreoptions}, @keys);
		$keyvals{$_} = $value foreach(@keys);
		push @lines, [($self->{hidekeys} ? "" : $options.$delim).$label."\n", length($options)];
			#Length of options included to get the
			#number of spaces that need to be included.
		$maxoptlen = length($options) if(length($options) > $maxoptlen and !$self->{hidekeys});
	}
	my $spaces = $self->{spaces};
	$spaces = $maxoptlen if($maxoptlen > $spaces);
	print $self->{beforetext},"\n" if defined $self->{beforetext};
	foreach (@lines) {
		my ($line, $len) = @$_;
		my $nspace = $spaces - $len;
		print " " x $nspace, $line;
	}
	while(1) {
		print $self->{aftertext} if defined $self->{aftertext};
		my $answ = <STDIN>;
		chomp $answ;
		foreach(keys %keyvals) {
			if($answ eq $_) {
				$self->{lastval} = $keyvals{$_};
				return $keyvals{$_};
			}
		}
		print $self->{nooptiontext},"\n" if defined $self->{nooptiontext};
		$self->{tried} ||= 0;
		$self->{tried}++;
		if($self->{tried} >= $self->{tries} and $self->{tries} != 0) {
			last;
		}
	}
	if($self->{tried} >= $self->{tries} and $self->{tries} != 0) {
		print $self->{toomanytries},"\n" if defined $self->{toomanytries};
		$self->{tried} = 0;
		$self->{lastval} = undef;
		return undef;
	}
}

sub question {
	my ($self, $question) = @_;
	print $question;
	my $answer = <STDIN>;
	$self->{lastval} = $answer;
	return $answer;
}

sub lastval {
	my $self = shift;
	croak("Error: lastval is an instance method") if(!ref($self));
	return $self->{lastval};
}

sub table {
	my ($pkg, $heads, $contents) = @_;

	# We first get a list of columns and their sizes.
	# We only print as many columns as there are things in $heads.
	my $column_sizes = [];
	for(my $i = 0; $i < @$heads; ++$i) {
		# Max size of this column...
		my $size = length($heads->[$i]);
		foreach my $row (@$contents) {
			$size = length($row->[$i])
				if(length($row->[$i]) > $size);
		}
		$column_sizes->[$i] = $size;
	}

	# Now we start printing.
	# Line 1, 3 and n: delimiters
	my $delimline = "+";
	foreach(@$column_sizes) {
		$delimline .= ("-" x $_) . "+";
	}
	$delimline .= "\n";
	print $delimline;

	# Line 2: column names
	my $nameline = "|";
	for(my $i = 0; $i < @$heads; ++$i) {
		# Name of the head, plus as many spaces as needed.
		$nameline .= $heads->[$i] . (" " x ($column_sizes->[$i] - length($heads->[$i]))) . "|";
	}
	$nameline .= "\n";
	print $nameline;

	print $delimline;

	foreach my $content (@$contents) {
		my $contentline = "|";
		for(my $i = 0; $i < @$heads; ++$i) {
			$contentline .= $content->[$i] . (" " x ($column_sizes->[$i] - length($content->[$i]))) . "|";
		}
		$contentline .= "\n";
		print $contentline;
	}
	print $delimline;
}

1;
__END__

=head1 NAME

Term::Menu - Perl extension for asking questions and printing menus at the terminal 

=head1 SYNOPSIS

  use Term::Menu;
  my $prompt = new Term::Menu;
  my $answer = $prompt->menu(
  	foobar	=>	["Go the FooBar Way!", 'f'],
	barfoo	=>	["Or rather choose BarFoo!", 'b'],
	test	=>	["Or test the script out.", 't'],
	number  =>	["Choose this one if you only want to use numbers!", 0..9],
  );
  my $same_answer = $prompt->lastval;
  my $smallquestion = $prompt->question("What's your name? ");
  $prompt->table(
  	['id', 'name'],
	[[1, "Perl"], [2, "Ruby"], [3, "C++"], [4, "C"]]
  );

=head1 DESCRIPTION

Term::Menu is a highly tweakable module that eases the task of programming
user interactivity. It helps you to get information from users, and to ask
what they really want. It uses basic print commands, and has no
dependancies (But you might want to install the optional Test::Expect
for the test cases). 

=head2 Sample output

For example, if we have this script:

  use Term::Menu;
  my $menu = new Term::Menu;
  my $answer = $menu->menu(
  	Foo    => ["Bar", 'a'],
  );
  if(defined($answer)) {
  	print "Answer was $answer\n";
  } else {
  	print "Answer was undefined\n";
  }

If we run it, we get this:

  Please choose one of the following options.
        a) Bar
  Please enter a letter or number corresponding to the option you want to choose: 

You see that there's just one option, named "Bar". (Look at the code if you want to know why.)
Now we press an a, and enter. We get:

  Answer was Foo

Which was the key we gave to the menu. 
Now we rerun the program, and now we enter a 'b', to test (or tease) the module. We get:

  That's not one of the available options.
  You've tried too many times.
  Answer was undefined

(See the next paragraph for more information on tweaking the module, including a way to give the user more tries)

As you see, you give a hash to ->menu. The key is the string you will get back,
and the value is an arrayref; in this arrayref, the first value is the label,
and all other values are the possible keys. (In practice, this hash is secretly
an array so that the values appear in the order given. If you want to guarantee
this yourself, make sure to either use hard-coded options or keep the list as
an array. In this array, all even numbered items are the keys, all odd numbered
items are the label and key references.)

=head2 Tweaking the module

You can give several arguments to the 'new' method (Or to the 'setcfg' method):

  delim			- The delimiter between the possible keys and the label
  				default: ") "
  spaces		- The number of spaces before the possible keys.
  				This may be set higher to keep the delimiters under each other, depending on the number
				of possible keys and the text between them (see moreoptions)
  				default: 7
  beforetext		- The text that's displayed before the options.
  				default: "Please choose one of the following options."
  aftertext		- The text that's displayed after the options.
  				default: "Please enter a letter or number corresponding to the option you want to choose: "
  nooptiontext		- The text that's displayed when the user tries to enter an option that's not in the list.
				default: "That's not one of the available options."
  moreoptions		- If more possible options are given, this is between all possible options.
				default: " or "
  tries			- The number of tries the user has to enter a possible option, before the module decides
  				to print a message (see toomanytries) and return undef. A value of 0 means unlimited.
				default: 0
  toomanytries		- The message that ->menu outputs when the user tried to give a non-existing option 
  				too much times. (see tries) 
  				default: "You've tried too many times."
  hidekeys		- Wether to hide or show the possible keys and delimiter.

=head2 About multiple options, 'spaces' and 'moreoptions'

Term::Menu will always try to keep the delimiters under each other, to keep things clear and overseeable. It may adjust the 'spaces' setting, eventhough you've set it. See this program, for example:

  use Term::Menu;
  my $menu = new Term::Menu (
          spaces  =>      5,
  );
  my $answer = $menu->menu(
          Foo     => ["Bar", 'a', 'b', 'c', 'd'],
          Bar     => ["Foo", 'e'],
  );
  if(defined($answer)) {
          print "Answer was $answer\n";
  } else {
          print "Answer was undefined\n";
  }

As you see, the option labeled "Bar" has four answer options, 'a', 'b', 'c' and 'd'. Spaces is set to 5.
You would expect the following menu:

  Please choose one of the following options.
       e) Foo
  a or b or c or d) Bar
  Please enter a letter or number corresponding to the option you want to choose: 

As you see, this is ugly not very clear. Especially, if your program grows and more options come available, this will greatly decrease overseeability. The second option, labeled "Bar", has 4 different options, and moreoptions is by default set to " or ". This gives the option string of "a or b or c or d", as you can see. The length of that string is 16, so 'spaces' is set to 16, and the option labeled "Foo" gets 15 spaces (16 minus the length of Foo's optionstring, 1) in front of it, which produces the following more overseeable menu:

  Please choose one of the following options.
                 e) Foo
  a or b or c or d) Bar
  Please enter a letter or number corresponding to the option you want to choose: 

If you want to prevent this from happening, you have to set 'hidekeys' to 1, and include the option in the label itself, as in this program:

  use Term::Menu;
  my $menu = new Term::Menu (
          spaces   =>     5,
          hidekeys =>     1,
  );
  my $answer = $menu->menu(
          Foo     => ["a, b, c or d: Bar", 'a', 'b', 'c', 'd'],
          Bar     => ["e: Foo", 'e'],
  );
  if(defined($answer)) {
          print "Answer was $answer\n";
  } else {
          print "Answer was undefined\n";
  }

This will produce the following output:

  Please choose one of the following options.
      e: Foo
  a, b, c or d: Bar
  Please enter a letter or number corresponding to the option you want to choose: 

This is only possible from version 0.04, as version 0.03 had a bug that it still changed the 'spaces' option, eventhough 'hidekeys' was set to 1.   

=head2 Printing tables

Tables is an added feature since Term::Menu 0.09. It allows you to print a nicely formatted menu based on a
list of array references.

For example, see this script:

  Term::Menu->table(
  	[qw(id name mark OK)],
	[
		[qw(1 dazjorz A yes)],
		[qw(2 f00li5h A yes)],
		[qw(3 buu B yes)],
		[qw(4 rindolf C no)],
	]);

This will give the following output:

   +--+-------+----+---+
   |id|name   |mark|OK |
   +--+-------+----+---+
   |1 |dazjorz|A   |yes|
   |2 |f00li5h|A   |yes|
   |3 |buu    |B   |yes|
   |4 |rindolf|C   |no |
   +--+-------+----+---+

=head1 AUTHOR

Sjors Gielen, E<lt>cpan-termmenu@sjor.sgE<gt>

Special thanks to Kevin Montuori, Stephen Davies, Jeffrey D Johnson irc.freenode.org #perl for giving
hints or fixing bugs.

=head1 COPYRIGHT AND LICENSE

This module is released under the same license as the perl 5.8.4 distribution.

Copyright (C) 2006-2014 by Sjors Gielen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

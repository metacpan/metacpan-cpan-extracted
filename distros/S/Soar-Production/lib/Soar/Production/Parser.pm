#
# This file is part of Soar-Production
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Soar::Production::Parser;
# ABSTRACT: Parse Soar productions

use strict;
use warnings;
#needed for advanced regex expressions
use 5.010;

our $VERSION = '0.03'; # VERSION
use Exporter::Easy (
	OK => [qw(no_comment)]
);
use Soar::Production::Parser::PRDGrammar;
use Parse::RecDescent;
use Carp;
use Data::Dumper;



#a regular expression to split text into productions
my $splitter = qr/
	(sp\s+				#start with 'sp'
	\{					#opening brace
	  (					#save to $2
		 (?: 			#either
			\{ (?-1) \}	#more braces and recurse
			|			#or
			(?:			#group
				[^|{}]++	#not bar or braces
				|   		#or
				\| 			#a bar
				(?:			#group
					[^\\|]++	#no slashes or bars, no backtracking
					|			#or
					\\.			#slash anything
				)*+
				\|
			)++				#one or more, no backtracking
		 )*				#0 or more times
	  )					#end $2
	\}					#ending brace
	)					#end $1
/x;

__PACKAGE__->new->_run(shift) unless caller;

sub _run {
  my ($soarParser, $filePath) = @_;
  print Dumper($soarParser->productions(file => $filePath, parse => 1) );
  return;
}


sub new {
  my ($class) = @_;
  my $soarParser = bless {}, $class;
  $soarParser->_init;
  return $soarParser;
}

sub _init {
  my ($soarParser) = @_;
    $soarParser->{parser} = Parse::RecDescent->new($Soar::Production::Parser::PRDGrammar::GRAMMAR);

	#if you wish to debug the grammar, try turning on traces by uncommenting the following lines:
	# $::RD_TRACE = 1;
	# $::RD_HINT = 1;
	return;
}


sub productions {## no critic RequireArgUnpacking
    my ($soarParser) = shift;
	my %args = (
		parse	=> 0,
		text	=> undef,
		file	=> undef,
		@_
	);
	defined $args{text} or defined $args{file}
		or croak 'Must specify parameter \'file\' or \'text\' to extract productions.';

	if($args{text}){
		return $soarParser->_productions_from_text($args{text}, $args{parse});
	}
	if($args{file}){
		# print "$args{file}\n";
		return $soarParser->_productions_from_file($args{file}, $args{parse});
	}
}

sub _productions_from_text {
    my ( $soarParser, $text, $parse) = @_;

	#remove comments
	$text = no_comment($text);
	my $productions = _split_text(\$text);
	return $productions
		unless($parse);

	return $soarParser->get_parses($productions);
}

sub _productions_from_file {
    my ( $soarParser, $file, $parse) = @_;
    my $text = _readFile($file);

	my $productions = _split_text($text);
	return $productions
		unless($parse);

	return $soarParser->get_parses($productions);
}

#split text reference into production
sub _split_text {
	my ($text) = @_;
	#split the text into productions by looking for 'sp { ... }'
	my @productions;
	while($$text =~ /$splitter/g){
		# print "found production: $1";
		push @productions, $1;
	}
	return \@productions;
}


sub parse_text {
    my ( $soarParser, $text ) = @_;
    croak 'no text to parse!'
      unless defined $text;
    # $soarParser->{input} = \$text;
    return $soarParser->{parser}->parse($text);
}



sub get_parses {
	my ($soarParser, $productions) = @_;
	my @parses;
	for(@$productions){
		# print STDERR $_;
		push @parses, $soarParser->{parser}->parse($_);
	}
	return \@parses;
}

#argument should be an opened file handle
#returns string pointer to text
sub _readFile {
    my ($file) = @_;
    open my $fh, '<', $file
		or croak "Couldn't open $file";

    my $text = q();
    $text .= $_ while (<$fh>);

	close $fh;
	$text = no_comment($text);
    return \$text;
}


sub no_comment {
	my ($text) = @_;
	$text =~ s/
			(			#save in $1
				\|			#literal bar
				(?:			#group
					\\[|]		#an escaped bar
					|
					[^|]		#or anything but a literal bar
				)*		#zero or more of previous group
				\|			#literal bar
			)			#end $1
			|			#or
			(?:;\s*)?			# optional semicolon
			\#			# pound character
			.*			#followed by anything
		/			#replace with
			$1||''	# $1 or nothing (the quote if there was one;
					# no quote will simply remove matching comment)
		/xeg;
	return $text;
}
1;

__END__

=pod

=head1 NAME

Soar::Production::Parser - Parse Soar productions

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Soar::Production::Parser;
  use Data::Dumper;
  my $parser = Soar::Production::Parser->new;
  my @trees=$parser->parse_file("foo.soar");
  print Dumper(\@trees);

=head1 DESCRIPTION

Soar is a cognitive modeling architecture for programming and experimenting with intelligent agents. Soar is programmed using productions that look like this:

	sp{name
		(state <s>)
		-->
		(<s> ^foo bar)
	}

The preceding production matches any state and adds an element named "foo" with the value "bar" to it. Productions can get much more complicated than that.
This module can be used to parse these productions. Underlyingly, a Parse::RecDescent grammar is used to convert a production into a parse tree.
There are also methods for extracting all of the productions from a file string, and to remove comments (not that I think you'll ever want to do that!).

=head1 NAME

Soar::Production::Parser - Perl extension for parsing angst grammar files

=head1 METHODS

=head2 C<new>

Creates a new parser.

=head2 C<productions>

This method extracts productions from a given text. It returns a reference to an array containing either the text of each of the productions, or a parse tree for each of them. Note that all comments are removed as a preprocessing step to detecting and extracting productions. It takes a set of named arguments:
'file'- the name of a file to read.
'text'- the text to split.
'parse'- set to true if the return value should be an array of parse trees for the extracted productions; otherwise an array containing the production text will be returned.
For example, if you would like to extract all of the productions from a file and print their parse trees, you could do this:

    use Soar::Production::Parser;
	use Data::Dumper;

	my $file = shift;
	my $parser = Soar::Production::Parser->new();
	my $parses = $parser->productions(
		file => $file,
		parse => 1
	);

	for my $prod(@$productions){
		print Dumper($prod);
	}

=head2 C<parse_text>

Argument: the text of a single Soar production.
Returns: a parse tree for the given production.

=head2 C<get_parses>

Argument: Reference to array containing text for individual productions.
Return: Reference to an array containing parse trees for each of the productions in the input array reference.

=head1 EXPORTED FUNCTIONS

The following functions are available for export:

=head2 C<no_comment>

Argument: Text which contains Soar productions or commands
Return: Same text, but with all comments removed. Comments are indicated with a # (pound), optionally preceded by a ; (semicolon) and whitespace.

=head1 SEE ALSO

The documentation for Soar is located at L<https://code.google.com/p/soar/>.
You may also be interested in what a production system is, since this module parses Soar productions: L<http://en.wikipedia.org/wiki/Production_system>.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

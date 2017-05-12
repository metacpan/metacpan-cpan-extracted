package Parse::Yapp::KeyValue;

use strict;
use warnings;

our $VERSION = 0.10;

=head1 NAME

Parse::Yapp::KeyValue - parser for simple key/value pairs

=head1 DESCRIPTION

parse a string of simple key/value pairs and
store the results in a hash reference for easy
access.  Parse::KeyValue correctly handles
escaped quotes as well as escaped backslashes.

Parse::KeyValue will parse the following example
string:

     AL=53 AK=54 AB=55 TN="home sweet home" =$

into a hashref with the following contents:

     {
         ''   => '$',
         'AL' => '53',
         'TN' => 'home sweet home',
         'AK' => '54',
         'AB' => '55'
     }

multiple identical keys are treated as arrays.
the string

     A=1 A=2 A=3

will return a hash reference with the following
contents:

     { A => [ 1, 2, 3 ] }

tokens without an associated key name will be
treated as pairs with an empty string for the
key.  the string

     yeah alabama "crimson tide"

will return a hash reference with the following
contents:

     { '' => [ 'yeah', 'alabama', 'crimson tide' ] }

=head1 SYNOPSIS

 my $str  = 'A=1 K=2 B=3 A=4';
 my $kv   = new Parse::Yapp::KeyValue;
 my $href = $kv->parse($str);

 print $href ? Dumper $href : "parse failed\n";

=head1 TODO

 - configurable delimiter
 - flags to alter behavior in the event of
   multiple keys (error, overwrite last value,
   keep first value)
 - flag to require ALL values be inside an array
   reference, not just keys with multiple values

=cut

use Parse::Yapp::KeyValue::Parser;
use Parse::Lex;

my @lex =
(
	OP_ASSIGNMENT	=> '=',
	KEY				=> '[A-Za-z0-9]+',
	TEXT_Q_SINGLE	=> '\'[^\']+\'',
	TEXT_Q_DOUBLE	=> '"[^"]+"',
	TEXT_NONQUOTED	=> '[^\'" 	]+',
);

=head1 METHODS

=over 4

=item new

instantiates a new Parse::Yapp::KeyValue object.
no arguments are currently accepted.

=cut

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;

	return bless {}, $class;
}

=item parse

parses the supplied string and returns a hash
reference containing the parsed data.  in the
even that parsing fails, undef is returned.

=cut

sub parse
{
	my $self	= shift;
	my $str		= shift;

	# handle escaped quotes and escaped backslashes
	# this is just wrong, but it's quick and easy

	$str =~ s/\\\\/\x01/g;
	$str =~ s/\\'/\x02/g;
	$str =~ s/\\"/\x03/g;

	my $lexer = new Parse::Lex @lex;
	$lexer->from($str);

	my $parser = Parse::Yapp::KeyValue::Parser->new;
	$parser->YYData->{lexer} = $lexer;
	$parser->YYData->{DATA} = {};

	$parser->YYParse
	(
		yylex => sub
		{
			$_[0]->YYData->{ERR} = 0;
			my $lexer = $_[0]->YYData->{lexer};
			return ('', undef) if $lexer->eoi;
			my $token = $lexer->next;
			return $token->name, $token->text;
		},
		yyerror => sub
		{
			$_[0]->YYData->{ERR} = 1;
		}
	);

	return $parser->YYData->{ERR} == 1 ? undef : $parser->YYData->{DATA};
}

=back

=head1 AUTHOR

mike eldridge <diz@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

package Plucene::Analysis::Token;

=head1 NAME

Plucene::Analysis::Token - A term in a field

=head1 SYNOPSIS

=head1 DESCRIPTION

A Token is an occurence of a term from the text of a field.  It consists of
a term's text, the start and end offset of the term in the text of the field,
and a type string.

The start and end offsets permit applications to re-associate a token with
its source text, e.g., to display highlighted query terms in a document
browser, or to show matching text fragments in a KWIC (KeyWord In Context)
display, etc.

The type is an interned string, assigned by a lexical analyzer
(a.k.a. tokenizer), naming the lexical or syntactic class that the token
belongs to.  For example an end of sentence marker token might be implemented
with type "eos".  The default token type is "word".

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw[type text start end]);

=head2 new

	my $token = Plucene::Analysis::Token->new({
		type  => $type,
		text  => $text,
		start => $start,
		end   => $end });

This will create a new Plucene::Analysis::Token object.
		
=cut

sub new {
	my ($class, %args) = @_;
	$args{type} ||= "word";
	$class->SUPER::new({%args});
}

1;

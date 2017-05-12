package Plucene::Analysis::CharTokenizer;

=head1 NAME 

Plucene::Analysis::CharTokenizer - base class for character tokenisers

=head1 SYNOPSIS

	# isa Plucene::Analysis::Tokenizer

	my $next = $chartokenizer->next;
	
=head1 DESCRIPTION

This is an abstract base class for simple, character-oriented tokenizers.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

use Plucene::Analysis::Token;

use base 'Plucene::Analysis::Tokenizer';

=head2 token_re

This should be defined in subclasses.

=cut

# And here we deviate from the script
sub token_re { die "You should define this" }

# Class::Virtually::Abstract doesn't like being called twice.

=head2 normalize

This will normalise the character before it is added to the token.

=cut

sub normalize { return $_[1] }

=head2 next

	my $next = $chartokenizer->next;

This will return the next token in the string, or undef at the end 
of the string.
	
=cut

sub next {
	my $self = shift;
	my $re   = $self->token_re();
	my $fh   = $self->{reader};
	retry:
	if (!defined $self->{buffer} or !length $self->{buffer}) {
		return if eof($fh);
		$self->{start} = tell($fh);
		$self->{buffer} .= <$fh>;
	}
	return unless length $self->{buffer};

	if ($self->{buffer} =~ s/(.*?)($re)//) {
		$self->{start} += length $1;
		my $word = $self->normalize($2);
		my $rv   = Plucene::Analysis::Token->new(
			text  => $word,
			start => $self->{start},
			end   => ($self->{start} + length($word)));
		$self->{start} += length($word);
		return $rv;
	}

	# No match, rest of buffer is useless.
	$self->{buffer} = "";

	# But we should try for some more text
	goto retry;
}

1;

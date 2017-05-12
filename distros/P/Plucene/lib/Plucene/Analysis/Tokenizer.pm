package Plucene::Analysis::Tokenizer;

=head1 NAME 

Plucene::Analysis::Tokenizer - base class for tokenizers

=head1 SYNOPSIS

	my $tokenizer = Plucene::Analysis::Tokenizer::Subclass
		->new({ reader => $reader });

=head1 DESCRIPTION

This is an abstract base class for tokenizers.

A Tokenizer is a TokenStream whose input is a Reader.

=head1 METHODS

=head2 new

	my $tokenizer = Plucene::Analysis::Tokenizer::Subclass
		->new({ reader => $reader });

This will create a new tokenizer.

=cut

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw[ reader ]);

=head2 next

This must be defined in a subclass

=cut

sub next { die "next must define this in a subclass" }

=head2 close

Close the input reader.

=cut

sub close {
	my $self = shift;
	$self->{reader}->close if $self->{reader};
	return 1;
}

1;

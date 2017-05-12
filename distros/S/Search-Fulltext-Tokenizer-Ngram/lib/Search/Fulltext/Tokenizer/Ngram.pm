package Search::Fulltext::Tokenizer::Ngram;

# ABSTRACT: Character n-gram tokenizer for Search::Fulltext

use strict;
use warnings;
use Carp ();
use Scalar::Util qw/looks_like_number/;

our $VERSION = 0.01;

sub new {
  my ($class, $token_length) = @_;

  unless (looks_like_number $token_length and $token_length > 0) {
    Carp::croak('Token length must be 1+.');
  }

  bless +{ token_length => $token_length } => $class;
}

sub create_token_iterator {
  my ($self, $text) = @_;

  my $token_index = -1;
  my $n = $self->token_length;
  return sub {
  GET_NEXT_TOKEN:
    {
      ++$token_index;
      return if $token_index + $n > length($text);
      my $token = substr $text, $token_index, $n;
      redo GET_NEXT_TOKEN if $token =~ /\s/;
      return ($token, $n, $token_index, $token_index + $n, $token_index);
    }
  };
}

sub token_length { $_[0]->{token_length} }

1;

__END__

=pod

=head1 NAME

Search::Fulltext::Tokenizer::Ngram - Character n-gram tokenizer for Search::Fulltext

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use utf8;
  use Search::Fulltext;
  use Search::Fulltext::Tokenizer::Bigramm;
  
  my $searcher = Search::Fulltext->new(
      docs => [
          'ハンプティ・ダンプティ 塀の上',
          'ハンプティ・ダンプティ 落っこちた',
          '王様の馬みんなと 王様の家来みんなでも',
          'ハンプティを元に 戻せなかった',
      ],
      tokenizer => q/perl 'Search::Fulltext::Tokenizer::Bigram::get_tokenizer'/,
  );
  my $hit_document_ids = $searcher->search('ハンプティ');  # [0, 1, 3]

=head1 DESCRIPTION

This module provides character N-gram tokenizers for L<Search::Fulltext>.

By default {1,2,3}-gram tokenzers are available.

=head1 CREATING A N(> 3)-GRAM TOKENIZER

If you wish to use other N-grams where N > 3, you can create it by inheriting C<Search::Fulltext::Tokenizer::Ngram>:

  package My::Tokenizer::42gram;
  
  use parent qw/Search::Fulltext::Tokenizer::Ngram/;
  
  my $iterator_generator = __PACKAGE__->new(42);
  
  sub get_tokenizer {
      sub { $iterator_generator->create_token_iterator(@_) };
  }

=head1 SEE ALSO

L<Search::Fulltext::Tokenizer::Unigram>
L<Search::Fulltext::Tokenizer::Bigram>
L<Search::Fulltext::Tokenizer::Trigram>

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut

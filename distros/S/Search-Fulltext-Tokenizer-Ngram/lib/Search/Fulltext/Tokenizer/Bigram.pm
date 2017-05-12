package Search::Fulltext::Tokenizer::Bigram;

use parent qw/Search::Fulltext::Tokenizer::Ngram/;

sub get_tokenizer {
  sub { __PACKAGE__->new(2)->create_token_iterator(@_) };
}

1;

__END__

=pod

=head1 NAME

Search::Fulltext::Tokenizer::Bigram

=head1 VERSION

version 0.01

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut

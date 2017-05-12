package Pistachio::Token::Constructor::Perl5;
# ABSTRACT: provides text_to_tokens(), which turns source code text into an array of Pistachio::Tokens

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

use Pistachio::Keywords::Perl5 'is_keyword';
use Pistachio::Token;
use PPI::Tokenizer;

use Exporter 'import';
our @EXPORT_OK = 'text_to_tokens';

# @param scalarref    reference to text
# @return arrayref    Pistachio::Token array
sub text_to_tokens {
    my $ppi = PPI::Tokenizer->new(shift);

    my @tokens;
    while (my $token = $ppi->get_token) {
        (my $type = ref $token) =~ s/PPI::Token:://o;
        my $val = $token->{content};

        $type eq 'Word' and do {
            my $is = is_keyword $val;
            $type .= '::' . ($is ? 'Reserved' : 'Defined');
        };

        push @tokens, Pistachio::Token->new($type, $val);
    }
    \@tokens;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Token::Constructor::Perl5 - provides text_to_tokens(), which turns source code text into an array of Pistachio::Tokens

=head1 VERSION

version 0.10

=head1 SYNPOSIS

 use Pistachio::Token::Constructor::Perl5 'text_to_tokens';
 my $tokens = text_to_tokens(\"use strict; ...;");

 for my $token (@$tokens) {
     print $token->type, ': ', $token->value, "\n";
 }

=head1 NOTES

This module uses L<PPI::Tokenizer> to tokenize Perl5 source code.

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

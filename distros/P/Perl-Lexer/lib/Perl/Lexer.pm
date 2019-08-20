package Perl::Lexer;
use 5.010000;
use strict;
use warnings;
use B;

our $VERSION = "0.30";

use parent qw(Exporter);

our @EXPORT = qw(
    TOKENTYPE_NONE
    TOKENTYPE_IVAL
    TOKENTYPE_OPNUM
    TOKENTYPE_PVAL
    TOKENTYPE_OPVAL
);

use Perl::Lexer::Token;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my $class = shift;
    bless {}, $class;
}

sub scan_string {
    my ($self, $str) = @_;
    open my $fh, '<', \$str;
    $self->scan_fh($fh);
}

4649;
__END__

=for stopwords hackish yylval tokenize

=encoding utf-8

=head1 NAME

Perl::Lexer - Use Perl5 lexer as a library.

=head1 SYNOPSIS

    use v5.18.0;
    use Perl::Lexer;

    my $lexer = Perl::Lexer->new();
    my @tokens = @{$lexer->scan_string('1+2')};
    for (@tokens) {
        say $_->inspect;
    }

Output is:

    <Token: THING opval 1>
    <Token: ADDOP opnum 63>
    <Token: THING opval 2>

=head1 DESCRIPTION

B<THIS LIBRARY IS WRITTEN FOR RESEARCHING PERL5 LEXER API. THIS MODULE USES PERL5 INTERNAL API. DO NOT USE THIS.>

Perl::Lexer is a really hackish library for using Perl5 lexer as a library.

=head1 MOTIVATION

The programming language provides lexer library for itself is pretty nice.
I want to tokenize perl5 code by perl5.

Of course, this module uses Perl5's private APIs. I hope these APIs turn into public.

If we can use lexer, we can write a source code analysis related things like Test::MinimumVersion, and other things.

=head1 WHAT API IS NEEDED FOR WRITING MODULES LIKE THIS.

=over 4

=item Open the token informations for XS hackers.

Now, token name, type, and arguments informations are hidden at toke.c and perly.h.

I need to define `PERL_CORE` for use it... It's too bad.

And, I take token_type and debug_tokens from toke.c.

=back

=head1 METHODS

=over 4

=item my $lexer = Perl::Lexer->new();

Create new Perl::Lexer object.

=item $lexer->scan_string($code: Str) : ArrayRef[Str]

Tokenize perl5 code. This method returns arrayref of Perl::Lexer::Token.

=back

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut


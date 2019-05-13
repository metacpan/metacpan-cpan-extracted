package Syntax::Keyword::RawQuote;

use 5.012;

use strict;
use warnings;
use XSLoader;

BEGIN {
  our $VERSION = '0.04';
  our $AUTHORITY = 'cpan:ARODLAND';
  XSLoader::load(__PACKAGE__);
}

sub import {
  my ($class, %args) = @_;

  my $keyword = $args{"-as"} || "r";
  $^H{+HINTK_KEYWORDS} .= ",$keyword";
}

sub uninstall {
  my ($class, %args) = @_;
  if ($args{"-as"}) {
    $^H{+HINTK_KEYWORDS} =~ s/,\Q$args{"-as"}\E//;
  } else {
    $^H{+HINTK_KEYWORDS} = "";
  }
}

1;

__END__

=head1 NAME

Syntax::Keyword::RawQuote - A raw quote operator for Perl

=head1 SYNOPSIS

    use Syntax::Keyword::RawQuote;
    say r`I keep all of my files in \\yourserver\private`;

    use Syntax::Keyword::RawQuote -as => "qraw";
    say qraw[Maybe the `r` keyword is too risky?];

=head1 DESCRIPTION

This library provides an absolutely uninterpreted (raw) quote operator for
Perl, as seen in some other programming languages. While Perl single-quoted
strings are nearly uninterpreted, they still treat the sequences C<\'> and
C<\\> specially, allowing a single quote to be included in the string.
The C<q> operator behaves similarly, allowing the closing delimiter to be
backslashed, and treating C<\\> as a single backslash. By contrast, a raw
string treats I<every> character literally, and ends at the first occurrence of
the closing delimiter, no matter what.

=head1 WARNING

This is beta software that mucks about with the perl internals. Do not use
it for anything too important.

=head1 SYNTAX

By default, the raw quote operator will be installed as C<r> in the lexical
scope where this module is imported. If that name is inconvenient, you can
choose another one by providing the C<-as> option in the C<use> statement.

The operator behaves like other quote-like operators (see
L<perlop/Quote and Quote-like Operators>). The first non-whitespace character
after the operator is taken as the opening delimiter. If the opening
delimiter is one of the ASCII left bracket characters (one of C<< ( [ < { >>),
then the closing delimiter is the matching right bracket (from
C<< ) ] > } >>), otherwise it is the same as the opening delimiter. This
choice of delimiters allows you to choose a character that won't appear
inside the string.

Since editors' syntax highlighting features will probably not recognize the
existence of this module, you may want to use an existing quote character to
avoid confusing them. C<r""> and C<r''> are obvious choices, but C<r``>
(similar to Go) has the advantage that backticks hardly ever occur inside of
quoted strings, and it is visually distinct.

=head1 METHODS

=head2 import

Enables the raw quote keyword in the current lexical scope when called during
compilation (C<use Syntax::Keyword::RawQuote>). If the C<-as> keyword argument
is provided, it will be used as the keyword name, otherwise C<"r"> is used.

=head2 unimport

Disables the raw quote keyword in the current lexical scope when called
during compilation (C<no Syntax::Keyword::RawQuote>). If the C<-as> keyword is
provided, disables that keyword specifically; otherwise, all keywords
installed will be disabled.

=head1 syntax.pm SUPPORT

A module L<Syntax::Feature::RawQuote> is also provided, if you prefer the
form C<use syntax 'raw_quote'>. Provides all of the same features and
options, except that it is not possible to
C<< no syntax raw_quote => { -as => 'foo' } >>.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 LICENSE

Copyright (c) Andrew Rodland.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

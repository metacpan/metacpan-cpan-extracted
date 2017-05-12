package Parse::Keyword;
use strict;
use warnings;
use 5.014;
# ABSTRACT: DEPRECATED: write syntax extensions in perl

our $VERSION = '0.09';

use Devel::CallParser;
use XSLoader;

XSLoader::load(
    __PACKAGE__,
    exists $Parse::Keyword::{VERSION} ? ${ $Parse::Keyword::{VERSION} } : (),
);



sub import {
    my $package = shift;
    my ($keywords) = @_;

    my $caller = caller;

    for my $keyword (keys %$keywords) {
        my $sub = do {
            no strict 'refs';
            \&{ $caller . '::' . $keyword };
        };
        install_keyword_handler($sub, $keywords->{$keyword});
    }

    my @helpers = qw(
        lex_peek
        lex_read
        lex_read_space
        lex_stuff
        parse_block
        parse_stmtseq
        parse_fullstmt
        parse_barestmt
        parse_fullexpr
        parse_listexpr
        parse_termexpr
        parse_arithexpr
        compiling_package
    );

    for my $helper (@helpers) {
        no strict 'refs';
        *{ $caller . '::' . $helper } = \&{ __PACKAGE__ . '::' . $helper };
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Keyword - DEPRECATED: write syntax extensions in perl

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use Parse::Keyword { try => \&try_parser };
  use Exporter 'import';
  our @EXPORT = 'try';

  sub try {
      my ($try, $catch) = @_;
      &Try::Tiny::try($try, ($catch ? (&Try::Tiny::catch($catch)) : ()));
  }

  sub try_parser {
      lex_read_space;
      die "syntax error" unless lex_peek eq '{';
      my $try = parse_block;
      lex_read_space;

      my $catch;
      if (lex_peek(6) =~ /^catch\b/) {
          lex_read(5);
          lex_read_space;
          die "syntax error" unless lex_peek eq '{';
          $catch = parse_block;
      }

      return (sub { ($try, $catch) }, 1);
  }

=head1 DESCRIPTION

=head2 DO NOT USE!

This module has fundamental errors in the way it handles closures, which are
not fixable. Runtime keywords will never be able to work properly with the
current design of this module. There are certain cases where this module is
still safe to use (keywords that only have effect at compile time, or keywords
that never call any of the C<parse_*> functions), but that is limiting enough
to make this module mostly worthless, and I likely won't be continuing to
maintain it. Be warned!

B<< NOTE: The API of this module is still in flux. I may make
backwards-incompatible changes as I figure out how it should look. >>

This module allows you to write keyword-based syntax extensions without
requiring you to write any C code yourself. It is similar to L<Devel::Declare>,
except that it uses the Perl parser API introduced in Perl 5.14 in order to
allow you to parse parts of things using perl's own parser, rather than having
to fake it with balanced brace matching or other fragile things.

To use this module, you should pass a hashref to the C<use> statement. The keys
of this hashref are subroutines in the current package which should have
special parsing behavior attached to them, and the values are coderefs which
should be used to implement the custom parsing behavior.

The parsing coderefs will be called when perl encounters a call to the keyword
that you attached custom parsing to. The current parser state will be directly
after parsing the keyword. The parser function will receive the name of the
keyword as a parameter, and should return a coderef which, when called at
runtime, will produce the arguments to the function. In addition, if your
keyword should be parsed as a statement (for instance, if you don't want to
require a trailing semicolon), you can return a second, true value.

In order to actually handle the parsing itself, this module also exports
various parsing functions, which you can call. See below for details.

=head1 FUNCTIONS

=head2 lex_peek($n)

Returns a string consisting of the next C<$n> characters in the input (or next
one character, if C<$n> isn't given). This string may be shorter than C<$n>
characters if there are fewer than C<$n> characters remaining to read. The
current position in the buffer to be parsed is not moved. See L<<
perlapi/PL_parser->linestr >> and L<perlapi/lex_next_chunk> for more
information.

NOTE: This function currently only returns text that is on the current line,
unless the current line has been fully read (via C<lex_read>). This is due to a
bug in perl itself, and this restriction will hopefully be lifted in a future
version of this module, so don't depend on it. See the L</BUGS> section for
more information.

=head2 lex_read($n)

Moves the current position in the parsing buffer forward by C<$n> characters
(or one character, if C<$n> isn't given). See L<perlapi/lex_read_to> for more
details.

=head2 lex_read_space

Moves the current position in the parsing buffer forward past any whitespace or
comments. See L<perlapi/lex_read_space> for more details.

=head2 lex_stuff($str)

Inserts C<$str> into the current parsing buffer at the current location, so
that future calls to C<lex_peek> and such will see it. Note that this does not
move the current position in the parsing buffer, so multiple calls to
C<lex_stuff> at the same location will end up inserted into the buffer in
reverse order. See L<perlapi/lex_stuff_sv> for more information.

=head2 parse_block, parse_stmtseq, parse_fullstmt, parse_barestmt,
parse_fullexpr, parse_listexpr, parse_termexpr, parse_arithexpr

These functions parse the specified amount of Perl code, and return a coderef
which will evaluate that code when executed. They each take an optional boolean
parameter that should be true if you are creating a subroutine which will be
going in the symbol table, or in other more obscure situations involving
closures (the CVf_ANON flag will be set on the created coderef if this is not
passed - see C<t/unavailable.t> in this distribution). See
L<perlapi/parse_block>, L<perlapi/parse_stmtseq>, L<perlapi/parse_fullstmt>,
L<perlapi/parse_barestmt>, L<perlapi/parse_fullexpr>, L<parse_listexpr>,
L<parse_termexpr>, and L<perlapi/parse_arithexpr> for more details.

=head2 compiling_package

Returns the name of the package that the keyword which is currently being
parsed was called in. This should be used instead of C<caller> if you want to
do something like install a subroutine in the calling package.

=head1 BUGS

Peeking into the next line is currently (as of 5.19.2) broken in perl if the
current line hasn't been fully consumed. This module works around this by just
not doing that. This shouldn't be an issue for the most part, since it will
only come up if you need to conditionally parse something based on a token that
can span multiple lines. Just keep in mind that if you're reading in a large
chunk of text, you'll need to alternate between calling C<lex_peek> and
C<lex_read>, or else you'll only be able to see text on the current line.

This module also inherits the limitation from L<Devel::CallParser> that custom
parsing is only triggered if the keyword is called by its unqualified name
(C<try>, not C<Try::try>, for instance).

This module doesn't yet work with lexical subs, such as via
L<Exporter::Lexical>. This will hopefully be fixed in the future, but will
likely require modifications to perl.

=head1 SEE ALSO

L<Devel::CallParser>

L<Keyword::API>

L<Devel::Declare>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Parse::Keyword

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Parse-Keyword>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Keyword>

=item * Github

L<https://github.com/haarg/Parse-Keyword>

=back

=for Pod::Coverage   install_keyword_handler

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

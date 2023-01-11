package Quote::Code;

use v5.14.0;
use warnings;

use Carp qw(croak);

use XSLoader;
BEGIN {
    our $VERSION = '1.0103';
    XSLoader::load;
}

my %export = (
    qc    => HINTK_QC,
    qc_to => HINTK_QC_TO,
    qcw   => HINTK_QCW,
);

sub import {
    my $class = shift;

    my @todo;
    for my $item (@_) {
        push @todo, $export{$item} || croak qq{"$item" is not exported by the $class module};
    }
    for my $item (@todo ? @todo : values %export) {
        $^H{$item} = 1;
    }
}

sub unimport {
    my $class = shift;
    my @todo;
    for my $item (@_) {
        push @todo, $export{$item} || croak qq{"$item" is not exported by the $class module};
    }
    for my $item (@todo ? @todo : values %export) {
        delete $^H{$item};
    }
}

'ok'

__END__

=encoding UTF-8

=head1 NAME

Quote::Code - quoted strings with arbitrary code interpolation

=head1 SYNOPSIS

 use Quote::Code;
 print qc"2 + 2 = {2 + 2}";  # "2 + 2 is 4"
 my $msg = qc{The {$obj->name()} is {$obj->state()}.};
 
 my $heredoc = qc_to <<'EOT';
 .trigger:hover .message:after {
   content: "The #{get_adjective()} brown fox #{get_verb()} over the lazy dog.";
 }
 EOT
 print $heredoc;

 my $name = "A B C";
 my @words = qcw(
   foo
   bar\ baz
   {2 + 2}
   ({$name})
 );
 # @words = ("foo", "bar baz", "4", "(A B C)");

=head1 DESCRIPTION

This module provides the new keywords C<qc>, C<qc_to> and C<qcw>.

=head2 qc

C<qc> is a quoting operator like L<q or qq|perlop/Quote and Quote-like Operators>.
It works like C<q> in that it doesn't interpolate C<$foo> or C<@foo>, but like
C<qq> in that it recognizes backslash escapes such as C<\n>, C<\xff>,
C<\N{EURO SIGN}>, etc.

What it adds is the ability to embed arbitrary expressions in braces
(C<{...}>). This is both more readable and more efficient than the old C<"foo
@{[bar]}"> L<trick|perlfaq4/How do I expand function calls in a string?>. All
embedded code runs in scalar context.

If you need a literal C<{> in a C<qc> string, you can escape it with a backslash
(C<\{>) or interpolate code that yields a left brace (C<{'{'}>).

=head2 qc_to

For longer strings you can use C<qc_to>, which provides a
L<heredoc-like|perlop/<<I<EOF>> syntax. The main difference between C<qc> and
C<qc_to> is that C<qc_to> uses the Ruby-like C<#{ ... }> to interpolate code
(not C<{ ... }>). This is because C<{ }> are more common in longer texts and
escaping them gets annoying.

C<qc_to> has two syntactic forms:

 qc_to <<'FOO'
 ...
 FOO

and

 qc_to <<"FOO"
 ...
 FOO

After C<qc_to> there must always be a C<E<lt>E<lt>> (this is to give syntax
highlighters a chance to get things right). After that, there are two
possibilities:

=over

=item *

An identifier in single quotes. Backslash isn't treated specially in the
string. To embed a literal C<#{>, you need to write C<#{'#{'}>.

=item *

An identifier in double quotes. Backslash escapes are recognized. You can
escape C<#{> by writing either C<\#{> or C<#\{>.

=back

Variables aren't interpolated in either case.

=head2 qcw

C<qcw> is analogous to L<C<qw>|perlop/C<qw/I<STRING>/>>. It quotes a list of
strings with code interpolation (C<{ ... }>) like C<qc>.

Differences between C<qcw> and C<qw>:

=over

=item *

C<{ ... }> sequences are interpreted as expressions to be interpolated in the
current word. The result of C<{ ... }> is not scanned for spaces or split.

=item *

Backslash escape sequences such as C<\n>, C<\xff>, C<\cA> etc. are recognized.

=item *

Spaces can be escaped with a backslash to prevent word splitting:
C<qcw(a b\ c d)> is equivalent to C<('a', 'b c', 'd')>.

=back

=head2 Backslash escape sequences

C<qc>, C<qcw>, and C<<< qc_to <<"..." >>> support the following backslash
escape sequences:

 \\         backslash
 \a         alarm/bell       (BEL)
 \b         backspace        (BS)
 \e         escape           (ESC)
 \f         form feed        (FF)
 \n         newline          (LF)
 \r         carriage return  (CR)
 \t         tab              (HT)

 \cX        control-X
            X can be any character from the set
              ?, @, a-z, A-Z, [, \, ], ^, _

 \o{FOO}    the character whose octal code is FOO
 \FOO       the character whose octal code is FOO
            (where FOO is at most 3 octal digits long)

 \x{FOO}    the character whose hexadecimal code is FOO
 \xFOO      the character whose hexadecimal code is FOO
            (where FOO is at most 2 hexadecimal digits long)
 \x         a NUL byte (if \x is not followed by '{' or a hex digit)
            (don't use this, it might go away in a future release)

 \N{U+FOO}  the character whose hexadecimal code is FOO
 \N{FOO}    the character whose Unicode name is FOO
            (as determined by the charnames pragma)

Any other backslashed character (including delimiters) is taken literally. In
particular this means e.g. both C<qc!a\!b!> and C<qc(a\!b)> represent the
three-character string C<"a!b">.

The following are explicitly B<not supported>: C<\Q>, C<\L>, C<\l>, C<\U>,
C<\u>, C<\F>, C<\E>.

Starting with perl v5.16, if you specify a named Unicode character with
C<\N{...}> and L<C<charnames>|charnames> hasn't been loaded yet, it is
automatically loaded as if by C<use charnames ':full', ':short';>.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

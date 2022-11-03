package Regexp::From::String;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-03'; # DATE
our $DIST = 'Regexp-From-String'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(str_maybe_to_re str_to_re);

sub str_maybe_to_re {
    my $str = shift;
    if ($str =~ m!\A(?:/.*/|qr\(.*\))(?:[ims]*)\z!s) {
        my $re = eval(substr($str, 0, 2) eq 'qr' ? $str : "qr$str"); ## no critic: BuiltinFunctions::ProhibitStringyEval
        die if $@;
        return $re;
    }
    $str;
}

sub str_to_re {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $str = shift;
    if (!$opts->{always_quote} && $str =~ m!\A(?:/.*/|qr\(.*\))(?:[ims]*)\z!s) {
        my $re = eval(substr($str, 0, 2) eq 'qr' ? $str : "qr$str"); ## no critic: BuiltinFunctions::ProhibitStringyEval
        die if $@;
        return $re;
    } else {
        $str = quotemeta($str);
        if ($opts->{anchored}) {
            if ($opts->{case_insensitive}) { return qr/\A$str\z/i } else { return qr/\A$str\z/ }
        } else {
            if ($opts->{case_insensitive}) { return qr/$str/i     } else { return qr/$str/     }
        }
    }
    $str;
}

1;
# ABSTRACT: Convert '/.../' or 'qr(...)' into Regexp object

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::From::String - Convert '/.../' or 'qr(...)' into Regexp object

=head1 VERSION

This document describes version 0.004 of Regexp::From::String (from Perl distribution Regexp-From-String), released on 2022-11-03.

=head1 SYNOPSIS

 use Regexp::From::String qw(str_maybe_to_re str_to_re);

 my $re1 = str_maybe_to_re('foo.');       # stays as string 'foo.'
 my $re2 = str_maybe_to_re('/foo.');      # stays as string '/foo.'
 my $re3 = str_maybe_to_re('/foo./');     # compiled to Regexp object qr(foo.) (metacharacters are allowed)
 my $re4 = str_maybe_to_re('qr(foo.)i');  # compiled to Regexp object qr(foo.)i
 my $re5 = str_maybe_to_re('qr(foo[)i');  # dies, invalid regex syntax

 my $re1 = str_to_re('foo.');       # compiled to Regexp object qr(foo\.) (metacharacters are quoted)
 my $re2 = str_to_re('/foo.');      # compiled to Regexp object qr(/foo\.)
 my $re2 = str_to_re({case_insensitive=>1}, 'foo.');    # compiled to Regexp object qr(foo\.)i
 my $re2 = str_to_re({anchored=>1}, 'foo.');            # compiled to Regexp object qr(\Afoo\.\z)
 my $re3 = str_to_re('/foo./');     # compiled to Regexp object qr(foo) (metacharacters are allowed)
 my $re4 = str_to_re('qr(foo.)i');  # compiled to Regexp object qr(foo.)i
 my $re4 = str_to_re({always_quote=>1}, 'qr(foo.)');  # compiled to Regexp object qr(qr\(foo\.\)) (metacharacters are quoted)
 my $re5 = str_to_re('qr(foo[)i');  # dies, invalid regex syntax

=head1 FUNCTIONS

=head2 str_maybe_to_re

Maybe convert string to Regexp object.

Usage:

 $str_or_re = str_maybe_to_re($str);

Check if string C<$str> is in the form of C</.../> or C<qr(...)'> and if so,
compile the inside regex (currently simply using stringy C<eval>) and return the
resulting Regexp object. Otherwise, will simply return the argument unmodified.

Will die if compilation fails, e.g. when the regexp syntax is invalid.

For the C<qr(...)> form, unlike in Perl, currently only the C<()> delimiter
characters are recognized and not others.

Optional modifiers C<i>, C<m>, and C<s> are currently allowed at the end.

=head2 str_to_re

Convert string to Regexp object.

Usage:

 $str_or_re = str_to_re([ \%opts , ] $str);

This function is similar to L</str_maybe_to_re> except that when string is not
in the form of C</.../> or C<qr(...)>, the string is C<quotemeta()>'ed then
converted to a Regexp object anyway. There are some options available to specify
in first argument hashref C<\%opts>:

=over

=item * always_quote

Bool. Default false. If set to true, will always C<quotemeta()> regardless of
whether the string is in the form of C</.../> or C<qr(...)> or not. This means
user will not be able to use metacharacters and the Regexp will only match the
literal string (with some option like anchoring and case-sensitivity, see other
options).

Defaults to false because the point of this function is to allow specifying
regex.

=item * case_insensitive

Bool. If set to true will compile to Regexp object with C<i> regexp modifier.

=item * anchored

Bool. If set to true will anchor the pattern with C<\A> and C<\z>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-From-String>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-From-String>.

=head1 SEE ALSO

L<Sah::Schema::str_or_re>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-From-String>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

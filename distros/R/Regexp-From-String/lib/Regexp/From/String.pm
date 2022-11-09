package Regexp::From::String;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-08'; # DATE
our $DIST = 'Regexp-From-String'; # DIST
our $VERSION = '0.007'; # VERSION

our @EXPORT_OK = qw(str_maybe_to_re str_to_re);

sub _str_maybe_to_re_or_to_re {
    my $which = shift;

    my $opts = ref $_[0] eq 'HASH' ? {%{shift()}} : {};
    my $opt_ci1 = delete($opts->{ci});
    my $opt_ci2 = delete $opts->{case_insensitive}; # so we delete both ci & this. case_insensitive is deprecated and no longer documented.
    my $opt_ci  = defined $opt_ci1 ? $opt_ci1 : defined $opt_ci2 ? $opt_ci2 : 0;
    my $opt_always_quote = delete $opts->{always_quote};
    my $opt_anchored = delete $opts->{anchored}; $opt_anchored = 0 unless defined $opt_anchored;
    my $opt_safety = delete $opts->{safety}; $opt_safety = 1 unless defined $opt_safety;
    die "Unknown option(s): ".join(", ", sort keys %$opts) if keys %$opts;

    my $str = shift;

    if (!$opt_always_quote && $str =~ m!\A(?:/(.*)/|qr\((.*)\))(?:[ims]*)\z!s) {
        my ($pat1, $pat2) = ($1, $2);
        my $code = "my \$re = " . (substr($str, 0, 2) eq 'qr' ? $str : "qr$str");
        $code .= "i" if $opt_ci;
        $code .= "; \$re = qr(\\A\$re\\z)" if $opt_anchored;

        #print "D: $code\n";
        my $re;

        if ($opt_safety == 0) {
            $re = eval $code; ## no critic: BuiltinFunctions::ProhibitStringyEval
            die if $@;
        } elsif ($opt_safety == 2) {
            require Regexp::Util;
            $re = Regexp::Util::deserialize_regexp($code);
            die "$which(): Unsafe regex: contains embedded code"
                if Regexp::Util::regexp_seen_evals($re);
        } else {
            if (defined $pat1) {
                die "$which(): Unsafe regex: contains literal /" if $pat1 =~ m!/!;
            } else {
                die "$which(): Unsafe regex: contains literal )" if $pat2 =~ m!\)!;
            }
            my $pat = defined $pat1 ? $pat1 : $pat2;
            die "$which(): Unsafe regex: contains embedded code" if $pat =~ m!\(\?\??\{!;

            $re = eval $code; ## no critic: BuiltinFunctions::ProhibitStringyEval
            die if $@;
        }

        return $re;
    } else {
        return $str if $which eq 'str_maybe_to_re';

        $str = quotemeta($str);
        my $re = $opt_anchored ?
            ($opt_ci ? qr/\A$str\z/i : qr/\A$str\z/) :
            ($opt_ci ? qr/$str/i     : qr/$str/);
        return $re;
    }
}

sub str_maybe_to_re {
    _str_maybe_to_re_or_to_re('str_maybe_to_re', @_);
}

sub str_to_re {
    _str_maybe_to_re_or_to_re('str_to_re', @_);
}

1;
# ABSTRACT: Convert '/.../' or 'qr(...)' into Regexp object

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::From::String - Convert '/.../' or 'qr(...)' into Regexp object

=head1 VERSION

This document describes version 0.007 of Regexp::From::String (from Perl distribution Regexp-From-String), released on 2022-11-08.

=head1 SYNOPSIS

 use Regexp::From::String qw(str_maybe_to_re str_to_re);

 my $re1 = str_maybe_to_re('foo.');       # stays as string 'foo.'
 my $re2 = str_maybe_to_re('/foo.');      # stays as string '/foo.'
 my $re3 = str_maybe_to_re('/foo./');     # compiled to Regexp object qr(foo.) (metacharacters are allowed)
 my $re4 = str_maybe_to_re('qr(foo.)i');  # compiled to Regexp object qr(foo.)i
 my $re5 = str_maybe_to_re('qr(foo[)i');  # dies, invalid regex syntax

 my $re1 = str_to_re('foo.');       # compiled to Regexp object qr(foo\.) (metacharacters are quoted)
 my $re2 = str_to_re('/foo.');      # compiled to Regexp object qr(/foo\.)
 my $re2 = str_to_re({ci=>1}, 'foo.');        # compiled to Regexp object qr(foo\.)i
 my $re2 = str_to_re({anchored=>1}, 'foo.');  # compiled to Regexp object qr(\Afoo\.\z)
 my $re3 = str_to_re('/foo./');     # compiled to Regexp object qr(foo) (metacharacters are allowed)
 my $re4 = str_to_re('qr(foo.)i');  # compiled to Regexp object qr(foo.)i
 my $re4 = str_to_re({always_quote=>1}, 'qr(foo.)');  # compiled to Regexp object qr(qr\(foo\.\)s) (the whole string is quotemeta'ed)
 my $re5 = str_to_re('qr(foo[)i');  # dies, invalid regex syntax

=head1 FUNCTIONS

=head2 str_maybe_to_re

Maybe convert string to Regexp object.

Usage:

 $str_or_re = str_maybe_to_re([ \%opts , ] $str);

Check if string C<$str> is in the form of C</.../> or C<qr(...)'> and if so,
compile the inside regex (currently using stringy C<eval> or L<Safe>'s C<reval>)
and return the resulting Regexp object. Otherwise, will simply return the
argument unmodified.

Will die if compilation fails, e.g. when the regexp syntax is invalid.

For the C<qr(...)> form, unlike in Perl, currently only the C<()> delimiter
characters are recognized and not others.

Optional modifiers C<i>, C<m>, and C<s> are currently allowed at the end.

Recognize some options, see L</str_to_re> for more details.

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

Bool. Default is false. If set to true then will always quote the whole string
regardless of whether the string is in the form of C</.../> or C<qr(...)>. This
means user will not be able to use metacharacters and the Regexp will only match
the literal string (with some option like anchoring and case-sensitivity, see
other options).

Defaults to false because the main point of this function is to allow specifying
regex.

=item * ci

Bool, default is false.

If set to true will compile to regexp with the /i modifier, so matching is done
case-insensitively. This includes when the string is in the form of C</.../> or
C<qr(...)> (the /i is also added).

=item * anchored

Bool. If set to true will anchor the pattern with C<\A> and C<\z>. This includes
when the string is in the form of C</.../> or C<qr(...)> (the regexp will be
enclosed with anchor).

=item * safety

Int, default 1. Valid values include 0, 1, 2.

If set to 0, the compilation of string into regex will use stringy C<eval>. Note
that this is B<insecure> as it can be tricked to execute arbitrary Perl code by
strings like:

 qr() and unlink q(hello.txt) and qr()

If set to 1 (the default), compilation will use stringy C<eval> but these extra
restrictions are added: 1) pattern inside string of the form C</.../> is not
allowed to have literal C</> (to prevent one from getting out of the pattern);
2) pattern inside string of the form C<qr(...)> is not allowed to have literal
C<)> (to prevent one from getting out of the pattern); 3) pattern inside string
cannot contain literal C<(?{> or C<(??{> (to prevent specifying embedded code
inside regex pattern). These restrictions might be annoying in some cases.

If set to 2, compilation will use L<Regexp::Util>'s C<deserialize_regexp()>,
which in turn uses L<Safe>'s C<reval> to add some security. In addition to that,
a check using C<Regexp::Util>'s C<regexp_seen_evals()> to reject regex that
contains embedded Perl code. Note that C<Regexp::Util> is specified as a
Recommends prerequisite (optional dependency) so you will need to install it
manually or use L<cpanm>'s C<--with-recommends> option when installing this
distribution.

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

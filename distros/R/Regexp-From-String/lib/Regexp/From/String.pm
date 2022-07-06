package Regexp::From::String;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-05'; # DATE
our $DIST = 'Regexp-From-String'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(str_to_re);

sub str_to_re {
    my $str = shift;
    if ($str =~ m!\A(?:/.*/|qr\(.*\))(?:[ims]*)\z!s) {
        my $re = eval(substr($str, 0, 2) eq 'qr' ? $str : "qr$str"); ## no critic: BuiltinFunctions::ProhibitStringyEval
        die if $@;
        return $re;
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

This document describes version 0.001 of Regexp::From::String (from Perl distribution Regexp-From-String), released on 2022-07-05.

=head1 SYNOPSIS

 use Regexp::From::String qw(str_to_re);

 my $re1 = str_to_re('foo');       # stays as string 'foo'
 my $re2 = str_to_re('/foo');      # ditto
 my $re3 = str_to_re('/foo/');     # compiled to Regexp object qr(foo)
 my $re4 = str_to_re('qr(foo)i');  # compiled to Regexp object qr(foo)i
 my $re5 = str_to_re('qr(foo[)i'); # dies, invalid regex syntax

=head1 FUNCTIONS

=head2 str_to_re

Usage:

 $str_or_re = str_to_re($str);

Check if string C<$str> is in the form of C</.../> or C<qr(...)'> and if so,
compile the inside regex (currently simply using stringy C<eval>) and return the
resulting Regexp object. Otherwise, will simply return the argument unmodified.

Will die if compilation fails, e.g. when the regexp syntax is invalid.

For the C<qr(...)> form, unlike in Perl, currently only the C<()> delimiter
characters are recognized and not others.

Optional modifiers C<i>, C<m>, and C<s> are currently allowed at the end.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

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

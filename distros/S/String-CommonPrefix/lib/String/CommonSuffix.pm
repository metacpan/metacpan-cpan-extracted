package String::CommonSuffix;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-16'; # DATE
our $DIST = 'String-CommonPrefix'; # DIST
our $VERSION = '0.020'; # VERSION

use Exporter qw(import);

our @EXPORT_OK = qw(
                       common_suffix
               );

sub common_suffix {
    require List::Util;

    return undef unless @_; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    my $i;
  L1:
    for ($i = 0; $i < length($_[0]); $i++) {
        for (@_[1..$#_]) {
            if (length($_) < $i) {
                $i--; last L1;
            } else {
                last L1 if substr($_, -($i+1), 1) ne substr($_[0], -($i+1), 1);
            }
        }
    }
    $i ? substr($_[0], -$i) : "";
}

1;
# ABSTRACT: Return suffix common to all strings

__END__

=pod

=encoding UTF-8

=head1 NAME

String::CommonSuffix - Return suffix common to all strings

=head1 VERSION

This document describes version 0.020 of String::CommonSuffix (from Perl distribution String-CommonPrefix), released on 2024-05-16.

=head1 FUNCTIONS

=head2 common_suffix(@LIST) => STR

Given a list of strings, return common suffix.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-CommonPrefix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-CommonPrefix>.

=head1 SEE ALSO

L<String::CommonPrefix>

CLI L<strip-common-suffix> (from L<App::CommonSuffixUtils>).

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

This software is copyright (c) 2024, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-CommonPrefix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

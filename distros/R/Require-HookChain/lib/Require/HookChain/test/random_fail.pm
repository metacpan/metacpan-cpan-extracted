## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain::test::random_fail;

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-23'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.015'; # VERSION

sub new {
    my ($class, $probability) = @_;
    $probability = 0.5 unless defined $probability;
    bless {probability=>$probability}, $class;
}

sub Require::HookChain::test::random_fail::INC {
    my ($self, $r) = @_;

    if (rand() < $self->{probability}) {
        my $filename = $r->filename;
        die "Can't locate $filename: test::random_fail";
    }
    ();
}

1;
# ABSTRACT: Fail a module loading randomly

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::test::random_fail - Fail a module loading randomly

=head1 VERSION

This document describes version 0.015 of Require::HookChain::test::random_fail (from Perl distribution Require-HookChain), released on 2023-07-23.

=head1 SYNOPSIS

 use Require::HookChain 'test::random_fail', 0.25; # probability, default is 0.5 (50%)
 # now each subsequent require() will ~25% fail

=head1 DESCRIPTION

For testing only.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<Require::HookChain::test::fail>

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

This software is copyright (c) 2023, 2022, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-HookChain>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Perinci::Sub::XCompletion::kdeactivity_name;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-09'; # DATE
our $DIST = 'Sah-SchemaBundle-KDEActivity'; # DIST
our $VERSION = '0.002'; # VERSION

sub gen_completion {
    my %gcargs = @_;

    sub {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my %cargs = @_;

        my $word = $cargs{word};

        require Complete::KDEActivity;
        Complete::KDEActivity::complete_kde_activity_name(
            word => $word,
        );
    },
}

1;
# ABSTRACT: Generate completion for KDE activity name

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::kdeactivity_name - Generate completion for KDE activity name

=head1 VERSION

This document describes version 0.002 of Perinci::Sub::XCompletion::kdeactivity_name (from Perl distribution Sah-SchemaBundle-KDEActivity), released on 2026-04-09.

=head1 SYNOPSIS

To use, put this in your L<Sah> schema's C<x.completion> attribute:

 'x.completion' => ['kdeactivity_name'],

=for Pod::Coverage ^(gen_completion)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-KDEActivity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-KDEActivity>.

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-KDEActivity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain::test::noop_all;

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
#use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-12'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.011'; # VERSION

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub Require::HookChain::test::noop_all::INC {
    my ($self, $r) = @_;

    #print "Loading ", $r->filename, " ...\n";
    $self->src("1;");
}

1;
# ABSTRACT: Make module loading a no-op

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::test::noop_all - Make module loading a no-op

=head1 VERSION

This document describes version 0.011 of Require::HookChain::test::noop_all (from Perl distribution Require-HookChain), released on 2023-02-12.

=head1 SYNOPSIS

 use Require::HookChain 'test::noop_all';
 # now each subsequent require() will do nothing and will not load any source

=head1 DESCRIPTION

For testing only.

This hook returns a source code of C<<1;>> for all modules, effectively making
all module loading a no-op. On subsequent loading for a module, perl sees that
the source code has been applied and will not load the source again, which is
the regular "no-op" upon re-loading a module.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<Require::HookChain::test::noop>

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

## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain::debug::dump_source::stderr;

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-05'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.016'; # VERSION

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub Require::HookChain::debug::dump_source::stderr::INC {
    my ($self, $r) = @_;

    # safety, in case we are not called by Require::HookChain
    return () unless ref $r;

    my $src = $r->src;
    return unless defined $src;

    warn "Require::HookChain::debug::dump_source::stderr: source code of ", $r->filename, " <<END_DUMP\n$src\nEND_DUMP\n";
}

1;
# ABSTRACT: Dump loaded source code to STDERR

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::debug::dump_source::stderr - Dump loaded source code to STDERR

=head1 VERSION

This document describes version 0.016 of Require::HookChain::debug::dump_source::stderr (from Perl distribution Require-HookChain), released on 2023-12-05.

=head1 SYNOPSIS

 use Require::HookChain -end=>1,  'debug::dump_source::stderr';
 # now each time we require(), source code is printed to STDERR

A demo (L<nauniq> is a script available on CPAN):

 % PERL5OPT="-MRequire::HookChain=-end,1,debug::dump_source::stderr" nauniq ~/samples/1.csv
 Require::HookChain::debug::dump_source::stderr: source code of App/nauniq.pm <<END_DUMP
 ...
 END_DUMP
 Require::HookChain::debug::dump_source::stderr: source code of App/nauniq.pm <<END_DUMP
 ...
 END_DUMP
 ...

=head1 DESCRIPTION

This hook will do nothing if by the time it runs the source code is not yet
available, so make sure you put this hook at the end of C<@INC> using the C<<
-end => 1 >> option:

 use Require::HookChain -end=>1,  'debug::dump_source::stderr';

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<Require::HookChain::debug::dump_source::logger>

L<Require::HookChain>

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

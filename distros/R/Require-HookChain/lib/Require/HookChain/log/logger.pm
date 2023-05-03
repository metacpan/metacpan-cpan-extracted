## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain::log::logger;

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-12'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.009'; # VERSION

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub Require::HookChain::log::logger::INC {
    my ($self, $r) = @_;

    # safety, in case we are not called by Require::HookChain
    return () unless ref $r;

    my @caller = caller(1);
    log_trace "Require::HookChain::log::logger: Require-ing %s (called from package %s file %s:%d) ...", $r->filename, $caller[0], $caller[1], $caller[2];
}

1;
# ABSTRACT: Log a message to Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::log::logger - Log a message to Log::ger

=head1 VERSION

This document describes version 0.009 of Require::HookChain::log::logger (from Perl distribution Require-HookChain), released on 2023-02-12.

=head1 SYNOPSIS

 use Require::HookChain 'log::ger';
 # now each time we require(), a logging statement is produced at the trace level

A demo (L<nauniq> is a Perl script you can get from CPAN, and
L<Log::ger::Screen> is a module to show log statements on the terminal. Note
that the loading of L<strict>.pm and L<warnings>.pm are not logged because they
are already loaded by C<Log::ger::Screen>. If you want logging of such modules
you can try L<Require::HookChain::log::stderr> which avoids the use of any
module itself.

 $ TRACE=1 PERL5OPT="-MLog::ger::Screen -MRequire::HookChain=log::logger" nauniq ~/samples/1.csv
 Require::HookChain::log::logger: Require-ing App/nauniq.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:7) ...
 Require::HookChain::log::logger: Require-ing Getopt/Long.pm (called from package main file /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/nauniq:8) ...
 Require::HookChain::log::logger: Require-ing vars.pm (called from package Getopt::Long file /loader/0x56139558fdb0/Getopt/Long.pm:20) ...
 Require::HookChain::log::logger: Require-ing warnings/register.pm (called from package vars file /loader/0x56139558fdb0/vars.pm:7) ...
 Require::HookChain::log::logger: Require-ing constant.pm (called from package Getopt::Long file /loader/0x56139558fdb0/Getopt/Long.pm:220) ...
 Require::HookChain::log::logger: Require-ing overload.pm (called from package Getopt::Long::CallBack file /loader/0x56139558fdb0/Getopt/Long.pm:1574) ...
 Require::HookChain::log::logger: Require-ing overloading.pm (called from package overload file /loader/0x56139558fdb0/overload.pm:84) ...
 Require::HookChain::log::logger: Require-ing Exporter/Heavy.pm (called from package Exporter file /home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/5.34.0/Exporter.pm:13) ...
 ...

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<Require::HookChain::log::stderr>

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

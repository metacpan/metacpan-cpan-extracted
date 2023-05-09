## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain::timestamp::hires;

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

use Time::HiRes qw(time);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-12'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.011'; # VERSION

our %Timestamps; # key=module name, value=epoch

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub Require::HookChain::timestamp::hires::INC {
    my ($self, $r) = @_;

    # safety, in case we are not called by Require::HookChain
    return () unless ref $r;

    $Timestamps{$r->filename} = time()
        unless defined $Timestamps{$r->{filename}};
}

1;
# ABSTRACT: Record timestamp of each module's loading (uses Time::HiRes)

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::timestamp::hires - Record timestamp of each module's loading (uses Time::HiRes)

=head1 VERSION

This document describes version 0.011 of Require::HookChain::timestamp::hires (from Perl distribution Require-HookChain), released on 2023-02-12.

=head1 SYNOPSIS

 use Require::HookChain 'timestamp::hires';
 # now each time we require(), the timestamp is recorded in %Require::HookChain::timestamp::hires::Timestamps

 # later, print out the timestamps
 for (sort keys %Require::HookChain::timestamp::hires::Timestamps) {
     print "Module $_ loaded at ", scalar(localtime $Require::HookChain::timestamp::hires::Timestamps{$_}), "\n";
 }

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<Require::HookChain::timestamp::std> which uses built-in time() which only has
1-second granularity but does not require loading any module by itself.

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

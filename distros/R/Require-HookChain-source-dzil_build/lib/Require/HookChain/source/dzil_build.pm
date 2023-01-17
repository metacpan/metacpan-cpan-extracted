## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain::source::dzil_build;

use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-15'; # DATE
our $DIST = 'Require-HookChain-source-dzil_build'; # DIST
our $VERSION = '0.001'; # VERSION

use Require::Hook::Source::DzilBuild;

sub new {
    my ($class, $zilla) = @_;
    $zilla or die "Please supply zilla object";
    bless { zilla => $zilla }, $class;
}

sub Require::HookChain::source::dzil_build::INC {
    my ($self, $r) = @_;

    my $filename = $r->filename;

    # safety, in case we are not called by Require::HookChain
    return () unless ref $r;

    if (defined $r->src) {
        log_trace "[RHC:source::dzil_build] source code already defined for $filename, declining";
        return;
    }

    my $rh = Require::Hook::Source::DzilBuild->new(zilla => $self->{zilla});
    my $res = Require::Hook::Source::DzilBuild::INC($rh, $filename);
    return unless $res;
    $r->src($$res);
}

1;
# ABSTRACT: Load module source code from Dist::Zilla build files

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::source::dzil_build - Load module source code from Dist::Zilla build files

=head1 VERSION

This document describes version 0.001 of Require::HookChain::source::dzil_build (from Perl distribution Require-HookChain-source-dzil_build), released on 2022-11-15.

=head1 SYNOPSIS

In your L<Dist::Zilla> plugin, e.g. in C<munge_files()>:

 sub munge_files {
     my $self = shift;

     local @INC = @INC;
     require Require::HookChain;
     Require::HookChain->import('source::dzil_build', $self->zilla);

     require Foo::Bar; # will be searched from build files, if exist

     ...
 }

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain-source-dzil_build>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain-source-dzil_build>.

=head1 SEE ALSO

L<Require::Hook::Source::DzilBuild>, the L<Require::Hook> (non-chainable)
version of us.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-HookChain-source-dzil_build>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

## no critic: TestingAndDebugging::RequireUseStrict
package Require::Hook;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-22'; # DATE
our $DIST = 'Require-Hook'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Namespace for require() hooks

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::Hook - Namespace for require() hooks

=head1 VERSION

This document describes version 0.003 of Require::Hook (from Perl distribution Require-Hook), released on 2023-04-22.

=head1 DESCRIPTION

B<NOTE:> Please see L<Require::HookChain> instead which largely supersedes this.

As one already understands, Perl lets you put coderefs or objects in C<@INC> as
"hooks". This lets you do all sorts of things when it comes to loading modules,
for example:

=over

=item * faking that a module does not exist when it does

This can be used for testing.

=item * loading module from various sources

You can load module source from the DATA section or variables, as is done in a
fatpacked script. Or you can retrieve module source from CPAN so a script can
magically run without installing extra CPAN modules.

=item * munging source code

Like adding some Perl code before (C<use strict;>) or after, for testing purpose
or otherwise.

=item * decrypt from an ecrypted source

=back

In the case of objects, perl will call your C<INC> method. So this is how you
would write a module for a require hook:

 package My::INCHandler;
 sub new { ... }
 sub My::INCHandler::INC {
     my ($self, $filename) = @_;
     ...
 }
 1;

C<Require::Hook> is just a namespace to put and share all your require hooks.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-Hook>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-Hook>.

=head1 SEE ALSO

C<Require::Hook::*> modules.

L<Require::HookChain> is a newer framework that largely supersedes
Require::Hook.

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

This software is copyright (c) 2023, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Hook>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

## no critic: TestingAndDebugging::RequireUseStrict
package RHC;
use alias::module 'Require::HookChain';

1;
# ABSTRACT: Short alias for Require::HookChain

__END__

=pod

=encoding UTF-8

=head1 NAME

RHC - Short alias for Require::HookChain

=head1 VERSION

This document describes version 0.009 of RHC (from Perl distribution Require-HookChain), released on 2023-02-12.

=head1 SYNOPSIS

On the command-line:

 # add 'use strict' to all loaded modules
 % perl -MRHC=munge::prepend,'use strict' ...

=head1 DESCRIPTION

This is a short alias for L<Require::HookChain> for less typing on the
command-line.

=for Pod::Coverage ^(blessed)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

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

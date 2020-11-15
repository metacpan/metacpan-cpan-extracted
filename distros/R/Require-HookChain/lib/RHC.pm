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

This document describes version 0.002 of RHC (from Perl distribution Require-HookChain), released on 2020-11-13.

=head1 SYNOPSIS

On the command-line:

 # add 'use strict' to all loaded modules
 % perl -MRHC=munge::prepend,'use strict' ...

=head1 DESCRIPTION

This is a short alias for L<Require::HookChain> for less typing on the
command-line.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-HookChain>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Require::HookChain>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Perinci::Sub::XCompletion;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-01'; # DATE
our $DIST = 'Perinci-Sub-XCompletion'; # DIST
our $VERSION = '0.104'; # VERSION

1;
# ABSTRACT: Write completion routines in x.{,element_,index_}completion attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion - Write completion routines in x.{,element_,index_}completion attributes

=head1 VERSION

This document describes version 0.104 of Perinci::Sub::XCompletion (from Perl distribution Perinci-Sub-XCompletion), released on 2023-03-01.

=head1 SYNOPSIS

In L<Rinci> metadata:

 args => {
     foo => {
         ...
         'x.completion' => [filename => {file_regex_filter=>qr/\.(yaml|yml)$/i}],
     },
     ...
 },
 ...

=head1 DESCRIPTION

This is a module to support an experimental (and temporary?) way to ease writing
completion routine. Instead of putting a coderef in C<completion> or
C<element_completion> property in argument specification, you put C<$name> or
C<< [$name, \%args] >> in C<x.completion> or C<x.element_completion> or
C<x.index_completion> attributes. C<$name> is the name of
C<Perinci::Sub::XCompletion::*> submodule to use, and \%args is arguments.

But you can also use a coderef as usual.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletion>.

=head1 SEE ALSO

L<Perinci::Sub::Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2023, 2022, 2019, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

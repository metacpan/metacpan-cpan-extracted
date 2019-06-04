package Perinci::Sub::XCompletion;

our $DATE = '2019-06-03'; # DATE
our $VERSION = '0.102'; # VERSION

1;
# ABSTRACT: Write completion routines in x.{,element_,index_}completion attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion - Write completion routines in x.{,element_,index_}completion attributes

=head1 VERSION

This document describes version 0.102 of Perinci::Sub::XCompletion (from Perl distribution Perinci-Sub-XCompletion), released on 2019-06-03.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Sub::Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

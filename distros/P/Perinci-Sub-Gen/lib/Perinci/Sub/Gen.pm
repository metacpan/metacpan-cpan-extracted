package Perinci::Sub::Gen;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;

our %common_args = (
    name => {
        summary => "Generated function's name, e.g. `myfunc`",
        schema => 'str*',
    },
    package => {
        summary => "Generated function's package, e.g. `My::Package`",
        schema => 'str*',
        description => <<'_',

This is needed mostly for installing the function. You usually don't need to
supply this if you set `install` to false.

If not specified, caller's package will be used by default.

_
    },
    summary => {
        summary => "Generated function's summary",
        schema => 'str*',
    },
    description => {
        summary => "Generated function's description",
        schema => 'str*',
    },
    install => {
        summary => 'Whether to install generated function (and metadata)',
        schema  => [bool => {default=>1}],
        description => <<'_',

By default, generated function will be installed to the specified (or caller's)
package, as well as its generated metadata into %SPEC. Set this argument to
false to skip installing.

_
    },
);

1;
# ABSTRACT: Common stuffs used by Perinci::Sub::Gen::*

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Gen - Common stuffs used by Perinci::Sub::Gen::*

=head1 VERSION

This document describes version 0.03 of Perinci::Sub::Gen (from Perl distribution Perinci-Sub-Gen), released on 2015-09-04.

=head1 DESCRIPTION

Perinci::Sub::Gen::* namespace is used for modules that generate functions (and
their metadata).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Gen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Gen>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Gen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

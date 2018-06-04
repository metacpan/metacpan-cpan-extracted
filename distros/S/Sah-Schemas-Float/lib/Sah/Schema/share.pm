package Sah::Schema::share;

our $DATE = '2018-06-04'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = ['float', {
    summary => 'A float between 0 and 1',
    description => <<'_',

Accepted in one of these forms:

    0.5      # a normal float between 0 and 1
    10       # a float between 1 (exclusive) and 100, interpreted as percent
    10%      # a percentage string, between 0% and 100%

Due to different interpretations, particularly "1" (some people might expect it
to mean "0.01" or "1%") use of this type is discouraged. Use
<pm:Sah::Schema::percent> instead.

_
    'x.perl.coerce_rules' => [
        'str_share',
    ],
}, {}];

1;
# ABSTRACT: A float between 0 and 1

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::share - A float between 0 and 1

=head1 VERSION

This document describes version 0.002 of Sah::Schema::share (from Perl distribution Sah-Schemas-Float), released on 2018-06-04.

=head1 DESCRIPTION

Accepted in one of these forms:

 0.5      # a normal float between 0 and 1
 10       # a float between 1 (exclusive) and 100, interpreted as percent
 10%      # a percentage string, between 0% and 100%

Due to different interpretations, particularly "1" (some people might expect it
to mean "0.01" or "1%") use of this type is discouraged. Use
L<Sah::Schema::percent> instead.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

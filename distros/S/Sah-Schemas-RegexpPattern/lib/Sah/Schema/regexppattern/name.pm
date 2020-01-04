package Sah::Schema::regexppattern::name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-03'; # DATE
our $DIST = 'Sah-Schemas-RegexpPattern'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = ['str', {
    summary => "Name of pattern, with module prefix but without the 'Regexp::Pattern'",
    match => qr!\A\w+((::|/|\.)\w+)+\z!,
    'x.completion' => ['regexppattern_name'],
    'x.perl.coerce_rules' => ['From_str::normalize_perl_modname'],
}, {}];

1;
# ABSTRACT: Name of pattern, with module prefix but without the 'Regexp::Pattern'

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::regexppattern::name - Name of pattern, with module prefix but without the 'Regexp::Pattern'

=head1 VERSION

This document describes version 0.001 of Sah::Schema::regexppattern::name (from Perl distribution Sah-Schemas-RegexpPattern), released on 2020-01-03.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-RegexpPattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-RegexpPattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-RegexpPattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

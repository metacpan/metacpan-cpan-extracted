package Sah::Schema::date::month_num;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.003'; # VERSION

our $schema = [int => {
    summary => 'Month number',
    min => 1,
    max => 12,
    'x.perl.coerce_rules' => ['str_convert_en_month_name_to_num'],
}, {}];

1;

# ABSTRACT: Month number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::month_num - Month number

=head1 VERSION

This document describes version 0.003 of Sah::Schema::date::month_num (from Perl distribution Sah-Schemas-Date), released on 2019-06-20.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

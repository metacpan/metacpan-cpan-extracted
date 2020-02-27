package Sah::Schema::date::tz_name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-27'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.008'; # VERSION

our $schema = [str => {
    summary => 'Timezone name',
    completion => sub {
        require Complete::TZ;

        my %args = @_;

        Complete::TZ::complete_tz(word => $args{word});
    },
}, {}];

1;

# ABSTRACT: Timezone name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::tz_name - Timezone name

=head1 VERSION

This document describes version 0.008 of Sah::Schema::date::tz_name (from Perl distribution Sah-Schemas-Date), released on 2020-02-27.

=head1 DESCRIPTION

Currently no validation for valid timezone names. But completion is provided.

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

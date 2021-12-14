package Sah::Schemas::CPAN;

# during build by perl >= 5.014, Sah::SchemaR::cpan::pause_id will contain sequence (?^...) which is not supported by perl <= 5.012
use 5.014;

1;
# ABSTRACT: Sah schemas related to CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::CPAN - Sah schemas related to CPAN

=head1 VERSION

This document describes version 0.013 of Sah::Schemas::CPAN (from Perl distribution Sah-Schemas-CPAN), released on 2021-07-19.

=head1 SYNOPSIS

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-dell-xps13)

perlancar (on netbook-dell-xps13) <perlancar@gmail.com>

=head1 SAH SCHEMAS

=over

=item * L<cpan::distname|Sah::Schema::cpan::distname>

Like perl::distname, but with completion from distribution names on CPAN (using
lcpan).


=item * L<cpan::modname|Sah::Schema::cpan::modname>

Like perl::modname, but with completion from module names on CPAN (using lcpan).


=item * L<cpan::pause_id|Sah::Schema::cpan::pause_id>

PAUSE author ID.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schemas::CPANMeta>

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

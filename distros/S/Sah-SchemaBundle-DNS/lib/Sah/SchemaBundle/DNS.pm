package Sah::SchemaBundle::DNS;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-26'; # DATE
our $DIST = 'Sah-SchemaBundle-DNS'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Schemas related to DNS

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::DNS - Schemas related to DNS

=head1 VERSION

This document describes version 0.003 of Sah::SchemaBundle::DNS (from Perl distribution Sah-SchemaBundle-DNS), released on 2024-06-26.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<dns::record|Sah::Schema::dns::record>

DNS record structure.

=item * L<dns::record::a|Sah::Schema::dns::record::a>

DNS A record.

=item * L<dns::record::cname|Sah::Schema::dns::record::cname>

DNS CNAME record.

=item * L<dns::record::mx|Sah::Schema::dns::record::mx>

DNS MX record.

=item * L<dns::record::ns|Sah::Schema::dns::record::ns>

DNS NS record.

=item * L<dns::record::soa|Sah::Schema::dns::record::soa>

DNS SOA record.

=item * L<dns::record::srv|Sah::Schema::dns::record::srv>

DNS SRV record.

=item * L<dns::record::sshfp|Sah::Schema::dns::record::sshfp>

DNS SSHFP record.

=item * L<dns::record::txt|Sah::Schema::dns::record::txt>

DNS TXT record.

=item * L<dns::record_field::name::allow_underscore|Sah::Schema::dns::record_field::name::allow_underscore>

The "name" field in DNS record, underscore allowed as the first character of word.

=item * L<dns::record_field::name::disallow_underscore|Sah::Schema::dns::record_field::name::disallow_underscore>

The "name" field in DNS record, underscore not allowed.

=item * L<dns::record_of_known_types|Sah::Schema::dns::record_of_known_types>

DNS record structure (restricted to known types only).

=item * L<dns::records|Sah::Schema::dns::records>

Array of DNS records.

=item * L<dns::records_of_known_types|Sah::Schema::dns::records_of_known_types>

Array of DNS records (restricted to known types only).

=item * L<dns::zone|Sah::Schema::dns::zone>

DNS zone structure.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-DNS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-DNS>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

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

This software is copyright (c) 2024, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-DNS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

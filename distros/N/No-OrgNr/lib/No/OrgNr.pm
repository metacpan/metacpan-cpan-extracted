package No::OrgNr;

use utf8;
use 5.014;
use warnings;
use open qw/:encoding(UTF-8) :std/;

use Net::Whois::Norid;

$Net::Whois::Raw::CHECK_FAIL = 1;
$Net::Whois::Raw::OMIT_MSG   = 1;

use version; our $VERSION = qv('0.9.3');

use parent qw/Exporter/;
our @EXPORT_OK = qw/all domain2orgnr num_domains orgnr_ok orgnr2domains/;
our %EXPORT_TAGS = ( 'all' => [qw/domain2orgnr num_domains orgnr_ok orgnr2domains/] );

sub domain2orgnr {
    my $domain = shift or return;

    if ( $domain !~ / [.] no \z /x ) {
        return;
    }

    return Net::Whois::Norid->new($domain)->id_number;
}

sub num_domains {
    my $orgnr = shift;

    my @domains = orgnr2domains($orgnr);

    return scalar @domains;
}

sub orgnr2domains {
    my $orgnr = shift;

    my @domains;

    if ( !orgnr_ok($orgnr) ) {
        return @domains;
    }

    $orgnr =~ s/ \s //gx;

    my $whois        = Net::Whois::Norid->new($orgnr);
    my $norid_handle = $whois->norid_handle;

    if ( !defined $norid_handle ) {
        return @domains;
    }

    for my $nh ( split / \n /x, $norid_handle ) {
        my $nhobj = Net::Whois::Norid->new($nh);

        for my $domain ( split / /, $nhobj->domains ) {
            push @domains, $domain;
        }
    }

    return ( sort @domains );
}

sub orgnr_ok {
    my $orgnr = shift or return 0;

    $orgnr =~ s/ \s //gx;

    # Valid numbers start on 8 or 9
    if ( $orgnr !~ /\A [89] \d{8} \z/ax ) {
        return 0;
    }

    my @d = split //, $orgnr;
    my $w = [ 3, 2, 7, 6, 5, 4, 3, 2 ];
    my $sum = 0;
    for my $i ( 0 .. 7 ) {
        $sum += $d[$i] * $w->[$i];
    }

    my $rem = $sum % 11;
    my $control_digit = ( $rem == 0 ? 0 : 11 - $rem );

    # Invalid number if control digit is 10
    if ( $control_digit == 10 ) {
        return 0;
    }

    if ( $control_digit != $d[8] ) {
        return 0;
    }

    return $d[0] . $d[1] . $d[2] . ' ' . $d[3] . $d[4] . $d[5] . ' ' . $d[6] . $d[7] . $d[8];
}

1;

__END__

=encoding utf8

=for html
<a href="https://travis-ci.org/geirmyk/No-OrgNr">
<img alt="Build Status" src="https://travis-ci.org/geirmyk/No-OrgNr.svg?branch=master" /></a>
<a href="https://badge.fury.io/pl/No-OrgNr">
<img alt="CPAN version" src="https://badge.fury.io/pl/No-OrgNr.svg" /></a>

=head1 NAME

No::OrgNr - Utility functions for Norwegian organizations' ID numbers

=head1 VERSION

This document describes No::OrgNr version 0.9.3

=head1 SYNOPSIS

    use No::OrgNr qw/domain2orgnr num_domains orgnr2domains orgnr_ok/;
    # or
    use No::OrgNr qw/:all/;

    my $owner   = domain2orgnr('google.no'); # Returns "988588261", as seen by Whois
    my $num     = num_domains(ORG_NR);       # Returns the number of domain names owned by ORG_NR
    my $orgnr   = orgnr_ok('988588261');     # Returns "988 588 261"
    my @domains = orgnr2domains(ORG_NR);     # Returns a list of domain names owned by ORG_NR

=head1 DESCRIPTION

Organizations in Norway have a 9-digit number for identification. Valid numbers start on 8 or 9. No
information about the given organization can be derived from the number.

This module contains utility functions for handling these numbers.

Please keep in mind that this module utilizes the module C<Net::Whois::Norid>, which in turn uses
the server C<whois.norid.no>. This server has a limitation for the number of requests. See
documentation at L<https://www.norid.no/en/registrar/system/tjenester/whois-das-service/>.

The Norwegian term for organization number is "organisasjonsnummer". See
L<https://no.wikipedia.org/wiki/Organisasjonsnummer> for a description (Norwegian text only).

Organizations in other countries have ID numbers as well. See
L<https://en.wikipedia.org/wiki/VAT_identification_number>.

=head1 SUBROUTINES/METHODS

Nothing is exported by default. See L</"SYNOPSIS"> above.

=head2 domain2orgnr(DOMAIN_NAME)

The function returns the organization number for the owner of C<DOMAIN_NAME>. Only Norwegian domain
names (*.no) are supported. If no organization number can be found, the undefined value is returned.

=head2 num_domains(ORG_NR)

The function returns the number of domain names owned by organization number C<ORG_NR>. The value is
zero if no such domain name exists.

=head2 orgnr2domains(ORG_NR)

The function returns a sorted list of domain names (if any) owned by organization number C<ORG_NR>.
If C<ORG_NR> is missing or invalid, or the organization does not own a domain name, an empty list is
returned.

=head2 orgnr_ok(ORG_NR)

The function returns false if C<ORG_NR> is invalid. Otherwise, it returns the number in standard
form, e.g., "987 654 321", which of course is a true value. A valid number is not necessarily used
by any real organization.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION

None.

=head1 DEPENDENCIES

This module requires Perl 5.14 or later, due to the "/a" regular expression modifier.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

The modules L<No::KontoNr|https://metacpan.org/pod/No::KontoNr> and
L<No::PersonNr|https://metacpan.org/pod/No::PersonNr>, written by another CPAN author, may be of
interest for validation purposes. The documentation for these modules is in Norwegian only.

=head1 BUGS

Please report bugs using L<GitHub|https://github.com/geirmyk/No-OrgNr/issues>.

=head1 SUPPORT

Documentation for this module is available using the following command:

    perldoc No::OrgNr

The following sites may be useful:

=over 4

=item *

AnnoCPAN: L<http://annocpan.org/dist/No-OrgNr>

=item *

MetaCPAN: L<https://metacpan.org/pod/No::OrgNr>

=item *

CPAN Dependencies: L<http://deps.cpantesters.org/?module=No%3A%3AOrgNr>

=item *

CPAN Ratings: L<http://cpanratings.perl.org/dist/No::OrgNr>

=item *

CPAN Search: L<http://search.cpan.org/perldoc?No::OrgNr>

=item *

CPAN Testers Matrix: L<http://matrix.cpantesters.org/?dist=No-OrgNr>

=item *

CPAN Testers Reports: L<http://www.cpantesters.org/distro/N/No-OrgNr.html>

=item *

CPANTS (CPAN Testing Service): L<http://cpants.cpanauthors.org/dist/No-OrgNr>

=back

=head1 AUTHOR

Geir Myklebust C<< <geirmy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

No::OrgNr is Copyright (C) 2015, 2016, Geir Myklebust.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl
5.14.0. For details, see L<GNU General Public License|https://metacpan.org/pod/perlgpl> and L<Perl
Artistic License|https://metacpan.org/pod/perlartistic>.

This program is distributed in the hope that it will be useful, but it is provided "as is" and
without any express or implied warranties.

use v5.20;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Carp ();
use JSON ();
use HTTP::Tiny;

our $VERSION = '0.0.3';

package Net::NVD {
  sub new ($class, %args) {
    Carp::croak('"format" must be "cve" or "complete"')
      if exists $args{format} && $args{format} ne 'complete' && $args{format} ne 'cve';
    return bless {
      ua     => _build_user_agent($args{api_key}),
      format => $args{format} // 'cve',
    }, $class;
  }

  sub get ($self, $cve_id) {
    my ($single) = $self->search( cve_id => $cve_id );
    return $single;
  }

  sub search ($self, %params) {
    my $res = $self->{ua}->request('GET', 'https://services.nvd.nist.gov/rest/json/cves/2.0?' . _build_url_params($self->{ua}, %params));
    if ($res->{success}) {
      my $json = JSON::decode_json($res->{content});
      return $self->{format} eq 'complete'
        ? $json : map $_->{cve}, $json->{vulnerabilities}->@*;
    }
    Carp::carp($res->{headers}{message} // "error querying NVD service ($res->{status})");
    return ();
  }

  sub _build_user_agent($api_key) {
    return HTTP::Tiny->new(
      agent      => __PACKAGE__ . '/' . $VERSION,
      verify_SSL => 1,
      ($api_key ? (default_headers => { apiKey => $api_key }) : ()),
    );
  }

  sub _build_url_params ($ua, %params) {
    my $iso8061 = qr{\A\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?(?:[\+\-]\d{2}:\d{2})?\z};
    my %translation = (
      cpe_name             => { name => 'cpeName'           , validation => qr{\Acpe:2.3(\:[^*:]+){4}(\:[^:]+){7}\z} },
      cve_id               => { name => 'cveId'             , validation => qr{\ACVE\-[0-9]{4}\-[0-9]+\z} },
      cvssv2_metrics       => { name => 'cvssV2Metrics'     , validation => qr{.} },
      cvssV2Severity       => { name => 'cvssV2Severity'    , validation => qr{\A(?:LOW|MEDIUM|HIGH)\z} },
      cvssv3_metrics       => { name => 'cvssV3Metrics'     , validation => qr{.} },
      cvssv3_severity      => { name => 'cvssV3Severity'    , validation => qr{\A(?:LOW|MEDIUM|HIGH|CRITICAL)\z} },
      cwe_id               => { name => 'cweId'             , validation => qr{\ACWE\-\d+\z} },
      keyword_search       => { name => 'keywordSearch'     , validation => qr{\A.+\z} },
      last_mod_start_date  => { name => 'lastModStartDate'  , validation => $iso8061 },
      last_mod_end_date    => { name => 'lastModEndDate'    , validation => $iso8061 },
      pub_start_date       => { name => 'pubStartDate'      , validation => $iso8061 },
      pub_end_date         => { name => 'pubEndDate'        , validation => $iso8061 },
      results_per_page     => { name => 'resultsPerPage'    , validation => qr{\A\d+\z} },
      start_index          => { name => 'startIndex'        , validation => qr{\A\d+\z} },
      source_identifier    => { name => 'sourceIdentifier'  , validation => qr{.} },
      version_end          => { name => 'versionEnd'        , validation => qr{.} },
      version_end_type     => { name => 'versionEndType'    , validation => qr{\A(?:including|excluding)\z} },
      version_start        => { name => 'versionStart'      , validation => qr{.} },
      version_start_type   => { name => 'versionStartType'  , validation => qr{\A(?:including|excluding)\z} },
      virtual_match_string => { name => 'virtualMatchString', validation => qr{.} },
      has_cert_alerts      => { name => 'hasCertAlerts'     , boolean => 1 },
      has_cert_notes       => { name => 'hasCertNotes'      , boolean => 1 },
      has_kev              => { name => 'hasKev'            , boolean => 1 },
      has_oval             => { name => 'hasOval'           , boolean => 1 },
      is_vulnerable        => { name => 'isVulnerable'      , boolean => 1 },
      keyword_exact_match  => { name => 'keywordExactMatch' , boolean => 1 },
      no_rejected          => { name => 'noRejected'        , boolean => 1 },
    );

    my @params;
    my %translated;
    foreach my $p (keys %params) {
      Carp::croak("'$p' is not a valid search parameter") unless exists $translation{$p};
      if ($translation{$p}{boolean}) {
        push @params, $translation{$p}{name} if delete $params{$p};
      }
      else {
        Carp::croak("invalid value '$params{$p}' for '$p'") unless $params{$p} =~ $translation{$p}{validation};
        $translated{$translation{$p}{name}} = $params{$p};
      }
    }
    return join('&', @params, $ua->www_form_urlencode(\%translated));
  }
};

1;
__END__

=head1 NAME

Net::NVD - query CVE data from NIST's NVD (National Vulnerability Database)

=head1 SYNOPSIS

    use Net::NVD;

    my $nvd = Net::NVD->new;

    # query a specific CVE
    my $cve = $nvd->get( 'CVE-2019-1010218' );
    say $cve->{descriptions}[0]{value};

    # get non-rejected reports matching some keywords and a date interval:
    my @cves = $nvd->search(
        keyword_search      => 'perl cpan',
        last_mod_start_date => '2023-01-01T00:00:00',
        last_mod_end_date   => '2023-04-01T00:00:00',
        no_rejected         => 1,
    );

    foreach my $report (@cves) {
        say "$report->{id} (published in $report->{id}{published})";
        say "$report->{descriptions}[0]{value}";
    }

=head1 DESCRIPTION

This modules provides a Perl interface to L<< NIST's National Vulnerability Database (NVD) | https://nvd.nist.gov/ >>, allowing developers to search and retrieve L<< CVE (Common Vulnerabilities and Exposures) | https://cve.mitre.org >> information.

=head1 METHODS

=head2 new( %params )

    my $nvd = Net::NVD->new;
    my $nvd = Net::NVD->new(
      api_key => 'your secret key',
      format  => 'complete',
    );

Instantiates a new object. If you want a better rate limit, you should
L<request an API key|https://nvd.nist.gov/developers/request-an-api-key>
for your organization. But you should probably only do it if you
actually hit the limit, as their API is quite generous.

You may also specify the C<format> of the output. Available are:

=over 4

=item * B<cve> (default) - returns only the actual CVE portion.

=item * B<complete> - returns the entire data structure from NVD.

=back

=head2 get( $cve_id )

    my $cve_data = $nvd->get( 'CVE-2003-0521' );

Retrieves data for a given CVE. It is a shortcut to:

    my $cve_data = (Net::NVD->new->search(cve_id => 'CVE-2003-0521'))[0]{cve};

=head2 search( %params )

    my @cves = $nvd->search(
      keyword_search      => 'Microsoft Outlook',
      keyword_exact_match => true,
    );

Queries NVD's API with the following parameters:

=over 4

=item * cpe_name - a given CPE v2.3 name.

=item * cve_id - a specific CVE id.

=item * cvssv2_metrics - a full or partial CVSSv2 vector string.

=item * cvssV2Severity - LOW, MEDIUM or HIGH.

=item * cvssv3_metrics - a full or partial CVSSv3 vector string.

=item * cvssv3_severity - LOW, MEDIUM, HIGH or CRITICAL.

=item * cwe_id - a CWE (Common Weakness Enumeration) id.

=item * has_cert_alerts - set to true to return only CVE's containing a Technical Alert from US-CERT.

=item * has_cert_notes - set to true to return only CVE's containing a Vulnerability Note from CERT/CC.

=item * has_kev - set to true to return only CVE's that appear in CISA's L<Known Exploited Vulnerabilities (KEV) Catalog|https://www.cisa.gov/known-exploited-vulnerabilities-catalog>.

=item * has_oval - set to true to return only CVE's that contain information from MITRE's L<Open Vulnerability and Assessment Language (OVAL)|https://oval.mitre.org/inuse/> before this transitioned to the Center for Internet Security (CIS).

=item * is_vulnerable - set to true to return only CVE's associated with a specific CPE, where the CPE is also considered vulnerable (if you use this parameter, you must also set C<cpe_name>).

=item * keyword_search - return CVE's with ANY of the given words found in the current description. To search for an exact phrase, set C<keyword_exact_match> to true.

=item * keyword_exact_match - set to true to make C<keyword_search> look for an exact phrase match.

=item * last_mod_start_date / last_mod_end_date - CVE's that were last modified during the specified period (iso8061 format). Must be used together.

=item * no_rejected - set to true to return only CVE records with the REJECT or Rejected status.

=item * pub_start_date / pub_end_date - CVE's that were added to NVD (i.e. published) during the specified period (iso8061 format). Must be used together.

=item * results_per_page - maximum number of CVE records to return. Defaults to the maximum of 2_000 (and NIST recommends you keep it like so).

=item * start_index - the index of the first CVE to be returned in the response data (zero based).

=item * source_identifier - CVE records with the given source identifier appearing as a data source in the CVE record.

=item * virtual_match_string - a broader CPE filter than C<cpe_name>. May be augmented by the parameters below.

=item * version_end - augments C<virtual_match_string> filtering CPE's in specific version ranges.

=item * version_end_type - 'including' or 'excluding', specifying the type for C<version_end>.

=item * version_start - augments C<virtual_match_string> filtering CPE's in the specific version ranges.

=item * version_start_type - 'including' or 'excluding', specifying the type for C<version_start>.

=back

Please refer to L<NIST NVD API Specification|https://nvd.nist.gov/developers/vulnerabilities> for more information on the search parameters above.

=head2 Return Values

A typical CVE portion on this API looks like this:

    {
      configurations => [{
          nodes => [{
            cpeMatch => [{
              criteria => '(some CPE value)',
              matchCriteriaId => '(some id)',
              vulnerable => true,
            }],
            negate   => false,
            operator => 'OR',
          }],
      }],
      descriptions => [
        {
          lang  => 'en',
          value => 'the CVE description, in english',
        },
        {
          lang  => 'es',
          value => 'la descripción del CVE, en español',
        },
      ],
      id => 'CVE-YYYY-NNNNN',  # the current CVE id
      lastModified => 'YYYY-MM-DDThh:mm:ss',
      metricts => {
        cvssMetricV2  => [{ ... }],
        cvssMetricV30 => [{ ... }],
        cvssMetricV31 => [{ ... }],
      },
      published => 'YYYY-MM-DDThh:mm:ss',
      references => [
        {
          source => 'source handle',
          tags => [ 'tag1', 'tag2', ... ],
          url => 'where to find the reference',
        },
        { ...}
      ],
      sourceIdentifier => 'source handle',
      vulnStatus => 'Analyzed',
      weaknesses => [{
        description => [{ lang => 'en', value => 'CWD-NNNN' }],
        source      => 'source handle',
        type        => 'Primary',
      }],
    }

Expect a single one of these when you call C<get()>, and an array of these
when you call C<search()>. If you have set the C<format> to 'complete', the
return value will instead be:

    {
      format => 'NVD_CVE',
      resultsPerPage => 10,  # some integer
      startIndex     => 0,   # some integer
      timestamp      => 'YYYY-MM-DDThh:mm:ss', # when the request was processed
      totalResults   => 4,   # some integer
      version        => 2.0, # API version
      vulnerabilities => [
        { cve => $cve_hashref },
        { cve => $cve_hashref },
        ...
      ],
    }

Of course, when your result only have one CVE (e.g. you called C<get()>), the
'complete' format will still include this header, but you can expect only one
element in C<< $ret->vulnerabilities->[0] >>.

B<NOTE>: NVD mentions there could be up to four different JSON formats. Please
L<check here|https://nvd.nist.gov/developers/vulnerabilities> to get extra
information on possible return values. If in doubt, request in 'complete'
format and dump the output using a tool like Data::Printer (DDP).

    my $result = Net::NVD->new( format => 'complete' )->get('CVE-2003-0521');
    use DDP; p $result;

=head1 SEE ALSO

L<Net::OSV>

L<Net::CVE>

L<CPAN::Audit>


=head1 LICENSE AND COPYRIGHT

Copyright 2023- Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

This product uses data from the NVD API but is not endorsed or certified by the NVD.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

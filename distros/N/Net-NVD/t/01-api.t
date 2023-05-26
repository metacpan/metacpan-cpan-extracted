use 5.20.0;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Test::More ;
use Net::NVD;

my $requested_uri = '';

my $nvd = Net::NVD->new;

{no warnings 'redefine'; *HTTP::Tiny::request = \&_request_mock }

my $single = $nvd->get( 'CVE-0000-0001' );
is $requested_uri, 'https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-0000-0001', 'request for a single CVE';
is_deeply $single, { descriptions => [{lang => 'en', value => 'Some vuln in Foo'}], id => 'CVE-0000-0001'}, 'proper return value for get()';


my @multiple = $nvd->search(
  keyword_search      => 'perl cpan',
  last_mod_start_date => '2023-01-15T13:00:00+01:00',
  no_rejected         => 1,
);
is $requested_uri, 'https://services.nvd.nist.gov/rest/json/cves/2.0?noRejected&keywordSearch=perl+cpan&lastModStartDate=2023-01-15T13%3A00%3A00%2B01%3A00', 'request for multiple CVEs';

is_deeply \@multiple, [{ descriptions => [{ lang => 'en', value => 'Some vuln in Foo'}], id => 'CVE-0000-0001'}, {descriptions => [{ lang => 'en', value => 'Other vuln in Foo'}], id => 'CVE-0000-0002' }, {descriptions => [{ lang => 'en', value => 'A vuln in Bar' }], id => 'CVE-0000-0003'}], 'proper return value for search()';

sub _request_mock ($self, $method, $url) {
  $requested_uri = $url;
  return { success => 1, content => '{"vulnerabilities": [{"cve":{"descriptions":[{"lang":"en","value":"Some vuln in Foo"}],"id":"CVE-0000-0001"}},{"cve":{"descriptions":[{"lang":"en","value":"Other vuln in Foo"}],"id":"CVE-0000-0002"}},{"cve":{"descriptions":[{"lang":"en","value":"A vuln in Bar"}],"id":"CVE-0000-0003"}}]}' };
}


done_testing;

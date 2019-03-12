# -*- perl -*-

# t/001_load.t - check module loading and create testing directory
use strict;
use warnings;

my $jdata_works = <<'END';
{"status":"ok","message-type":"work","message-version":"1.0.0","message":{"indexed":{"date-parts":[[2018,9,1]],"date-time":"2018-09-01T21:10:25Z","timestamp":1535836225666},"reference-count":38,"publisher":"Elsevier BV","license":[{"URL":"https:\/\/www.elsevier.com\/tdm\/userlicense\/1.0\/","start":{"date-parts":[[2017,6,1]],"date-time":"2017-06-01T00:00:00Z","timestamp":1496275200000},"delay-in-days":0,"content-version":"tdm"},{"URL":"https:\/\/www.elsevier.com\/open-access\/userlicense\/1.0\/","start":{"date-parts":[[2018,5,16]],"date-time":"2018-05-16T00:00:00Z","timestamp":1526428800000},"delay-in-days":349,"content-version":"am"}],"funder":[{"DOI":"10.13039\/501100001711","name":"Schweizerischer Nationalfonds zur F\u00f6rderung der Wissenschaftlichen Forschung","doi-asserted-by":"publisher","award":["PP00P2_150552\/1"]},{"name":"CIRM-FBK","award":[]}],"content-domain":{"domain":["elsevier.com","sciencedirect.com"],"crossmark-restriction":true},"short-container-title":["Advances in Mathematics"],"published-print":{"date-parts":[[2017,6]]},"DOI":"10.1016\/j.aim.2017.04.017","type":"journal-article","created":{"date-parts":[[2017,5,16]],"date-time":"2017-05-16T06:15:34Z","timestamp":1494915334000},"page":"746-802","update-policy":"http:\/\/dx.doi.org\/10.1016\/elsevier_cm_policy","source":"Crossref","is-referenced-by-count":2,"title":["The integer cohomology algebra of toric arrangements"],"prefix":"10.1016","volume":"313","author":[{"ORCID":"http:\/\/orcid.org\/0000-0002-2658-3721","authenticated-orcid":false,"given":"Filippo","family":"Callegaro","sequence":"first","affiliation":[]},{"given":"Emanuele","family":"Delucchi","sequence":"additional","affiliation":[]}],"member":"78","container-title":["Advances in Mathematics"],"original-title":[],"language":"en","link":[{"URL":"https:\/\/api.elsevier.com\/content\/article\/PII:S0001870815301614?httpAccept=text\/xml","content-type":"text\/xml","content-version":"vor","intended-application":"text-mining"},{"URL":"https:\/\/api.elsevier.com\/content\/article\/PII:S0001870815301614?httpAccept=text\/plain","content-type":"text\/plain","content-version":"vor","intended-application":"text-mining"}],"deposited":{"date-parts":[[2018,9,1]],"date-time":"2018-09-01T20:52:45Z","timestamp":1535835165000},"score":1.0,"subtitle":[],"short-title":[],"issued":{"date-parts":[[2017,6]]},"references-count":38,"alternative-id":["S0001870815301614"],"URL":"http:\/\/dx.doi.org\/10.1016\/j.aim.2017.04.017","relation":{},"ISSN":["0001-8708"],"issn-type":[{"value":"0001-8708","type":"print"}],"subject":["General Mathematics"],"assertion":[{"value":"Elsevier","name":"publisher","label":"This article is maintained by"},{"value":"The integer cohomology algebra of toric arrangements","name":"articletitle","label":"Article Title"},{"value":"Advances in Mathematics","name":"journaltitle","label":"Journal Title"},{"value":"https:\/\/doi.org\/10.1016\/j.aim.2017.04.017","name":"articlelink","label":"CrossRef DOI link to publisher maintained version"},{"value":"article","name":"content_type","label":"Content Type"},{"value":"\u00a9 2017 Elsevier Inc. All rights reserved.","name":"copyright","label":"Copyright"}]}}
END

my $jdata_member = <<'END';
{"status":"ok","message-type":"member","message-version":"1.0.0","message":{"last-status-check-time":1539154440433,"primary-name":"Journal of Dentistry Indonesia","counts":{"total-dois":405,"current-dois":54,"backfile-dois":351},"breakdowns":{"dois-by-issued-year":[[2008,212],[2013,81],[2018,20],[2017,19],[2015,16],[2016,15],[2014,13],[2010,10],[2011,9],[2009,9],[2012,1]]},"prefixes":["10.14693"],"coverage":{"affiliations-current":0.0,"similarity-checking-current":0.0,"funders-backfile":0.0,"licenses-backfile":0.0,"funders-current":0.0,"affiliations-backfile":0.0,"resource-links-backfile":0.0,"orcids-backfile":0.0,"update-policies-current":0.0,"open-references-backfile":0.0,"orcids-current":0.0,"similarity-checking-backfile":0.0,"references-backfile":0.0,"award-numbers-backfile":0.0,"update-policies-backfile":0.0,"licenses-current":0.0,"award-numbers-current":0.0,"abstracts-backfile":0.0,"resource-links-current":0.0,"abstracts-current":0.0,"open-references-current":0.0,"references-current":0.0},"prefix":[{"value":"10.14693","name":"Journal of Dentistry Indonesia","public-references":false,"reference-visibility":"limited"}],"id":5740,"tokens":["journal","of","dentistry","indonesia"],"counts-type":{"all":{"journal-article":405},"current":{"journal-article":54},"backfile":{"journal-article":351}},"coverage-type":{"all":{"journal-article":{"last-status-check-time":1539154437884,"affiliations":0.0,"abstracts":0.0,"orcids":0.0,"licenses":0.0,"references":0.0,"funders":0.0,"similarity-checking":0.0,"award-numbers":0.0,"update-policies":0.0,"resource-links":0.0,"open-references":0.0}},"backfile":{"journal-article":{"last-status-check-time":1539154437030,"affiliations":0.0,"abstracts":0.0,"orcids":0.0,"licenses":0.0,"references":0.0,"funders":0.0,"similarity-checking":0.0,"award-numbers":0.0,"update-policies":0.0,"resource-links":0.0,"open-references":0.0}},"current":{"journal-article":{"last-status-check-time":1539154436314,"affiliations":0.0,"abstracts":0.0,"orcids":0.0,"licenses":0.0,"references":0.0,"funders":0.0,"similarity-checking":0.0,"award-numbers":0.0,"update-policies":0.0,"resource-links":0.0,"open-references":0.0}}},"flags":{"deposits-abstracts-current":false,"deposits-orcids-current":false,"deposits":true,"deposits-affiliations-backfile":false,"deposits-update-policies-backfile":false,"deposits-similarity-checking-backfile":false,"deposits-award-numbers-current":false,"deposits-resource-links-current":false,"deposits-articles":true,"deposits-affiliations-current":false,"deposits-funders-current":false,"deposits-references-backfile":false,"deposits-abstracts-backfile":false,"deposits-licenses-backfile":false,"deposits-award-numbers-backfile":false,"deposits-open-references-backfile":false,"deposits-open-references-current":false,"deposits-references-current":false,"deposits-resource-links-backfile":false,"deposits-orcids-backfile":false,"deposits-funders-backfile":false,"deposits-update-policies-current":false,"deposits-similarity-checking-current":false,"deposits-licenses-current":false},"location":"Building C, Level 3, Faculty of Dentistry Universitas indonesia Jalan Salemba Raya No. 4 Jalan Salemba Raya No.4 Jakarta 10430 Indonesia","names":["Journal of Dentistry Indonesia"]}}
END

use Test::More;
use Data::Dumper;

BEGIN { use_ok('REST::Client::CrossRef'); }

my $client = REST::Client::CrossRef->new(
    spit_raw_data => 0,
    test_data     => $jdata_works,
    keys_to_keep  => [ ['title'], ['container-title'], ],
);

isa_ok( $client, 'REST::Client::CrossRef' );

# $client->_set_test_data($jdata_work);
my $data = $client->article_from_doi('10.1016/j.aim.2017.04.017');
my $href = $data->[0];

ok( $href->{'title'} eq "The integer cohomology algebra of toric arrangements", "got title (local data)") or diag( Dumper $href);
$href = $data->[1];

ok($href->{'container-title'} eq "Advances in Mathematics", "got journal title (local data)") or diag( Dumper $href);
   

$client = REST::Client::CrossRef->new(
    spit_raw_data => 0,
    add_end_flag  => 0,
    test_data     => $jdata_member,
    keys_to_keep  => [['prefix/name']  ],
);

$data = $client->member_from_id('5740');
for my $row (@$data) {
   ok($row->{'prefix/name'} eq "Journal of Dentistry Indonesia", "got member name (local data)") or diag( Dumper $data);
}

$client = REST::Client::CrossRef->new( spit_raw_data => 1 );

#$client->_set_test_data(undef);
$data = $client->get_types();

# print Dumper($data), "\n";
my $tests_run;
my $items_ar = $data->{message}->{items};
if (! defined $items_ar) {
    $tests_run=5;
}
else {
    my $total    = @$items_ar;
    cmp_ok( $total, '>=', 20, "got number of types from CrossRef" );
    $tests_run=6;
}
done_testing($tests_run);




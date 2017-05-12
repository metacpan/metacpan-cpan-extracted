#!perl
use strict;
use warnings;
use lib 'lib';
use IO::Prompt;
use Test::More;
use Test::Exception;

my ( $aws_access_key_id, $secret_access_key );

eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 60;
    $aws_access_key_id
        = prompt("Please enter an AWS access key ID for testing: ");
    alarm 60;
    $secret_access_key
        = prompt("Please enter a secret access key for testing: ");
    alarm 0;
};

if ( $aws_access_key_id && $secret_access_key
		&& length $aws_access_key_id->{value}
		&& length $secret_access_key->{value} ) {
    eval 'use Test::More tests => 22;';
} else {
    eval
        'use Test::More plan skip_all => "Need AWS access key ID and secret access key for testing, skipping"';
}

use_ok("Net::Amazon::AWIS");

my $awis = Net::Amazon::AWIS->new( $aws_access_key_id, $secret_access_key );
isa_ok( $awis, "Net::Amazon::AWIS", "Have an object back" );

my $data = $awis->url_info( url => "http://use.perl.org/" );

ok( !$data->{adult_content}, "not porn" );
is_deeply(
    $data->{categories},
    [   {   path  => 'Top/Computers/Programming/Languages/Perl',
            title => 'Languages/Perl'
        },
    ],
    "categories fine"
);

is( $data->{encoding}, "us-ascii", "encoding is us-ascii" );
is( $data->{locale},   "en",       "locale is en" );
ok( $data->{median_load_time} > 100,     "load time > 100ms" );
ok( $data->{percentile_load_time} < 100, "percentile" );
ok( $data->{rank} > 1000,                "rank" );
ok( scalar( @{ $data->{related} } ) > 5, "related" );

$data = $awis->web_map( url => "http://use.perl.org" );
ok( scalar( @{ $data->{links_in} } ) > 5, "links_in" );

my @results = $awis->crawl( url => "http://www.cpan.org", count => 10 );
cmp_ok( scalar(@results), '>=', 1, "At least one result" );

foreach my $result ( @results[ 0 .. 0 ] ) {
    like( $result->{url}, qr{http://(www\.)?cpan\.org:80/}, "url" );
    is( $result->{ip}, "66.39.76.93", "ip" );
    isa_ok( $result->{date}, 'DateTime', "date" );
    is( $result->{content_type}, "text/html", "content type is text/html" );
    is( $result->{code},         200,         "code" );
    cmp_ok( $result->{length}, '>', 5_000, "length > 5_000" );
    is( $result->{language}, "en.us-ascii", "language is en.us-ascii" );

    cmp_ok( scalar( @{ $result->{other_urls} } ), '>=', 0,  "Other urls" );
    cmp_ok( scalar( @{ $result->{images} } ),     '>=', 1,  ">= 1 images" );
    cmp_ok( scalar( @{ $result->{links} } ),      '>=', 15, ">= 15 links" );
}

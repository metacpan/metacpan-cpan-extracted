#!/usr/bin/env perl -T
use Test::More;
use Test::Exception;
use Data::Dumper;

if(!$ENV{DISQUS_API_SECRET} || !$ENV{DISQUS_ONLINE}) {
    plan skip_all => 'No live testing requested, set the DISQUS_ONLINE environment variable, and set the DISQUS_API_SECRET environment variable to your secret api key';
} else {
    my $api_secret = $ENV{DISQUS_API_SECRET};
    my $test_url   = '/applications/listUsage';

    use_ok 'Net::Disqus';
    use_ok 'Net::Disqus::Exception';
    use_ok 'Net::Disqus::UserAgent';

    my $ua = Net::Disqus::UserAgent->new(pass_content_as_is => 1, forcelwp => 1);
    my ($content, $rate) = $ua->request('get', 'http://search.cpan.org/search/', query => 'Mojolicious', mode => 'all');
    like($content, qr/Mojolicious/, 'LWP::UserAgent get OK');

    $ua = Net::Disqus::UserAgent->new(forcelwp => 1);
    ($content, $rate) = $ua->request('get', 'http://disqus.com/api/3.0/applications/listUsage', api_secret => $ENV{DISQUS_API_SECRET});
    ok(defined($content->{code}), 'LWP::UserAgent: Have a response code');
    ok(defined($content->{response}), 'LWP::UserAgent: Have a response value');
    ok(exists($rate->{'X-Ratelimit-Limit'}), 'LWP::UserAgent: Have a rate limit');

    done_testing();
}


#!perl

use strict;
use warnings;

use Perl::Critic::TestUtils 'pcritique';
use Test::More;

my @ok = (
    'HTTP::CookieJar::LWP->new',
    'HTTP::Cookies->can("new")',
    'LWP::UserAgent->new',
    'LWP::UserAgent -> new',
    'LWP::UserAgent->new( cookie_jar => undef )',
    'LWP::UserAgent->new( "cookie_jar" => undef )',
    # $cookies might be a HTTP::CookieJar::LWP
    'LWP::UserAgent->new( cookie_jar => $cookies )',
    'LWP::UserAgent->new( timeout => 10, max_redirect => 0 )',
    'LWP::UserAgent->new( agent => "cookie_jar" )',
    'LWP::UserAgent->new( agent => "cookie_jar", max_redirect => 2 )',
    'new LWP::UserAgent',
);

my @not_ok = (
    'HTTP::Cookies->new',
    'HTTP::Cookies -> new',
    "HTTP::Cookies\n-> new",
    'new HTTP::Cookies',
    'LWP::UserAgent->new( cookie_jar => {} )',
    'LWP::UserAgent -> new ( cookie_jar => {} )',
    'LWP::UserAgent->new( "cookie_jar" => {} )',
    'LWP::UserAgent->new( cookie_jar => { } )',
    "LWP::UserAgent->new(\ncookie_jar => {}\n)",
    'LWP::UserAgent->new( timeout => 10, cookie_jar => {}, max_redirect => 0 )',
    'LWP::UserAgent->new( cookie_jar => undef, cookie_jar => {}, )',
    'LWP::UserAgent->new( cookie_jar, {} )',
    'LWP::UserAgent->new("cookie_jar"=>{})',
    'new LWP::UserAgent ( cookie_jar => {} )',
);

my @todo_ok = (
    'LWP::UserAgent->new( cookie_jar => {}, cookie_jar => undef )',
);

my @todo_not_ok = (
    'my $ua = LWP::UserAgent->new; $ua->cookie_jar({});',
);

my $policy = 'HTTPCookies';

plan tests => @ok + @not_ok + @todo_ok + @todo_not_ok;

foreach my $code (@ok) {
    my $violations = pcritique($policy, \$code);
    is $violations, 0, "Nothing wrong: $code";
}

foreach my $code (@not_ok) {
    my $violations = pcritique($policy, \$code);
    is $violations, 1, "Violation: $code";
}

foreach my $code (@todo_ok) {
    local $TODO = 'Unimplemented';
    my $violations = pcritique($policy, \$code);
    is $violations, 0, "Nothing wrong: $code";
}

foreach my $code (@todo_not_ok) {
    local $TODO = 'Unimplemented';
    my $violations = pcritique($policy, \$code);
    is $violations, 1, "Violation: $code";
}

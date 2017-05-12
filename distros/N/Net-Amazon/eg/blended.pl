#!/usr/bin/perl
###########################################
use warnings;
use strict;

use Net::Amazon;
use Net::Amazon::Request::Blended;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

my $ua = Net::Amazon->new(
    associate_tag => $ENV{AMAZON_ASSOCIATE_TAG},
    token         => $ENV{AMAZON_TOKEN},
    secret_key    => $ENV{AMAZON_SECRET_KEY},
);
my $response = $ua->search(blended => ($ARGV[0] || "Perl"));

if($response->is_success()) {
    print $response->total_results(), "\n";
}

__END__

my @properties = $response->properties();

foreach (@properties) {
        print $_->as_string() . "\n";
}

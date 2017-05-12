#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Test::More qw(no_plan);

BEGIN { use_ok("Serengeti::Backend::Native::Transport::Curl"); }

my $transport = Serengeti::Backend::Native::Transport::Curl->new();

isa_ok($transport, "Serengeti::Backend::Native::Transport::Curl");

my $response = $transport->get("http://www.google.com/search", { 
    hl => "en",
    source => "hp",
    q => "foo",
});

like($response->decoded_content, qr{<title>foo - Google Search</title>});


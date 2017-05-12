#!/usr/bin/env perl

$|=1;

use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Reflexive::Client::HTTP is a wrapper for POE::Component::Client::HTTP.

use Reflexive::Client::HTTP;

### Main usage.

use HTTP::Request;

# 1. Create a user-agent object.

my $ua = Reflexive::Client::HTTP->new;

# 2. Send a request.

$ua->request(
	HTTP::Request->new( GET => $_ ),
	sub { print $_->code.":".join('|',@_)."\n" },
	$_
) foreach (
	'http://poe.perl.org/',
	'http://duckduckgo.com/',
	'http://metacpan.org/',
	'http://perl.org/',
	'http://twitter.com/',
);

# 3. Wait for stuff.

Reflex->run_all();

exit;

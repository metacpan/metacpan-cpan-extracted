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

$ua->request( HTTP::Request->new( GET => 'http://duckduckgo.com/' ) );

# 3. Use promise syntax to wait for the next response.

my $event = $ua->next();

# 4. Process the response. $event == Reflexive::Client::HTTP::ResponseEvent

print $event->response->as_string();

exit;
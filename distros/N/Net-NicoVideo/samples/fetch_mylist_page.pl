#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;

my $page = Net::NicoVideo->new->fetch_mylist_page;
say "taken token: ". $page->token;

1;
__END__

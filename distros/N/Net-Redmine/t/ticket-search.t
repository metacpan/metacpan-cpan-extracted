#!/usr/bin/env perl -w
use strict;
use Test::More;
use Quantum::Superpositions;
use Net::Redmine;
use Net::Redmine::Search;

require 't/net_redmine_test.pl';
my $r = new_net_redmine();

plan tests => 1;

### Prepare new tickets. The default page size is 15. The number of
### tickets created here should be larger then that in order to prove
### that it crawls all pages of search results.

my @tickets = new_tickets($r, 20);

my @found = $r->search_ticket(__FILE__)->results;

ok( all( map { $_->id } @tickets ) == any(map { $_-> id } @found), "All the newly created issues can be found in the search result." );

$_->destroy for @tickets;

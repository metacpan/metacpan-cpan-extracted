#!/usr/bin/env perl
# FILENAME: users.pl
# CREATED: 02/13/14 20:06:37 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Show users by passing a github token

use strict;
use warnings;
use utf8;

# example usage:
#
# perl ./users.pl $(git config github.token)
#
use Net::Travis::API::Auth::GitHub;

die "$0 <githubtoken>" if @ARGV < 1;

my $ua = Net::Travis::API::Auth::GitHub->get_authorised_ua_for( $ARGV[0] );

die "Could not authorize" unless defined $ua;

my $result = $ua->get('/users');

my $json = $result->content_json;

use Data::Dump qw(pp);

pp($json);

1;

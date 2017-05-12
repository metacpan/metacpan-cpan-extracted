#!/usr/bin/env perl
# FILENAME: get_authtoken_from_github_authtoken.pl
# CREATED: 02/13/14 19:55:30 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Give a GitHub API Token and get a Travis Token in return

use strict;
use warnings;
use utf8;

# Example usage:
#
# perl ./get_authtoken_from_github_authtoken.pl $(git config github.token)
#
use Net::Travis::API::Auth::GitHub;

die "$0 <githubtoken>" if @ARGV < 1;

my $token = Net::Travis::API::Auth::GitHub->get_token_for( $ARGV[0] );

if ( not $token ) {
  die "Could not get token";
}

print $token;


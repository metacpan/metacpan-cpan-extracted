#!/usr/bin/env perl
# FILENAME: create_github_repo.pl
# CREATED: 12/21/13 22:40:10 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Create a github repo for the current repository

use strict;
use warnings;
use utf8;
use Carp qw(croak);

sub _git_config {
  my $key = shift;
  chomp( my $value = `git config --get $key` );
  croak "Unknown $key" unless $value;
  return $value;
}

if ( not @ARGV == 2 ) {
  die "$0 Repo-Name-Here \"Some Description\"";
}

my $github_user  = _git_config('github.user');
my $github_token = _git_config('github.token');

use Net::GitHub;
my $gh = Net::GitHub->new( access_token => $github_token );
my $reponame = "git\@github.com:" . $github_user . "/" . $ARGV[0] . ".git";
print "Creating $reponame \n";

my $rp = $gh->repos->create(
  {
    name        => $ARGV[0],
    description => $ARGV[1],
  }
);

system( 'git', 'remote', 'add', 'origin', $reponame );


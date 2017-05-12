#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use Carp;
use Net::GitHub;
use Getopt::Lucid ':all';
use Path::Tiny;
use FindBin;

my $yamls = path($FindBin::Bin)->child('yamls');

my $opts = Getopt::Lucid->getopt(
  [
        #<<< No perltidy
        Param('repo|r'),
        #>>>
  ]
);

$opts->validate;

sub _detect_repo {
  my ($origin) = grep { /origin/ } `git remote -v`;

  die "Couldn't determine origin\n" unless $origin;

  chomp $origin;
  $origin =~ s/^origin\s+//;
  $origin =~ s/\s+\(.*$//;
  if ( $origin =~ m{^.+?://github.com/([^/]+)/(.+)\.git$} ) {
    return [ $1, $2 ];
  }
  elsif ( $origin =~ m{^git\@github\.com:([^/]+)/(.+)\.git$} ) {
    return [ $1, $2 ];
  }
  else {
    die "Can't determine repo name from '$origin'.  Try manually with -r REPO\n";
  }
}

sub _git_config {
  my $key = shift;
  chomp( my $value = `git config --get $key` );
  croak "Unknown $key" unless $value;
  return $value;
}

my $github_user  = _git_config("github.user");
my $github_token = _git_config("github.token");
my $travis_token = _git_config("travis.token");

my $gh = Net::GitHub->new( access_token => $github_token );

my @repos;

if ( $opts->get_repo ) {
  @repos = $opts->get_repo;
}
else {
  ( $github_user, @repos ) = @{ _detect_repo() };
}

my $hook_hash = {
  name   => 'travis',
  config => {
    token  => $travis_token,
    user   => $github_user,
    domain => '',
  },
  events => [qw/push pull_request issue_comment public member/],
  active => 1,
};

my $repos = $gh->repos;
$repos->set_default_user_repo( $github_user, $repos[0] );
my $hook = eval { $repos->create_hook($hook_hash) };
if ($@) {
  say "Failed: $@";
}
else {
  say "Enabled travis for $repos[0]";
}

unless ( -f '.travis.yml' ) {
  $yamls->child('sterile2.yaml')->copy('./.travis.yml');
  say "copied .travis.yml to current directory";
}

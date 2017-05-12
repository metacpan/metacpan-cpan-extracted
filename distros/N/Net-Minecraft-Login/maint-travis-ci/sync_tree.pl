#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

use Path::FindDev qw( find_dev );
my $root = find_dev('./');

chdir "$root";

sub git_subtree {
  safe_exec( 'git', 'subtree', @_ );
}

my $travis = 'https://github.com/kentfredric/travis-scripts.git';
my $prefix = 'maint-travis-ci';

my $opts = { pushas => 'incomming' };

for my $id ( 0 .. $#ARGV ) {
  my ($field) = $ARGV[$id];
  next unless $field;
  next unless $field =~ /^-+(.*?$)/;
  my ($field_name) = $1;
  my ($value)      = $ARGV[ $id + 1 ];
  undef $ARGV[$id];
  undef $ARGV[ $id + 1 ];
  if ( $field_name eq 'push' ) {
    $opts->{push}    = 1;
    $opts->{push_to} = $value;
    next;
  }
  if ( $field_name eq 'pushas' ) {
    $opts->{pushas} = $value;
    next;
  }
  if ( $field_name eq 'mc' ) {
    $opts->{has_commit} = 1;
    $opts->{commit}     = $value;
    next;
  }
}
if ( not $opts->{push} ) {
  my $commitish = 'master';
  $commitish = $opts->{commit} if $opts->{has_commit};

  if ( not -d -e $root->child($prefix) ) {
    git_subtree( 'add', '--squash', '--prefix=' . $prefix, $travis, $commitish );
  }
  else {
    git_subtree( 'pull', '--squash', '-m', 'Synchronise git subtree maint-travis-ci', '--prefix=' . $prefix, $travis,
      $commitish );
  }
}
else {
  git_subtree( 'push', '--prefix=' . $prefix, $opts->{push_to}, $opts->{pushas} );
}


#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

if ( not env_exists('TRAVIS') ) {
  diag('Is not running under travis!');
  exit 1;
}
if ( not env_exists('STERILIZE_ENV') ) {
  diag("\e[31STERILIZE_ENV is not set, skipping, because this is probably Travis's Default ( and unwanted ) target");
  exit 0;
}

# See https://github.com/dbsrgits/dbix-class/commit/8c11c33f8
safe_exec_nonfatal( 'sudo', 'ip6tables', '-I', 'OUTPUT', '-d', 'api.metacpan.org', '-j', 'REJECT' );
my (@params) = qw[ --quiet --notest --mirror http://cpan.metacpan.org/ --no-man-pages ];
my ($branch) = $ENV{TRAVIS_BRANCH};
my ($prefix) = './.travis_early_installdeps.';

$branch =~ s{/}{_}g;
my ($depsfile)   = ( $prefix . $branch );
my ($paramsfile) = ( $prefix . 'params.' . $branch );

if ( not( -e $depsfile and -f $depsfile ) ) {
  diag("\e[31m$depsfile does not exist, no extra deps\e[0m");
  exit 0;
}

my (@deps) = split /\n/, do {
  open my $fh, '<', $depsfile;
  local $/ = undef;
  scalar <$fh>;
};
if ( -e $paramsfile and -f $paramsfile ) {
  push @params, split /\n/, do {
    open my $fh, '<', $paramsfile;
    local $/ = undef;
    scalar <$fh>;
  };
}
cpanm( @params, @deps );
exit 0;

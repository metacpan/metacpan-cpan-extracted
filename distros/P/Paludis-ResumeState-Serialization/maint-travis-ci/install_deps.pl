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
if ( env_is( 'TRAVIS_BRANCH', 'master' ) and env_is( 'TRAVIS_PERL_VERSION', '5.8' ) ) {
  diag("\e[31minstalldeps skipped on 5.8 on master, because \@Git, a dependency of \@Author::KENTNL, is unavailble on 5.8\e[0m");
  exit 0;
}
my (@params) = qw[ --quiet --notest --mirror http://cpan.metacpan.org/ --no-man-pages ];
if ( env_true('DEVELOPER_DEPS') ) {
  push @params, '--dev';
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) ) {
  cpanm( @params, 'Dist::Zilla', 'Capture::Tiny',      'Pod::Weaver' );
  cpanm( @params, '--dev',       'Dist::Zilla~>5.002', 'Pod::Weaver' );
  safe_exec( 'git', 'config', '--global', 'user.email', 'kentfredric+travisci@gmail.com' );
  safe_exec( 'git', 'config', '--global', 'user.name',  'Travis CI ( On behalf of Kent Fredric )' );

  my $stdout = capture_stdout {
    safe_exec( 'dzil', 'authordeps', '--missing' );
  };

  if ( $stdout !~ /^\s*$/msx ) {
    cpanm( @params, split /\n/, $stdout );
  }
  $stdout = capture_stdout {
    safe_exec( 'dzil', 'listdeps', '--missing' );
  };

  if ( $stdout !~ /^\s*$/msx ) {
    cpanm( @params, split /\n/, $stdout );
  }
}
else {
  cpanm( @params, '--installdeps', '.' );
  if ( env_true('AUTHOR_TESTING') or env_true('RELEASE_TESTING') ) {
    my $prereqs = parse_meta_json()->effective_prereqs;
    my $reqs = $prereqs->requirements_for( 'develop', 'requires' );
    my @wanted;

    for my $want ( $reqs->required_modules ) {
      my $module_requirement = $reqs->requirements_for_module($want);
      if ( $module_requirement =~ /^\d/ ) {
        push @wanted, $want . '~>=' . $module_requirement;
        next;
      }
      push @wanted, $want . '~' . $module_requirement;
    }
    cpanm( @params, @wanted );

  }
}

exit 0;

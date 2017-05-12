#!/usr/bin/perl

use strict;
use warnings;
use Shell::Guess;
use Shell::Config::Generate;

my $config = Shell::Config::Generate->new;
$config->comment( 'this is my config file' );
$config->set( FOO => 'bar' );
$config->set_path( 
  PERL5LIB => '/foo/bar/lib/perl5', 
              '/foo/bar/lib/perl5/perl5/site',
);
$config->append_path(
  PATH => '/foo/bar/bin',
          '/bar/foo/bin',
);

$config->generate_file(Shell::Guess->bourne_shell, 'config.sh');
$config->generate_file(Shell::Guess->c_shell, 'config.csh');
$config->generate_file(Shell::Guess->cmd_shell, 'config.cmd');

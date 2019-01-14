#!/usr/bin/env perl
# Run this like so: `perl pml2base.t'
#   Matyas Kopp <matyas.kopp@gmail.com>     2015/09/19 20:30:00

use Test::Most;
use File::Spec;
use Cwd;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'lib' ) );

BEGIN {
  require 'test_commands.pl';    # Load subs to test commands
}

use Capture::Tiny ':all';
use PMLTQ;
use PMLTQ::Commands;
use PMLTQ::Command;
use File::Temp;

start_postgres();

my @CMDS = qw/initdb verify convert delete load/;

subtest command => sub {
  lives_ok { PMLTQ::Commands->run('help') } 'help command ok';
  throws_ok {
    PMLTQ::Commands->run('UNKNOWN_COMMAND')
  }
  qr/unknown command/i, 'calling unknown command fails';
};

subtest help => sub {
  for my $c (@CMDS) {
    my @args = ( 'help', $c, 1 );
    my $h = capture_merged {
      lives_ok { PMLTQ::Commands->run(@args) } "calling help for $c command";
    };
    unlike( $h, qr/^$/, "$c help is not empty" );
  }

  my $c = 'UNKNOWN_COMMAND';
  my @args = ( 'help', "$c", 1 );
  throws_ok { PMLTQ::Commands->run(@args) } qr/unknown command/i, "$c help contains warning 'unknown command'";

  my $h = capture_merged {
    lives_ok { PMLTQ::Commands->run('help') } 'calling help without parameters';
  };
  unlike( $h, qr/^$/, 'help is not empty' );
};

my $cwd = getcwd();

for my $treebank ( treebanks() ) {
  my $tmp_dir       = File::Temp->newdir( CLEANUP => 0 );
  my $output_dir    = $tmp_dir->dirname;
  my $treebank_name = $treebank->{name};
  my $config        = $treebank->{config};

  chdir $treebank->{dir};

  # create, convert and load treebank to the database
  verify( $config, $output_dir );

  # test treebank
  test_queries_for($treebank_name);

  # drop treebank
  del($config);
}

chdir $cwd;

done_testing();



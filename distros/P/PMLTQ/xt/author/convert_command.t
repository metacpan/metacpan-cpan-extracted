#!/usr/bin/env perl
# Run this like so: `perl convert_command.t'
#   Michal Sedlak <sedlakmichal@gmail.com>     2014/05/07 15:13:00

use Test::Most;
use File::Spec;
use File::Basename qw/dirname basename/;
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'lib' ) );

BEGIN {
  require 'bootstrap.pl';    ## no critic
}

use File::Temp qw/ tempfile tempdir /;
use File::Slurp 'write_file';

use PMLTQ::Command::convert;
use Test::MockModule;
use Module::Spy;

my $Pml2baseMock = Test::MockModule->new('PMLTQ::PML2BASE');
my $PmlFactoryMock = Test::MockModule->new('Treex::PML::Factory');

my ( $init_called, @files_converted, $destroy_called, $finish_called );

sub _reset {
  @files_converted = ();
  ( $init_called, $destroy_called, $finish_called ) = ( 0, 0, 0 );
}

$PmlFactoryMock->mock(createDocumentFromFile => sub { shift; shift; });

$Pml2baseMock->mock( init => sub { $init_called = 1 } );
$Pml2baseMock->mock( fs2base => sub { my $fsfile = shift; push @files_converted, $fsfile; } );
$Pml2baseMock->mock( destroy => sub { $destroy_called = 1 } );
$Pml2baseMock->mock( finish  => sub { $finish_called  = 1 } );

my @files = qw{file1.a file2.t /abs/path/file3.a};

# setup testing files
my $output_dir    = tempdir( CLEANUP => 1 );
my $resources_dir = tempdir( CLEANUP => 1 );

my $data_dir = tempdir( CLEANUP => 1 );
for (@files) {
  write_file( File::Spec->catfile( $data_dir, basename($_) ), 'FILE' );
}

sub test_conversion {
  ok $init_called, 'init called';

  my $expected = [ map { basename($_) } @files ];
  my $got      = [ map { basename($_) } @files_converted ];
  cmp_bag( $got, $expected, 'files has been processed' );

  ok $finish_called,  'finished';
  ok $destroy_called, 'destroyed';
  _reset();
}

subtest 'Test glob loading' => sub {
  my $cmd = PMLTQ::Command::convert->new(
    config => {
      resources  => $resources_dir,
      output_dir => $output_dir,
      data_dir   => $data_dir,
      layers     => [
        {
          name       => 'test_layer',
          data       => '*.{a,t}',
          references => {}
        }
      ]
    }
  );

  my $spy = spy_on( $cmd, 'load_filelist' )->and_call_through;
  $cmd->run();
  test_conversion();
  ok !$spy->called, 'not loaded from filelist';
};

subtest 'Test filelist loading' => sub {
  my (undef, $filelist) = tempfile();
  write_file($filelist, "\n" . join("\n", @files) . "\n");

  my $cmd = PMLTQ::Command::convert->new(
    config => {
      resources  => $resources_dir,
      output_dir => $output_dir,
      data_dir   => $data_dir,
      layers     => [
        {
          name       => 'test_layer',
          filelist   => $filelist,
          references => {}
        }
      ]
    }
  );

  my $spy = spy_on( $cmd, 'load_filelist' )->and_call_through;
  $cmd->run();
  test_conversion();
  ok $spy->called, 'loaded from filelist';
};

done_testing();

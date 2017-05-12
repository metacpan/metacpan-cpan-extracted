#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use MySQL::Workbench::DBIC;

my $file        = '/test.xml';
my $namespace   = 'MyApp::DB';
my $output_path = '/Test';

my $foo = MySQL::Workbench::DBIC->new(
  file        => $file,
  output_path => $output_path,
  namespace   => $namespace,
);

isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type F::D::D' );
is( $foo->file, $file, 'input_file' );
is( $foo->output_path, $output_path, 'output_path' );
is( $foo->namespace, $namespace, 'namespace' );

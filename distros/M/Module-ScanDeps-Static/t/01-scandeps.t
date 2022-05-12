use strict;
use warnings;

use lib qw{ . lib };

use Test::More;
use Data::Dumper;

plan tests => 3;

use_ok qw{ Module::ScanDeps::Static };
my $data_start_pos = tell DATA;

subtest 'use' => sub {
  my $scanner = Module::ScanDeps::Static->new( { handle => *DATA } );

  my @dependencies = $scanner->parse;

  ok( scalar @dependencies > 0, 'found dependencies' );

  my $module_names = join '', map { $_->{'name'} } @dependencies;
  is( $module_names, 'Buz::BazCarpFoo::Bar', 'sorted dependencies' );

  isa_ok( $dependencies[2], 'HASH', 'return hash' );

  ok( exists $dependencies[2]->{'name'}, 'name in hash' );

  is( $dependencies[2]->{'name'}, 'Foo::Bar', 'Foo::Bar' );

  ok( exists $dependencies[2]->{'version'}, 'name in hash' );

  is( $dependencies[2]->{'version'}, q{},    'version is empty string' );
  is( $dependencies[0]->{'version'}, q{1.0}, 'version is 1.0' )
    or diag( Dumper \@dependencies );

};

subtest 'require' => sub {
  seek DATA, $data_start_pos, 0;

  my $scanner = Module::ScanDeps::Static->new( { handle => *DATA } );

  my @dependencies = $scanner->parse;

  ok( @dependencies, 'found 3 dependencies' )
    or diag( Dumper \@dependencies );

  ok( $dependencies[1]->{'name'} eq 'Carp',  'found require' );
  ok( defined $dependencies[1]->{'version'}, 'version defined' );

};

1;

__DATA__
use Buz::Baz 1.0;
use Foo::Bar;

require Carp;

use strict;
use warnings;

use lib qw{ . lib };

use Test::More;
use Data::Dumper;

plan tests => 3;

use_ok qw{ Module::ScanDeps::Static };
my $data_start_pos = tell DATA;

subtest 'use' => sub {
  my $scanner
    = Module::ScanDeps::Static->new( { handle => *DATA, add_version => 1 } );

  my @dependencies = $scanner->parse;
  my $require      = $scanner->get_require;

  ok( scalar @dependencies > 0, 'found dependencies' );
  isa_ok( $require, 'HASH', 'require is a HASH' );

  my $module_names = join '', @dependencies;

  is( $module_names,    'Buz::BazCarpFoo::Bar', 'sorted dependencies' );
  is( $dependencies[2], 'Foo::Bar',             'Foo::Bar' );

  ok( exists $require->{'Foo::Bar'}, 'version for Foo::Bar in hash' );
  is( $require->{'Foo::Bar'}, q{}, 'version is empty string' );

  is( $require->{'Buz::Baz'}, q{1.0}, 'version of Buz::Baz is 1.0' )
    or diag( Dumper \@dependencies );

};

subtest 'require' => sub {
  seek DATA, $data_start_pos, 0;

  my $scanner = Module::ScanDeps::Static->new( { handle => *DATA } );

  my @dependencies = $scanner->parse;
  my $require      = $scanner->get_require;

  ok( @dependencies, 'found 3 dependencies' )
    or diag( Dumper \@dependencies );

  ok( grep {/Carp/} @dependencies, 'found require Carp' )
    or diag( Dumper \@dependencies );

  ok( defined $require->{'Carp'}, 'version defined' );

};

1;

__DATA__
use Buz::Baz 1.0;
use Foo::Bar;

require Carp;

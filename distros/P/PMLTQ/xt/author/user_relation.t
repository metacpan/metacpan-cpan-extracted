#!/usr/bin/env perl
# Run this like so: `perl user_relation.t'
#   Michal Sedlak <sedlakmichal@gmail.com>     2014/05/07 15:13:00

use Test::Most;
use File::Spec;
use File::Basename 'dirname';
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'lib' ) );

BEGIN {
  require 'bootstrap.pl';
}

use List::Util 'first';

use PMLTQ::TypeMapper;
use PMLTQ::Relation;

# Mocks
use PML;
use TredMacro;

my $PDT_TREEBANK   = 'pdt_test';
my $TREEX_TREEBANK = 'treex_test';

subtest pdt_relations => sub {
  my @files = treebank_files($PDT_TREEBANK);

  my $a_file = first {/a\.gz$/} @files;
  my $a_type_mapper = PMLTQ::TypeMapper->new( { fsfile => open_file($a_file) } );

  cmp_bag( $a_type_mapper->get_user_defined_relations('a-node'), [qw/eparent echild/], 'a-node user relations' );

  is($a_type_mapper->get_relation_target_type('a-node',$_->[0],'implementation'),$_->[1],"Target type $_->[1] is correct for $_->[0] relation") for map {[$_,'a-node']} qw/eparent echild/;
  is($a_type_mapper->get_relation_target_type('a-node',$_,'implementation'),undef,"Target type is undefined for $_ relation") for  qw{eparentC echildC a/lex.rf|a/aux.rf UNKNOWNRELATION};
  

  my $t_file = first {/t\.gz$/} @files;
  my $t_type_mapper = PMLTQ::TypeMapper->new( { fsfile => open_file($t_file) } );

  cmp_bag( $t_type_mapper->get_user_defined_relations('t-node'), [qw{eparent echild a/lex.rf|a/aux.rf}], 't-node user relations' );

  is($t_type_mapper->get_relation_target_type('t-node',$_->[0],'implementation'),$_->[1],"Target type $_->[1] is correct for $_->[0] relation") for (['a/lex.rf|a/aux.rf', 'a-node'], map {[$_,'t-node']} qw/eparent echild/);
  is($t_type_mapper->get_relation_target_type('t-node',$_,'implementation'),undef,"Target type is undefined for $_ relation") for  qw{eparentC echildC  UNKNOWNRELATION};
};

subtest treex_relations => sub {
  my @files = treebank_files($TREEX_TREEBANK);
  my $file = shift @files;
  my $type_mapper = PMLTQ::TypeMapper->new( { fsfile => open_file($file) } );

  cmp_bag( $type_mapper->get_user_defined_relations('a-node'), [qw/eparent eparentC echild echildC/], 'a-node user relations' );
  cmp_bag( $type_mapper->get_user_defined_relations('t-node'), [qw/eparent echild/], 't-node user relations' );
  is($type_mapper->get_relation_target_type($_->[1],$_->[0],'implementation'),$_->[1],"Target type $_->[1] is correct for $_->[1] with $_->[0] relation") 
      for ( (map {[$_,'a-node']} qw/eparent eparentC echild echildC/), (map {[$_,'t-node']} qw/eparent echild/));
  is($type_mapper->get_relation_target_type('t-node',$_,'implementation'),undef,"t-node target type is undefined for $_ relation") for  qw{eparentC echildC UNKNOWNRELATION};
};

done_testing();

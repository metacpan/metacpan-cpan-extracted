#$Id$

use Test::More tests => 68;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
no warnings qw(once);
my @cleanup;
my $build;
my ($user,$pass);

eval {
  $build = Module::Build->current;
  $user = $build->notes('user');
  $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';
my $num_live_tests = 67;

use_ok('REST::Neo4p');

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  my @node_defs = 
    (
     { name => 'A', type => 'purine' },
     { name => 'T', type => 'pyrimidine' },
     { name => 'G', type => 'purine'},
     { name => 'C', type => 'pyrimidine' }
    );
  @cleanup = my ($A,$T,$G,$C) = map { REST::Neo4p::Node->new($_) } @node_defs;
  for (@cleanup) {
    isa_ok($_, 'REST::Neo4p::Node')
  }
  
  ok my $nt_types = REST::Neo4p::Index->new('node','nt_types'), 'create node index';
  ok my $nt_names = REST::Neo4p::Index->new('node','nt_names'), 'create node index(2)';
  ok my $nt_comment = REST::Neo4p::Index->new('node','nt_comment',
					     { type => 'fulltext',
					       provider => 'lucene' }), 
						 'create node index (test uri_escape)';
  push @cleanup, $nt_types if $nt_types;
  push @cleanup, $nt_names if $nt_names;
  push @cleanup, $nt_comment if $nt_comment;

  ok $nt_types->add_entry($A, 'type' => 'purine'),'add A to types';
  ok $nt_types->add_entry($C, 'type' => 'pyrimidine'), 'add C to types';
  ok $nt_types->add_entry($G, 'type' => 'purine'), 'add G to types';
  ok $nt_types->add_entry($T, 'type' => 'pyrimidine'), 'add T to types';
  ok $nt_names->add_entry($A, 'fullname' => 'adenine'),'add A to names';
  ok $nt_names->add_entry($C, 'fullname' => 'cytosine'), 'add C to names';
  ok $nt_names->add_entry($G, 'fullname' => 'guanosine'), 'add G to names';
  ok $nt_names->add_entry($T, 'fullname' => 'thymidine'), 'add T to names';

  diag("rt80440");
  ok $nt_names->add_entry($T, 'nickname' => 'old_thymy',
			      'friends_call_him' => 'Mr_T'), 
  'add multiple key/values (rt80440)';
  ok my ($mrt) = $nt_names->find_entries('friends_call_him' => 'Mr_T'), 'found multiply added entry';
  is $mrt->get_property('name'), 'T', 'found right node';

  ok $nt_comment->add_entry($C, 'comment' => 'Man, this is my fave nucleotide!'), 'funky value added';
  ok $nt_comment->add_entry($T, 'comment' => 'This one & A spell "at"'), 'funky value added';

  ok my $nt_muts = REST::Neo4p::Index->new('relationship','nt_muts'), 'create relationship index';
  push @cleanup, $nt_muts if $nt_muts;
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $A->relate_to($T,'transition'),
			 'mut_type' => 'transition'
			 ), 'add A->T';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $T->relate_to($A,'transition'),
			 'mut_type' => 'transition'
			 ), 'add T->A';
  ok $nt_muts->add_entry(  $cleanup[@cleanup] =
			 $C->relate_to($G,'transition'),
			 'mut_type' => 'transition'
			), 'add C->G';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $G->relate_to($C,'transition'),
			 'mut_type' => 'transition'
			 ), 'add G->C';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $A->relate_to($T,'transversion'),
			 'mut_type' => 'transversion'
			), 'add A->T';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $A->relate_to($C,'transversion'),
			 'mut_type' => 'transversion'
			 ), 'add A->C';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $T->relate_to($A,'transversion'),
			 'mut_type' => 'transversion'
			), 'add T->A';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $T->relate_to($G,'transversion'),
			 'mut_type' => 'transversion'
			), 'add T->G';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $C->relate_to($A,'transversion'),
			 'mut_type' => 'transversion'
			), 'add C->A';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $C->relate_to($T,'transversion'),
			 'mut_type' => 'transversion'
			), 'add C->T';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $G->relate_to($A,'transversion'),
			 'mut_type' => 'transversion'
			), 'add G->A';
  ok $nt_muts->add_entry( $cleanup[@cleanup] =
			 $G->relate_to($T,'transversion'),
			 'mut_type' => 'transversion'
			 ), 'add G->T';


  ok my @purines = $nt_types->find_entries( type => 'purine' ), 'find purines';
  cmp_ok scalar @purines, '>=', 2, 'found purines';
  for (@purines) {
    is $_->get_property('type'), 'purine', 'node has purine type'
  }
  ok my @pyrimidines = $nt_types->find_entries( type => 'pyrimidine' ), 'find pyrimidines';
  cmp_ok scalar @pyrimidines,'>=', 2, 'found pyrimidines';
  for (@pyrimidines) {
    is $_->get_property('type'), 'pyrimidine', 'node has pyrimidine type'
  }
  
  ok my @nts = $nt_names->find_entries( fullname => 'adenine' ), 'find A on fullname key';
  cmp_ok scalar @nts,'>=', 1, 'found nt';
  is $nts[0]->get_property('name'),'A', 'found A as adenine';

  ok my @commented = $nt_comment->find_entries('comment:*spell*'), 'find T in comment index with lucene query';
  cmp_ok scalar @commented, '>=', 1, 'found one';
  is $commented[0]->get_property('name'), 'T', 'found T with comment';
}

END {
  CLEANUP : {
    ok ($_->remove, 'entity removed') for reverse @cleanup;
  }
  }

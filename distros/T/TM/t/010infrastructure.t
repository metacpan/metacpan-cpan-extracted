use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

use TM::PSI;

#== TESTS =====================================================================

require_ok ('TM::PSI');
require_ok ('TM');

#&TM::_prime_infrastructure;
##warn Dumper $TM::infrastructure;

{
    ok (keys %{ $TM::infrastructure->{mid2iid} },    'toplets infrastructure created');
    ok (keys %{ $TM::infrastructure->{assertions} }, 'asserts infrastructure created');

    is (scalar keys %{ $TM::infrastructure->{mid2iid} },
	  scalar (keys %{$TM::PSI::core->{mid2iid}})
	+ scalar (keys %{$TM::PSI::topicmaps_inc->{mid2iid}})
	+ scalar (keys %{$TM::PSI::tmql_inc->{mid2iid}})
	+ scalar (keys %{$TM::PSI::astma_inc->{mid2iid}})
	, 
	'predefined concepts in map');
}

{
    my $tm = new TM;
    ok (eq_set ([ $tm->toplets (\ '+infrastructure') ],
		[ values %{ $TM::infrastructure->{mid2iid} } ]), 
	'infrastructure toplets in map');

    ok (eq_set ([ $tm->toplets (\ '+all -infrastructure') ],
		[  ]), 
	'all - infrastructure toplets in map');

    is (grep (!defined $_, $tm->tids (keys %{$TM::PSI::core->{mid2iid}})), 0, 'no undefined iid (core)');
    ok (eq_array ([
		   $tm->tids (qw(thing is-subclass-of isa us))
		   ], 
		  [
		   'thing',
		   'is-subclass-of',
		   'isa',
		   'us',
		   ]
		  ), 'found predefined');
    ok (eq_array ([
		   $tm->mids (\ 'http://psi.topicmaps.org/sam/1.0/#type-instance',
			      \ 'http://www.topicmaps.org/xtm/#psi-superclass-subclass')
		   ], 
		  [
		   'isa',
		   'is-subclass-of',
		   ]
		  ), 'found predefined 2');
    is (scalar $tm->match (TM->FORALL, type => 'isa', iplayer => 'assertion-type'),    2, 'assertion-type: all instances');
}

{
    my $tm = new TM;
    ok ($tm->isa ('TM'), 'class');
    is ($tm->baseuri, 'tm://nirvana/', 'baseuri default');
    ok ($tm->{created}, 'created there');
}

{ # baseuri
    my $tm = new TM (baseuri => 'xxx:yyy');
    is ($tm->baseuri, 'xxx:yyy#', 'baseuri set');

    $tm->baseuri ('xxx');
    is ($tm->baseuri, 'xxx:yyy#', 'baseuri immutable');
}

{ # consistency accessors
    my $tm = new TM;
    ok (eq_set([ $tm->consistency ],
	       [ TM->Subject_based_Merging,
		 TM->Indicator_based_Merging ] ), 'default consistency');

    $tm = new TM (consistency => [ TM->Subject_based_Merging ]);
    ok (eq_set([ $tm->consistency ],
               [ TM->Subject_based_Merging ] ),   'explicit consistency');

    $tm->consistency (TM->Indicator_based_Merging);
    ok (eq_set([ $tm->consistency ],
	       [ TM->Indicator_based_Merging ] ), 'changed consistency');
}

__END__

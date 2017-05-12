use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use constant DONE => 1;

my $AG_SERVER = $ENV{AG4_SERVER};

unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

use RDF::AllegroGraph::Server;
my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
# TODO: generate scratch here
use RDF::AllegroGraph::Catalog4;
my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
use Fcntl;
my $model  = $scratch->repository ('/scratch/catlitter', O_CREAT);

my $cwd = `pwd`; chomp $cwd;
$model->add ("file://$cwd/t/lesmiserables.rdf");

my $se = $model->session;
$se->namespace ('lm' => 'http://www.franz.com/lesmis#');

END {
    $model->disband if $model;
}



if (DONE) {    # low level
    $se->generator ('associates', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional' });
    @ss = $se->prolog (q{
  (select (?member)
       (ego-group-member !lm:character11 1 associates ?member)
   )
  });
    ok (
 	eq_set (
 		[ map {$_->[0] } @ss ],
 		[ map { "<http://www.franz.com/lesmis#character$_>" } ( '27', '26', '55', '11'  ) ]
 		), 'associates with knows_well');

    { # using a predefined generator
	$se->generator ('intimates', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional' });
	ok ( # using several mixed
	     eq_set (
		     [ $se->SNA_members ('lm:character11', 'intimates')],
		     [ map { "<http://www.franz.com/lesmis#character$_>" } ('27', '26', '55', '11' ) ]
		     ), 'associates with knows_well and knows (via predef generator)');
    }
}

if (0&&DONE) { # strange results that differ from the Python solution

    $se->generator ('associates', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional',
				    '<http://www.franz.com/lesmis#knows>'      => 'bidirectional' });
    
    foreach my $spec ({ '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional',
			'<http://www.franz.com/lesmis#knows>'      => 'bidirectional' },
		      'associates') { # that should make a difference

	my @cs = $se->SNA_cliques ('lm:character11', $spec);
	warn Dumper \@cs;

	is ((scalar @cs), 2, '2 cliques');
	is ((scalar @{$cs[0]}), 3, 'first clique #');
	    is ((scalar @{$cs[1]}), 3, 'second clique #');
	    
	    ok ((grep { $_ =~ /11/ } @{$cs[0]}), '11 is in both');
	ok ((grep { $_ =~ /11/ } @{$cs[1]}), '11 is in both');

	is (
	    (scalar
	     grep { $_ =~ /25/ } (@{$cs[0]}, @{$cs[1]})
	     ), 1, '25 in exactly one');
    }

    {
	$se->generator ('intimates', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional' });
	my @cs = $se->SNA_path ('lm:character11', 'lm:character64', 'intimates', 10);
	is ((scalar @cs), 1,       '1 path intimates');
	is ((scalar @{$cs[0]}), 0, 'but that is the empty path');
#	warn Dumper \@cs;

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	$se->generator ('associates', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional',
					'<http://www.franz.com/lesmis#knows>'      => 'bidirectional' });
	@cs = $se->SNA_path ('lm:character11', 'lm:character64', 'associates', 10);
	is ((scalar @cs), 2,       '2 path associates');
	is ((scalar @{$cs[0]}), 4, 'and that has length');
	is ((scalar @{$cs[1]}), 4, 'and that has length');
	warn Dumper \@cs;


# Shortest breadth-first path connecting Valjean to Bossuet? with associates (should be two).
# Found 2 query results
# [ <http://www.franz.com/lesmis#character11> <http://www.franz.com/lesmis#character55> <http://www.franz.com/lesmis#character58> <http://www.franz.com/lesmis#character64> ]
# [ <http://www.franz.com/lesmis#character11> <http://www.franz.com/lesmis#character55> <http://www.franz.com/lesmis#character62> <http://www.franz.com/lesmis#character64> ]

# Return depth-first path connecting Valjean to Bossuet with associates (should be one).
# Found 1 query results
# [ <http://www.franz.com/lesmis#character11> <http://www.franz.com/lesmis#character55> <http://www.franz.com/lesmis#character62> <http://www.franz.com/lesmis#character64> ]

# Shortest bidirectional paths connecting Valjean to Bossuet with associates (should be two).
# Found 2 query results
# [ <http://www.franz.com/lesmis#character11> <http://www.franz.com/lesmis#character55> <http://www.franz.com/lesmis#character58> <http://www.franz.com/lesmis#character64> ]
# [ <http://www.franz.com/lesmis#character11> <http://www.franz.com/lesmis#character55> <http://www.franz.com/lesmis#character62> <http://www.franz.com/lesmis#character64> ]

# Nodal degree of Valjean (should be seven).
# "7"^^<http://www.w3.org/2001/XMLSchema#integer>
# 7

# How many neighbors are around Valjean? (should be 36).
# "36"^^<http://www.w3.org/2001/XMLSchema#integer>
# 36


    }
}

if (DONE) {     # higher level
    ok (
	 eq_set (
		 [ $se->SNA_members ('<http://www.franz.com/lesmis#character11>', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional' }) ],
		 [ map { "<http://www.franz.com/lesmis#character$_>" } ('27', '26', '55', '11' ) ]
		 ), 'associates with knows_well (via SNA members');
     
    ok ( # using namespace on start
	 eq_set (
		 [ $se->SNA_members ('lm:character11', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional' }) ],
		 [ map { "<http://www.franz.com/lesmis#character$_>" } ('27', '26', '55', '11' ) ]
		 ), 'associates with knows_well (via SNA members, namespaced 1)');
     
  TODO: {
      local $TODO = 'strangely, namespaces on edges do not work for generators';
      ok ( # using namespace on edge
	 eq_set (
		 [ $se->SNA_members ('lm:character11', { '<lm:knows_well>' => 'bidirectional' }) ],
		 [ map { "<http://www.franz.com/lesmis#character$_>" } ('27', '26', '55', '11' ) ]
		 ), 'associates with knows_well (via SNA members, namespaced 1)');
    }
     
    ok ( # using several
	 eq_set (
		 [ $se->SNA_members ('lm:character11', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional',
							 '<http://www.franz.com/lesmis#knows>'      => 'bidirectional' })],
		 [ map { "<http://www.franz.com/lesmis#character$_>" } ('27', '25', '28', '23', '26', '55', '11', '24' ) ]
		 ), 'associates with knows_well and knows');

    ok ( # using several mixed
	 eq_set (
		 [ $se->SNA_members ('lm:character11', { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional',
							 '<http://www.franz.com/lesmis#knows>'      => 'forward' })],
		 [ map { "<http://www.franz.com/lesmis#character$_>" } ('27', '26', '55', '11' ) ]
		 ), 'associates with knows_well and knows');

    @ss = $se->SNA_members ('lm:character11', { '<http://www.franz.com/lesmis#knows_well>'   => 'bidirectional',
						'<http://www.franz.com/lesmis#knows>'        => 'bidirectional',
						'<http://www.franz.com/lesmis#barely_knows>' => 'bidirectional', });
#     warn Dumper \@ss;
    is ((scalar @ss), 37, 'associated with all characters');

#warn Dumper [ map { $_->[0] =~ /(\d+)>$/ && $1 } @ss ];
}



__END__

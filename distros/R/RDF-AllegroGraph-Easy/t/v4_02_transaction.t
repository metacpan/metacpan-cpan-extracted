use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use constant DONE => 1;

my $AG_SERVER = $ENV{AG4_SERVER};
unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (DONE) {
    use RDF::AllegroGraph::Server;
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    # TODO: generate scratch here
    use RDF::AllegroGraph::Catalog4;
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);

    use Fcntl;
    my $model  = $scratch->repository ('/scratch/catlitter', O_CREAT);

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
                     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
                     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
                     );
    my @ss = $model->match ([undef, undef, undef]);
    is ((scalar @ss), 3, 'outer session 1');

    {
	my $tx = $model->transaction;
	isa_ok ($tx, 'RDF::AllegroGraph::Transaction4');
	isa_ok ($tx, 'RDF::AllegroGraph::Session4');
	isa_ok ($tx, 'RDF::AllegroGraph::Repository4');
    }	
    { # explicit rollback
	my $tx = $model->transaction;
	@ss = $tx->match ([undef, undef, undef]);
	is ((scalar @ss), 3, 'inner session 1');
	
	$tx->add    (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
	@ss = $tx->match ([undef, undef, '<urn:x-me:rho>']);
	is ((scalar @ss), 1, 'inner session 2');
	@ss = $model->match ([undef, undef, '<urn:x-me:rho>']);
	is ((scalar @ss), 0, 'outer session 2');

	$model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:drrho>']);
	@ss = $tx->match ([undef, undef, '<urn:x-me:drrho>']);
	is ((scalar @ss), 0, 'inner session 3');
	@ss = $model->match ([undef, undef, '<urn:x-me:drrho>']);
	is ((scalar @ss), 1, 'outer session 3');
	
	$tx->rollback; # explicit

	@ss = $tx->match ([undef, undef, undef]);
	is ((scalar @ss), 4, 'inner session 4');
	@ss = $model->match ([undef, undef, undef]);
	is ((scalar @ss), 4, 'outer session 4');
    }

    { # implicit in destructor
	my $tx = $model->transaction;
	@ss = $tx->match ([undef, undef, undef]);
	is ((scalar @ss), 4, 'inner session 5');
	
	$tx->add    (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
	@ss = $tx->match ([undef, undef, '<urn:x-me:rho>']);
	is ((scalar @ss), 1, 'inner session 6');
	@ss = $model->match ([undef, undef, '<urn:x-me:rho>']);
	is ((scalar @ss), 0, 'outer session 6');

	$model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:drrrho>']);
	@ss = $tx->match ([undef, undef, '<urn:x-me:drrrho>']);
	is ((scalar @ss), 0, 'inner session 7');
	@ss = $model->match ([undef, undef, '<urn:x-me:drrrho>']);
	is ((scalar @ss), 1, 'outer session 7');
	
    }
    @ss = $model->match ([undef, undef, undef]);
    is ((scalar @ss), 5, 'outer session 8');

    { # explicit commit
	my $tx = $model->transaction;
	@ss = $tx->match ([undef, undef, undef]);
	is ((scalar @ss), 5, 'inner session 9');
	
	$tx->add    (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
	@ss = $tx->match ([undef, undef, '<urn:x-me:rho>']);
	is ((scalar @ss), 1, 'inner session 10');
	@ss = $model->match ([undef, undef, '<urn:x-me:rho>']);
	is ((scalar @ss), 0, 'outer session 10');

	$model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:drrrrho>']);
	@ss = $tx->match ([undef, undef, '<urn:x-me:drrrrho>']);
	is ((scalar @ss), 0, 'inner session 11');
	@ss = $model->match ([undef, undef, '<urn:x-me:drrrrho>']);
	is ((scalar @ss), 1, 'outer session 11');
	
	$tx->commit; # explicit

	@ss = $tx->match ([undef, undef, undef]);
	is ((scalar @ss), 7, 'inner session 12');
	@ss = $model->match ([undef, undef, undef]);
	is ((scalar @ss), 7, 'outer session 12');
    }


    $model->disband;
}

__END__


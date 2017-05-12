use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use_ok( 'RDF::AllegroGraph::Server' );


use constant DONE => 1;


my $AG3_SERVER = $ENV{AG3_SERVER};
my $AG4_SERVER = $ENV{AG4_SERVER};

unless ($AG3_SERVER || $AG4_SERVER) {
    ok (1, 'Tests skipped. Use "export AG3_SERVER=http://my.server:port" or "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if ($AG3_SERVER && (DONE)) {
    my $s = new RDF::AllegroGraph::Server (ADDRESS => $AG3_SERVER);
    isa_ok ($s, 'RDF::AllegroGraph::Server3');
    isa_ok ($s, 'RDF::AllegroGraph::Server');
    is ($s->protocol, 3, 'protocol version');
}
if ($AG4_SERVER && (DONE)) {
    my $s = new RDF::AllegroGraph::Server (ADDRESS => $AG4_SERVER);
    isa_ok ($s, 'RDF::AllegroGraph::Server4');
    isa_ok ($s, 'RDF::AllegroGraph::Server');
    is ($s->protocol, 4, 'protocol version');

    lives_ok( sub { $s->reconfigure }, 'expecting to survive the reconfiguration' );
    lives_ok( sub { $s->reopen_log },  'expecting to survive the log reopen' );

}

__END__


# TEST AG4_SERVER



if (DONE) {
#    my $storage = new RDF::AllegroGraph::Easy;
#    isa_ok ($storage, 'RDF::AllegroGraph::Server');

    my $storage;

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy ('xyz');
    } qr/ADDRESS/, 'invalid server address';

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy ('http://localhost:1111', TEST => 1 );
    } qr/connect to localhost:1111/, 'non-working server address';

    lives_ok {
	$storage = new RDF::AllegroGraph::Easy ('http://localhost:1111', TEST => 0 );
    } 'no testing of connectivity'; 

    lives_ok {
	$storage = new RDF::AllegroGraph::Easy ($AG_SERVER, TEST => 1 );
    } 'testing of connectivity';

    
#    lives_ok {
#	$storage = new RDF::AllegroGraph::Easy (undef, TEST => 1 );
#    } 'testing of connectivity (default)';
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my %models = $storage->models;
    is (scalar keys %models, 0, 'no model to begin with');

    throws_ok {
	my $model = $storage->model ('/scratch/catlitter');
    } qr/cannot/, 'at start no catlitter';

    use Fcntl;
    my $model = $storage->model ('/scratch/catlitter', mode => O_CREAT);
    isa_ok ($model, 'RDF::AllegroGraph::Repository', 'catlitter created');

    $model->disband;

    throws_ok {
	my $model = $storage->model ('/scratch/catlitter');
    } qr/cannot/, 'at end no catlitter';


# TODO wrong path /xxx
# TODO create several and delete
}

if (DONE) {
   my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
   my $vienna = new RDF::AllegroGraph::Catalog (NAME => '/scratch', SERVER => $server);

   like ($vienna->version,  qr/^3\./, 'store version');
   like ($vienna->protocol, qr/\d/,   'protocol version');
}


if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    is ($model->size, 0, 'empty model');
    $model->add ();
    is ($model->size, 0, 'still empty model');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
    is ($model->size, 1, 'added: model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
    is ($model->size, 2, 'added: model of 2');
    
    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>']);
    is ($model->size, 1, 'replaced: model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:ketty>'],
	);
    is ($model->size, 4, 'replaced/added: model of 4');

    $model->delete (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>']);
    is ($model->size, 3, 'deleted (fact): model of 3');

    $model->delete ([undef, '<urn:x-me:hates>', undef]);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->delete (['<urn:x-me:rumsti>', undef, undef]);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);
    $model->delete ([undef, '<urn:x-me:loves>', undef ],
		    [undef, undef, '<urn:x-me:kitty>' ]	);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);
    $model->delete ([undef, '<urn:x-me:loves>', undef ],
                    ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>' ] );
    is ($model->size, 2, 'deleted (wildcard): model of 2');

    $model->disband;
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	             );

    my @ss = $model->match ([undef, undef, '<urn:x-me:kitty>']);
    is (scalar @ss, 2, 'match found kitty');
    map { is ($_->[2], '<urn:x-me:kitty>', 'kitty!') } @ss;

    @ss = $model->match (['<urn:x-me:sacklpicker>', undef, undef]);
    is (scalar @ss, 4, 'match found sacklpicker');
    map { is ($_->[0], '<urn:x-me:sacklpicker>', 'sacklpicker!') } @ss;

    @ss = $model->match (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>']);
    is (scalar @ss, 2, 'match found exactly two identical');

    @ss = $model->match ([undef, '<urn:x-me:hates>', undef],
			 [undef, '<urn:x-me:loves>', undef]);
    is (scalar @ss, 4, 'match found love and hate');

    $model->disband;
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER);
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:tomcat> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 1, 'added N3: 1');

    $model->add ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kitty> .
                  <urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:katty> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 3, 'added N3: 3');

    $model->replace ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:ketty> .
                      <urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kotty> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2, 'replaced N3: 2');

    $model->disband;

}

my $file;
END { $AG_SERVER && unlink $file; }

if (DONE) {
    use POSIX qw(tmpnam);
    use IO::File;
    do { $file = tmpnam().".n3";  } until IO::File->new ($file, O_RDWR|O_CREAT|O_EXCL);
    my $fh = IO::File->new ("> $file") || die "so what?";
    print $fh "
<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:ketty> .
<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kotty> .
";
    $fh->close;

    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER);
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add ('file://'. $file);
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2, 'added N3 file: 2');

    $model->replace (('file://'. $file ) x 3);
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2*3, 'added N3 file: 2*3');

    $model->disband;
}



if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);

    my @ss = $model->sparql ('SELECT ?s ?p ?o WHERE {?s ?p ?o .}' );
#    warn Dumper \@ss;
    is (scalar @ss, 4, 'query: all triples');
    map { is ($_->[0], '<urn:x-me:sacklpicker>', 'sackelpicker everywhere') } @ss;
    map { is (scalar @$_, 3,                     'triple everywhere')       } @ss;

    @ss = $model->sparql ('SELECT ?thing WHERE { ?cat <urn:x-me:hates> ?thing . }' );
    is (scalar @ss, 2, 'query: all that hate');
    map {  like ($_->[0], qr/<urn:x-me:(kitty|tomcat)>/, 'tomcat/litty everywhere') } @ss;
    map { is (scalar @$_, 1,                 'singleton everywhere')        } @ss;

    $model->disband;
}

# TODO with and w/o authentication


__END__

# prefixes

PREFIXES resolve local/remote
         locally use, smaller uri, let remote resolve

$storage->version

    $model = $storage->model ('name', .... POSIX) NAMESPACES {}



$model->add (s, p, o) # NAMESPACES
$model->add (s, s, s, s, ...)
$model->add (N3);
$model->add (RDF/XML);

$model->text ('rumsti')        # freetext

$model->reindex


use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use_ok( 'RDF::AllegroGraph::Easy' );

use constant DONE => 1;


my $AG_SERVER = $ENV{AG3_SERVER};

unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

use Fcntl;

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);

    my %ns = $model->namespaces ;
    is ($ns{rdf}, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'rdf prefix');
    is ($ns{rdfs}, 'http://www.w3.org/2000/01/rdf-schema#',      'rdfs prefix');

    is ($model->namespace ('rdfs'), 'http://www.w3.org/2000/01/rdf-schema#', 'namespace fetch');
    is ($model->namespace ('xxx'), undef,                                    'namespace nonexist');

    $model->namespace ('xxx' => 'http://rumsti.com');
    is ($model->namespace ('xxx'), 'http://rumsti.com', 'namespace set/fetch');

    $model->namespace ('xxx' => undef);
    is ($model->namespace ('xxx'), undef,                                    'namespace set/nonexist');

    $model->disband;
}



__END__

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


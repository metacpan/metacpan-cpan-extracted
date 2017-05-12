use strict ;
 
BEGIN { print "1..14\n"; };
END { print "not ok 1\n" unless $::loaded; RDFStore::debug_malloc_dump(); eval{ rmtree('cooltest'); }; };

my $a = "";
local $SIG{__WARN__} = sub {$a = $_[0]} ;
 
sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}
 
sub docat
{
    my $file = shift;
    local $/ = undef;
    open(CAT,$file) || die "Cannot open $file:$!";
    my $result = <CAT>;
    close(CAT);
    return $result;
};

#$::debug=1;

umask(0);

use RDFStore::Object;

$::loaded = 1;
print "ok 1\n";

my $tt=2;

#simplest
ok $tt++, my $rdf_obj = new RDFStore::Object;
#ok $tt++, $rdf_obj->define( 'cip' => { 'namespace' => 'http://earth.esa.int/standards/cip/', 'URI' => 'file:///Users/reggiori/tmp/www-asemantics/demo/biz/infeo/cip.rdf', 'content_type' => 'RDF/XML' } );
ok $tt++, $rdf_obj->define( 'cip' => { 'namespace' => 'http://earth.esa.int/standards/cip/' } );
ok $tt++, ! $rdf_obj->getNamespace;
ok $tt++, ! $rdf_obj->getLocalName;

#print $rdf_obj->load( 'file:///Users/reggiori/tmp/Ireland_ASA_WSM_Orbit_09567_20031229.rdf' );
#$rdf_obj->load( $rdf_obj->{'prefixes'}->{'cip'}->{'schema'} );

$rdf_obj->export( 'foaf', 'dc');
$rdf_obj->foaf::name( "BLAAAA" );

$rdf_obj->set( 'cip:title' => 'foo bar' );
$rdf_obj->set( 'dc:title' => 'foo bar' );
$rdf_obj->set( 'dc:title' => [ 't1', 't2', 't3' , [ 't5' ], { 'foaf:Person' } ] );

#print $rdf_obj->serialize."\n";

my @vals = map { $_->toString } $rdf_obj->get( 'cip:title' );
ok $tt++, @vals;
ok $tt++, ($#vals==0);
ok $tt++, ($vals[0] eq 'foo bar');
eval { @vals = map { $_->toString } $rdf_obj->cip::title; };
ok $tt++, $@;

@vals = map { $_->toString } $rdf_obj->dc::title;
ok $tt++, @vals;
ok $tt++, $#vals==1;

ok $tt++, my $rdf_obj1 = new RDFStore::Object('http://www.google.com/index.php');
ok $tt++, $rdf_obj1->connect;

my $connection;
ok $tt++, $connection = $rdf_obj1->connection;
#ok $tt++, $connection->fetch_object( $rdf_obj1 )->getResource( $rdf_obj1 )->equals( $rdf_obj1 );

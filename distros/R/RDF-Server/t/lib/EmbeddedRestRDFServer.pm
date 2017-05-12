package EmbeddedRestRDFServer;

use RDF::Server;

protocol 'Embedded';
interface 'REST';
semantic 'RDF';

render 'xml' => 'RDF';
render 'atom' => 'Atom';

if( not not eval "require JSON::Any" ) {
    render 'json' => 'JSON';
}

1;

__END__

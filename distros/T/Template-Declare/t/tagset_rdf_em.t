use strict;
use warnings;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags
        'RDF::EM' => { namespace => 'em' }, 'RDF';

template foo => sub {
    RDF {
        attr {
            'xmlns' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            'xmlns:em' => 'http://www.mozilla.org/2004/em-rdf#'
        }
        Description {
            attr { about => 'urn:mozilla:install-manifest' }
            em::id { 'foo@bar.com' }
            em::version { '1.2.0' }
            em::type { '2' }
            em::creator { 'Agent Zhang' }
        }
    }
};

package main;
use Test::More tests => 1;

Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('foo') . "\n";
is $out, <<'_EOC_';

<RDF xmlns="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:em="http://www.mozilla.org/2004/em-rdf#">
 <Description about="urn:mozilla:install-manifest">
  <em:id>foo@bar.com</em:id>
  <em:version>1.2.0</em:version>
  <em:type>2</em:type>
  <em:creator>Agent Zhang</em:creator>
 </Description>
</RDF>
_EOC_


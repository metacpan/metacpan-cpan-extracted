use strict;
use warnings;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags
        RDF => { namespace => 'rdf' }, 'RDF';

template with_ns => sub {
    rdf::RDF {
        attr { 'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#" }
        rdf::Description {
            attr { about => "Matilda" }
            rdf::type {}
            #...
        }
        rdf::Bag {
            rdf::li {}
            rdf::_1 {}
        }
        rdf::Seq {
            rdf::_2 {}
            rdf::_9 {}
            rdf::_10 {}
        }
        rdf::Alt {}
    }
};

template without_ns => sub {
    RDF {
        attr { 'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#" }
        Description {
            attr { about => "Matilda" }
            type {}
            #...
        }
        Bag {
            li {}
            _1 {}
        }
        Seq {
            _2 {}
            _9 {}
            _10 {}
        }
        Alt {}
    }
};

package main;
use Test::More tests => 2;

Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('with_ns') . "\n";
is $out, <<_EOC_;

<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
 <rdf:Description about="Matilda">
  <rdf:type />
 </rdf:Description>
 <rdf:Bag>
  <rdf:li />
  <rdf:_1 />
 </rdf:Bag>
 <rdf:Seq>
  <rdf:_2 />
  <rdf:_9 />
  <rdf:_10 />
 </rdf:Seq>
 <rdf:Alt />
</rdf:RDF>
_EOC_

$out = Template::Declare->show('without_ns') . "\n";
is $out, <<_EOC_;

<RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
 <Description about="Matilda">
  <type />
 </Description>
 <Bag>
  <li />
  <_1 />
 </Bag>
 <Seq>
  <_2 />
  <_9 />
  <_10 />
 </Seq>
 <Alt />
</RDF>
_EOC_


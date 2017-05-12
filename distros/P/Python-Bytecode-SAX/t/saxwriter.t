print "1..1\n";

use strict;
use warnings;

use Python::Bytecode::SAX;

eval "use XML::SAX::Writer";

if ($@) {
    print "ok 1 # Skip no XML::SAX::Writer\n";
}
else {
    my $handler = XML::SAX::Writer->new(
        Output => 't/primes2-saxwriter.xml',
    );

    my $parser = Python::Bytecode::SAX->new(
        SAX     => 2,
        Handler => $handler
    );

    $parser->parse_file('t/primes2.pyc');

    print "ok 1\n";
}

exit 0;


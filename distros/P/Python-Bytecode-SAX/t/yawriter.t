print "1..1\n";

use strict;
use warnings;

use Python::Bytecode::SAX;

eval "use XML::Handler::YAWriter";

if ($@) {
    print "ok 1 # Skip no XML::Handler::YAWriter\n";
}
else {
    my $handler = XML::Handler::YAWriter->new(
        AsFile => 't/primes2-yawriter.xml',
        Pretty  => {
            CompactAttrIndent  => 1,
            PrettyWhiteIndent  => 1,
            PrettyWhiteNewline => 1,
            CatchEmptyElement  => 1
        }
    );

    my $parser = Python::Bytecode::SAX->new(
        SAX     => 1,
        Handler => $handler
    );

    $parser->parse_file('t/primes2.pyc');

    print "ok 1\n";
}

exit 0;


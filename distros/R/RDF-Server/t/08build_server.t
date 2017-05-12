use Test::More;
use Test::Moose;

use RDF::Server::Types qw( Protocol Interface Formatter );
eval "use Carp::Always"; # for those who don't have it

my $e;

my @protocols;
my @interfaces;
my @semantics;

BEGIN {

foreach my $p (qw( FCGI HTTP Embedded )) {
    push @protocols, $p if not not eval "require RDF::Server::Protocol::$p";
}

foreach my $i (qw( REST )) {
    push @interfaces, $i if not not eval "require RDF::Server::Interface::$i";
}

foreach my $s (qw( Atom RDF )) {
    push @semantics, $s if not not eval "require RDF::Server::Semantic::$s";
}

plan skip_all => 'No protocols are available' unless @protocols;
plan skip_all => 'No interfaces are available' unless @interfaces;
plan skip_all => 'No semantics are available' unless @semantics;

plan tests => scalar(@protocols)*scalar(@interfaces)*scalar(@semantics)*10 +1;


my $counter = 0;
my $bad_render_test = <<'eoCODE';
    eval {
        render foo => 'Foo';
    };

    main::isnt( $@, '', 'Bad formatter package causes an error' );
eoCODE

foreach my $protocol (@protocols) {
    foreach my $interface (@interfaces) {
        foreach my $semantic (@semantics) {

            $counter ++;

            eval <<eoEVAL;
package My::Server$counter;

use RDF::Server;

protocol '$protocol';
interface '$interface';
semantic '$semantic';

$bad_render_test
eoEVAL

            $e = $@;

            is( $e, '', "No error creating test package ($protocol $interface $semantic)" );

            $bad_render_test = '';

            $counter ++;

            eval <<eoEVAL;
package My::Server$counter;

use RDF::Server;

interface '$interface';
protocol '$protocol';
semantic '$semantic';

eoEVAL

            $e = $@;

            is( $e, '', "No error creating test package ($interface $protocol $semantic)" );

            $counter ++;

            eval <<eoEVAL;
package My::Server$counter;

use RDF::Server;

interface '$interface';
semantic '$semantic';
protocol '$protocol';

eoEVAL

            $e = $@;

            is( $e, '', "No error creating test package ($interface $semantic $protocol)" );


            $counter ++;

            eval <<eoEVAL;
package My::Server$counter;

use RDF::Server;

semantic '$semantic';
protocol '$protocol';
interface '$interface';

eoEVAL

            $e = $@;

            is( $e, '', "No error creating test package ($semantic $protocol $interface)" );

            eval {
                $class = RDF::Server -> build_from_config(
                    interface => $interface,
                    protocol => $protocol,
                    semantic => $semantic
                );
            };

            $e = $@;

            is( $e, '', "No error building from config($protocol, $interface, $semantic)");
            SKIP: {
                skip "Errors encountered building, so no further testing of this combination", 3 if $e;
                does_ok( $class, "RDF::Server::Protocol::$protocol" );
                does_ok( $class, "RDF::Server::Interface::$interface" );
                does_ok( $class, "RDF::Server::Semantic::$semantic" );
            }

            $counter ++;

            eval <<eoEVAL;
package My::Server$counter;

use RDF::Server qw($interface $protocol $semantic);

eoEVAL

            $e = $@;

            is( $e, '', "No error creating test package qw($interface $protocol $semantic)" );

            $counter ++;

            eval <<eoEVAL;
package My::Server$counter;

use RDF::Server qw($interface $protocol +RDF::Server::Semantic::$semantic);

eoEVAL

            $e = $@;

            is( $e, '', "No error creating test package qw($interface $protocol +$semantic)" );
        } # semantic
    } # interface
} # protocol

} # BEGIN

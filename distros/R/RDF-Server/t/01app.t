use strict;
use warnings;

eval "use Carp::Always"; # for those who don't have it

use Test::More tests => 29;

BEGIN {
use_ok 'RDF::Server::Interface';
use_ok 'RDF::Server::Protocol';
use_ok 'RDF::Server::Formatter';

use_ok 'RDF::Server::Types';
use_ok 'RDF::Server::Constants';
use_ok 'RDF::Server::Exception';

use_ok 'RDF::Server';

use_ok "RDF::Server::Role::$_" for qw[
   Container
   Handler
   Model
   Mutable
   Renderable
   Resource
];

use_ok 'RDF::Server::Formatter::RDF';
use_ok 'RDF::Server::Formatter::Atom';

use_ok 'RDF::Server::Semantic::Atom::Workspace';
use_ok 'RDF::Server::Semantic::Atom::Collection';
use_ok 'RDF::Server::Semantic::Atom::Category';
use_ok 'RDF::Server::Semantic::Atom::Types';
use_ok 'RDF::Server::Semantic::Atom';

use_ok 'RDF::Server::Semantic::RDF::Types';
use_ok 'RDF::Server::Semantic::RDF::Handler';
use_ok 'RDF::Server::Semantic::RDF::Collection';

use_ok 'RDF::Server::Semantic::RDF';

SKIP: {
    skip 'RDF::Core not found', 2 unless not not eval 'require RDF::Core';

    use_ok( 'RDF::Server::Model::RDFCore' );
    use_ok( 'RDF::Server::Resource::RDFCore' );
};

SKIP: {
    skip 'JSON::Any not found', 1 unless not not eval 'require JSON::Any';

    use_ok( 'RDF::Server::Formatter::JSON' );
}

SKIP: {
    foreach my $m (qw(
        FCGI MooseX::Daemonize
    )) {
        skip("$m not found", 1) && last 
            unless not not eval "require $m";
    }

    use_ok( 'RDF::Server::Protocol::FCGI' );
}

SKIP: {
    foreach my $m (qw(
        POE::Component::Server::HTTP MooseX::Daemonize
    )) {
        skip("$m not found", 1) && last 
            unless not not eval "require $m";
    }

    use_ok( 'RDF::Server::Protocol::HTTP' );
}
}

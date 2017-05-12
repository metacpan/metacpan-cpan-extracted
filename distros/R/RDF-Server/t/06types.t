use Test::More;
use MooseX::Types::Moose qw( :all );
use RDF::Server;
use Class::MOP;
eval "use Carp::Always"; # for those who don't have it

my %tests;

my $tests; my %failed_loads;

BEGIN {

%tests = (
    'RDF::Server::Types' => 5,
    'RDF::Server::Semantic::Atom::Types' => 1,
    'RDF::Server::Semantic::RDF::Types' => 1,
);

foreach my $module ( keys %tests ) {
    if( eval { Class::MOP::load_class($module) } ) {
        $tests += $tests{$module};
        $module -> import(qw(:all));
    }
    else {
        $failed_loads{$module} = 1;
    }
}

if( $tests == 0 || $failed_loads{'RDF::Server::Types'} ) {
    plan skip_all => 'Unable to load: ' . join(", ", keys %failed_loads);
}
else {
    if( keys %failed_loads ) {
        diag "Unable to load: ", join(", ", keys %failed_loads);
    }
    plan tests => $tests;
}

} # BEGIN

###
# test _does_role
###

ok( !RDF::Server::Types::_does_role('IO::Handler', 'Foo::Bar') );

eval "package My::Foo; sub meta { 3 };";

ok( !RDF::Server::Types::_does_role('My::Foo', 'Foo::Bar') );

eval "package My::FooBar; sub meta { undef };";

ok( !RDF::Server::Types::_does_role('My::FooBar', 'Foo::Bar') );

###
# test basic types
###

ok( !is_Handler( 'Test::More' ) );
ok( !is_Handler( 'RDF::Server') );

###
# test Atom types
###

if(!$failed_loads{'RDF::Server::Atom::Types'}) {

    ok(
      AtomHandler -> is_subtype_of(Handler), 
      "AtomHandler is a type of Handler"
    );

}

if(!$failed_loads{'RDF::Server::RDF::Types'}) {

    ok(
      RDFHandler -> is_subtype_of(Handler), 
      "RDFHandler is a type of Handler"
    );

}

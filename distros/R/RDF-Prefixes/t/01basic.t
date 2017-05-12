use Test::More tests => 3;
BEGIN { use_ok('RDF::Prefixes') };
my $context = new_ok 'RDF::Prefixes';
isa_ok $context => 'RDF::Prefixes';

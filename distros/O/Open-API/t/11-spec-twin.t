#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# The JSON and YAML petstore twins compile to the same operation table.

plan skip_all => 'YAML::XS not installed'
    unless eval { require YAML::XS; 1 };

my $j = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");
my $y = Open::API->new(spec => "$FindBin::Bin/spec/petstore.yaml");

my @jops = sort { $a->{operationId} cmp $b->{operationId} } @{ $j->operations };
my @yops = sort { $a->{operationId} cmp $b->{operationId} } @{ $y->operations };
is_deeply(\@yops, \@jops, 'same operations from both twins');

for my $id (map { $_->{operationId} } @jops) {
    my ($yo, $jo) = ($y->operation($id), $j->operation($id));
    # content-type order comes from a hash walk - not meaningful, so normalise
    @{ $_->{body}{content} } = sort @{ $_->{body}{content} } for $yo, $jo;
    @{ $_->{responses} }     = sort @{ $_->{responses} }     for $yo, $jo;
    is_deeply($yo, $jo, "operation($id) identical");
}

# and the YAML-compiled schemas actually validate (booleans decoded as
# File::Raw::YAML::Boolean must behave like JSON booleans)
is($y->_body_check('createPet', 'application/json', { name => 'x' }), 1,
    'YAML-compiled body schema validates');
is($y->_param_check('getPet', 'path', 'petId', '5'), 1,
    'YAML-compiled param schema validates');

done_testing();

use Mojo::Base -strict;

use SolarBeam::Response;
use Test::More;

is_deeply ffah({}), {}, 'facet_fields_as_hashes empty';
is_deeply ffah({foo => [{value => 'x', count => 42}, {value => 'y' => count => 3}]}),
  {foo => {x => 42, y => 3}}, 'facet_fields_as_hashes foo';

done_testing;

sub ffah {
  SolarBeam::Response->new(facet_fields => shift || {})->facet_fields_as_hashes;
}

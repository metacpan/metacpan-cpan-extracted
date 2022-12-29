use strict;
use warnings;

use Test::More tests => 8;

use PDL;
use PDL::Parallel::threads qw(retrieve_pdls free_pdls);

# Make it easier to use this darn function
*data_count = \&PDL::Parallel::threads::__get_pdl_datasv_ref_count;

my $data = sequence(20);
is(data_count($data), 1, "Data's initial refcount for normal ndarray is 1");

my $copy = $data;
is(data_count($data), 1, "Shallow copy does not increase data's refcount");

$data->share_as('foo');
is(data_count($data), 2, "Sharing data increases data's refcount");

my $shallow = retrieve_pdls('foo');
is(data_count($data), 3, "Retrieving data increases data's refcount");

undef($shallow);
is(data_count($data), 2, "Undef'ing retrieved copy decreases data's refcount");

undef($copy);
is(data_count($data), 2, "Undef'ing one of two original copies does not decrease data's refcount");

undef($data);

# At this point, there should be only one reference, but we can't actually
# know because we don't have a reference to an ndarray to check! Get a new
# shared copy:
$shallow = retrieve_pdls('foo');
is(data_count($shallow), 2, "Getting rid of original does not destroy the data");

free_pdls('foo');
is(data_count($shallow), 1, "Freeing memory only decrements refcount by one");

use strict;
use warnings;
use Test::More;
use Test::Deep;           # For deep structure checking
use File::Temp qw/tempdir/;

use Mojo::File qw/path tempfile/;
use Mojo::Util qw/dumper/;

$\ = "\n"; $, = "\t";

# Load the module to test
use_ok 'Mojo::File::Role::JSON' or BAIL_OUT("Can't load Mojo::File::Role::JSON");

# Create a temp directory for testing
my $tempdir = tempdir( CLEANUP => 0 );

print $tempdir;

my $temp_path = path($tempdir);

my $expected = {
    key1 => 'value1',
    key2 => [1, 2, 3],
    key3 => { subkey => 'subvalue' },
};

my $json_file = $temp_path->child('testfile.json')->with_roles("+JSON");

my $result = $json_file->json($expected);

cmp_deeply($result, $expected, 'Direct assignment in json: structure matches expected result');

$expected->{key4} = 4;

$result = $json_file->json($expected)->json;

cmp_deeply($result, $expected, 'Assignment and dereference in json: structure matches expected result');

done_testing;

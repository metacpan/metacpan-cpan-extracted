use strict;
use warnings;
use Test::More 0.98;
use Nuspec::Reader;

my $reader = Nuspec::Reader->new(nuspec_filename => 't/sample.nuspec');

is_deeply($reader->get_dependencies(), [{id => 'dep_1', version => '0.1.0'}]);

done_testing;


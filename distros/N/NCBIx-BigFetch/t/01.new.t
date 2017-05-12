use Test::More tests => 3;

BEGIN {
use_ok( 'NCBIx::BigFetch' );
}

my $project = NCBIx::BigFetch->new({});
ok($project, 'NCBIx::BigFetch->new()');

my $status  = $project->file_test();
ok($status eq '2', '$project->file_test()');

diag( "Testing NCBIx::BigFetch $NCBIx::BigFetch::VERSION" );

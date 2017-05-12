use strict;
use warnings;

use Test::More tests => 4;

use_ok 'SRS::EPP::Response::Error';

my $error = SRS::EPP::Response::Error->new(
    exception => 'A horrible crash at /some/file line 444',
    code => 2000,
    server_id => '123',
);

my $mapped_errors = $error->mapped_errors;
is(scalar @$mapped_errors, 1, "One mapped error returned");
isa_ok($mapped_errors->[0], "XML::EPP::Error", "EPP Error object created");
is($mapped_errors->[0]->reason->content, "(none)", "EPP error object has correct reason");
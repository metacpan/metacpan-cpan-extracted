use Test::More tests => 1;

use Net::Google::Storage;

my $gs = Net::Google::Storage->new(projectId => 1234, access_token => 'dummy_access_token');

isa_ok($gs, 'Net::Google::Storage');

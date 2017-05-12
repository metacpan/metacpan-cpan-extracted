use Test::More tests => 2;
BEGIN {use_ok ('Net::Google::FederatedLogin')};

my $fl = Net::Google::FederatedLogin->new();
isa_ok($fl, 'Net::Google::FederatedLogin');

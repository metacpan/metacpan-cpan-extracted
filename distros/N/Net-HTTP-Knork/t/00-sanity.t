use Test::More; 
use Carp;
use JSON::MaybeXS;
use Net::HTTP::Knork;
use FindBin qw($Bin);

my $client =
  Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec     => 't/fixtures/api.json', base_url => 'http://example.com' );

can_ok($client,'get_info','get_user_info','add_user','add_email','attach_file');
is($client->base_url, 'http://example.com');

$client =
  Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec     => 't/fixtures/api.json');


is($client->base_url, 'http://localhost.localdomain');


open my $fh, '<', 't/fixtures/api.json' or croak 'Cannot read the spec file';
local $/ = undef;
binmode $fh;
my $json_content = <$fh>;
my $decoded_content = decode_json($json_content);
close $fh;


my $client2 = Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec => $json_content,
);

is($client2->base_url, 'http://localhost.localdomain');

my $client3 = Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec => $decoded_content,
);

is($client3->base_url, 'http://localhost.localdomain');

done_testing();

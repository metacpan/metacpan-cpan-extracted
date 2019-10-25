package MongoHosting::Role::Provider;
use Moo::Role;
use strictures 2;
use MooX::HandlesVia;

has api_key        => (is => 'ro', required => 1);
has ssh_public_key => (is => 'ro', required => 1);
has _api_client    => (is => 'ro', lazy     => 1, builder => 1);
has config         => (is => 'ro', required => 1);
has boxes => (
  is          => 'ro',
  builder     => 1,
  lazy        => 1,
  handles_via => 'Hash',
  handles     => {
    get_box   => 'get',
    set_box   => 'set',
    all_boxes => 'values',
    has_boxes => 'count'
  }
);

requires '_build_boxes';
requires '_build__api_client';

1;



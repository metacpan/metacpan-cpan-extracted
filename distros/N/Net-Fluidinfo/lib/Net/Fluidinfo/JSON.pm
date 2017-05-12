package Net::Fluidinfo::JSON;
use Moose;

use JSON::XS;

has json => (
    is      => 'ro',
    isa     => 'JSON::XS',
    default => sub { JSON::XS->new->utf8->allow_nonref },
    handles => [qw(encode decode)]
);

1;

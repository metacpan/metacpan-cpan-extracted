package PDK::Content::Parser;

use 5.030;
use Moose;
use namespace::autoclean;

has '+id' => (required => 0,);

has '+name' => (required => 0,);

has '+type' => (required => 0,);


__PACKAGE__->meta->make_immutable;
1;

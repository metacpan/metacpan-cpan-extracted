package PDK::Content::Parser;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;

extends 'PDK::Content::Reader';

has '+id' => (required => 0,);

has '+name' => (required => 0,);

has '+type' => (required => 0,);


__PACKAGE__->meta->make_immutable;
1;

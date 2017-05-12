package Test::Exception::DataServer;
use Moose;
use namespace::autoclean;

with 'Siebel::COM::Exception::DataServer';

__PACKAGE__->meta->make_immutable;

1;

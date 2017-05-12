package Tak::Client::RemoteRouter;

use Moo;

extends 'Tak::Client::Router';

has host => (is => 'ro', required => 1);

1;

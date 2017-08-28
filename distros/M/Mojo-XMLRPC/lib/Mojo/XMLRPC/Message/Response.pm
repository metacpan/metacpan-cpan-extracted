package Mojo::XMLRPC::Message::Response;

use Mojo::Base 'Mojo::XMLRPC::Message';

has 'fault';

sub is_fault { defined shift->fault };

1;


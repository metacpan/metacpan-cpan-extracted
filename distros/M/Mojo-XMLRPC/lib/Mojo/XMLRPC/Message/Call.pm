package Mojo::XMLRPC::Message::Call;

use Mojo::Base 'Mojo::XMLRPC::Message';

has 'method_name' => sub { die 'method_name is required' };

1;


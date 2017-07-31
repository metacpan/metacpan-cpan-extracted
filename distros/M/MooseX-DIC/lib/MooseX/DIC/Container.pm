package MooseX::DIC::Container;

use Moose::Role;

requires 'get_service';
requires 'register_service';

1;

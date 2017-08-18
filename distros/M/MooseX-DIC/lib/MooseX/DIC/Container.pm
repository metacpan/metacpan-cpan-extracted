package MooseX::DIC::Container;

use Moose::Role;

requires 'get_service';
requires 'has_service';
requires 'get_service_metadata';

1;

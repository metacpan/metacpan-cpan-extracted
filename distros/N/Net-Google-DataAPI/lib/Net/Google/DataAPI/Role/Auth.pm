package Net::Google::DataAPI::Role::Auth;
use Any::Moose '::Role';
requires 'sign_request';
no Any::Moose '::Role';
our $VERSION = '0.02';

1;

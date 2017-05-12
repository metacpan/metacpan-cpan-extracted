package PagSeguro::API::Response;
use Moo;

# attributes
has error => (is => 'rw');
has url   => (is => 'rw');

has data => (is => 'rw', default => sub { {} });

1;

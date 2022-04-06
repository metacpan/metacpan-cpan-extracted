package Mock::Mojo::Response;
use Mojo::Base -base, -signatures;

has code     => 200;
has is_error => 0;
has json     => sub { {} };

1;

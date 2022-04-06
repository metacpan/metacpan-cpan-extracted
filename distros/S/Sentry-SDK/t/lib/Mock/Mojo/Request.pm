package Mock::Mojo::Request;
use Mojo::Base -base, -signatures;

has body => 'mocked';

1;

package PAUSE::Users::User;
$PAUSE::Users::User::VERSION = '0.07';
use 5.10.0;
use Moo;

has 'asciiname'     => (is => 'ro');
has 'email'         => (is => 'ro');
has 'fullname'      => (is => 'ro');
has 'has_cpandir'   => (is => 'ro', default => sub { 0 } );
has 'homepage'      => (is => 'ro');
has 'id'            => (is => 'ro');
has 'introduced'    => (is => 'ro');

1;

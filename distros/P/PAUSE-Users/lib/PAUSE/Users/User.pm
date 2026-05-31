package PAUSE::Users::User;
$PAUSE::Users::User::VERSION = '0.12';
use 5.10.0;
use Moo;

has 'asciiname'     => (is => 'ro');
has 'email'         => (is => 'ro');
has 'fullname'      => (is => 'ro');
has 'has_cpandir'   => (is => 'ro', default => sub { 0 } );
has 'homepage'      => (is => 'ro');
has 'id'            => (is => 'ro');
has 'introduced'    => (is => 'ro');
has 'nologin'       => (is => 'ro');
has 'deleted'       => (is => 'ro');
has 'type'          => (is => 'ro');

1;

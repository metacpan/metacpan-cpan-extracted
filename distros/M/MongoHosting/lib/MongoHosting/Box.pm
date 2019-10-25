package MongoHosting::Box;

use Moo;
use strictures 2;

has name       => (is => 'ro', lazy => 1, builder => 1);
has id         => (is => 'ro', lazy => 1, builder => 1);
has private_ip => (is => 'ro', lazy => 1, builder => 1);
has public_ip  => (is => 'ro', lazy => 1, builder => 1);


1;

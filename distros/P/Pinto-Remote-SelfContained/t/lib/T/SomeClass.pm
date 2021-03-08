package
    T::SomeClass; # hide from PAUSE

use v5.10;
use Moo;

use Pinto::Remote::SelfContained::Types qw(
    BodyPart
    SingleBodyPart
    Uri
    Username
);

use namespace::clean;

has body_part => (is => 'rw', isa => BodyPart);
has single_body_part => (is => 'rw', isa => SingleBodyPart);
has uri => (is => 'rw', isa => Uri, coerce => 1);
has username => (is => 'rw', isa => Username);

1;

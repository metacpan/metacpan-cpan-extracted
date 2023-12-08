package PayProp::API::Public::Client::Response::Tag;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::JSON /;


has name  => (is => 'ro', isa => 'Str');
has id    => (is => 'ro', isa => 'Str' );
has type  => (is => 'ro', isa => 'Maybe[Str]' );
has links => (is => 'ro', isa => 'Maybe[HashRef]');

__PACKAGE__->meta->make_immutable;

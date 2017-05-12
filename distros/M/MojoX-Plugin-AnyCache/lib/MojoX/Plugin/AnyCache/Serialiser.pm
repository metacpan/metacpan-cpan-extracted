package MojoX::Plugin::AnyCache::Serialiser;

use strict;
use warnings;
use Mojo::Base '-base';

has 'config';

sub serialise { die("Must be overridden in serialiser module") };
sub deserialise { die("Must be overridden in serialiser module") };

1;
use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::URI 'Uri';

ok(is_Uri(URI->new("http://www.google.com")), 'is_Uri');

ok(Uri->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::URI::Uri->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;

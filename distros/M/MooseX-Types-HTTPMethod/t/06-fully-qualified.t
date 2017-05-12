use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::HTTPMethod 'HTTPMethod10';

ok(is_HTTPMethod10('GET'), 'is_HTTPMethod10');

ok(HTTPMethod10->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

# TODO: it would be nice to have this work *and* be able to keep our
# namespaces clean -- but it looks like we need to do this in MooseX::Types
# itself, by using Sub::Exporter::ForMethods.
ok(MooseX::Types::HTTPMethod::HTTPMethod10->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;

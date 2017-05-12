use warnings;
use strict;

use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints 'find_type_constraint';

use Test::More;

plan tests => 4;

# check that Dir is a subtype of Path::Class::Dir, etc...

my $tc;
$tc = find_type_constraint(Dir);
isa_ok( $tc, 'Moose::Meta::TypeConstraint' );
ok( $tc->is_subtype_of('Path::Class::Dir'),
    'Dir is subtype of Path::Class::Dir'
);
$tc = find_type_constraint(File);
isa_ok( $tc, 'Moose::Meta::TypeConstraint' );
ok( $tc->is_subtype_of('Path::Class::File'),
    'File is subtype of Path::Class::File'
);


use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use DateTime;
use MooseX::Types::DateTime 'DateTime';

my $dt = 'DateTime'->now;
ok(is_DateTime($dt), 'is_DateTime');

ok(DateTime->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::DateTime::DateTime->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;

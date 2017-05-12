use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/01-lib';

use_ok('Example');

my $e;

$e = exception {
  Example->new( field => 0 );
};

#my $tc = Example->meta->get_attribute('field')->type_constraint();

#note $tc->validate(0);

note "!--";
note explain $e;
note "!--";
isnt( $e, undef, '0 is not a valid value for a field' );

#$e = exception {
#  $tc->assert_valid(0);
#};

note explain $e;

isa_ok( $e, 'MooseX::TypeArray::Error' );
can_ok( $e, 'errors' );

my $errors;

is( exception { $errors = $e->errors }, undef, 'errors doesn\'t error itself' );
is( ref $errors, 'HASH', 'errors is an hash' );

note explain $errors;

done_testing;


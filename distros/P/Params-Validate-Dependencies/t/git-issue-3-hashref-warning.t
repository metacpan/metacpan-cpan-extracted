use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Params::Validate::Dependencies qw( validate SCALAR );

END { done_testing(); }

sub foo { validate( @_, { bar => { type => SCALAR } } ) }

my %params = ( bar => 'baz' );

is_deeply +{ foo(%params) }, \%params, 'Params::Validate::Dependencies with list';

is_deeply +{ foo(\%params) }, \%params, 'Params::Validate::Dependencies with hashref';

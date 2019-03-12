use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use SMS::Send::Mocean;

dies_ok {
    my $args = {foo => 1, bar => 1};
    my @required_args = qw(foo baz);

    SMS::Send::Mocean::_required($args, @required_args);
} 'Expect exception on missing required argument.';


done_testing;

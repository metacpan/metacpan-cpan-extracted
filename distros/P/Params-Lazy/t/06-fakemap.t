use strict;
use warnings;

use Test::More;

use Params::Lazy fakemap  => "^@",
                 fakegrep => "^@";

sub fakemap {
   my $code = shift;
   my @ret;
   push @ret, force($code) for @_;
   return @ret;
}

sub fakegrep {
   my $code = shift;
   my @ret;
   for (@_) {
      push @ret, $_ if force($code);
   }
   return @ret;
}

my @results = fakemap "<$_>", 1..10;

is_deeply(
    \@results,
    [ map "<$_>", 1..10 ],
    "can fake map EXPR using lazy arguments"
);

is_deeply(
    [ fakemap "<$_>", 1..10 ],
    [ map     "<$_>", 1..10 ],
    "no stack corruption if used in a different way"
);

is(
   join("|", "foo", fakemap "_${_}_", 1..5),
   join("|", "foo", map     "_${_}_", 1..5),
   "works when used as part of an expression"
);

my $foo;
@results = fakegrep defined, 1, 2, 3, undef, $foo, "b";

is_deeply(
    \@results,
    [ 1, 2, 3, "b" ],
    "can fake grep EXPR"
);

done_testing;
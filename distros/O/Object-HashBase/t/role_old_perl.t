use strict;
use warnings;
use Test::More;

if ($] >= 5.010) {
    plan skip_all => "this test only runs on perl < 5.10";
}

my $err;
eval q{
    package My::TooOld;
    use Object::HashBase '&Some::Role';
    1;
} or $err = $@;

like($err, qr/'&' role prefix requires Perl 5\.010/, 'croak on old perl');

done_testing;

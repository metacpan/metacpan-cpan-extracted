#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Perinci::Sub::Wrapper::Patch::HandlePHPArray;

subtest 'expects hash' => sub {
    my $sub  = sub { my %args = @_; return [ref($args{a}) eq 'HASH' ? 200:400] };
    my $meta = {v => 1.1, args => {a=>{schema=>"hash"}}};
    my $wres = Perinci::Sub::Wrapper::wrap_sub(sub=>$sub, meta=>$meta);
    my $wsub = $wres->[2]{sub};

    my $cres;
    $cres = $wsub->(a=>{});
    is($cres->[0], 200, "status is 200 when given empty hash");
    $cres = $wsub->(a=>[]);
    is($cres->[0], 200, "status is 200 when given empty array");
};

subtest 'expects array' => sub {
    my $sub  = sub { my %args = @_; return [ref($args{a}) eq 'ARRAY' ? 200:400] };
    my $meta = {v => 1.1, args => {a=>{schema=>"array"}}};
    my $wres = Perinci::Sub::Wrapper::wrap_sub(sub=>$sub, meta=>$meta);
    my $wsub = $wres->[2]{sub};

    my $cres;
    $cres = $wsub->(a=>[]);
    is($cres->[0], 200, "status is 200 when given empty array");
    $cres = $wsub->(a=>{});
    is($cres->[0], 200, "status is 200 when given empty hash");
};

DONE_TESTING:
done_testing;

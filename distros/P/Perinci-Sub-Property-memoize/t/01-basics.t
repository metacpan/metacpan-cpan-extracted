#!perl

use 5.010001;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

sub _clean_cache {
    no warnings 'once';
    %Perinci::Sub::Wrapped::memoize_cache = ();
}

{
    my $n = 0;
    my $sub  = sub { [200,"OK",++$n] };
    my $meta = {v=>1.1};

    test_wrap(
        name => 'no args',
        pretest => sub { $n = 0; _clean_cache() },
        wrap_args => {sub => $sub, meta => $meta, convert=>{memoize=>1}},
        wrap_status => 200,
        calls => [
            {argsr=>[], actual_res=>1},
            {argsr=>[], actual_res=>1},
        ],
    );

    test_wrap(
        name => 'another function',
        pretest => sub { $n = 2; _clean_cache() },
        wrap_args => {sub => $sub, meta => $meta, convert=>{memoize=>1}},
        wrap_status => 200,
        calls => [
            {argsr=>[], actual_res=>3},
            {argsr=>[], actual_res=>3},
        ],
    );
}

{
    my $na;
    my $nb;
    my $sub  = sub {
        my %args = @_;
        if ($args{a}) { [200,"OK",++$na] } elsif ($args{b}) { [200,"OK",++$nb] } else { [200,"OK",0] }
    };
    my $meta = {v=>1.1, args=>{a=>{}, b=>{}}};

    test_wrap(
        name => 'with args',
        pretest => sub { $na = 0; $nb = 10; _clean_cache() },
        wrap_args => {sub => $sub, meta => $meta, convert=>{memoize=>1}},
        wrap_status => 200,
        calls => [
            {argsr=>[]    , actual_res=>0},

            {argsr=>[a=>1], actual_res=>1},
            {argsr=>[a=>1], actual_res=>1},
            {argsr=>[b=>1], actual_res=>11},
            {argsr=>[b=>1], actual_res=>11},

            {argsr=>[a=>2], actual_res=>2},
            {argsr=>[a=>2], actual_res=>2},
            {argsr=>[b=>2], actual_res=>12},
            {argsr=>[b=>2], actual_res=>12},

            {argsr=>[a=>1, b=>0], actual_res=>3},
            {argsr=>[a=>1, b=>0], actual_res=>3},
            {argsr=>[b=>1, a=>0], actual_res=>13},
            {argsr=>[b=>1, a=>0], actual_res=>13},
        ],
    );
}

DONE_TESTING:
done_testing;

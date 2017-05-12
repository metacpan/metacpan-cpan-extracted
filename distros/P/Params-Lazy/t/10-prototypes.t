use strict;
use warnings;

use Test::More;

sub fakemap (&@);
use Params::Lazy fakemap => ':@';

sub fakemap (&@) {
    my $code    = shift;
    my $coderef = ref($code) eq 'CODE';
    my @ret;
    for (@_) {
        push @ret, $coderef ? $code->() : force($code);
    }
    return @ret;
}

is_deeply(
    [ fakemap "_${_}_", 1..10 ],
    [ map     "_${_}_", 1..10 ],
    "fakemap EXPR works"
);

is_deeply(
    [ fakemap { "_${_}_" } 1..10 ],
    [ map     { "_${_}_" } 1..10 ],
    "fakemap BLOCK works"
);

is_deeply(
    [fakemap \"_${_}_", 1..10],
    [    map \"_${_}_", 1..10],
    'fakemap \"_${_}_"'
);

TODO: {
    local $TODO = "fakemap sub {}, 1; differs from map sub {}, 1";
    is_deeply(
        [map ref, fakemap sub { "_${_}_"}, 1..10],
        [map ref,     map sub { "_${_}_"}, 1..10],
        'fakemap sub {}'
    );
}

is_deeply(
    [fakemap [ "_${_}_" ], 1..10],
    [    map [ "_${_}_" ], 1..10],
    'fakemap []'
);

is_deeply(
    [fakemap { $_ => chr(96+$_) } 1..10],
    [    map { $_ => chr(96+$_) } 1..10],
    'fakemap {}'
);

is_deeply(
    [fakemap +{ $_ => chr(96+$_) }, 1..10],
    [    map +{ $_ => chr(96+$_) }, 1..10],
    'fakemap +{}'
);

sub fakegrep (&@) {
    my $delayed = shift;
    my $coderef  = ref($delayed) eq 'CODE';
    my @retvals;
    for (@_) {
        if ($coderef ? $delayed->() : force($delayed)) {
            push @retvals, $_;
        }
    }
    return @retvals;
}
use Params::Lazy fakegrep => ':@';

is_deeply(
    [fakegrep { $_ % 2 } 9, 16, 25, 36],
    [    grep { $_ % 2 } 9, 16, 25, 36],
    "fakegrep BLOCK"
);

is_deeply(
    [fakegrep $_ % 2, 9, 16, 25, 36],
    [    grep $_ % 2, 9, 16, 25, 36],
    "fakegrep EXPR"
);

my @avoid;
@_ = (sub { push @avoid, $_ }, 1..10);
&fakegrep;
is_deeply(
    \@avoid,
    [1..10],
    "can use &sub to avoid lazifying"
);

done_testing;

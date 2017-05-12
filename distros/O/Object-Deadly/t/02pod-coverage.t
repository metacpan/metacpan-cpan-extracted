#!perl
use Test::More;

if ( not $ENV{AUTHOR_TESTS} ) {
    plan skip_all => 'Skipping author tests';
}
else {
    plan tests => 1;
    require Devel::Symdump;
    eval "use Test::Pod::Coverage 1.04";
    die $@ if $@;

    pod_coverage_ok(
        'Object::Deadly',
        {   trustme => [
                map {qr/\A\Q$_/}
                    map { /\AUNIVERSAL::(.+)/xms ? $1 : $_ }
                    Devel::Symdump->rnew('UNIVERSAL')->functions
            ]
        }
    );
}

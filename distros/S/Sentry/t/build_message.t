#!/usr/bin/perl
# perl -I lib t/build_message.t

use Sentry;
use Test::More;

my $dsn = 'http://public_key:secret_key@example.com/1234';

my $sentry = Sentry->new( $dsn, tags => { tag1 => 'val1' } );

is( $sentry->{secret_key}, 'secret_key', 'secret_key parsed from dsn' );
is( $sentry->{public_key}, 'public_key', 'public_key parsed from dsn' );
is(
    $sentry->{uri},
    'http://example.com/api/1234/store/',
    'uri was constructed'
);

my $a = $sentry->_build_message(
    message            => 'Arbeiten',
    some_unwanted_attr => 'Msg'
);

is( $a->{message},    'Arbeiten', 'Message attribute is correct' );
is( $a->{level},      'info',     'Default level is info if not specified' );
is( $a->{tags}{tag1}, 'val1',     'Tag specified in constructor is set' );
is( $a->{platform},   'perl',     'Default platform is perl' );
is( $a->{some_unwanted_attr},
    undef,
    'Filter parameters that are not defined in Sentry API for less payload' );

$a = $sentry->_build_message(
    message => 'Perl rocks',
    tags    => { tag2 => 'val2' }
);

is( $a->{tags}{tag1},
    'val1', 'Default tag saved after new _build_message call' );
is( $a->{tags}{tag2}, 'val2', 'New tag set' );

done_testing();

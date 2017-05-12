package t::Net::ACME::X;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use parent qw(
  Test::Class
);

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use Net::ACME::X ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_InvalidParameter : Tests(5) {
    my $exc = Net::ACME::X::create('InvalidParameter', 'ohnono', { value => 'oops' });
    isa_ok( $exc, 'Net::ACME::X::InvalidParameter' );
    unlike( "$exc", qr<SCALAR>, '… and the class is overridden' );

    like( $exc->to_string(), qr<\Aohnono>, 'to_string()' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    is( $exc->get('value'), 'oops', 'get(name)' );

    return;
}

sub test_InvalidCharacters : Tests(5) {
    my $exc = Net::ACME::X::create('InvalidCharacters', 'ohnono', { value => 'oops' });
    isa_ok( $exc, 'Net::ACME::X::InvalidCharacters' );
    unlike( "$exc", qr<SCALAR>, '… and the class is overridden' );

    like( $exc->to_string(), qr<\Aohnono>, 'to_string()' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    is( $exc->get('value'), 'oops', 'get(name)' );

    return;
}

sub test_Empty : Tests(6) {
    my $exc = Net::ACME::X::create('Empty');
    isa_ok( $exc, 'Net::ACME::X::Empty' );
    unlike( "$exc", qr<SCALAR>, '… and the class is overridden' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    $exc = Net::ACME::X::create('Empty', { name => 'hahaha' } );
    isa_ok( $exc, 'Net::ACME::X::Empty' );
    like( "$exc", qr<hahaha>, '… and the override text displays the “name”' );

    is( $exc->get('name'), 'hahaha', 'get(name)' );

    return;
}

sub test_Protocol : Tests(12) {
    my %attrs = (
        url => 'http://where',
        status => 499,
        reason => 'Dunno',
        type => 'some:acme:type',
        detail => 'ohh you’re in trouble now',
    );

    my $exc = Net::ACME::X::create(
        'Protocol',
        \%attrs,
    );
    isa_ok( $exc, 'Net::ACME::X::Protocol' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    while ( my ($k, $v) = each %attrs ) {
        like( "$exc", qr<\Q$v\E>, "… and the override text displays the “$k”" );
        is( $exc->get($k), $v, "get($k)" );
    }

    return;
}

sub test_UnexpectedResponse : Tests(8) {
    my %attrs = (
        uri => 'http://where',
        status => 274,
        reason => 'cuz Jersey',
    );

    my $exc = Net::ACME::X::create(
        'UnexpectedResponse',
        \%attrs,
    );
    isa_ok( $exc, 'Net::ACME::X::UnexpectedResponse' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    while ( my ($k, $v) = each %attrs ) {
        like( "$exc", qr<\Q$v\E>, "… and the override text displays the “$k”" );
        is( $exc->get($k), $v, "get($k)" );
    }

    return;
}

sub test_HTTP_Network : Tests(8) {
    my %attrs = (
        error => 'booboo',
        url => 'http://where',
        method => 'GET',
    );

    my $exc = Net::ACME::X::create(
        'HTTP::Network',
        \%attrs,
    );
    isa_ok( $exc, 'Net::ACME::X::HTTP::Network' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    while ( my ($k, $v) = each %attrs ) {
        like( "$exc", qr<\Q$v\E>, "… and the override text displays the “$k”" );
        is( $exc->get($k), $v, "get($k)" );
    }

    return;
}

sub test_HTTP_Protocol : Tests(14) {
    my %attrs = (
        method => 'GET',
        status => 499,
        reason => 'booboo',
        url => 'http://where',
    );

    my $exc = Net::ACME::X::create(
        'HTTP::Protocol',
        \%attrs,
    );
    isa_ok( $exc, 'Net::ACME::X::HTTP::Protocol' );

    my $str = $exc->to_string();
    like( "$exc", qr<\A\Q$str\E>, '… and the override matches to_string()' );

    while ( my ($k, $v) = each %attrs ) {
        like( "$exc", qr<\Q$v\E>, "… and the override text displays the “$k”" );
    }

    note '… and no warning from an undefined “content” … ?';

    $attrs{'content'} = 'ohh dear';

    $exc = Net::ACME::X::create( 'HTTP::Protocol', \%attrs );

    like( "$exc", qr[\Q$attrs{'content'}\E], "… and the override text displays the “content”" );

    my $max_content_size = Net::ACME::X::HTTP::Protocol::BODY_DISPLAY_SIZE();

    my $max_content = 'x' x $max_content_size;

    $attrs{'content'} = "$max_content///";

    $exc = Net::ACME::X::create( 'HTTP::Protocol', \%attrs );

    unlike( "$exc", qr[\Q$attrs{'content'}\E], '“content” gets trimmed down if needed' );
    like( "$exc", qr[\Q$max_content\E], "… but the first $max_content_size bytes are shown" );

    while ( my ($k, $v) = each %attrs ) {
        is( $exc->get($k), $v, "get($k)" );
    }

    return;
}

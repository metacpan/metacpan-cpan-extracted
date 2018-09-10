#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;
use Pcore::Util::List qw[pairs];

our $tests = [

    # parsing
    ['http://user:password@host:9999/path?query=123#fragment'] => 'http://user:password@host:9999/path?query=123#fragment',
    ['//host:9999/path/']                                      => '//host:9999/path/',
    ['./path:path']                                            => './path:path',
    ['scheme:./path:path']                                     => 'scheme:./path:path',

    # parsing with base
    [ '//host:9999/path/', base => 'http://' ]                     => 'http://host:9999/path/',
    [ '//host:9999/path/', base => 'http://base_host/base_path/' ] => 'http://host:9999/path/',
    [ '/path/path/',       base => 'http://base-host/base_path/' ] => 'http://base-host/path/path/',
    [ '/base_path/path/',  base => 'http://base_host/base_path/' ] => 'http://base_host/base_path/path/',
    [ 'path/path/',        base => 'http://base_host/base_path/' ] => 'http://base_host/base_path/path/path/',

    # file path
    ['file://user:password@host:9999/path?query=123#fragment'] => 'file://user:password@host:9999/path?query=123#fragment',
    [ '//user:password@host:9999/path?query=123#fragment', base => 'file://' ]           => 'file://user:password@host:9999/path?query=123#fragment',
    [ 'path/path',                                         base => 'file://' ]           => 'file:///path/path',
    [ 'path/path',                                         base => 'file:///base_path' ] => 'file:///path/path',

    # inherit
    [ 'path/path?q#f', base => 'http://host/path/?bq#bf' ] => 'http://host/path/path/path?q#f',
    [ 'path/path#f',   base => 'http://host/path/?bq#bf' ] => 'http://host/path/path/path#f',
    [ 'path/path?q',   base => 'http://host/path/?bq#bf' ] => 'http://host/path/path/path?q',

    [ '?q#f', base => 'http://host/path/?bq#bf' ] => 'http://host/path/?q#f',
    [ '?q',   base => 'http://host/path/?bq#bf' ] => 'http://host/path/?q',
    [ '#f',   base => 'http://host/path/?bq#bf' ] => 'http://host/path/?bq#f',

    # mailto
    [ 'user@host', base => 'mailto:' ] => 'mailto:user@host',

    # IDN
    ['http://президент.ua'] => 'http://xn--d1abbgf6aiiy.ua/',
];

our $TESTS = $tests->@* / 2;

plan tests => $TESTS;

my $i;

for my $pair ( pairs( $tests->@* ) ) {
    my $uri = P->uri( $pair->key->@* );

    if ( $uri->to_string ne $pair->value ) {
        my $src  = shift $pair->key->@*;
        my %args = $pair->key->@*;

        say sprintf qq["%s" + "%s" = "%s"\nEXPECTED: "%s"\n], $src, $args{base} // '', $uri->to_string, $pair->value;
    }

    ok( $uri->to_string eq $pair->value, 'p_util_uri_' . ++$i );
}

done_testing $TESTS;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 59                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut

#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;

our $TESTS = [    #
    [ 'tumblr.com',                     is_web2 => 0 ],
    [ 'aaa.tumblr.com',                 is_web2 => 1 ],
    [ 'faketumblr.com',                 is_web2 => 0 ],
    [ 'bbb.aaa.tumblr.com',             is_web2 => 1 ],
    [ 'www.aaa.tumblr.com',             is_web2 => 1 ],
    [ 'blogspot.com/path',              is_web2 => 0 ],
    [ 'www.blogspot.com/path',          is_web2 => 0 ],
    [ 'aaa.blogspot.com/path',          is_web2 => 1 ],
    [ 'blogspot.co.uk/path',            is_web2 => 0 ],
    [ 'www.blogspot.co.uk/path',        is_web2 => 0 ],
    [ 'aaa.blogspot.co.uk/path',        is_web2 => 1 ],
    [ 'www.blogspot.co.uk.tld/path',    is_web2 => 0 ],
    [ 'aaa.blogspot.co.uk.tld/path',    is_web2 => 0 ],
    [ 'twitter.com/path',               is_web2 => 1 ],
    [ 'www.twitter.com/path/asd/asd/s', is_web2 => 1 ],
    [ 'aaa.twitter.com/path/11/',       is_web2 => 0 ],
    [ 'twitter.com/path/subpath',       is_web2 => 1 ],
    [ 'faketwitter.com/path/subpath',   is_web2 => 0 ],
];

plan tests => scalar $TESTS->@*;

my $i;

for my $test ( $TESTS->@* ) {
    my $uri = P->uri( $test->[0], base => 'http://', authority => 1 );

    my %methods = splice $test->@*, 1;

    for my $method ( sort keys %methods ) {
        say dump $uri->_web2_data if !ok( $uri->$method eq $methods{$method}, $i++ . "_$test->[0]_$method" );
    }
}

done_testing scalar $TESTS->@*;

1;
__END__
=pod

=encoding utf8

=cut

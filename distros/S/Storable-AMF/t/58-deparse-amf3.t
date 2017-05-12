use ExtUtils::testlib;
# vim: ts=8 et sw=4 sts=4
use lib 't';
use strict;
use warnings;
use Storable::AMF3 qw(freeze thaw);
use Test::More 'no_plan';

# several tests for different objects
#

my @a = ("[25,50]", '"asdf"', "{a=>1, b=>1}");
for (0..$#a){
    my $obj   = eval $a[$_];
    die $@ if $@;
    my $bytes = freeze $obj;
    is_deeply( [Storable::AMF3::deparse_amf( $bytes )], [$obj, length $bytes], "$_ deparse \"$a[$_]\"");
    is_deeply( [scalar Storable::AMF3::deparse_amf( $bytes )], [$obj], "$_ deparse scalar \"$a[$_]\"");

    is_deeply( [Storable::AMF3::deparse_amf( $bytes." " )], [$obj, length $bytes], "$_ deparse \"$a[$_]\" + 1");
    is_deeply( [scalar Storable::AMF3::deparse_amf( $bytes." " )], [$obj], "$_ deparse scalar \"$a[$_]\" + 1");

    substr( $bytes, -1, 1 )= '';
    is_deeply( [Storable::AMF3::deparse_amf( $bytes )], [], "$_ deparse \"$a[$_]\" - 1");
    ok($@, "-1");
    is_deeply( [scalar Storable::AMF3::deparse_amf( $bytes )], [undef], "$_ deparse \"$a[$_]\" - 1");
    ok($@, "-1");

}
*{TODO} = *Test::More::TODO;



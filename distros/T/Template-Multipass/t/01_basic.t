#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Path::Class;

use ok 'Template::Multipass';

my $t = Template::Multipass->new(
    INCLUDE_PATH => [ file(__FILE__)->parent->subdir("templates")->stringify ],
);

{
my $out;
ok( $t->process( "foo.tt", { blah => "bork" }, \$out, { meta_vars => { bar => "la" } } ) );

is( $out, <<'', "template" );
meta_blah: 
blah: bork
meta_bar: la
bar: la

}

{
my $out;
ok( $t->process( "foo.tt", { blah => "bork", bar => "oink" }, \$out, { meta_vars => { bar => "la" } } ) );

is( $out, <<'', "template" );
meta_blah: 
blah: bork
meta_bar: la
bar: oink

}

{
my $out;
ok( $t->process( "foo.tt", { blah => "ding" }, \$out, { meta_vars => { bar => "dong" } } ) );
is( $out, <<'', "template" );
meta_blah: 
blah: ding
meta_bar: dong
bar: dong

}

{
my $out;
ok( $t->process( "foo.tt", { blah => "ding", bar => "magic" }, \$out, { meta_vars => { bar => "dong", blah => "oi", extra => [ ] } } ) );
is( $out, <<'', "template" );
meta_blah: oi
blah: ding
meta_bar: dong
bar: magic

}

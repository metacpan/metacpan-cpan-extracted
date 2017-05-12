#!perl -wT
use strict;
use warnings;
use Test::More;


plan tests => 6;


use_ok("RackMan::Template");

my $path = "t/files/test.tmpl";

open my $fh, ">", $path or die "error: can't write '$path': $!\n";
print {$fh} qq|{ type:"[% type %]", name:"[% name %]", addr:"[% addr %]" }|;
close $fh;

my $tmpl = eval { RackMan::Template->new(filename => $path) };
is $@, "", "RackMan::Template->new(filename => '$path')";
isa_ok $tmpl, "RackMan::Template", 'check that $tmpl';

my @params = ( type => "Server", name => "squeak.estat", addr => "172.16.100.7" );
eval { $tmpl->param(@params) };
is $@, "", "\$tmpl->param(@params)";

my $out = eval { $tmpl->output };
is $@, "", '$tmpl->output';
is $out, '{ type:"Server", name:"squeak.estat", addr:"172.16.100.7" }',
    "check the rendered output";

unlink $path;


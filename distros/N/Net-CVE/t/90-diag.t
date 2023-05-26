#!/usr/bin/perl

use 5.014002;
use warnings;

use Test::More;
use Test::Warnings;

use Net::CVE;

my $bad = "XYZ-2-BAZ";
my @w;

local $SIG{__WARN__} = sub { push @w => @_ };

my $r = Net::CVE->new->get ($bad);
is_deeply ($r->data, {},			"Bad CVE");
is_deeply ($r->diag, {
    status => -1,
    reason => "Invalid CVE format: '$bad'",
    action => "get",
    source => "tag",
    usage  => 'get ("CVE-2022-26928")',
    },						"Got diagnostics");

# TODO: autodiag
#is (scalar @w, 1,	"Got warning");
#is ($w[0], "Invalid CVE format: '$bad' - expected format CVE-2023-12345\n", "Error");

ok   ($r->get ($0),				"Get non-JSON");
ok   (my $d = $r->diag,				"Get diagnostics");
is   ($d->{status}, -2,				"Status");
is   ($d->{action}, "decode_json",		"Action decode_json");
like ($d->{reason}, qr{malformed JSON},		"Error");

my $tf = "cve-1234-5678.json";
unlink $tf;
if (open my $fh, ">", $tf) {
    say $fh "Invalid";
    close $fh;

    ok   ($r->get ($tf),			"Get non-JSON 2");
    ok   ($d = $r->diag,			"Get diagnostics");
    is   ($d->{action}, "decode_json",		"Action decode_json");
    is   ($d->{source}, $tf,			"Source");
    is   ($d->{status}, -2,			"Status");
    like ($d->{reason}, qr{malformed JSON},	"Error");

    my $is_linux = $^O eq "linux";
    chmod 006, $tf;
    $r->get ($tf);
    ok   ($r->get ($tf),			"Get unreadable");
    ok   ($d = $r->diag,			"Get diagnostics");
    is   ($d->{action}, "get",			"Action get");
    is   ($d->{source}, $tf,			"Source");
    is   ($d->{status}, 13,			"Status")	if $is_linux;
    like ($d->{reason}, qr{denied},		"Error")	if $is_linux;
    }
unlink $tf;

done_testing;

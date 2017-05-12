#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 16;
use Cwd;

use_ok("Template::Provider::HTTP") || die;
use Template;

# create a test server and start it.
require 't/lib/TestServer.pm';
my $s        = TestServer->new;
my $url_root = $s->started_ok("starting a test server");
ok $url_root, "url_root is '$url_root'";

# create a template object based on our provider
my %config = (
    INCLUDE_PATH => [
        getcwd . "/t/templates/files",    # file
        "$url_root/http_a/",              # url
        "$url_root/http_b/",              # alternative url
    ],
);
my $tt = Template->new(
    {   %config,
        LOAD_TEMPLATES => [
            Template::Provider::HTTP->new( \%config ),
            Template::Provider->new( \%config )
        ],
    }
);

ok $tt, "created the tt object";

my %tests = (
    ### template => output
    'in_files'  => "in_files\n",
    'in_http_a' => "in_http_a\n",
    'in_http_b' => "in_http_b\n",
);

foreach my $template ( sort keys %tests ) {

    pass "-------------- $template ---------------";

    my $out = '';
    ok $tt->process( $template, {}, \$out ), "process $template";
    is $out, $tests{$template}, "output is correct";

    $tt->error
        ? fail( "got an unexpected error: " . $tt->error )
        : pass("no error generated");
}


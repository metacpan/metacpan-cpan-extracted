#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use lib qw(t/lib);
use Utils;

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 1+scalar(@cgi_modules);

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart');
foreach my $class (@cgi_modules) {
    if ($class) {
        diag "Testing with $class";
    }

    my $cgi = undef;
    if ($class) {
        $cgi = $tcm->create_cgi(cgi=>$class);
    }
    else {
        $cgi = $tcm->create_cgi;
    }
    isa_ok($cgi, $class || 'CGI');
}


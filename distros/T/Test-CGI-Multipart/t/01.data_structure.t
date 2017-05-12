#!perl -w
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::CGI::Multipart;
use lib qw(t/lib);
use Utils;

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 1+scalar(@cgi_modules);

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart');

# This should not happen.
$tcm->{params}->{weird} = sub {return "weird"};

foreach my $class (@cgi_modules) {
    if ($class) {
        diag "Testing with $class";
    }

    my $cgi = undef;

    if ($class) {
        dies_ok {
            $cgi = $tcm->create_cgi(cgi=>$class);
        } 'unexpected data structure';
    }
    else {
        dies_ok {
            $cgi = $tcm->create_cgi;
        } 'unexpected data structure';
    }
}


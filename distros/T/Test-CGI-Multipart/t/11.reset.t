#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Readonly;
use lib qw(t/lib);
use Utils;
Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 8+6*scalar(@cgi_modules);

{
    my $tcm = Test::CGI::Multipart->new;
    isa_ok($tcm, 'Test::CGI::Multipart');

    ok(!defined $tcm->set_param(
        name=>'first_name',
        value=>'Jim'),
    'setting parameter');
    my @values = $tcm->get_param(name=>'first_name');
    is_deeply(\@values, ['Jim'], 'get param');
    my @names= $tcm->get_names;
    is_deeply(\@names, ['first_name'], 'first name deep');

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
        isa_ok($cgi, $class||'CGI', 'created CGI object okay');

        @names = grep {$_ ne '' and $_ ne '.submit'} sort $cgi->param;
        is_deeply(\@names, ['first_name'], 'names deep');
        foreach my $name (@names) {
            my @got = $cgi->param($name);
            my @expected = $tcm->get_param(name=>$name);
            is_deeply(\@got, \@expected, $name);
        }
    }
}

{
    my $tcm = Test::CGI::Multipart->new;
    isa_ok($tcm, 'Test::CGI::Multipart');

    ok(!defined $tcm->set_param(
        name=>'pets',
        value=>$PETS),
    'setting parameter');
    my @values = $tcm->get_param(name=>'pets');
    is_deeply(\@values, $PETS, 'get param');
    my @names= sort $tcm->get_names;
    is_deeply(\@names, ['pets'], 'names deep');

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
        isa_ok($cgi, $class||'CGI', 'created CGI object okay');

        @names = grep {$_ ne '' and $_ ne '.submit'} sort $cgi->param;
        is_deeply(\@names, ['pets'], 'names deep');
        foreach my $name (@names) {
            my @got = $cgi->param($name);
            my @expected = $tcm->get_param(name=>$name);
            is_deeply(\@got, \@expected, $name);
        }
    }
}


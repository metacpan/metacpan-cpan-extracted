#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Test::Exception;
use Readonly;
use lib qw(t/lib);
use Utils;
Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 12+5*@cgi_modules;

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

ok(!defined $tcm->set_param(
    name=>'pets',
    value=>$PETS),
'setting parameter');
@values = $tcm->get_param(name=>'pets');
is_deeply(\@values, $PETS, 'get param');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name','pets'], 'names deep');

ok(!defined $tcm->upload_file(
    name=>'files',
    file=>'doo_doo.blah',
    value=>'Blah, Blah, Blah,....'),
'uploading blah file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['files', 'first_name', 'pets'], 'names deep');

ok(!defined $tcm->upload_file(
    name=>'files',
    file=>'nah_nah.blah',
    value=>'Nah, Nah, Nah,....'),
'uploading second blah file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['files', 'first_name', 'pets'], 'names deep');

dies_ok{ $tcm->upload_file(
    name=>'first_name',
    file=>'name.blah',
    value=>'Alfred, Bob, Carl, Dexter, Edward, Frank, George, Harry, Ivan, John,,,,,,')} 'mismatch: is first_name a file upload or not';

foreach my $class (@cgi_modules) {
SKIP: {

    if (defined $class and $class eq 'CGI::Simple') {
        skip 'CGI::Simple apparently does not support multiple files', 5;
    }

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
    is_deeply(\@names, ['files', 'first_name','pets'], 'names deep');
    foreach my $name (@names) {
        my $expected = Utils::get_expected($tcm, $name);
        my $got = undef;
        if (ref $expected->[0] eq 'HASH') {
            $got = Utils::get_actual_upload($cgi, $name);
        }
        else {
            my @got = $cgi->param($name);
            $got = \@got;
        }

        is_deeply($got, $expected, $name);
    }

    }
}



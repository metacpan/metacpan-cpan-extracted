#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Readonly;
use lib qw(t/lib);
use Utils;
use autodie qw(open close);
Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];

eval {require Test::CGI::Multipart::Gen::Image;};
if ($@) {
    my $msg = "This test requires GD::Simple";
    plan skip_all => $msg;
}

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 9+5*@cgi_modules;

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
        name=>'image',
        width=>400,
        height=>250,
        instructions=>[
            ['bgcolor','red'],
            ['fgcolor','blue'],
            ['rectangle',30,30,100,100],
            ['moveTo',80,210],
            ['fontsize',20],
            ['string','Helloooooooooooo world!'],
        ],
        file=>'cleopatra.doc',
        type=>'image/jpeg'
), 'image');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'image', 'pets'], 'names deep');

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
    is_deeply(\@names, ['first_name', 'image', 'pets'], 'names deep');
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



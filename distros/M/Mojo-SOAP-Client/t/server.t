#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::File 'curfile';
use Test::More;
use Test::Mojo;

use Mojo::Util qw(dumper);
use Mojo::SOAP::Client;

eval "use Mojolicious::Plugin::SOAP::Server";

plan skip_all => "Mojolicious::Plugin::SOAP::Server required for end2end test" if $@;

my $t = Test::Mojo->new(
    curfile->sibling('exsoaple.pl'));

my $sc = Mojo::SOAP::Client->new(
    log => $t->app->log,
    mojo_ua => $t->ua,
    wsdl => curfile->sibling('nameservice.wsdl'),
    xsds => [
        curfile->sibling('nameservice.xsd')
    ],
    endPoint => '/SOAP'
);
use Data::Dumper;

my $in;
my $err;

$sc->call_p('getCountries')->then(sub {
    $in = shift;
})->wait;

is_deeply $in, {
    'parameters' => {
        'country' => [
            'Switzerland',
            'Germany'
        ]
    }
}, "getContries respons check";

$in = undef;
$sc->call_p('getNamesInCountry',{
    country => 'Switzerland'
})->then(sub {
    $in = shift;
})->wait; 
is_deeply $in, {
    'parameters' => {
        'name' => [
            qw(A B C),'Switzerland'
        ]
    }
}, "getNamesInCountry Call";

eval { 
    $sc->call('getNamesInCountry',{
        country => 'Lock'
    });
};

is $@->message, '/SOAP - 401 Unauthorized',"Check SOAP Exception";

$t->get_ok('/soapGwTest')
    -> status_is(200)
    -> json_is('/parameters/country',['Switzerland','Germany']);


done_testing;

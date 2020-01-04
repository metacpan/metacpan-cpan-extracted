#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::File 'curfile';
use Test::More;
use Test::Mojo;

use Mojo::Util qw(dumper);
use Mojo::SOAP::Client;

my $t = Test::Mojo->new('Mojolicious');

$t->get_ok('/SOAPxx')->status_is(404);

my $sc = Mojo::SOAP::Client->new(
    ua => $t->ua,
    log => $t->app->log,
    wsdl => curfile->sibling('nameservice.wsdl'),
    xsds => [
        curfile->sibling('nameservice.xsd')
    ],
    endPoint => '/SOAP'
);

my $in;
my $err;

$sc->call_p('getCountries')->then(sub {
    $in = shift;
})->wait;

done_testing;

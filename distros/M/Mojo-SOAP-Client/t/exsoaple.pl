#!/usr/bin/perl

use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use Mojolicious::Lite;
use Mojo::SOAP::Client;
use Mojo::File qw(curfile);

plugin 'SOAP::Server' => {
    wsdl => curfile->sibling('nameservice.wsdl'),
    xsds => [curfile->sibling('nameservice.xsd')],
    controller => SoapCtrl->new,
    endPoint => '/SOAP'
};

my $sc = Mojo::SOAP::Client->new(
    log => app->log,
    wsdl => curfile->sibling('nameservice.wsdl'),
    xsds => [
        curfile->sibling('nameservice.xsd')
    ],
    endPoint => '/SOAP'
);

get '/soapGwTest' => sub {
    my $c = shift;
    $sc->call_p('getCountries')->then(sub {
        $c->render(
            json => shift
         );
    });
    $c->render_later;
};


app->start;

package SoapCtrl;

use Mojo::Base -base;
use Data::Dumper;
use XML::Compile::Util qw/pack_type/;

sub getCountries {
    return {
        country => [qw(Switzerland Germany)]
    };
}

sub getNamesInCountry {
    my ($self,$server,$params,$c) = @_;

    my $name = $params->{parameters}{country};
    $c->log->debug("Test Message");
    if ($name eq 'Lock') {
        die {
            status => 401,
            text => 'Unauthorized'
        };
    }

    return {
        name => [qw(A B C),$name]
    };
}


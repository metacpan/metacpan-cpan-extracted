#!/usr/bin/perl

use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use Data::Dumper;
use Mojolicious::Lite;

plugin 'SOAP::Server' => {
    wsdl => $FindBin::Bin.'/nameservice.wsdl',
    xsds => [$FindBin::Bin.'/nameservice.xsd'],
    controller => SoapCtrl->new,
    endPoint => '/SOAP'
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

    #warn Dumper $params;
    my $name = $params->{parameters}{country};
    $c->log->debug("Test Message");
    if ($name eq 'Lock') {
        die {
            status => 401,
            text => 'Unauthorized'
        };
        # return {
        #     _RETURN_CODE => 401,
        #     _RETURN_TEXT => 'Unauthorized',
        # };
    }

    return {
        name => [qw(A B C),$name]
    };
}


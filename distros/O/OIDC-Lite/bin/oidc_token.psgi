use strict;
use warnings;
use Plack::Builder;
use OIDC::Lite::Server::Endpoint::Token;

builder {

    OIDC::Lite::Server::Endpoint::Token->new(

    );

};


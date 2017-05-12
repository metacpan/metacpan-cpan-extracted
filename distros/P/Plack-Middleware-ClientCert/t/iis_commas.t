use strict;
use warnings;

use Plack::Middleware::ClientCert;
use Plack::Test;
use Plack::Util;
use Test::More;

use Data::Dumper;

my $app = sub { 
  my ($env) = @_;

  is $env->{ client_cn }, "Troy O'Leary";
  is $env->{ client_ou }, 'My Insurance, Inc.';
  is $env->{ client_o }, 'Agents Virtual Community';

  return [ 200, [], [] ];
};

$app = Plack::Middleware::ClientCert->wrap( $app ),

my $res = Plack::Util::run_app( $app, { CERT_SUBJECT => qq|C=US, O=Agents Virtual Community, OU="My Insurance, Inc.", CN=Troy O'Leary| } );

done_testing;

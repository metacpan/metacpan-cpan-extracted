use strict;
use warnings;

use Plack::Middleware::ClientCert;
use Plack::Test;
use Plack::Util;
use Test::More;

use Data::Dumper;

my $app = sub { 
  my ($env) = @_;

  is $env->{ client_cn }, 'Employee Name';
  is $env->{ client_ou }, 'Department';
  is $env->{ client_o }, 'Company, Inc';

  return [ 200, [], [] ];
};

$app = Plack::Middleware::ClientCert->wrap( $app ),

my $res = Plack::Util::run_app( $app, { CERT_SUBJECT => '/C=US/O=Company, Inc/OU=Department/CN=Employee Name' } );

$res = Plack::Util::run_app( $app, { 
   SSL_CLIENT_S_DN => '/C=US/O=Company, Inc/OU=Department/CN=Employee Name',
   SSL_CLIENT_S_DN_C => 'US',
   SSL_CLIENT_S_DN_CN => 'Employee Name',
   SSL_CLIENT_S_DN_O => 'Company, Inc',
   SSL_CLIENT_S_DN_OU => 'Department' } );

done_testing;

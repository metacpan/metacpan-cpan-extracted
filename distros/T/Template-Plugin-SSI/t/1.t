# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 2;
use CGI::SSI;

my $ssi = CGI::SSI->new();
ok ( defined $ssi,          "Object Created");
ok ( $ssi->isa("CGI::SSI"), "Object is CGI::SSI" );


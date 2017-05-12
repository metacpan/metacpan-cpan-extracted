#!/usr/bin/env perl
use Plack::Handler::FCGI;

my $app = do('/Users/chris/Projects/venda/saml/Saml2Test/Saml2Test.pl');
my $server = Plack::Handler::FCGI->new(nproc  => 5, detach => 1);
$server->run($app);

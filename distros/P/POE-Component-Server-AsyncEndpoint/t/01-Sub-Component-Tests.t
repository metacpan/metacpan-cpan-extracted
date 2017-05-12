#!/usr/bin/perl

use Config;
use Test::More tests => 1;
#use Test::More "no_plan";
use Test::Output;

ok(1==1, 'Initial tests planned for 0.5x...');

# Debugging only
#sub POE::Kernel::TRACE_SESSIONS { 1 }

# all dependent modules are loaded here
#BEGIN {
#    # threads are needed for testing
#    $Config{useithreads} or die "Sorry. You must recompile Perl with threads to run this program.";
#    use_ok('threads');
#    use_ok('POE::Component::Server::AsyncEndpoint');
#};

# 1) Config package tests
#my $config = POE::Component::Server::AsyncEndpoint::Config->init();

# 2) this one is from the default configuration
#ok($config->webserver_port == 32090, 'config parameter from package');

# 3) this one is from the sample conf file
#ok($config->mq_server_port == 61614, 'config parameter from sample file');


# Channel package tests
#my @chfiles = POE::Component::Server::AsyncEndpoint::Endpoints::init();

# 4) ch file test
#ok($chfiles[0] =~ /\.\/t\/endpoints\/endpoint_(one|two)\/endpoint/, 'finding test channels');


# Webserver package tests
#my $webserver = POE::Component::Server::AsyncEndpoint::WebServer->new({port => 12345});

# 5) web server loaded and quits ok
#isa_ok($webserver, 'POE::Component::Server::AsyncEndpoint::WebServer');
#POE::Kernel->post($webserver->{aliases}->{httpd}, 'shutdown');
#POE::Kernel->run();

# MQ Server package tests
# my $mqsrv = POE::Component::MessageQueue->new({
#     alias    => 'mq_queue',
#     port     => $config->mq_server_port,
#     address  => $config->mq_server_addr,
#     hostname => $config->mq_server_host,
#     logger_alias => 'mq_logger',
#     storage => POE::Component::MessageQueue::Storage::Complex->new({
#         data_dir     => $config->mqdb_path,
#         timeout      => $config->mqdb_timeout,
#         throttle_max => $config->mqdb_throttle_max,
#     }),
# });


# 6) PoCo::MQ loaded and quits ok
#diag("Testing run and shutdown of MQ server...");
#isa_ok($mqsrv, 'POE::Component::MessageQueue');
#$mqsrv->shutdown();
#POE::Kernel->run();


# Runs a simple SOAP test server to test the complete AES Server
#$soapserver = threads->new(\&soapsrv);

# sub soapsrv{

#     use SOAP::Transport::HTTP;
#     use warnings;
#     use strict;

#     my $daemon = SOAP::Transport::HTTP::Daemon
#         -> new (LocalPort => 8081)
#         -> dispatch_with ({'urn://MyTestSOAPClass' => 'MyTestSOAPClass'})
#         -> dispatch_to('MyTestSOAPClass')
#         ->handle();

#     package MyTestSOAPClass;
#     use SOAP::Lite;

#     sub test1{

#         my ($class, $args) = @_;

#         my $soapdata = SOAP::Data
#             -> name('myname')
#             -> type('string')
#             -> uri('MySOAPClass')
#             -> value('HELLO THERE');

#             return $soapdata;

#     }

# }


# Main AES Package Tests
#my $aes = POE::Component::Server::AsyncEndpoint->new();

# X) 
#isa_ok($aes, 'POE::Component::Server::AsyncEndpoint');
#diag("Running the AES Server...");
#POE::Kernel->run();











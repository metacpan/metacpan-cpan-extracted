use strict;
use warnings;
use Test::More;
plan tests => 4;
use Supervisord::Client;
use FindBin;
use File::Spec;
use File::Temp;

my $sock_file_path = File::Temp::tmpnam;
my $tmp_fh = File::Temp->new;


my $ini_config = << "EOS";
[unix_http_server]
file=$sock_file_path
chmod = 0770

[supervisord]

logfile=supervisord.log
pidfile=supervisor.pid

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix://$sock_file_path
;;;; END DEFAULT SETTINGS

[program:print_and_sleep]
command=bash -c 'while true; do echo "sleep forever"; sleep 1; done'

EOS

print $tmp_fh $ini_config;
close( $tmp_fh );

ok my $client =
  Supervisord::Client->new( path_to_supervisor_config => $tmp_fh->filename ), "spawned the client";
ok $client->rpc, 'created the rpc';
is $client->serverurl, "unix://$sock_file_path", "correctly grabbed the socket path";
ok $client->ua->isa("LWP::UserAgent"),"->ua parameter works";
done_testing;

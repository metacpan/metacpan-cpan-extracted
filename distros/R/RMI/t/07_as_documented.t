#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

# THIS IS THE CODE IN THE POD
# UPDATE THEM IN TANDEM!

use_ok("RMI::Client::Tcp");
use_ok("RMI::Server::Tcp");

#process 1: the server

my $parent_pid = $$;
my $child_pid = fork();
unless ($child_pid) {
    # the child process is the server

    # if $RMI::LOG is true, this will make the server logs indent relative to the client
    do { no warnings; $RMI::DEBUG_MSG_PREFIX = ' '; };

    # a grandchild kills the child after 3 seconds
    if (0) {
        unless (fork()) {
            my $c = RMI::Client::Tcp->new();
            sleep 2;
            eval { $c->call_eval('exit 1'); };
            exit;
        }
    }

    # the child process runs a server we test with
    my $s = RMI::Server::Tcp->new(
        #port => 1234,
        allow_eval => 1,
        allow_packages => ['IO::File','Sys::Hostname', qr/Bio::.*/],
        timeout => 3000,
    );
    
    
    require IO::File;
    $s->run;
    exit;
} 

sleep 1;

#process 2: the client on another host

my $c = RMI::Client::Tcp->new(
   #host => "localhost",
   #port => 1234,
); 

ok($c, "got a connection to a TCP server");

# do individual remote object construction or other class methods
my $o = $c->call_class_method("IO::File","new","/etc/passwd");
isa_ok($o,"IO::File", "remote object seems to be an IO::File");
is(ref($o),"RMI::ProxyObject", "..but ref() reveals it is really a proxy object");

my $expect_fh;
open($expect_fh,"/etc/passwd") or die;
my @expect_lines = <$expect_fh>;
ok(scalar(@expect_lines>3), "got at least three lines in our test file");

my $line0 = $o->getline;
is($line0,$expect_lines[0], 'got the first line from the file using $fh->getline');
my $line1 = <$o>;
is($line1,$expect_lines[1], 'got the second line from the file using <$fh> in scalar context');
my @remaining_lines = <$o>;
is_deeply(\@remaining_lines,[@expect_lines[2..$#expect_lines]], 'got the rest of the lines from <$fh> in array context');

# call remote subs/functions
$c->call_eval("use Sys::Hostname");
my $server_hostname = $c->call_function("Sys::Hostname::hostname");
ok($server_hostname, "call to Sys::Hostname::hostname function on the server side works");

# execute arbitrary remote code 
my $otherpid = $c->call_eval('$$'); 
is($otherpid,$child_pid, "got the other process' pid from call_eval");

# changes to perl refs are visible from both sides 
my $a = $c->call_eval('@main::x = (11,22,33); return \@main::x;');
push @$a, 44, 55;
is(scalar(@$a), 5, 'got the correct count on the client side');
is($c->call_eval('scalar(@main::x)'),5, 'got the correct count on the server side');

# references from either side can be used on either side
my $local_fh;
open($local_fh, "/etc/passwd");
my $remote_fh = $c->call_class_method('IO::File','new',"/etc/passwd");
my $remote_coderef = $c->call_eval('sub { my $f1 = shift; my $f2 = shift; my @lines = (<$f1>, <$f2>); return scalar(@lines) }');
my $total_line_count = $remote_coderef->($local_fh, $remote_fh);
is($total_line_count, scalar(@expect_lines)*2, "used a remote CODE ref to read from a local file handle and remote file handle on the remote side");

# this works with Perl primitive IO handles too, if you want to do the work to pass them around in the standard way
open(LOCAL_IO, "/etc/passwd");
my $remote_io = $c->call_eval('open(SOME_FH,"/etc/passwd"); return *SOME_FH{IO}');
$total_line_count = $remote_coderef->(*LOCAL_IO{IO}, $remote_io);
is($total_line_count, scalar(@expect_lines)*2, "used the same code ref on a local old-stype Perl IO hande and a reference to a remote old-style Perl IO handle reference");

# very transparent...
isa_ok($o, 'IO::File');
ok($o->can("getline"), "object can() works");

# ...but not completely (this works if you bring in the whole class with use_remote)
is(ref($o), "RMI::ProxyObject", "ref() reveals the real class");
  
# do the whole class remotely...
$c->use_remote("IO::File");
$o = IO::File->new("/etc/passwd");
my @lines = <$o>; #->getlines;
ok(scalar(@lines) > 1, "got " . scalar(@lines) . " lines");
is(ref($o),'IO::File', "ref() returns IO::File instead of RMI::ProxyObject because we've fully proxied the entire package in this process");

$c->call_eval("exit 1");

# kill the server in the child process
kill $child_pid;


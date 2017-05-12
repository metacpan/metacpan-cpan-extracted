#!/usr/bin/env perl
use RMI::Client::Tcp;

my $c = RMI::Client::Tcp->new(
    host => 'localhost', 
    port => 1234,
);

$c->call_use('IO::File'); 
$r = $c->call_class_method('IO::File','new','/etc/passwd');

$line1 = $r->getline;           # works as an object

$line2 = <$r>;                  # works as a file handle
@rest  = <$r>;                  # detects scalar/list context correctly

$r->isa('IO::File');            # transparent in standard ways
$r->can('getline');

ref($r) eq 'RMI::ProxyObject';  # the only sign this isn't a real IO::File...
                # (see RMI::Client's use_remote() to fix this)


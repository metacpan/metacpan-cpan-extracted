use strict;
use Test::More;
eval "use Test::Pod 1.0";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

#TODO: thinks .pod files are not valid if they do not start with #!/usr/bin/perl
#all_pod_files_ok();

my @files = qw(
	blib/lib/Net/Jabber/Loudmouth.pm
	blib/lib/Net/Jabber/Loudmouth/Connection.pod
	blib/lib/Net/Jabber/Loudmouth/Proxy.pod
	blib/lib/Net/Jabber/Loudmouth/MessageNode.pod
	blib/lib/Net/Jabber/Loudmouth/MessageHandler.pod
	blib/lib/Net/Jabber/Loudmouth/Message.pod
	blib/lib/Net/Jabber/Loudmouth/SSL.pod
	blib/lib/Net/Jabber/Loudmouth/index.pod
);

all_pod_files_ok(@files);

#!/usr/local/bin/perl
use strict;
use lib qw(./lib);
use Net::Kubernetes;
require Net::Kunbernetes::Exception::NotFound;
use Data::Dumper;
use syntax 'try';

my $kube = Net::Kubernetes->new(url=>'http://10.255.67.223:8080', api_version=>'v1beta3');

print Dumper($kube->list_nodes()->[1]->get_pods())."\n";

my $ns = $kube->get_namespace('default');

#my ($rc) = $ns->list_rc(labels=>{'name'=>'doppler-storage-pod-v1'});

#print $rc->scale(2)."\n";

#print Dumper($kube->list_service_accounts)."\n";

# my $sec = $ns->build_secret('testing', { 'sshpubkeypub' => '/home/dave/.ssh/id_rsa.pub', 'otherthingjson' => {type=>'JSON', value=>{text=>'Ha Ha'}} });

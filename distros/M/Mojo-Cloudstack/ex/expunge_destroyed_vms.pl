#!/usr/bin/perl

use Mojo::Util 'slurp';
use Data::Dumper 'Dumper';
use Mojo::Cloudstack;

my $api_key = slurp("/home/holger/.mojo_cloudstack/api_key");
chomp $api_key;
my $secret_key = slurp("/home/holger/.mojo_cloudstack/secret_key");
chomp $secret_key;

my $cs = Mojo::Cloudstack->new(
  host       => "172.29.0.10",
  path       => "/client/api",
  port       => "443",
  scheme     => "https",
  api_key    => $api_key,
  secret_key => $secret_key,
);

my $projectid = $cs->listProjects(
  name => 'Blueprint-Customer'
)->[0]->id;

my $vms = $cs->listVirtualMachines(
  listall => 1,
  projectid => $projectid,
);

my @job_ids;
foreach my $vm (@$vms) {
  next if $vm->state ne 'Destroyed';
  my $ex = $cs->expungeVirtualMachine(
    id => $vm->id,
  );
  push @job_ids, $ex->jobid;

}

warn Dumper \@job_ids;



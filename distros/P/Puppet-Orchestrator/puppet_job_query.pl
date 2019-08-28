#!/usr/bin/env perl

use strict;
use Puppet::DB;
use Puppet::Orchestrator;
use Puppet::Classify;
use Data::Dumper;
use YAML qw(LoadFile Dump);
use Hash::Flatten qw(:all);
use 5.10.0;

# Globals
my $config = LoadFile( "/usr/local/etc/puppet_api_access.yaml" );

# Create a Puppet DB object
my $puppet_db = Puppet::DB->new(
    server_name => $config->{puppetdb_host},
    server_port => $config->{puppetdb_port},
);

# Create a Puppet classification object
my $classify = Puppet::Classify->new(
                  cert_name       => $config->{puppet_classify_cert},
                  server_name     => $config->{puppet_classify_host},
                  server_port     => $config->{puppet_classify_port},
                  puppet_ssl_path => $config->{puppet_ssl_path},
                  puppet_db       => $puppet_db,
                );

# Create a Puppet orchestrator object
my $orchestrator = Puppet::Orchestrator->new(
    server_name       => 'puppet',
    puppet_db       => $puppet_db,
);

my $jobid;

my $group = "Environment - dev";
$group = "All Nodes";
my $nodes = $classify->get_nodes_matching_group( $group );
#$nodes = ["adlawjbda01.corpdev.apdev.local"];
$jobid = $orchestrator->submit_task( "profile::check_id", { "id" => "836" }, $nodes );

#$jobid = 3061;
#$jobid = 3004;
#$orchestrator->wait_for_job($jobid);
$orchestrator->print_output_wait($jobid);

#!/usr/bin/perl
package Service::Engine;

use 5.010;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use File::Pid;
use threads;
use threads::shared;
use Thread::Queue;
use Module::Runtime qw(require_module);

use Service::Engine::Logging;
use Service::Engine::Data;
use Service::Engine::Config;
use Service::Engine::Threads;
use Service::Engine::Alerting;
use Service::Engine::Health;
use Service::Engine::Admin;
use Service::Engine::Admin::Server;
use Service::Engine::Throughput;
use Service::Engine::API;
use Service::Engine::API::Server;

=head1 NAME

Service::Engine - a framework for getting things done!

=head1 VERSION

Version 0.48

0.45 -- Adding Elasticsearch
0.46 -- Updating Mysql to use utf8mb4
0.47 -- Removing unused code
0.48 -- Updating Email Lib
0.49 -- Adding CrateDB Logging

=cut

# shared variables
# any module can set/get them e.g. $Service::Engine::Debug = 1;
our $Config;
our $Log;
our $Data;
our $EngineName;
our $EngineInstance;
our $EngineConfig;
our $VERSION = '0.49';
our $Modules = {};
our $ModuleMethods = {};
our $Alert;
our $Admin;
our $API;
our $Threads;
our $Health;
our $Throughput;
our $Engine;
our $Shutdown = 0;

share($Shutdown);
share($Threads);
share($Log);
share($Admin);
share($API);
share($Health);
share($Throughput);

=head1 SYNOPSIS

A Service Engine performs two basic functions:

Select itmes to process
Work on the items selected

What is selected is definded in Modules::Selector
The work performed is defined in Modules::Worker

To make a service engine:
    - duplicate an example
    - rename the directory
    - modify config.pl
    - customize Modules::Selector and Modules::Worker
    - start the new engine: ./start-engine.pl

To connect to the admin console, telnet to the ip and port defined in config.pl

To connect to the REST API, browse to http://yourIP:yourPort/Health/api_overview, 
or other endooints you define in your config file.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
   
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # load configuration into a shared variable
    # access $Config->get_config('logging')->{'log_level'}
    $Config = Service::Engine::Config->new({'config_file'=>$attributes->{config_file}});
    
    # make sure we have an EngineName
    if (ref($Config->get_config('engine')) eq 'HASH') {
        $EngineName = $Config->get_config('engine')->{'name'};
        $EngineName =~ s/[^\w]//g;
        if (!$EngineName) {
            croak('engine name not valid');
        }
        $EngineInstance = $Config->get_config('engine')->{'instance'};
        $EngineInstance =~ s/[^\w]//g;
        if (!$EngineInstance) {
            croak('engine instance not valid');
        }
    } else {
        croak('engine config not found');
    }
    
    $EngineConfig = $Config->get_config($EngineName);
    if (ref($EngineConfig) ne 'HASH') {
    	croak($EngineName . ' config not found');
    }
    
    # set up Logging
    $Log = shared_clone(Service::Engine::Logging->new());
    
    # set up data for use outside of threads
    # Each thread gets it own set of connections in Threads.pm
    $Data = Service::Engine::Data->new();
    
    $Alert = Service::Engine::Alerting->new();
    
    my $self = bless $attributes, $class;
    $Engine = $self;
    
    $Log->log({msg=>"finished initializing engine",level=>2});
    
    return $self;

}

sub data {
    my $self = shift;
    return $self->{data};
}

=head2 start

=cut

sub start {

    my $self = shift;
    
    my $sleep = $Config->get_config('engine')->{'sleep'};
    $sleep ||= 0;

    $Log->log({msg=>"starting engine",level=>2});
    
    # write pidfile
    # Write the current process id to a file
    # so that the service start and stop commands work :)
    my $pidfile = File::Pid->new({
        file => '/var/run/' . lc $EngineName . '.pid'
    });

    $pidfile->write;
    
    # initialize our selector and worker modules
    my $modules = $EngineConfig->{'required_modules'};
    if (ref($modules) ne 'HASH') {
    	croak('required_modules not found  in config' );
    } elsif (!$modules->{'selector'} || !$modules->{'worker'}) {
    	croak('selector and worker modules are required  in config' );
    }
    
    foreach my $module (keys %{$modules}) {
    	my $module_name = $modules->{$module}->{'name'};
        $ModuleMethods->{$module} = {'method'=>$modules->{$module}->{'method'}};
		$Log->log({msg=>"loading module $module_name",level=>2});
		my $package = $EngineName . '::Modules::' . $module_name;
		my $res = eval { require_module($package) };
		if ($@) {
			$Log->log({msg=>"error loading $package: $@",level=>1});
		} else {
			$Modules->{$module} = $package->new($modules->{$module}->{'config'});
			$Log->log({msg=>"loaded $package",level=>3});
		}
    }
    
    # we need Throughput initialized before Threads
    if ($Config->get_config('health')->{'enabled'}) {
        if ($Config->get_config('health')->{'modules'}->{'Throughput'}->{'enabled'} && $Config->get_config('health')->{'memcached'}->{'enabled'}) {
            $Throughput = shared_clone(Service::Engine::Throughput->new());
        }
    }
    
    # initialize threads
    $Threads = shared_clone(Service::Engine::Threads->new());
    my $method = $ModuleMethods->{'selector'}->{'method'};
    
    # initialize admin
    if ($Config->get_config('admin')->{'enabled'}) {
        $Admin = shared_clone(Service::Engine::Admin->new());
    }
    
    # initialize API
    if ($Config->get_config('api')->{'enabled'}) {
        $API = shared_clone(Service::Engine::API->new());
    }
    
    # initialize health monitoring
    # we do this after admin, because we need access to the Admin object to adjust menus
    if ($Config->get_config('health')->{'enabled'}) {
        $Health = shared_clone(Service::Engine::Health->new());
        my $health_monitoring_thread = threads->create('start_health_monitoring');
    }
    
    if ($Config->get_config('admin')->{'enabled'}) {
        my $api_thread = threads->create('start_api');
    }
    
    # we have to start Admin last, since it needs access to all other modules
    if ($Config->get_config('admin')->{'enabled'}) {
        my $admin_thread = threads->create('start_admin');
    }
    
    $Log->log({msg=>"finished starting engine",level=>2});
    
    while (1) {
    
		my $queue = [];
		# some items to process unless we are shutting down
		$queue = $Modules->{'selector'}->$method() unless $Shutdown;
		
		if (ref($queue) ne 'ARRAY') {
			croak('the queue must be an array reference' );
		}
    
    	# enqueue
    	if (scalar(@{$queue})) {
    		foreach my $item (@{$queue}) {
    		    $Log->log({msg=>"received empty item, skipping",level=>3}) unless $item;
    		    next unless $item;
    		    if ($Throughput) {
                    $Throughput->add(1);
                }
    			my $thread = $Threads->get_thread();
    			$thread->enqueue( $item );
    		}
    	}
    	    	
    	sleep($sleep);

    }

}

sub start_admin {
    my $self = shift;
    $Log->log({msg=>"starting admin",level=>3});
    my $service = $Admin->start_admin_server();
}

sub start_api {
    my $self = shift;
    $Log->log({msg=>"starting api",level=>3});
    my $service = $API->start_api_server();
}

sub start_health_monitoring {
    my $self = shift;
    $Log->log({msg=>"starting health monitoring",level=>3});
    my $service = $Health->start();
}

sub stop_selector {
    my ($self,$fh) = @_;
    $fh->write("stopping selector process\n") unless !$fh;
    $Log->log({msg=>"stopping selector",level=>3});
    $Shutdown = 1;
}

sub start_selector {
    my ($self,$fh) = @_;
    $fh->write("starting selector process\n") unless !$fh;
    $Log->log({msg=>"starting selector",level=>3});
    $Shutdown = 0;
}

=head1 AUTHOR

Richard Bush, C<< <rbush at netsocialapp.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Service::Engine

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Richard Bush.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
 
1;
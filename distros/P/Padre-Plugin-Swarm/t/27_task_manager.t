#!/usr/bin/perl

# Create the task manager

use strict;
use warnings;
use Test::More;
use Time::HiRes ();


######################################################################
# This test requires a DISPLAY to run
BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
	plan skip_all => 'API breakage - this hangs. disabled';
	plan tests => 16;
}

use Padre::Logger;
use Padre::TaskManager        ();
use Padre::Task::Addition     ();
use Padre::Wx::App            ();
use t::lib::Padre::NullWindow ();
use Padre::Plugin::Swarm::Service;

use_ok('Test::NoWarnings');

# Do we start with no threads as expected
is( scalar( threads->list ), 0, 'No threads' );





######################################################################
# Basic Creation

SCOPE: {
	my $wxapp = Padre::Wx::App->new;
	isa_ok( $wxapp, 'Padre::Wx::App' );

	my $window = t::lib::Padre::NullWindow->new;
	isa_ok( $window, 't::lib::Padre::NullWindow' );

	my $manager = Padre::TaskManager->new( conduit => $window );
	isa_ok( $manager, 'Padre::TaskManager' );
	is( scalar( threads->list ), 0, 'No threads' );

	# Run the startup process
	ok( $manager->start, '->start ok' );
	Time::HiRes::sleep(1);
	is( scalar( threads->list ), 1, 'The master threads exists' );

	# Create the sample task
	my $addition = Padre::Task::Addition->new(
		x => 2,
		y => 3,
	);
	my $service = Padre::Plugin::Swarm::Service->new;
	
	isa_ok( $service, 'Padre::Plugin::Swarm::Service' );
	
	use Data::Dumper;
	diag( Dumper $service );
	

	# Schedule the task (which should trigger it's execution)
	ok( $manager->schedule($service), '->schedule ok' );
	threads->yield();
	Time::HiRes::sleep(2);
	
	$service->notify( send_global => { type=>'chat', body=>$0 , from=>'test' } );
	$service->notify( send_global => { type=>'disco', from=>'test' } );
	
	$service->notify( send_local => { type=>'chat', body=>$0 , from=>'test' } );
	$service->notify( send_local  => { type=>'disco', from=>'test' } );
	
	threads->yield();
	Time::HiRes::sleep(2);
	
	# Only the prepare phase should run (for now)
	is( $service->{prepare}, 1, '->{prepare} is false' );
	is( $service->{run},     0, '->{run}     is false' );
	is( $service->{finish},  0, '->{finish}  is false' );

        diag( threads->list );
	# Run the shutdown process
	ok( $manager->stop, '->stop ok' );
        #threads->yield();
        diag( threads->self );
        foreach my $th ( threads->list ) {
	    diag $th;
            $th->join;
        }
	Time::HiRes::sleep(1);
        diag( threads->list );
	is( scalar( threads->list ), 0, 'No threads' );
}

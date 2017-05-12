#===============================================================================
#
#         FILE:  QueueProcessor.pm
#
#  DESCRIPTION:  NetSDS queue processing application
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  10.08.2009 20:57:57 EEST
#===============================================================================

=head1 NAME

NetSDS::App::QueueProcessor - queue processing server framework

=head1 SYNOPSIS

	-----------------------------
	# Configuration file

	# Queue server IP and port
	queue_server = "127.0.0.1:22201"

	# Pulling queue name
	queue_name = "myq"

	# Processing bandwidth (messages per second)
	bandwidth = 2

	# Timeout on idle loops
	idle_timeout = 3
	-----------------------------

	QProc->run(conf_file => './qproc.conf');

	1;

	package QProc;

	use Data::Dumper;
	use base 'NetSDS::App::QueueProcessor';

	# Message processing logic
	sub process {

		my ( $self, $msg ) = @_;

		# Just dump message structure
		print Dumper($msg);

	}

	1;

=head1 DESCRIPTION

C<NetSDS::App::QueueProcessor> module implements framework for applications
processing messages arriving from MemcacheQ queue server.

=cut

package NetSDS::App::QueueProcessor;

use 5.8.0;
use strict;
use warnings;

use Time::HiRes qw(sleep time);    # high resolution timer
use NetSDS::Queue;                 # MemcacheQ API
use base 'NetSDS::App';

use version; our $VERSION = '0.032';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([...])> - class constructor

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	return $self;

}


#***********************************************************************

=item B<initialize()> - application initialization

Internal method implementing common startup actions.

=cut 

#-----------------------------------------------------------------------

sub initialize {

	my ( $self, @params ) = @_;

	$self->SUPER::initialize(@params);

	# Initialize queue server
	$self->{server} = NetSDS::Queue->new(
		server => $self->conf->{queue_server},
	);
	$self->{queue_name} = $self->conf->{queue_name};

	# Set time for each iteration
	if ( $self->conf->{'bandwidth'} ) {
		my $bandwidth = $self->conf->{'bandwidth'} + 0;
		if ($bandwidth) {
			# Bandwidth is given in message/sec
			$self->{'sleep_period'} = ( 1 / $bandwidth );
		} else {
			$self->{'sleep_period'} = 1;    # Default bandwidth = 1 message/sec
		}
	} else {
		$self->{'sleep_period'} = 1;        # Default bandwidth = 1 message/sec
	}

	$self->{'idle_timeout'} = ( $self->conf->{'idle_timeout'} + 0 ) ? $self->conf->{'idle_timeout'} + 0 : 5;

	return $self;

} ## end sub initialize


#***********************************************************************

=item B<main_loop()> - main processing loop

Internal method for application logic.

=cut 

#-----------------------------------------------------------------------

sub main_loop {

	my ($self) = @_;

	$self->start();

	# Main processing loop itself
	while ( !$self->{to_finalize} ) {

		# Call production code
		while ( my $res = $self->{server}->pull( $self->{queue_name} ) ) {

			# Set iteration start timestamp in microseconds
			my $start_time = time;

			$self->process($res);
			last if ( $self->{to_finalize} );

			# If iteration finished fast - sleep
			if ( time < ( $start_time + $self->{'sleep_period'} ) ) {
				sleep( $self->{'sleep_period'} + $start_time - time );
			}

		}
		# Sleep if no messages in queue
		sleep $self->{'idle_timeout'};

		# Process infinite loop
		unless ( $self->{infinite} ) {
			$self->{to_finalize} = 1;
		}

	} ## end while ( !$self->{to_finalize...

	$self->stop();

} ## end sub main_loop

#***********************************************************************

=item B<process()> - main JSON-RPC iteration

This is internal method that implements JSON-RPC call processing.

=cut

#-----------------------------------------------------------------------

sub process {

	my ( $self, $msg ) = @_;

}

1;

__END__

=back

=head1 EXAMPLES

See C<samples/app_qproc.pl> appliction.

=head1 SEE ALSO

L<NetSDS::Queue>

L<NetSDS::App>

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut



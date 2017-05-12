# $Id: Prima.pm,v 1.7 2010/03/24 21:59:53 dk Exp $

# Prima event loop bridge for POE::Kernel.

package POE::Loop::Prima;

use strict;
use warnings;
our $VERSION = '1.03';

# Include common signal handling.
use POE;
use POE::Loop::PerlSignals;

package POE::Kernel;

use strict;
use warnings;
no warnings 'redefine';
use Prima;

my $_watcher_timer;
my @fileno_watcher;

#------------------------------------------------------------------------------
# Loop construction and destruction.

sub loop_initialize 
{
	$::application = Prima::Application-> create()
		unless $::application;
}

sub loop_finalize
{
	my $self = shift;

	undef $_watcher_timer;
	
	foreach my $fd (0..$#fileno_watcher) {
		next unless defined $fileno_watcher[$fd];
		foreach my $mode (MODE_RD, MODE_WR, MODE_EX) {
			POE::Kernel::_warn(
			"Mode $mode watcher for fileno $fd is defined during loop finalize"
			) if defined $fileno_watcher[$fd]->[$mode];
		}
	}

	if ( $::application) {
		$::application-> destroy;
		undef $::application;
	}

  	$self-> loop_ignore_all_signals();
}

#------------------------------------------------------------------------------
# Signal handler maintenance functions.

# This function sets us up a signal when whichever window is passed to
# it closes.
sub loop_attach_uidestroy
{
	my ( $self, $window) = @_;
	
	$window-> onDestroy( sub {
		return unless $self-> _data_ses_count();
		$self-> _dispatch_event( 
			$self, $self,
			EN_SIGNAL, ET_SIGNAL, [ 'UIDESTROY' ],
			__FILE__, __LINE__, time(), -__LINE__
		);
		return 0;
	} );
}

#------------------------------------------------------------------------------
# Maintain time watchers.

my $last_time = time();

sub _loop_event_callback
{
	my $self = $poe_kernel;

	if ( TRACE_STATISTICS) {
		$self-> _data_stat_add('idle_seconds', time() - $last_time);
		$last_time = time();
	}
	
	$self->_data_ev_dispatch_due();
	$self->_test_if_kernel_is_idle();
	
	$_watcher_timer-> stop;
	
	# Return false to stop.
	return 0;
}

sub loop_pause_time_watcher
{
	$_watcher_timer-> stop if $_watcher_timer;
}

sub loop_resume_time_watcher
{
	my ($self, $next_time) = @_;

	$next_time -= time();
	$next_time *= 1000;
	$next_time = 0 if $next_time < 0;

	$_watcher_timer = Prima::Timer-> new( 
		owner  => $::application,
		onTick => \&_loop_event_callback,
	) unless $_watcher_timer;

	$_watcher_timer-> stop;
	$_watcher_timer-> timeout( $next_time);
	$_watcher_timer-> start;
}

*loop_reset_time_watcher = \&loop_resume_time_watcher;

#------------------------------------------------------------------------------
# Maintain filehandle watchers.

my %mask = (
	MODE_RD , [ fe::Read,       'onRead'      ],
	MODE_WR , [ fe::Write,      'onWrite'     ],
	MODE_EX , [ fe::Exception,  'onException' ],
);

sub _loop_select_callback
{
	my ( $self, $obj) = ( $poe_kernel, @_ );

	if (TRACE_FILES) {
		POE::Kernel::_warn "<fh> got $mask{$obj->{mode}}->[1] callback for " . $obj-> file;
	}

	$self-> _data_handle_enqueue_ready( $obj->{mode}, $obj-> {fileno} );
	$self-> _test_if_kernel_is_idle();

	# Return false to stop
	return 0;
}

sub loop_watch_filehandle
{
	my ($self, $handle, $mode) = @_;

	my $fileno = fileno($handle);
	my $mask = $mask{ $mode };
	die "Bad mode $mode" unless defined $mask;
	
	# Overwriting a pre-existing watcher?
	if (defined $fileno_watcher[$fileno]->[$mode]) {
		$fileno_watcher[$fileno]->[$mode]-> destroy;
		undef $fileno_watcher[$fileno]->[$mode];
	}
	
	if (TRACE_FILES) {
		POE::Kernel::_warn "<fh> new file $handle in mode $mode";
	}
	
	# Register the new watcher.
	my $obj = Prima::File-> new(
		owner       => $::application,
		file        => $handle,
		mask        => $mask-> [0],
		$mask-> [1] => \&_loop_select_callback,
	);

	$obj-> {mode}   = $mode;
	$obj-> {fileno} = $fileno;

	$fileno_watcher[$fileno]->[$mode] = $obj;
}

*loop_resume_filehandle = \&loop_watch_filehandle;

sub loop_ignore_filehandle
{
	my ($self, $handle, $mode) = @_;
	my $fileno = fileno($handle);
	
	if (TRACE_FILES) {
		POE::Kernel::_warn "<fh> destroy file $handle in mode $mode";
	}
	
	if (defined $fileno_watcher[$fileno]->[$mode]) {
		$fileno_watcher[$fileno]->[$mode]-> destroy;
		undef $fileno_watcher[$fileno]->[$mode];
	}
}

*loop_pause_filehandle = \&loop_ignore_filehandle;

#------------------------------------------------------------------------------
# The event loop itself.

sub loop_do_timeslice
{
	my $self = shift;
	
	# Check for a hung kernel.
	$self-> _test_if_kernel_is_idle();

	my $now = time if TRACE_STATISTICS;

	$::application-> yield() if $::application;
	
	$self-> _data_stat_add('idle_seconds', time - $now) if TRACE_STATISTICS;
	
	# Dispatch whatever events are due.  Update the next dispatch time.
	$self-> _data_ev_dispatch_due();
}

sub loop_run
{
	my $self = shift;

	# Run for as long as there are sessions to service.
	while ($self->_data_ses_count()) {
		$self->loop_do_timeslice();
	}
}

sub loop_halt {}

sub skip_tests
{
	return "Prima tests require the Prima module"
		if do { eval "use Prima"; $@ };
}

1;

__END__

=head1 NAME

POE::Loop::Prima - bridge between Prima and POE

=head1 SYNOPSIS

See L<POE::Loop>.

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface.
It follows POE::Loop's public interface exactly.  Therefore, please
see L<POE::Loop> for its documentation.

=head1 SEE ALSO

L<POE>, L<POE::Loop>, L<Prima>

=head1 AUTHORS & LICENSING

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut

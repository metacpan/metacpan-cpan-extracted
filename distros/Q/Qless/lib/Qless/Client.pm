package Qless::Client;
=head1 NAME

Qless::Client

=cut

use strict; use warnings;
use JSON::XS qw(decode_json);
use Sys::Hostname qw(hostname);
use Time::HiRes qw();
use Qless::Lua;
use Qless::Config;
use Qless::Workers;
use Qless::Queues;
use Qless::ClientJobs;

=head1 METHODS

=head2 C<new>
=cut
sub new {
	my $class = shift;
	my ($redis) = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	# Redis handler
	$self->{'redis'} = $redis;

	# worker name
	$self->{'worker_name'} = hostname.'-'.$$;

	$self->{'jobs'}     = Qless::ClientJobs->new($self);
	$self->{'queues'}   = Qless::Queues->new($self);
	$self->{'workers'}  = Qless::Workers->new($self);
	$self->{'config'}   = Qless::Config->new($self);

	$self->_mk_private_lua_method($_) foreach ('cancel', 'config', 'complete', 'depends', 'fail', 'failed', 'get', 'heartbeat', 'jobs', 'peek',
            'pop', 'priority', 'put', 'queues', 'recur', 'retry', 'stats', 'tag', 'track', 'unfail', 'workers');

	$self;
}

sub _mk_private_lua_method {
	my ($self, $name) = @_;

	my $script = Qless::Lua->new($name, $self->{'redis'});

	no strict qw(refs);
	no warnings;
	my $subname = __PACKAGE__.'::_'.$name;
	*{$subname} = sub {
		my $self = shift;
		$script->(@_);
	};
	use warnings;
	use strict qw(refs);
}

=head2 C<track($jid)>

Begin tracking the job
=cut
sub track {
	my ($self, $jid) = @_;
	return $self->_track([], 'track', $jid, Time::HiRes::time);
}

=head2 C<untrack($jid)>

Stop tracking the job
=cut
sub untrack {
	my ($self, $jid) = @_;
	return $self->_track([], 'untrack', $jid, Time::HiRes::time);
}

=head2 C<tags([$offset, $count])>

The most common tags among jobs
=cut
sub tags {
	my ($self, $offset, $count) = @_;
	$offset ||= 0;
	$count  ||= 100;

	return decode_json($self->_tag([], 'top', $offset, $count));
}

=head2 C<event - TBD>

Listen for a single event
=cut
sub event { }

=head2 C<events -TBD>

Listen indefinitely for all events
=cut
sub events { }

=head2 C<unfail($group, $queue[, $count])>

Move jobs from the failed group to the provided queue
=cut
sub unfail {
	my ($self, $group, $queue, $count) = @_;
	return $self->_unfail([], Time::HiRes::time, $group, $queue, $count||500);
}

# accessors
=head2 C<config>
=cut
sub config { $_[0]->{'config'} };

=head2 C<workers([$name])>

=cut

sub workers { $#_ == 1 ? $_[0]->{'workers'}->item($_[1]) : $_[0]->{'workers'} }

=head2 C<queues([$name])>

If the name is specified, this method gets or creates a queue with that name. Otherwise it returns L<Qless::Queues> object;
=cut
sub queues  { $#_ == 1 ? $_[0]->{'queues'}->item($_[1])  : $_[0]->{'queues'} }

=head2 C<jobs([$jid])>

If jid is specified this method returns a job object corresponding to that jid, or C<undef> if it doesn't exist. Otherwise it returns L<Qless::ClientJobs> object
=cut
sub jobs    { $#_ == 1 ? $_[0]->{'jobs'}->item($_[1])    : $_[0]->{'jobs'} }

=head2 C<worker_name>

=cut

sub worker_name { $#_ == 1 ? $_[0]->{'worker_name'} = $_[1] : $_[0]->{'worker_name'} }

=head2 C<redis>

=cut

sub redis       { $_[0]->{'redis'} }

1;

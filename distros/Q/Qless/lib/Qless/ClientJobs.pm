package Qless::ClientJobs;
=head1 NAME

Qless::ClientJobs

=cut

use strict; use warnings;
use JSON::XS qw(decode_json encode_json);
use Qless::Job;
use Qless::RecurringJob;
use Qless::Utils qw(fix_empty_array);

=head1 METHODS

=head2 C<new>
=cut
sub new {
	my $class = shift;
	my ($client) = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	$self->{'client'} = $client;

	$self;
}

=head2 C<complete([$offset, $count])>

Return the paginated jids of complete jobs
=cut
sub complete {
	my ($self, $offset, $count) = @_;
	return $self->{'client'}->_jobs([], 'complete', $offset||0, $count||25);
}

=head2 C<tracked>

Return an array of job objects that are being tracked
=cut
sub tracked {
	my ($self) = @_;
	my $results = decode_json($self->{'client'}->_track());
	$results->{'jobs'} = fix_empty_array($results->{'jobs'});
	$results->{'jobs'} = [ map { Qless::Job->new($self, $_) } @{ $results->{'jobs'} } ];
	return $results;
}

=head2 C<tagged($tag[, $offset, $count])>

Return the paginated jids of jobs tagged with a tag
=cut
sub tagged {
	my ($self, $tag, $offset, $count) = @_;
	my $results = decode_json($self->{'client'}->_tag([], 'get', $tag, $offset||0, $count||25));
	$results->{'jobs'} = fix_empty_array($results->{'jobs'});
	return $results;
}

=head2 C<failed([$group, $offset, $count])>

If no group is provided, this returns a JSON blob of the counts of the various types of failures known.
If a type is provided, returns paginated job objects affected by that kind of failure.
=cut
sub failed {
	my ($self, $group, $offset, $count) = @_;

	my $results;
	if (!$group) {
		$results = decode_json($self->{'client'}->_failed());
		return $results;
	}

	$results = decode_json($self->{'client'}->_failed([], $group, $offset||0, $count||25));
	$results->{'jobs'} = fix_empty_array($results->{'jobs'});
	$results->{'jobs'} = [ map { Qless::Job->new($self->{'client'}, $_) } @{ $results->{'jobs'} } ];
	return $results;
}

=head2 C<item($jid)>

Get a job object corresponding to that jid, or C<undef> if it doesn't exist
=cut
sub item {
	my ($self, $jid) = @_;

	my $results = $self->{'client'}->_get([], $jid);
	if (!$results) {
		$results = $self->{'client'}->_recur([], 'get', $jid);
		return undef if !$results;

		return Qless::RecurringJob->new($self->{'client'}, decode_json($results));
	}

	return Qless::Job->new($self->{'client'}, decode_json($results));
}


1;

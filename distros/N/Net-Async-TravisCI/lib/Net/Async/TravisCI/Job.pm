package Net::Async::TravisCI::Job;
$Net::Async::TravisCI::Job::VERSION = '0.002';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 id

=cut

sub id { shift->{id} }

=head2 build_id

=cut

sub build_id { shift->{build_id} }

=head2 repository_id

=cut

sub repository_id { shift->{repository_id} }

=head2 commit_id

=cut

sub commit_id { shift->{commit_id} }

=head2 log_id

=cut

sub log_id { shift->{log_id} }

=head2 annotation_ids

=cut

sub annotation_ids { shift->{annotation_ids} }

=head2 repository_slug

=cut

sub repository_slug { shift->{repository_slug} }

=head2 number

=cut

sub number { shift->{number} }

=head2 config

=cut

sub config { shift->{config} }

=head2 state

=cut

sub state { shift->{state} }

=head2 started_at

=cut

sub started_at { shift->{started_at} }

=head2 finished_at

=cut

sub finished_at { shift->{finished_at} }

=head2 queue

=cut

sub queue { shift->{queue} }

=head2 allow_failure

=cut

sub allow_failure { shift->{allow_failure} }


1;


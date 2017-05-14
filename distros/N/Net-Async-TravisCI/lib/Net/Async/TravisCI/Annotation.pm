package Net::Async::TravisCI::Annotation;
$Net::Async::TravisCI::Annotation::VERSION = '0.002';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 id

=cut

sub id { shift->{id} }

=head2 job_id

=cut

sub job_id { shift->{job_id} }

=head2 description

=cut

sub description { shift->{description} }

=head2 url

=cut

sub url { shift->{url} }

=head2 status

=cut

sub status { shift->{status} }

=head2 username

=cut

sub username { shift->{username} }

=head2 key

=cut

sub key { shift->{key} }


1;


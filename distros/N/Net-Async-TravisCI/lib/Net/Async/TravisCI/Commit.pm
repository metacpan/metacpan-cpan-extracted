package Net::Async::TravisCI::Commit;
$Net::Async::TravisCI::Commit::VERSION = '0.002';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 id

=cut

sub id { shift->{id} }

=head2 sha

=cut

sub sha { shift->{sha} }

=head2 branch

=cut

sub branch { shift->{branch} }

=head2 message

=cut

sub message { shift->{message} }

=head2 committed_at

=cut

sub committed_at { shift->{committed_at} }

=head2 author_name

=cut

sub author_name { shift->{author_name} }

=head2 author_email

=cut

sub author_email { shift->{author_email} }

=head2 committer_name

=cut

sub committer_name { shift->{committer_name} }

=head2 committer_email

=cut

sub committer_email { shift->{committer_email} }

=head2 compare_url

=cut

sub compare_url { shift->{compare_url} }


1;


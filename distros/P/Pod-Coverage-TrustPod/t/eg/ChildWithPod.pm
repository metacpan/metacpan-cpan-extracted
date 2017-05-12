package ChildWithPod;

use base qw(BaseWithNoPod);

=head1 NAME

ChildWithPod - And we inherit from someone without it, how rude!


=head1 METHODS

=head2 blah

Blah method

=cut

sub blah {}

sub zzz { 'Covered by trustme in tests' }

1;

#
# $Id: State.pm,v 58d7ce835577 2023/03/25 10:34:10 gomor $
#
package OPP::State;
use strict;
use warnings;

our $VERSION = '1.00';

use base qw(OPP);

our @AS = qw(
   state
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub init {
   my $self = shift;

   $self->state({});

   return $self;
}

sub _proc {
   my $self = shift;
   my ($idx) = @_;

   # We have to have a set per each proc so we can call multiple times
   # same procs (multiple | uniq, for instance). Otherwise, there will
   # be a collision and only first call we have its state kept and later
   # results will be lost:

   $idx ||= 0;

   my @c = caller(1);

   my $module = $c[0];
   $module =~ s{^.*::(\S+)$}{$1};

   return lc($module).':'.$idx;
}

# Return proc state object:
sub current {
   my $self = shift;
   my ($idx) = @_;

   return $self->state->{$self->_proc($idx)};
}

# Update proc state object from another state object:
sub update {
   my $self = shift;
   my ($state, $idx) = @_;

   return $self->state->{$self->_proc($idx)} = $state;
}

# Reset proc state object:
sub reset {
   my $self = shift;
   my ($idx) = @_;

   return $self->state->{$self->_proc($idx)} = undef;
}

# Reset all state objects:
sub reset_all {
   my $self = shift;

   return $self->state = {};
}

sub add {
   my $self = shift;
   my ($k, $v, $idx) = @_;

   return $self->state->{$self->_proc($idx)}{$k} = $v;
}

sub del {
   my $self = shift;
   my ($k, $idx) = @_;

   return delete $self->state->{$self->_proc($idx)}{$k};
}

sub exists {
   my $self = shift;
   my ($k, $idx) = @_;

   return defined($self->state->{$self->_proc($idx)}{$k}) ? 1 : 0;
}

sub incr {
   my $self = shift;
   my ($k, $idx) = @_;

   return $self->state->{$self->_proc($idx)}{$k}++;
}

sub decr {
   my $self = shift;
   my ($k, $idx) = @_;

   return $self->state->{$self->_proc($idx)}{$k}--;
}

sub value {
   my $self = shift;
   my ($k, $idx) = @_;

   return $self->state->{$self->_proc($idx)}{$k};
}

1;

__END__

=head1 NAME

OPP::State - state object for OPP's processors

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

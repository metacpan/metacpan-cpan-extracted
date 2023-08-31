#
# $Id: Output.pm,v fe275517c71d 2023/03/10 05:42:59 gomor $
#
package OPP::Output;
use strict;
use warnings;

our $VERSION = '1.00';

use base qw(OPP);

our @AS = qw(
   docs
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub init {
   my $self = shift;

   $self->docs([]);

   return $self;
}

sub add {
   my $self = shift;
   my ($doc) = @_;

   $doc = ref($doc) eq 'ARRAY' ? $doc : [ $doc ];

   return push @{$self->docs}, @$doc;
}

sub flush {
   my $self = shift;

   return $self->docs([]);
}

1;

__END__

=head1 NAME

OPP::Output - output object for OPP's processors

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

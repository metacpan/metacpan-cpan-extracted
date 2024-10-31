#
# $Id: Exec.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Exec;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# Note: script.sh will take the input doc from an input file as only argument
#
# | exec script.sh
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $command = $self->options->{0};

   my $unflatten = $self->unflatten($input) or return;
   my $json = $self->to_json($unflatten->[0]);
   $json =~ s{(?<!\\)'}{\\'}g;

   my $new = {};
   $new->{data} = `echo '$json' | $command`;
   $self->output->add($new);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Exec - exec processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

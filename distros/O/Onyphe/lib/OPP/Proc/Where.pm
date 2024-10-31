#
# $Id: Where.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Where;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

use Onyphe::Api;

our $VERSION = '1.00';

my $oa = Onyphe::Api->new->init or die("where: init failed");
$oa->silent(1);
$oa->verbose(0);

#
# NOTE: this where output only results from the previous proc
#
# | where category:datascan ip:$ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $args = $options->{args};

   # Update place holders with found input values:
   my $searches = $self->placeholder($args, $input);

   my $cb = sub {
      my ($results) = @_;
      for my $r (@$results) {
         # Keep original result if matches were found:
         $self->output->add($input);
      }
   };

   $oa->search($searches->[0], 1, 1, { trackquery => 'true' }, $cb);  # Use default callback

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Where - ONYPHE Search API where processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

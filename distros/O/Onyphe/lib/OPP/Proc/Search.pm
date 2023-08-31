#
# $Id: Search.pm,v 69a3d7308875 2023/04/05 15:11:02 gomor $
#
package OPP::Proc::Search;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

use Onyphe::Api;

our $VERSION = '1.00';

my $oa = Onyphe::Api->new->init or die("search: init failed");
$oa->silent(1);
$oa->verbose(0);

#
# | search category:datascan ip:$ip
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
      for (@$results) {
         $_ = $self->flatten($_);
         $self->output->add($_);
      }
   };

   $oa->search($searches->[0], 1, 1, { trackquery => 'true' }, $cb);  # Use default callback

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Search - ONYPHE Search API processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

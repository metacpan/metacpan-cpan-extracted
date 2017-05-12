#
# $Id: Null.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::Null;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
__PACKAGE__->cgBuildIndices;

use Net::SinFP3::Next::Null;

sub run {
   my $self = shift;

   if ($self->last) {
      return;
   }

   my $next = Net::SinFP3::Next::Null->new(
      global => $self->global,
   );
   $self->last(1);

   return $next;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::Null - turn off Input plugin

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

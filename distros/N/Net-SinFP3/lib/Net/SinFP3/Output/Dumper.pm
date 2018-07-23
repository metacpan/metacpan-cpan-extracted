#
# $Id: Dumper.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Output::Dumper;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
__PACKAGE__->cgBuildIndices;

use Data::Dumper;

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my @results = $global->result;

   print Dumper(\@results),"\n";

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Dumper - display results using Data::Dumper

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

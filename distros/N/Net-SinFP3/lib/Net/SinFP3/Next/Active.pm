#
# $Id: Active.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Next::Active;
use strict;
use warnings;

use base qw(Net::SinFP3::Next);
our @AS = qw(
   s1
   s2
   s3
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Ext::S;

sub new {
   my $self = shift->SUPER::new(
      s1 => Net::SinFP3::Ext::S->new,
      s2 => Net::SinFP3::Ext::S->new,
      s3 => Net::SinFP3::Ext::S->new,
      @_,
   );

   return $self;
}

sub print {
   my $self = shift;

   my $buf = 'S1: '.$self->s1->print.' '.
             'S2: '.$self->s2->print.' '.
             'S3: '.$self->s3->print;

   return $buf;
}

1;

__END__

=head1 NAME

Net::SinFP3::Next::Active - object describing a SinFP3 active signature

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

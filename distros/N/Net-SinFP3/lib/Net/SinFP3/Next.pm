#
# $Id: Next.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Next;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   global
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   if (!defined($self->global)) {
      die("[-] ".__PACKAGE__.": You must provide a global object\n");
   }

   return $self;
}

sub print {
   return '';
}

1;

__END__

=head1 NAME

Net::SinFP3::Next - base class for Next objects

=head1 SYNOPSIS

   use base qw(Net::SinFP3::Next);

   # Your Next module code

=head1 DESCRIPTION

This is the base class for all B<Net::SinFP3::Next> objects. When a B<Net::SinFP3::Input> plugin B<run> method is ran, it returns either a single B<Net::SinFP3::Next> object or an arrayref of B<Net::SinFP3::Next> objects.

Then, the main B<Net::SinFP3> loop is ran against each of these B<Net::SinFP3::Next> objects.

=head1 ATTRIBUTES

=over 4

=item B<global> (B<Net::SinFP3::Global>)

The global object containing global parameters and pointers to currently executing plugins.

=back

=head1 METHODS

=over 4

=item B<new> (%hash)

Object constructor. You must give it the following attributes: B<global>.

=item B<print> ()

Return a string containing identification data for this object.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

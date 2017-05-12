#
# $Id: DB.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::DB;
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

sub update {
   my $self = shift;
   return $self;
}

sub init {
   my $self = shift;
   return $self;
}

sub run {
   my $self = shift;
   return $self;
}

sub post {
   my $self = shift;
   return $self;
}

1;

__END__

=head1 NAME

Net::SinFP3::DB - base class for DB plugin objects

=head1 DESCRIPTION

   use base qw(Net::SinFP3::DB);

   # Your DB plugin code

=head1 DESCRIPTION

This is the base class for all B<Net::SinFP3::DB> plugins.

=head1 ATTRIBUTES

=over 4

=item B<global> (B<Net::SinFP3::Global>)

The global object containing global parameters and pointers to currently executing plugins.

=back

=head1 METHODS

=over 4

=item B<new> (%hash)

Object constructor. You must give it the following attributes: B<global>.

=item B<init> ()

Do some initialization by writing this method.

=item B<update> ()

Provides database update by writing this method.

=item B<run> ()

To use when you are ready to launch the main loop.

=item B<post> ()

Do some cleanup by writing this method. B<post> is run near the end of main B<Net::SinFP3> loop postlude. The exact order is:

   output->post > search->post > mode->post > db->post > input->post

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

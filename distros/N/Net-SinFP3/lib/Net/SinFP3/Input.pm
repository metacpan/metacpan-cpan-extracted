#
# $Id: Input.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   global
   last
);
our @AA = qw(
   nextList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

sub new {
   my $self = shift->SUPER::new(
      last     => 0,
      nextList => [ 1 ],
      @_,
   );

   if (!defined($self->global)) {
      die("[-] ".__PACKAGE__.": You must provide a global object\n");
   }

   return $self;
}

sub init {
   my $self = shift;
   return $self;
}

sub run {
   my $self = shift;
   if ($self->last || $self->nextList == 0) {
      return;
   }
   return $self;
}

sub postRun {
   my $self = shift;
   return $self;
}

sub post {
   my $self = shift;
   return $self;
}

sub postFork {
   my $self = shift;
   return $self;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input - base class for Input plugin objects

=head1 SYNOPSIS

   use base qw(Net::SinFP3::Input);

   # Your Input plugin code

=head1 DESCRIPTION

This is the base class for all B<Net::SinFP3::Input> plugins.

=head1 ATTRIBUTES

=over 4

=item B<global> (B<Net::SinFP3::Global>)

The global object containing global parameters and pointers to currently executing plugins.

=item B<last> ($scalar)

When set to true value, the next call to B<run> method will return undef. This means the plugin has nothing more to process and can stop.

=item B<nextList> ([ @array ])

This is mainly used internally when an B<init> method is able to fill a list of next data to process.

=back

=head1 METHODS

=over 4

=item B<new> (%hash)

Object constructor. You must give it the following attributes: B<global>.

=item B<init> ()

Do some initialization by writing this method.

=item B<run> ()

To use when you are ready to launch the main loop.

=item B<postRun> ()

Method will be run within the jobbed process (after fork or equivalent).

=item B<post> ()

Do some cleanup by writing this method. B<post> is run at the very end of main B<Net::SinFP3> loop postlude. The exact order is:

   output->post > search->post > mode->post > db->post > input->post

=item B<postFork> ()

Method will be run in the parent jobbed process (after fork or equivalent).

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

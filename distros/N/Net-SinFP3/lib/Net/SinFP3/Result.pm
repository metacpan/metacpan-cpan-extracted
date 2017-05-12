#
# $Id: Result.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Result;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   global
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub take {
   return [];
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   if (!defined($self->global)) {
      die("[-] ".__PACKAGE__.": You must provide a global object\n");
   }

   my $log = $self->global->log;

   my $take = $self->take;
   # By default we take all Mode objects
   if (@$take == 0) {
      return $self;
   }

   my $search = ref($self->global->search);
   for (@$take) {
      if (/^$search$/) {
         return $self;
      }
   }

   $log->error("Search type [$search] not allowed with this plugin");
   return;
}

sub print {
   my $self = shift;
   return '';
}

1;

__END__

=head1 NAME

Net::SinFP3::Result - base class for Result objects

=head1 SYNOPSIS

   use base qw(Net::SinFP3::Result);

   # Your Result module code

=head1 DESCRIPTION

This is the base class for all B<Net::SinFP3::Result> objects.

=head1 ATTRIBUTES

=over 4

=item B<global> (B<Net::SinFP3::Global>)

The global object containing global parameters and pointers to currently executing plugins.

=back

=head1 METHODS

=over 4

=item B<new> (%hash)

Object constructor. You must give it the following attributes: B<global>.

=item B<take> ()

Return an array ref of allowed I<Search> object types.

=item B<print> ()

Return a string containing data to be printed for this object.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

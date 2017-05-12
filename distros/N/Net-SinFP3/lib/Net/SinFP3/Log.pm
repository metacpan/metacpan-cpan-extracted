#
# $Id: Log.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Log;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   global
   level
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      level => 0,
      @_,
   );

   return $self;
}

sub init {
   my $self = shift;
   return $self;
}

sub info {
   return 'info';
}

sub warning {
   return 'warning';
}

sub error {
   return 'error';
}

sub fatal {
   die("fatal");
}

sub verbose {
   return 'verbose';
}

sub debug {
   return 'debug';
}

sub post {
   my $self = shift;
   return $self;
}

1;

__END__

=head1 NAME

Net::SinFP3::Log - base class for Log objects

=head1 SYNOPSIS

   use base qw(Net::SinFP3::Log);

   # Your Log module code

=head1 DESCRIPTION

This is the base class for all B<Net::SinFP3::Log> objects.

=head1 ATTRIBUTES

=over 4

=item B<global> (B<Net::SinFP3::Global>)

The global object containing global parameters and pointers to currently executing plugins.

=item B<level> ($level)

Set log level by setting this attribute to some value.

=back

=head1 METHODS

=over 4

=item B<new> (%hash)

Object constructor. You must give it the following attributes: B<global>.

=item B<init> ()

Do some initialization by writing this method.

=item B<info> ($message)

Prints $message in B<info> mode.

=item B<warning> ($message)

Prints $message in B<warning> mode.

=item B<error> ($message)

Prints $message in B<error> mode.

=item B<fatal> ($message)

Prints $message in B<fatal> mode and B<die>s.

=item B<verbose> ($message)

Prints $message in B<verbose> mode.

=item B<debug> ($message)

Prints $message in B<debug> mode.

=item B<post> ()

Do some cleanup by writing this method. This is user responsibility to call this method.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

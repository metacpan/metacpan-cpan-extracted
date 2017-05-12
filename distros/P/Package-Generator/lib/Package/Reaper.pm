use strict;
use warnings;
package Package::Reaper;
{
  $Package::Reaper::VERSION = '1.106';
}
use 5.008;
# ABSTRACT: pseudo-garbage-collection for packages

use Carp ();
use Symbol ();


sub new {
  my ($class, $package) = @_;

  # Do I care about checking $package with _CLASS and/or exists_package?
  # Probably not, for now. -- rjbs, 2006-06-05
  my $self = [ $package, 1 ];
  bless $self => $class;
}


sub package {
  my $self = shift;
  Carp::croak "a reaper's package may not be altered" if @_;
  return $self->[0];
}


sub is_armed {
  my $self = shift;
  return $self->[1] == 1;
}


sub disarm { $_[0]->[1] = 0 }


sub arm { $_[0]->[1] = 1 }

sub DESTROY {
  my ($self) = @_;

  return unless $self->is_armed;

  my $package = $self->package;

  Symbol::delete_package($package);
}

"You might be a king or a little street sweeper, but sooner or later you dance
with Package:Reaper.";

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::Reaper - pseudo-garbage-collection for packages

=head1 VERSION

version 1.106

=head1 SYNOPSIS

    use Package::Generator;
    use Package::Reaper;

    {
      my $package = Package::Generator->new_package;
      my $reaper  = Package::Reaper->new($package);
      ...
    }

    # at this point, $package stash has been deleted

=head1 DESCRIPTION

This module allows you to create simple objects which, when destroyed, delete a
given package.  This lets you approximate lexically scoped packages.

=head1 INTERFACE

=head2 new

  my $reaper = Package::Reaper->new($package);

This returns the newly generated package reaper.  When the reaper goes out of
scope and is garbage collected, it will delete the symbol table entry for the
package.

=head2 package

  my $package = $reaper->package;

This method returns the package which will be reaped.

=head2 is_armed

  if ($reaper->is_armed) { ... }

This method returns true if the reaper is armed and false otherwise.  Reapers
always start out armed.  A disarmed reaper will not actually reap when
destroyed.

=head2 disarm

  $reaper->disarm;

This method disarms the reaper, so that it will not reap the package when it is
destroyed.

=head2 arm

  $reaper->arm;

This method arms the reaper, so that it will reap its package when it is
destroyed.  By default, new reapers are armed.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

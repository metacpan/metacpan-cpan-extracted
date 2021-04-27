package Package::Checkpoint;

use strict;
use warnings;
use 5.020;
use experimental qw( postderef signatures );
use Package::Stash;
use Storable qw( dclone );
use Ref::Util qw( is_ref );

# ABSTRACT: Checkpoint the scalar, array and hash values in a package for later restoration
our $VERSION = '0.01'; # VERSION


sub new ($class, $name)
{
  my %self = ( name => $name );

  my $stash = $self{stash} = Package::Stash->new($name);

  foreach my $var ($stash->list_all_symbols('SCALAR'))
  {
    my $value = $stash->get_symbol("\$$var")->$*;
    $self{scalar}->{$var} = is_ref($value) ? dclone($value) : $value;
  }

  foreach my $var ($stash->list_all_symbols('ARRAY'))
  {
    $self{array}->{$var} = dclone $stash->get_symbol("\@$var");
  }

  foreach my $var ($stash->list_all_symbols('HASH'))
  {
    $self{hash}->{$var} = dclone $stash->get_symbol("\%$var");
  }

  bless \%self, $class;
}


sub restore ($self)
{
  my $stash = $self->{stash};

  foreach my $var (keys $self->{scalar}->%*)
  {
    my $value = $self->{scalar}->{$var};
    $stash->get_symbol("\$$var")->$* = is_ref $value ? dclone($value) : $value;
  }

  foreach my $var (keys $self->{array}->%*)
  {
    $stash->get_symbol("\@$var")->@* = dclone($self->{array}->{$var})->@*;
  }

  foreach my $var (keys $self->{hash}->%*)
  {
    $stash->get_symbol("\%$var")->%* = dclone($self->{hash}->{$var})->%*;
  }

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::Checkpoint - Checkpoint the scalar, array and hash values in a package for later restoration

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 package Foo::Bar {
   our $foo = 1;
   our @bar = (1,2,3);
   our %baz = ( a => 1 );
 }

 my $cp = Package::Checkpoint->new('Foo::Bar');

 # modify Foo::Bar
 $Foo::Bar::foo++;
 push @Foo::Bar::bar, 4;
 $Foo::Bar::baz{b} = 2;

 $cp->restore;
 # [$@%]Foo::Bar::{foo,bar,baz} are now back to their original values

=head1 DESCRIPTION

This module saves the scalars, array and hash variables inside a package.  It doesn't
save anything else, including anything in any sub-packages.  The intent is if you are
storing app configuration in a package, you can checkpoint the config, make changes,
test those changes, and then restore the old values.  Probably a better pattern would
be to store the configuration in another type of object like a single hash variable,
but sometimes that may not be an option due to the age and complexity of an application.

=head1 CONSTRUCTOR

=head2 new

 my $cp = Package::Checkpoint->new($package);

Creates a checkpoint for a package, saving all of the scalar, array and hash values
for later restoration.

=head1 METHODS

=head2 restore

 $cp->restore;

Restores the scalar, array and hash values from the checkpoint.

=head1 CAVEATS

Doesn't checkpoint or even consider a whole host of values that might be of interest,
like subroutines or file handles.

=head1 SEE ALSO

=over 4

=item L<Package::Stash>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Package::Checkpoint::Guard;

use strict;
use warnings;
use 5.020;
use base qw( Package::Checkpoint );
use experimental qw( signatures );

# ABSTRACT: Checkpoint the scalar, array and hash values in a package for automatic restoration
our $VERSION = '0.01'; # VERSION


sub DESTROY ($self)
{
  $self->restore;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::Checkpoint::Guard - Checkpoint the scalar, array and hash values in a package for automatic restoration

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 package Foo::Bar {
   our $foo = 1;
   our @bar = (1,2,3);
   our %baz = ( a => 1 );
 }

 {
   my $guard = Package::Checkpoint::Guard->new('Foo::Bar');

   # modify Foo::Bar
   $Foo::Bar::foo++;
   push @Foo::Bar::bar, 4;
   $Foo::Bar::baz{b} = 2;
 }
 # $guard falls out of scope...
 # [$@%]Foo::Bar::{foo,bar,baz} are now back to their original values

=head1 DESCRIPTION

This class works exactly like L<Package::Checkpoint>, except that it will automatically
restore when it falls out of scope.

=head1 BASE CLASS

=over 4

=item L<Package::Checkpoint>

=back

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

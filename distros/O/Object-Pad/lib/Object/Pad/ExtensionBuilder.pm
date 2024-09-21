#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::ExtensionBuilder 0.814;

use v5.18;
use warnings;

=head1 NAME

C<Object::Pad::ExtensionBuilder> - build-time support for extensions to C<Object::Pad>

=head1 SYNOPSIS

=for highlighter language=perl

In F<Build.PL>:

   use Object::Pad::ExtensionBuilder;

   my $build = Module::Build->new)
      ...,
      configure_requires => {
         'Object::Pad::ExtensionBuilder' => 0,
      },
   );

   Object::Pad::ExtensionBuilder->extend_module_build( $build );

   ...

=head1 DESCRIPTION

This module provides a build-time helper to assist authors writing XS modules
that provide L<Object::Pad> extensions. It prepares a L<Module::Build>-using
distribution to be able to compile it.

=cut

=head1 METHODS

=cut

=head2 write_object_pad_h

   Object::Pad::ExtensionBuilder->write_object_pad_h;

This method no longer does anything I<since version 0.810>.

=cut

sub write_object_pad_h
{
}

=head2 extra_compiler_flags

   @flags = Object::Pad::ExtensionBuilder->extra_compiler_flags;

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<object_pad.h> file.

=cut

sub extra_compiler_flags
{
   shift;

   require File::ShareDir;
   require File::Spec;
   require Object::Pad;
   return "-I" . File::Spec->catdir( File::ShareDir::module_dir( "Object::Pad" ), "include" );
}

=head2 extend_module_build

   Object::Pad::ExtensionBuilder->extend_module_build( $build );

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   # preserve existing flags
   my @flags = @{ $build->extra_compiler_flags };
   push @flags, $self->extra_compiler_flags;

   $build->extra_compiler_flags( @flags );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

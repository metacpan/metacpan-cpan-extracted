package Scalar::Readonly;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Scalar::Readonly ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
readonly readonly_on readonly_off	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Scalar::Readonly', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Scalar::Readonly - functions for controlling whether any scalar variable is read-only

=head1 SYNOPSIS

  use Scalar::Readonly ':all';
  my $foo = "foo";
  readonly_on($foo);
  $foo = "bar";  #ERROR!
  
  if (readonly($foo)) {
    readonly_off($foo);
  }
  
  readonly_off($]);
  $] = "6.0";
  
  print "This is Perl v$]";

=head1 DESCRIPTION

This simple module can make scalars read-only. Useful to protect configuration variables, for example.

This module can also be used to subvert Perl's many read-only variables to potential evil trickery.

=head2 readonly

Ths function takes a scalar variable and tells you whether it is read-only. It returns 0 if the scalar isn't
read-only, and a positive number if it is.

=head2 readonly_on

Makes the passed scalar variable read-only. If you try and modify a read-only scalar, your code will die with
the following error message:

  Modification of a read-only value attempted at

=head2 readonly_off

Makes the passed scalar variable read-write. You can even do this to read-only special variables,
though you almost certainly don't want to do that.

=head2 EXPORT

':all' => readonly, readonly_on, readonly_off

=head1 SEE ALSO

L<Scalar::Util>, L<Attribute::Constant>, L<Const::Fast>.

=head1 AUTHOR

Philippe M. Chiasson, E<lt>gozer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Philippe M. Chiasson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

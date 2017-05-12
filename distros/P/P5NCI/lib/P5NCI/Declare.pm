package P5NCI::Declare;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.31';

use P5NCI::Library;

use Attribute::Handlers autotie => { '__CALLER__::NCI' => __PACKAGE__ };

my %libs;

sub import
{
	my $class = shift;
	$libs{ caller() }  = P5NCI::Library->new( @_ );
}

sub UNIVERSAL::NCI :ATTR
{
	my ($package, $symbol, $referent, $attr, $data) = @_;

	my $lib          = $libs{$package};
	my ($name, $sig) = @$data;
	my $function     = $lib->load_function( $name, $sig );
	*$symbol         = $function;
}

1;
__END__

=head1 NAME

P5NCI::Declare - declarative syntax for P5NCI bindings

=head1 SYNOPSIS

  use P5NCI::Declare library => 'shared_library';

  sub perl_function :NCI( c_function => 'vii' );

  perl_function( 101, 77 );

=head1 DESCRIPTION

C<P5NCI::Declare> allows you to bind Perl functions to C functions with
subroutine attributes.

When you C<use> this module, you I<must> pass: the key C<library> where the
value is the name of the shared library you want to load (following the normal
L<P5NCI> conventions).  You may pass an I<optional> C<path> key, where the
value is the path to the library.

To bind a Perl function name to a C function, use a subroutine declaration with
the C<NCI> attribute.  The attribute takes a pair where the key is the name of
the function and the value is its P5NCI signature.

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<gt>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2006 - 2007, chromatic.  Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.x.

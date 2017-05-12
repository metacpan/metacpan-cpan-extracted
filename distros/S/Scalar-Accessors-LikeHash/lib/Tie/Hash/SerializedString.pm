package Tie::Hash::SerializedString;

use 5.008;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use base "Tie::Hash";
use Carp;
use Module::Runtime;

sub TIEHASH
{
	my $class = shift;
	my ($ref, $implementation) = @_;
	croak "need a scalar ref to tie hash to" unless ref $ref eq 'SCALAR';
	$implementation = "Scalar::Accessors::LikeHash::JSON" unless defined $implementation;
	Module::Runtime::use_package_optimistically($implementation);
	bless [$implementation, $ref] => $class;
}

for my $method (qw( STORE FETCH EXISTS DELETE CLEAR ))
{
	my $lc_method = lc $method;
	my $coderef = sub {
		my ($implementation, $ref) = @{+shift};
		return $implementation->$lc_method($ref, @_);
	};
	no strict 'refs';
	*$method = $coderef;
}

sub FIRSTKEY
{
	my ($implementation, $ref) = @{+shift};
	my @keys = $implementation->keys($ref);
	return $keys[0];
}

sub NEXTKEY
{
	my ($implementation, $ref) = @{+shift};
	my ($lastkey) = @_;
	my @keys = $implementation->keys($ref);
	while (@keys)
	{
		my $this = shift @keys;
		return $keys[0] if $this eq $lastkey && @keys;
	}
	return;
}

sub SCALAR
{
	my ($implementation, $ref) = @{+shift};
	return $$ref;
}

1;

__END__

=head1 NAME

Tie::Hash::SerializedString - tied interface for Scalar::Accessors::LikeHash

=head1 SYNOPSIS

   my $string = '{}';
   tie my %hash, "Tie::Hash::SerializedString", \$string;
   
   $hash{foo} = "bar";
   
   print $string;   # prints '{"foo":"bar"}'

=head1 DESCRIPTION

This provides a tied hash wrapper around L<Scalar::Accessors::LikeHash>
implementations.

Usage: C<< tie %hash, "Tie::Hash::SerializedString", \$scalar, $impl >>

... where C<< $impl >> is the class name of a concrete implementation of the
L<Scalar::Accessors::LikeHash> role. If the implementation is omitted, then
defaults to L<Scalar::Accessors::LikeHash::JSON>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Scalar-Accessors-LikeHash>.

=head1 SEE ALSO

L<Scalar::Accessors::LikeHash>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


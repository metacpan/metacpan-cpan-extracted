package Module::Hash;

use 5.006;
use strict;

BEGIN {
	$Module::Hash::AUTHORITY = 'cpan:TOBYINK';
	$Module::Hash::VERSION   = '0.002';
}

use base qw( Tie::Hash );
use Carp qw( croak );
use Module::Runtime qw( use_package_optimistically use_module );

# Tied interface
#

sub TIEHASH
{
	my $class = shift;
	return $class->new(@_);
}

sub STORE
{
	croak "Attempt to modify read-only hash, caught";
}

sub FETCH
{
	my ($self, $key) = @_;
	return $self->use($key);
}

sub FIRSTKEY
{
	return;
}

sub NEXTKEY
{
	return;
}

sub EXISTS
{
	my ($self, $key) = @_;
	defined $self->use($key);
}

sub DELETE
{
	croak "Attempt to modify read-only hash, caught";
}

sub CLEAR
{
	croak "Attempt to modify read-only hash, caught";
}

sub SCALAR
{
	return !!1;
}

# Object-oriented interface
#

sub new
{
	my $class = shift;
	my %args  = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
	
	# Defaults
	$args{optimistic} = 1 unless exists $args{optimistic};
	
	bless \%args, $class;
}

sub optimistic { $_[0]{optimistic} };
sub prefix     { $_[0]{prefix} };
sub has_prefix { exists $_[0]{prefix} };

sub use
{
	my ($self, $module) = @_;
	
	my @mv = grep /\w/, split /\s/, $module;
	croak "No module name given" unless @mv;
	
	$mv[0] = join(q[::], $self->prefix, $mv[0]) if $self->has_prefix;
	
	$self->optimistic ? &use_package_optimistically(@mv) : &use_module(@mv);
	return $mv[0];
}

# Import-oriented interface
#

sub import
{
	my $class = shift;
	tie %$_, $class for @_;
}

1
__END__

=head1 NAME

Module::Hash - a tied hash that requires modules for you

=head1 SYNOPSIS

	use strict;
	use Test::More tests => 1;
	use Module::Hash;
	
	tie my %MOD, "Module::Hash";
	
	my $number = $MOD{"Math::BigInt"}->new(42);
	
	ok( $number->isa("Math::BigInt") );

=head1 DESCRIPTION

Module::Hash provides a tied hash that can be used to load and quote
module names.

=head2 Tied Interface

	tie my %MOD, "Module::Hash", %options;

The hash is tied to Module::Hash. Every time you fetch a hash key, such
as C<< $MOD{"Math::BigInt"} >> that module is loaded, and the module
name is returned as a string. Thus the following works without you
needing to load L<Math::BigInt> in advance.

	$MOD{"Math::BigInt"}->new(...)

You may wonder what the advantage is of this hash, rather that using good
old:

	require Math::BigInt;
	Math::BigInt->new(...)

Well, the latter is actually ambiguous. Try defining a sub called
C<BigInt> in the C<Math> package!

You can provide an optional minimum version number for the module. The
module will be checked against the required version number, but the
version number will not be included in the returned string. Thus the
following works:

	$MOD{"Math::BigInt 1.00"}->new(...)

The following options are supported:

=over

=item *

B<prefix> - an optional prefix for modules

	tie my $MATH, "Module::Hash", prefix => "Math";
	my $number = $MATH{BigInt}->new(42);

=item *

B<optimistic> - a boolean. If the hash is optimistic, then it doesn't
croak when modules are missing; it silently returns the module name
anyway. Hashes are optimistic by default; you need to explicitly
pessimize them:

	tie my $MOD, "Module::Hash", optimistic => 0;

=back

Attempting to modify the hash will croak.

=head2 Import-Oriented Interface

If you just want to use the default options, you can supply a reference
to the hash in the import statement:

	my %MOD;
	use Module::Hash \%MOD;
	$MOD{"Math::BigInt"}->new(...);

Or:

	my $MOD;
	use Module::Hash $MOD;
	$MOD->{"Math::BigInt"}->new(...);

Little known fact: Perl has a built-in global hash called C<< %\ >>.
Unlike C<< %+ >> and C<< %- >> and some other built-in global hashes,
the Perl core doesn't use it for anything. And I don't think anybody
else uses it either. The following makes for some cute code...

	use Module::Hash \%\;
	$\{"Math::BigInt"}->new(...);

... or an unmaintainable nightmare depending on your perspective.

=head2 Object-Oriented Interface

This module also provides an object-oriented interface, intended
for subclassing, etc, etc.

Methods:

=over

=item C<< new(%options) >>

=item C<< optimistic >>

=item C<< has_prefix >>

=item C<< prefix >>

=item C<< use($hash_key) >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Hash>.

=head1 SEE ALSO

Most of the tricky stuff is handled by L<Module::Runtime>.

L<Module::Quote> is similar to this, but more insane. If this module isn't
insane enough for you, try that.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


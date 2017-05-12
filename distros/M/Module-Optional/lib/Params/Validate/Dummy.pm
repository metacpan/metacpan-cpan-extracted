package Params::Validate::Dummy;

use strict;
use warnings;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.03;
	@ISA         = qw (Exporter);
	my %tags =
        ( types =>
          [ qw( SCALAR ARRAYREF HASHREF CODEREF GLOB GLOBREF
                SCALARREF HANDLE BOOLEAN UNDEF OBJECT ) ],
        );

	%EXPORT_TAGS = (
	all => [ qw( validate validate_pos validation_options validate_with ),
                     map { @{ $tags{$_} } } keys %tags ],
	%tags,
	);
	@EXPORT      = qw (validate validate_pos);
	@EXPORT_OK   = (@{ $EXPORT_TAGS{all} }, 'set_options' );
}

sub validate (\@$) {
    @{$_[0]};
}

sub validate_pos (\@@) {
    @{$_[0]};
}

sub validate_with {
    my %p = @_;

    $p{params};
}

sub validation_options {}
sub set_options {}


sub SCALAR    () { 1 }
sub ARRAYREF  () { 2 }
sub HASHREF   () { 4 }
sub CODEREF   () { 8 }
sub GLOB      () { 16 }
sub GLOBREF   () { 32 }
sub SCALARREF () { 64 }
sub UNKNOWN   () { 128 }
sub UNDEF     () { 256 }
sub OBJECT    () { 512 }
sub HANDLE    () { 16 | 32 }
sub BOOLEAN   () { 1 | 256 }

1;

__END__

=head1 NAME

Params::Validate::Dummy - Stub for Params::Validate

=head1 SYNOPSIS

  use Params::Validate::Dummy qw();
  use Module::Optional qw(Params::Validate);

=head1 DESCRIPTION

This module provides stub routines for those who don't have Params::Validate
installed. 

For more details, please refer to the documentation for L<Params::Validate>.

The code here is just stub routines which do NOTHING at all, passing through
any arguments in the API and prototypes of L<Params::Validate>. In 
particular, the dummy stubs do not do defaulting, validation, untainting or
anything else that Params::Validate does. If you need this functionality,
either provide it yourself in the surrounding code, or don't use this module
and insist that the real Params::Validate is installed.

=head2 C<validate>, C<validate_pos>

The parameter list is passed through as a return value.

=head2 C<validate_with>

Returns the value of the params option.

=head2 C<set_options>, C<validation_options>

These do nothing at all.

=head2 Data types: C<SCALAR>, C<SCALARREF>, C<ARRAYREF>, C<HASHREF>, C<GLOB>, 
C<GLOBREF>, C<BOOLEAN>, C<CODEREF>, C<HANDLE>, C<OBJECT>, C<UNDEF>, C<UNKNOWN>

In the L<Params::Validate> module, these are constants implemented by subs
that return numbers. This module implements the same functions.


=head1 SUPPORT

See L<Module::Optional>

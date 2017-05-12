package Switch::Reftype;
$Switch::Reftype::VERSION = '0.001';
# ABSTRACT: Execute code based on which type of reference is given.
use strict;
use warnings;
use Scalar::Util 'reftype';

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    switch_reftype
    if_SCALAR
    if_ARRAY
    if_HASH
    if_CODE
    if_REF
    if_GLOB
    if_LVALUE
    if_FORMAT
    if_IO
    if_VSTRING
    if_REGEXP
)]);
our @EXPORT_OK = map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS;
our @EXPORT = qw(switch_reftype);


sub switch_reftype {
    my $ref = shift;
    my %dispatch = @_;
    my $reftype = defined($ref) && (reftype($ref) || "scalar") || "undef";
    for ($ref) {    # Alias $ref to $_
        for my $key ($reftype, 'default') {
            if (exists $dispatch{$key}) {
                my $result = $dispatch{$key};
                $result = $result->() if reftype $result eq "CODE";
                return $result;
            }
        }
    };
}


sub _if_reftype {
    my $ref = shift;
    switch_reftype $ref,
        @_,
        default => sub { $ref }
    ;
}    

sub if_SCALAR (&$)  {   return _if_reftype($_[1], SCALAR    => $_[0]);  }
sub if_ARRAY (&$)   {   return _if_reftype($_[1], ARRAY     => $_[0]);  }
sub if_HASH (&$)    {   return _if_reftype($_[1], HASH      => $_[0]);  }
sub if_CODE (&$)    {   return _if_reftype($_[1], CODE      => $_[0]);  }
sub if_REF (&$)     {   return _if_reftype($_[1], REF       => $_[0]);  }
sub if_GLOB (&$)    {   return _if_reftype($_[1], GLOB      => $_[0]);  }
sub if_LVALUE (&$)  {   return _if_reftype($_[1], LVALUE    => $_[0]);  }
sub if_FORMAT (&$)  {   return _if_reftype($_[1], FORMAT    => $_[0]);  }
sub if_IO (&$)      {   return _if_reftype($_[1], IO        => $_[0]);  }
sub if_VSTRING (&$) {   return _if_reftype($_[1], VSTRING   => $_[0]);  }
sub if_REGEXP (&$)  {   return _if_reftype($_[1], REGEXP    => $_[0]);  }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Switch::Reftype - Execute code based on which type of reference is given.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # switch-like statement on the reftype of a given variable:
  use Switch::Reftype;              # switch_reftype is imported by default.
  $result = switch_reftype $foo,
    SCALAR      => sub {...},       # Run when $foo is a SCALAR reference
    ARRAY       => sub {...},       # Run when $foo is an ARRAY reference
    HASH        => sub {...},       # Run when $foo is a HASH reference
    CODE        => sub {...},       # Run when $foo is a CODE reference
    REF         => sub {...},       # Run when $foo is a REF reference
    GLOB        => sub {...},       # Run when $foo is a GLOB reference
    LVALUE      => sub {...},       # Run when $foo is an LVALUE reference
    FORMAT      => sub {...},       # Run when $foo is a FORMAT reference
    IO          => sub {...},       # Run when $foo is an IO reference
    VSTRING     => sub {...},       # Run when $foo is a VSTRING reference
    REGEXP      => sub {...},       # Run when $foo is a Regexp reference
    scalar      => sub {...},       # Run when $foo isn't a reference
    undef       => sub {...},       # Run when not defined $foo
    default     => sub {...},       # Run when the reftype of $foo isn't given
  ;
  
  # map-like functions. $foo is aliassed to $_ inside the BLOCK:
  use Switch::Reftype ':all';       # Import all functions.
  $result = if_SCALAR {...} $foo;
  $result = if_ARRAY {...} $foo;
  $result = if_HASH {...} $foo;
  $result = if_CODE {...} $foo;
  $result = if_REF {...} $foo;
  $result = if_GLOB {...} $foo;
  $result = if_LVALUE {...} $foo;
  $result = if_FORMAT {...} $foo;
  $result = if_IO {...} $foo;
  $result = if_VSTRING {...} $foo;
  $result = if_REGEXP {...} $foo;

=head1 DESCRIPTION

Sometimes, you want your subroutine or method to perform a specific action based
on the type of argument given. For example, your subroutine might accept either
a simple scalar, an array reference, or a hash reference. Depending on which
type of argument your subroutine got, it has to act slightly differently. The
Switch::Reftype family of functions help you to easily codify these differences.

Switch::Reftype relies heavily on L<Scalar::Util/reftype> from
L<Scalar::Util> module.

=head1 FUNCTIONS

=head2 switch_reftype

  switch_reftype $reference, %reftypes

The keys of C<%reftypes> should correspond with the possible return values of
L<Scalar::Util/reftype> (for a complete list, see the L</SYNOPSIS>).

If C<$reference> isn't a reference but just another scalar, C<switch_reftype>
will look for the element with key C<'scalar'>. Likewise, if C<$reference>
isn't defined, it will look for key C<'undef'>. If C<$referencer> is both
defined and a reference, C<switch_reftype> will use Scalar::Util's
C<reftype $reference> to determine which key to look for.

If no suitable key/value pair was given (e.g. C<$reference> is an C<ARRAY>
reference but no C<< ARRAY => sub {...} >> pair exists), C<switch_reftype> will
look for the key C<'default'>.

If, at this point, still absolutely no appropriate key/value pair was found,
C<switch_reftype> gives up and returns undef (in scalar context) or the empty
list (in list context).

Otherwise, it calls the found subref and returns whatever that returns. Inside
the subref, C<$reference> is aliassed to C<$_>.

=head2 if_SCALAR

  if_SCALAR {...} $reference;

Syntactic sugar for

  switch_ref $reference
    SCALAR => sub {...},
    default => sub { $reference }
  ;

In other words, it calls the subroutine and returns whatever that returns if
C<$reference> is a reference to a scalar, or else it just returns C<$reference>.

=head2 if_ARRAY

  if_ARRAY {...} $reference

Like L</if_SCALAR>, but for ARRAY references.

=head2 if_HASH

  if_HASH {...} $reference

Like L</if_SCALAR>, but for HASH references.

=head2 if_CODE

  if_CODE {...} $reference

Like L</if_SCALAR>, but for CODE references.

=head2 if_REF

  if_REF {...} $reference

Like L</if_SCALAR>, but for REF references.

That is, references to references, as in:

  $ref = \"foo";    # Normal SCALAR reference
  $refref = \\$ref; # REF reference

=head2 if_GLOB

  if_GLOB {...} $reference

Like L</if_SCALAR>, but for GLOB references (i.e. C<\*foo>)

=head2 if_LVALUE

  if_LVALUE {...} $reference

Like L</if_SCALAR>, but for LVALUE references.

LVALUE references really get into the guts of what you can do with references.
It's beyond the scope of this document to explain them, but see L<ref>. Mostly
included for completeness' sake.

=head2 if_FORMAT

  if_FORMAT {...} $reference

Like L</if_SCALAR>, but for FORMAT references (see L<format>). Mostly
included for completeness' sake.

=head2 if_IO {...} 

  if_IO {...} $reference

Like L</if_SCALAR>, but for IO references (i.e. C<*STDIN{IO}>). Mostly
included for completeness' sake.

=head2 if_VSTRING

  if_VSTRING {...} $reference

Like L</if_SCALAR>, but for VSTRING references (i.e. C<\v127.0.0.1>).

=head2 if_REGEXP

  if_REGEXP {...} $reference

Like L</if_SCALAR>, but for Regexp references (i.e. C<qr/.../>).

=head1 AUTHOR

P. Ramakers <pramakers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by P. Ramakers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

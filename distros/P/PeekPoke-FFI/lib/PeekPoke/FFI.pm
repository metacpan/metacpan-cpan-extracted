package PeekPoke::FFI;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus 1.00;
use base qw( Exporter );

our @EXPORT_OK = qw( peek poke );

# ABSTRACT: Perl extension for reading and writing to arbitrary memory locations
our $VERSION = '0.01'; # VERSION


my $ffi = FFI::Platypus->new( api => 1, lib => [undef], lang => 'C' );


sub new
{
  my($class, %opts) = @_;

  my $base = $opts{base} || 0;
  my $type = $opts{type} || 'uint8';
  my $size = $ffi->sizeof($type);
  my $memcpy = $ffi->function( memcpy => [ 'opaque', "${type}[1]", 'size_t' ] => 'opaque' );

  bless {
    base   => $base,
    type   => $type,
    size   => $size,
    memcpy => $memcpy,
  }, $class;

}

my $default;

sub _self
{
  my $args = shift;
  if(ref $args->[0])
  {
    return shift @$args;
  }
  else
  {
    return $default ||= __PACKAGE__->new;
  }
}


sub peek
{
  my $self = _self(\@_);
  my($offset) = @_;
  $ffi->cast('opaque' => $self->{type} . '[1]', $self->{base} + $offset * $self->{size})->[0];
}


sub poke
{
  my $self = _self(\@_);
  my($offset, $value) = @_;
  $self->{memcpy}->call($self->{base} + $offset * $self->{size}, [$value], 1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PeekPoke::FFI - Perl extension for reading and writing to arbitrary memory locations

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 # function interface
 use PeekPoke::FFI qw( peek poke );
 my $value = peek( 0xdeadbeaf );
 poke( 0xdeadbeaf, $value + 1 );

 # OO-interface
 use PeekPoke::FFI;
 my $pp = PeekPoke::FFI->new( type => 'sint32', offset => 0xdeadbeaf );
 my $value = $pp->peek( 0xdeadbeaf );
 $pp->poke( 0xdeadbeaf, 0 - $value );

=head1 DESCRIPTION

Very occasionally I need to get/set bytes from arbitrary bits of memory
from a Perl script or module.  If you know what you are doing it isn't
too tricky to get an arbitrary byte from Perl.  Setting one is a little
harder, but can be done with tricks.  This module implements these tricks
so that I don't have to remind myself of how to do it the next time I
need to reach for this particular tool.

=head1 CONSTRUCTOR

=head2 new

 my $pp = PeekPoke::FFI->new(%opts);

Create a L<PeekPoke::FFI> instance.  If you need to get/set values other than bytes, or
if you want to set a base address, then you will want to create

=over 4

=item type

The L<FFI::Platypus> type to use for peeking and poking.  Defaults to C<uint8>.
Only integer and floating point types are supported.

=item base

The base address to use.  The offset will be added to this value.

=back

=head1 METHODS

=head2 peek

 my $value = $pp->peek($offset);
 my $value = peek($offset);

Get the value at the given offset.

=head2 poke

 $pp->poke($offset, $value);
 poke($offset, $value);

Set the value at the given offset.

=head1 CAVEATS

Most of the time you shouldn't be peeking and poking at random bits of memory.
Sometimes during development it can be useful for various reasons.  Use with
extreme caution in production.

=head1 SEE ALSO

=over

=item L<PeekPoke>

This is an XS module that has been around for donkey's years.  It only works
with the native Perl integer values (IV) which is not usually what I want.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Regexp::Melody;
use 5.014;
use warnings;

# ABSTRACT: Melody is a language that compiles to regular expressions, while aiming to be more readable and maintainable
our $VERSION = '0.001000';


use Exporter::Shiny 1.006000 qw( compiler );
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->bundle;
$ffi->mangler( sub { "melody_" . shift } );
$ffi->attach( compiler => [ 'string' ] => 'string' => sub {
	my ( $xsub, $input ) = @_;
	return $xsub->( $input );
} );


use Hash::Util::FieldHash qw( fieldhash );
fieldhash( my %melody );

sub new {
	my ( $class, $input ) = @_;
	my $output = compiler( $input );
	my $regexp = qr/$output/;
	my $self = bless( $regexp => $class );
	$melody{$self} = $input;
	return $self;
}

sub to_melody {
	my ( $self ) = @_;
	return $melody{$self};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Melody - Melody is a language that compiles to regular expressions, while aiming to be more readable and maintainable

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

  use Test2::V0;
  use Regexp::Melody;
  
  my $re = Regexp::Melody->new( <<'MELODY' );
  16 of "na";
  
  2 of match {
    <space>;
    "batman";
  }
  MELODY
  
  like( "nananananananananananananananana batman", $re );
  
  done_testing;

=head1 DESCRIPTION

Melody is a more verbose way of writing regular expressions.

Melody syntax is described at L<https://yoav-lavi.github.io/melody/book/>.

This module is a wrapper around the Rust implementation of Melody, and
provides a functional interface identical to the Rust library, as well as
an object-oriented interface which may be more convenient for use in Perl.

=head1 FUNCTIONAL INTERFACE

No functions are exported by default, but they may be requested:

  use Regexp::Melody qw( compiler );

=head2 Functions

=head3 C<< compiler( $melody ) >>

Compiles the string of Melody into a PCRE-like string.

=head1 OBJECT-ORIENTED INTERFACE

=head2 Constructor

=head3 C<< new( $melody ) >>

Compiles a string of Melody into a regular expression.

The returned object is a blessed Perl object, but may be used on the right
hand side of the `=~` operator like a regexp.

(It's actually a blessed regexp ref, but that detail may change in future
versions of this module.)

=head2 Methods

=head3 C<< to_melody() >>

Turns the regexp back into a string of Melody.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-regexp-melody/issues>.

=head1 SEE ALSO

L<https://crates.io/crates/melody_compiler>.

L<https://yoav-lavi.github.io/melody/book/>.

=head1 AUTHOR

Author: Toby Inkster

Contributors:

Yoav Lavi (Rust library)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

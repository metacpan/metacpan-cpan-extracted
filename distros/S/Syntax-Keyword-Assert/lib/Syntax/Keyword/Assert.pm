package Syntax::Keyword::Assert 0.10;

use v5.14;
use warnings;

use Carp ();
use Devel::StrictMode;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

sub import {
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub unimport {
   my $pkg = shift;
   my $caller = caller;

   $pkg->unimport_into( $caller, @_ );
}

sub import_into   { shift->apply( sub { $^H{ $_[0] }++ },      @_ ) }
sub unimport_into { shift->apply( sub { delete $^H{ $_[0] } }, @_ ) }

sub apply {
   my $pkg = shift;
   my ( $cb, $caller, @syms ) = @_;

   @syms or @syms = qw( assert );

   my %syms = map { $_ => 1 } @syms;
   $cb->( "Syntax::Keyword::Assert/assert" ) if delete $syms{assert};

   Carp::croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

# called from Assert.xs
sub _croak {
    goto &Carp::croak;
}

1;
__END__

=encoding utf-8

=head1 NAME

Syntax::Keyword::Assert - assert keyword for Perl

=head1 SYNOPSIS

    use Syntax::Keyword::Assert;

    sub hello($name) {
        assert { defined $name };
        say "Hello, $name!";
    }

    hello("Alice"); # => Hello, Alice!
    hello();        # => Dies when STRICT mode is enabled

=head1 DESCRIPTION

This module provides a syntax plugin that introduces an B<assert> keyword to Perl.
It dies when the block returns false and C<STRICT> mode is enabled. When C<STRICT> mode is disabled, the block is ignored at compile time. The syntax is simple, C<assert BLOCK>.

C<STRICT> mode is controlled by L<Devel::StrictMode>.

=head1 SEE ALSO

L<PerlX::Assert>, L<Devel::Assert>, L<Carp::Assert>

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut


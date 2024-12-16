package Syntax::Keyword::Assert 0.13;

use v5.14;
use warnings;

use Carp ();

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

1;
__END__

=encoding utf-8

=head1 NAME

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost in production

=head1 SYNOPSIS

    use Syntax::Keyword::Assert;

    my $name = 'Alice';
    assert( $name eq 'Bob' );
    # => Assertion failed ("Alice" eq "Bob")

=head1 DESCRIPTION

Syntax::Keyword::Assert introduces a lightweight assert keyword to Perl, designed to provide runtime assertions with minimal overhead.

=over 4

=item B<STRICT Mode>

When STRICT mode is enabled, assert statements are checked at runtime. Default is enabled. If the assertion fails (i.e., the block returns false), the program dies with an error. This is particularly useful for catching errors during development or testing.

C<$ENV{PERL_ASSERT_ENABLED}> can be used to control STRICT mode.

    BEGIN { $ENV{PERL_ASSERT_ENABLED} = 0 }  # Disable STRICT mode

=item B<Zero Runtime Cost>

When STRICT mode is disabled, the assert blocks are completely ignored at compile phase, resulting in zero runtime cost. This makes Syntax::Keyword::Assert ideal for use in production environments, as it does not introduce any performance penalties when assertions are not needed.

=item B<Simple Syntax>

The syntax is dead simple. Just use the assert keyword followed by a block that returns a boolean value.

    assert( $name eq 'Bob' );

=back

=head1 SEE ALSO

=over 4

=item L<PerlX::Assert>

This module also uses keyword plugin, but it depends on L<Keyword::Simple>.

=item L<Devel::Assert>

This module provides a similar functionality, but it dose not use a keyword plugin.

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut


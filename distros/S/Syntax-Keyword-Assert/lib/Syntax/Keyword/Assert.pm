package Syntax::Keyword::Assert 0.19;

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

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost

=head1 SYNOPSIS

    use Syntax::Keyword::Assert;

    my $obj = bless {}, "Foo";
    assert($obj isa "Bar");
    # => Assertion failed (Foo=HASH(0x11e022818) isa "Bar")

    assert($x > 0, "x must be positive");
    # => x must be positive

=head1 DESCRIPTION

Syntax::Keyword::Assert provides a syntax extension for Perl that introduces a C<assert> keyword.

By default assertions are enabled, but can be disabled by setting C<$ENV{PERL_ASSERT_ENABLED}> to false before this module is loaded:

    BEGIN { $ENV{PERL_ASSERT_ENABLED} = 0 }  # Disable assertions

When assertions are disabled, the C<assert> are completely ignored at compile phase, resulting in zero runtime cost. This makes Syntax::Keyword::Assert ideal for use in production environments, as it does not introduce any performance penalties when assertions are not needed.

=head1 KEYWORDS

=head2 assert

    assert(EXPR)
    assert(EXPR, MESSAGE)

If EXPR is truthy in scalar context, then happens nothing. Otherwise, it dies with a user-friendly error message.

Here are some examples:

    assert("apple" eq "banana");  # => Assertion failed ("apple" eq "banana")
    assert(123 != 123);           # => Assertion failed (123 != 123)
    assert(1 > 10);               # => Assertion failed (1 > 10)

You can provide a custom error message as the second argument:

    assert($x > 0, "x must be positive");
    # => x must be positive

The message expression is lazily evaluated. It is only evaluated when the assertion fails.
This is equivalent to:

    $cond || do { die $msg }

This means you can use expensive computations or side effects in the message without worrying about performance when the assertion passes:

    assert($x > 0, expensive_debug_info());
    # expensive_debug_info() is NOT called if $x > 0

=head1 SEE ALSO

=over 4

=item L<PerlX::Assert>

This module also uses keyword plugin, but it depends on L<Keyword::Simple>. And this module's error message does not include the failed expression.

=item L<Devel::Assert>

This module provides a similar functionality, but it does not use a keyword plugin.

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut


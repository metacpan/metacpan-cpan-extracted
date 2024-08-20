package Syntax::Keyword::Assert 0.11;

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

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost in production

=head1 SYNOPSIS

    use Syntax::Keyword::Assert;

    sub hello($name) {
        assert { defined $name };
        say "Hello, $name!";
    }

    hello("Alice"); # => Hello, Alice!
    hello();        # => Dies when STRICT mode is enabled

=head1 DESCRIPTION

Syntax::Keyword::Assert introduces a lightweight assert keyword to Perl, designed to provide runtime assertions with minimal overhead.

=over 4

=item B<STRICT Mode>

When STRICT mode is enabled, assert statements are checked at runtime. If the assertion fails (i.e., the block returns false), the program dies with an error. This is particularly useful for catching errors during development or testing.

=item B<Zero Runtime Cost>

When STRICT mode is disabled, the assert blocks are completely ignored at compile phase, resulting in zero runtime cost. This makes Syntax::Keyword::Assert ideal for use in production environments, as it does not introduce any performance penalties when assertions are not needed.

=item B<Simple Syntax>

The syntax is straightforward—assert BLOCK—making it easy to integrate into existing code.

=back

=head2 STRICT Mode Control

The behavior of STRICT mode is controlled by the L<Devel::StrictMode> module. You can enable or disable STRICT mode depending on your environment (e.g., development, testing, production).

For example, to enable STRICT mode:

    BEGIN { $ENV{PERL_STRICT} = 1 }  # Enable STRICT mode

    use Syntax::Keyword::Assert;
    use Devel::StrictMode;

    assert { 1 == 1 };  # Always passes
    assert { 0 == 1 };  # Dies if STRICT mode is enabled

To disable STRICT mode (it is disabled by default):

    use Syntax::Keyword::Assert;
    use Devel::StrictMode;

    assert { 0 == 1 };  # Block is ignored, no runtime cost

SEE ALSO:
L<Bench | https://github.com/kfly8/Syntax-Keyword-Assert/blob/main/bench/compare-no-assertion.pl>

=head1 TIPS

=head2 Verbose error messages

If you set C<$Carp::Verbose = 1>, you can see stack traces when an assertion fails.

    use Syntax::Keyword::Assert;
    use Carp;

    assert {
        local $Carp::Verbose = 1;
        0;
    }

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


package Symbol::Move;
use strict;
use warnings;

our $VERSION = '0.000002';

use Symbol::Methods;

sub import {
    my $class   = shift;
    my $package = caller;

    while (@_) {
        my $old = shift;
        my $new = shift;
        $package->symbol::move($old, $new);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Symbol::Move - Move or rename symbols at compile time.

=head1 DESCRIPTION

This package allows you to make move symbols in the current package, between
the current package and other packages, or between any arbitrary packages.

=head1 SYNOPSYS

    use Symbol::Move(
        'foo'        => 'bar',    # Move the sub foo in the current package to the name bar.
        '%A::B::foo' => 'bar',    # Move the %A::B::foo hash to the %bar symbol in the current package.
        '@foo' => 'A::B::bar',    # Move the @foo array in the current package to the @A::B::bar symbol.
    );

=head1 USAGE

    use Symbol::Move $SYMBOL => $NEW_NAME, ...;

C<$SYMBOL> must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in C<$PACKAGE>.

C<$NEW_NAME> must be a string identifying the symbol. The string may include a
symbol, or the sigil from the C<$SYMBOL> string will be used. The string can be
a fully qualified symbol name, or it will be assumed that the new name is in
C<$PACKAGE>.

=head1 USEFUL FOR RENAMING IMPORTS

    package Foo;

    {
        package Foo::Scratch;
        use Some::Exporter qw/xyz/;
    }
    use Symbol::Move '&Foo::Scratch::xyz' => 'my_xyz';

    my_xyz(' => 'my_xyz';

    my_xyz(...);

=head1 SEE ALSO

=over 4

=item Symbol::Alias

L<Symbol::Alias> Allows you to set up aliases within a package at compile-time.

=item Symbol::Delete

L<Symbol::Delete> Allows you to remove symbols from a package at compile time.

=item Symbol::Extract

L<Symbol::Extract> Allows you to extract symbols from packages and into
variables at compile time.

=item Symbol::Methods

L<Symbol::Methods> introduces several package methods for managing symbols.

=back

=head1 SOURCE

The source code repository for symbol can be found at
F<http://github.com/exodist/Symbol-Move>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

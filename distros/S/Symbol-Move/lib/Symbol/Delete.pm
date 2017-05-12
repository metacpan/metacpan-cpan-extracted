package Symbol::Delete;
use strict;
use warnings;

our $VERSION = '0.000002';

use Symbol::Methods;

sub import {
    my $class = shift;
    my $package = caller;
    $package->symbol::delete($_) for @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Symbol::Delete - Remove a symbol from the symbol table.

=head1 DESCRIPTION

This package allows you to remove symbols from the symbol table at compile
time. The symbol can be in the current package or any arbitrary packages.

=head1 SYNOPSYS

    use Symbol::Delete(
        'foo'           # Remove the sub 'foo' from the current package
        '%A::B::foo'    # Remove the hash 'foo' from the A::B package
        '@A::B::bar',   # Remove the array 'bar from the A::B package
    );

=head1 USAGE

    use Symbol::Delete $SYMBOL, $SYMBOL2, ...;

C<$SYMBOL> must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in C<$PACKAGE>.

=head1 SEE ALSO

=over 4

=item Symbol::Alias

L<Symbol::Alias> Allows you to set up aliases within a package at compile-time.

=item Symbol::Extract

L<Symbol::Extract> Allows you to extract symbols from packages and into
variables at compile time.

=item Symbol::Move

L<Symbol::Move> allows you to rename or relocate symbols at compile time.

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

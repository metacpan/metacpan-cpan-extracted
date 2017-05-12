package Symbol::Extract;
use strict;
use warnings;

our $VERSION = '0.000002';

use Symbol::Methods;

sub import {
    my $class   = shift;
    my $package = caller;

    while (@_) {
        my $sym  = shift;
        my $dest = shift;
        $$dest = $package->symbol::delete($sym);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Symbol::Extract - Remove a symbol from the symbol table and place it's ref into
a variable.

=head1 DESCRIPTION

This package allows you to remove symbols from the symbol table at compile
time, placing them into variables. The symbol can be in the current package or
any arbitrary packages.

=head1 SYNOPSYS

    my ($foo, $bar);
    use Symbol::Extract(
        foo       => \$foo,    # Remove the 'foo' sub from the current package, putting the ref into $foo
        A::B::bar => \$bar,    # Remove the 'bar' sub from the A::B package, putting the ref into $bar
    );

=head1 USAGE

    use Symbol::Extract $SYMBOL => $REF;

C<$SYMBOL> must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in C<$PACKAGE>.

C<$REF> must be a scalar ref, a reference to the symbol will be put into the
reference.

=head1 SEE ALSO

=over 4

=item Symbol::Alias

L<Symbol::Alias> Allows you to set up aliases within a package at compile-time.

=item Symbol::Delete

L<Symbol::Delete> Allows you to remove symbols from a package at compile time.

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

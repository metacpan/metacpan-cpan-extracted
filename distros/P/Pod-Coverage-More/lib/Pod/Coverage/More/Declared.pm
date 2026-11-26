# ABSTRACT: What class builders and signature modules declare about the subs of a package
# PODNAME: Pod::Coverage::More::Declared

package Pod::Coverage::More::Declared 0.005;

use 5.036;
use warnings FATAL => q{all};

use Module::Runtime qw{require_module};


# Signatures of single subs first: when a class builder also declares the sub, the signature is more specific.
our @PROVIDERS = map { "Pod::Coverage::More::Declared::$_" } qw{TypeParams FunctionParameters Kavorka MOP ObjectPad ClassTiny};


# The declaration of the invocant of a method, parameter 0, for the providers.
# @param   name  Maybe[Str]  the name of the invocant, or undef when it has none
# @returns HashRef  the declaration of the parameter
# @example my $self = Pod::Coverage::More::Declared->invocant('$self');
sub invocant {
    my ( $class, $name ) = @_;
    return { name => $name, index => 0, type => undef, optional => 0, invocant => 1 };
}

# The declarations of the subs of C<package> that C<names> lists and a provider declares.
# When two providers declare the same sub, the first in PROVIDERS wins, and a C<body> from a later one fills in a missing one.
# @param   package  Str            the name of the package
# @param   names    ArrayRef[Str]  the names of the subs
# @returns HashRef  from the name of each declared sub to its declaration
# @example my $declared = Pod::Coverage::More::Declared->declarations_for( 'Some::Class', [ 'new', 'size' ] );
sub declarations_for {
    my ( $class, $package, $names ) = @_;
    my %declared;
    foreach my $provider (@PROVIDERS) {
        require_module($provider);
        next if !$provider->applies_to($package);
        my $found = $provider->declarations( $package, $names );
        foreach my $name ( keys %$found ) {
            if ( !$declared{$name} ) {
                $declared{$name} = $found->{$name};
                next;
            }
            $declared{$name}{body} //= $found->{$name}{body};
        }
    }
    return \%declared;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Declared - What class builders and signature modules declare about the subs of a package

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Pod::Coverage::More::Declared;

    my $declared = Pod::Coverage::More::Declared->declarations_for( 'Pod::Coverage::More::Declared', ['declarations_for'] );

=head1 DESCRIPTION

Class builders and signature modules keep what a programmer declared about a sub: the types of its parameters,
which ones are required, what it returns, and which attribute an accessor reads.
This module asks one provider per such system, and each provider answers only for a package that its system built.
No provider loads its system, with one exception: a Moo class is read through its Moose metaclass, which loads Moose.

=head1 DECLARATIONS

A declaration is a HASHREF:

=over 4

=item B<via> - STRING - the system that declared it, such as C<Moose> or C<Function::Parameters>

=item B<role> - STRING - C<constructor>, C<reader>, C<writer>, C<accessor>, C<predicate>, C<clearer>, C<method> or C<function>

=item B<params> - ARRAYREF - one HASHREF per parameter: C<name>, the variable or undef, C<index> for a positional parameter
or C<named> for the key of a named one, C<type>, a L<Type::Tiny> constraint or undef, C<optional> and C<invocant>

=item B<returns> - ARRAYREF - the L<Type::Tiny> constraints that the sub is declared to return

=item B<attribute>, B<documentation> - STRING - the attribute that an accessor or a constructor parameter belongs to, and its documentation

=item B<body> - CODEREF - the code that does the work, when the sub in the symbol table only wraps it

=back

=head1 PROVIDERS

=over 4

=item L<Pod::Coverage::More::Declared::TypeParams> - signatures of L<Type::Params>

=item L<Pod::Coverage::More::Declared::FunctionParameters> - L<Function::Parameters>

=item L<Pod::Coverage::More::Declared::Kavorka> - L<Kavorka>

=item L<Pod::Coverage::More::Declared::MOP> - L<Moose>, L<Mouse> and L<Moo>

=item L<Pod::Coverage::More::Declared::ObjectPad> - L<Object::Pad>

=item L<Pod::Coverage::More::Declared::ClassTiny> - L<Class::Tiny>

=back

=head1 METHODS

=head2 declarations_for(package, names)

The declarations of the subs of C<package> that C<names> lists and a provider declares. When two providers declare the same sub, the first in PROVIDERS wins, and a C<body> from a later one fills in a missing one.

=over 4

=item package - Str - the name of the package

=item names - ArrayRef[Str] - the names of the subs

=back

Returns HashRef, from the name of each declared sub to its declaration.

    my $declared = Pod::Coverage::More::Declared->declarations_for( 'Some::Class', [ 'new', 'size' ] );

=head2 invocant(name)

The declaration of the invocant of a method, parameter 0, for the providers.

=over 4

=item name - Maybe[Str] - the name of the invocant, or undef when it has none

=back

Returns HashRef, the declaration of the parameter.

    my $self = Pod::Coverage::More::Declared->invocant('$self');

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Pod-Coverage-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2026 George S. Baugh


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

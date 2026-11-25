# ABSTRACT: Declarations of the attributes of Class::Tiny classes
# PODNAME: Pod::Coverage::More::Declared::ClassTiny

package Pod::Coverage::More::Declared::ClassTiny 0.003;

use 5.036;
use warnings FATAL => q{all};

use Pod::Coverage::More::Declared;

use Types::Standard qw{InstanceOf};


# Whether L<Class::Tiny> built C<package>.
# @param   package  Str  the name of the package
# @returns Bool
# @example next if !Pod::Coverage::More::Declared::ClassTiny->applies_to('Some::Class');
sub applies_to {
    my ( $class, $package ) = @_;
    return ( $INC{'Class/Tiny.pm'} && $package->isa('Class::Tiny::Object') ) ? 1 : 0;
}

# The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.
# @param   package  Str            the name of the package
# @param   names    ArrayRef[Str]  the names of the subs
# @returns HashRef  from the name of each declared sub to its declaration
# @example my $declared = Pod::Coverage::More::Declared::ClassTiny->declarations( 'Some::Class', ['new'] );
sub declarations {
    my ( $class, $package, $names ) = @_;
    my %own        = map { $_ => 1 } @$names;
    my @attributes = Class::Tiny->get_all_attributes_for($package);
    my %declared;

    foreach my $attribute (@attributes) {
        next if !$own{$attribute};
        $declared{$attribute} = {
            via       => 'Class::Tiny',
            role      => 'accessor',
            attribute => $attribute,
            params    => [
                Pod::Coverage::More::Declared->invocant,
                { name => undef, index => 1, type => undef, optional => 1, invocant => 0 },
            ],
            returns => [],
        };
    }
    if ( $own{new} ) {
        $declared{new} = {
            via    => 'Class::Tiny',
            role   => 'constructor',
            params => [
                Pod::Coverage::More::Declared->invocant,
                map { { name => undef, named => $_, type => undef, optional => 1, invocant => 0 } } @attributes,
            ],
            returns => [ InstanceOf [$package] ],
        };
    }
    return \%declared;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Declared::ClassTiny - Declarations of the attributes of Class::Tiny classes

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Reads the attributes of a class that L<Class::Tiny> built.
Each attribute declares an accessor and an optional named parameter of the constructor C<new>.
Class::Tiny has no types and no required attributes, so these declarations have neither.

=head1 METHODS

=head2 applies_to(package)

Whether L<Class::Tiny> built C<package>.

=over 4

=item package - Str - the name of the package

=back

Returns Bool.

    next if !Pod::Coverage::More::Declared::ClassTiny->applies_to('Some::Class');

=head2 declarations(package, names)

The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.

=over 4

=item package - Str - the name of the package

=item names - ArrayRef[Str] - the names of the subs

=back

Returns HashRef, from the name of each declared sub to its declaration.

    my $declared = Pod::Coverage::More::Declared::ClassTiny->declarations( 'Some::Class', ['new'] );

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

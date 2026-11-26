# ABSTRACT: Declarations of the classes of Object::Pad
# PODNAME: Pod::Coverage::More::Declared::ObjectPad

package Pod::Coverage::More::Declared::ObjectPad 0.005;

use 5.036;
use warnings FATAL => q{all};

use Pod::Coverage::More::Declared;

use Types::Standard qw{InstanceOf};


# Whether L<Object::Pad> built C<package>.
# @param   package  Str  the name of the package
# @returns Bool
# @example next if !Pod::Coverage::More::Declared::ObjectPad->applies_to('Some::Class');
sub applies_to {
    my ( $class, $package ) = @_;
    return _metaclass($package) ? 1 : 0;
}

sub _metaclass {
    my ($package) = @_;
    return if !$INC{'Object/Pad.pm'};

    # The metaclass API warns that it is experimental, and fatal warnings would make that a death.
    no warnings q{experimental};
    return eval { Object::Pad::MOP::Class->for_class($package) };
}

# The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.
# @param   package  Str            the name of the package
# @param   names    ArrayRef[Str]  the names of the subs
# @returns HashRef  from the name of each declared sub to its declaration
# @example my $declared = Pod::Coverage::More::Declared::ObjectPad->declarations( 'Some::Class', ['new'] );
sub declarations {
    my ( $class, $package, $names ) = @_;
    my $meta = _metaclass($package);
    my %own  = map { $_ => 1 } @$names;
    my %declared;
    my @named;

    no warnings q{experimental};    # as in _metaclass
    foreach my $method ( $meta->direct_methods ) {
        next if !$own{ $method->name };
        $declared{ $method->name } = { via => 'Object::Pad', role => 'method', params => [ _self() ], returns => [] };
    }
    foreach my $field ( $meta->fields ) {
        my $param = $field->get_attribute_value('param');
        push @named, { name => $field->name, named => $param, type => undef, optional => undef, invocant => 0 }
          if defined $param;
        my $reader = $field->get_attribute_value('reader');
        $declared{$reader} = { via => 'Object::Pad', role => 'reader', attribute => $field->name, params => [ _self() ], returns => [] }
          if defined $reader && $own{$reader};
    }
    $declared{new} = {
        via     => 'Object::Pad',
        role    => 'constructor',
        params  => [ Pod::Coverage::More::Declared->invocant, @named ],
        returns => [ InstanceOf [$package] ],
    };
    return \%declared;
}

sub _self {
    return Pod::Coverage::More::Declared->invocant(q{$self});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Declared::ObjectPad - Declarations of the classes of Object::Pad

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Reads a class of L<Object::Pad> through its metaclass, C<Object::Pad::MOP::Class>.
Each method declares its implicit C<$self>, each field with C<:param> a named parameter of the constructor C<new>,
and each field with C<:reader> its reader.  Object::Pad has no types, so these declarations have none,
and its metaclass does not say whether a field has a default, so a named parameter of C<new> has an C<optional> of undef.

The metaclass API of Object::Pad is experimental.  The core class feature is expected to take a metaclass API like it,
and then this provider is the model for one for core classes.

=head1 METHODS

=head2 applies_to(package)

Whether L<Object::Pad> built C<package>.

=over 4

=item package - Str - the name of the package

=back

Returns Bool.

    next if !Pod::Coverage::More::Declared::ObjectPad->applies_to('Some::Class');

=head2 declarations(package, names)

The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.

=over 4

=item package - Str - the name of the package

=item names - ArrayRef[Str] - the names of the subs

=back

Returns HashRef, from the name of each declared sub to its declaration.

    my $declared = Pod::Coverage::More::Declared::ObjectPad->declarations( 'Some::Class', ['new'] );

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

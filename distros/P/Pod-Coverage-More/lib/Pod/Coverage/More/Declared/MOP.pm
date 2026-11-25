# ABSTRACT: Declarations of the attributes of Moose, Mouse and Moo classes
# PODNAME: Pod::Coverage::More::Declared::MOP

package Pod::Coverage::More::Declared::MOP 0.003;

use 5.036;
use warnings FATAL => q{all};

use Pod::Coverage::More::Declared;

use Types::Standard qw{Bool InstanceOf};
use Types::TypeTiny qw{to_TypeTiny};


# Whether L<Moose>, L<Mouse> or L<Moo> built C<package>.
# @param   package  Str  the name of the package
# @returns Bool
# @example next if !Pod::Coverage::More::Declared::MOP->applies_to('Some::Class');
sub applies_to {
    my ( $class, $package ) = @_;
    return _metaclass($package) ? 1 : 0;
}

# The metaclass of PACKAGE and the system that built it, or nothing.
sub _metaclass {
    my ($package) = @_;
    if ( $INC{'Moo.pm'} && $package->isa('Moo::Object') ) {
        require Moose;
        return ( $package->meta, 'Moo' );
    }
    if ( $INC{'Class/MOP.pm'} ) {
        my $meta = Class::MOP::class_of($package);
        return ( $meta, 'Moose' ) if $meta && $meta->can('get_all_attributes');
    }
    if ( $INC{'Mouse.pm'} ) {
        my $meta = Mouse::Util::class_of($package);
        return ( $meta, 'Mouse' ) if $meta && $meta->can('get_all_attributes');
    }
    return;
}

# The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.
# @param   package  Str            the name of the package
# @param   names    ArrayRef[Str]  the names of the subs
# @returns HashRef  from the name of each declared sub to its declaration
# @example my $declared = Pod::Coverage::More::Declared::MOP->declarations( 'Some::Class', ['new'] );
sub declarations {
    my ( $class, $package, $names ) = @_;
    my ( $meta, $via ) = _metaclass($package);
    my %own = map { $_ => 1 } @$names;
    my %declared;
    my @named;

    foreach my $attr ( sort { $a->name cmp $b->name } $meta->get_all_attributes ) {
        my $type     = $attr->has_type_constraint ? to_TypeTiny( $attr->type_constraint ) : undef;
        my %common   = ( via => $via, attribute => $attr->name, documentation => $attr->can('documentation') ? $attr->documentation : undef );
        my @returned = $type ? ($type) : ();

        push @named, { name => undef, named => $attr->init_arg, type => $type, optional => $attr->is_required ? 0 : 1, invocant => 0 }
          if defined $attr->init_arg;

        my $reader = $attr->get_read_method;
        my $writer = $attr->get_write_method;
        if ( defined $reader && defined $writer && $reader eq $writer ) {
            $declared{$reader} = { %common, role => 'accessor', params => [ _self(), _value( $type, 1 ) ], returns => [@returned] };
        }
        else {
            $declared{$reader} = { %common, role => 'reader', params => [ _self() ], returns => [@returned] } if defined $reader;
            $declared{$writer} = { %common, role => 'writer', params => [ _self(), _value( $type, 0 ) ], returns => [@returned] } if defined $writer;
        }
        $declared{ $attr->predicate } = { %common, role => 'predicate', params => [ _self() ], returns => [Bool] } if $attr->predicate;
        $declared{ $attr->clearer }   = { %common, role => 'clearer',   params => [ _self() ], returns => [] }     if $attr->clearer;
    }

    $declared{new} = {
        via     => $via,
        role    => 'constructor',
        params  => [ Pod::Coverage::More::Declared->invocant, @named ],
        returns => [ InstanceOf [$package] ],
    };

    foreach my $name (@$names) {
        my $method = $meta->get_method($name) or next;
        next if !$method->isa('Class::MOP::Method::Wrapped');
        $declared{$name} //= { via => $via, role => 'method', params => [], returns => [] };
        $declared{$name}{body} = $method->get_original_method->body;
    }

    delete @declared{ grep { !$own{$_} } keys %declared };
    return \%declared;
}

sub _self {
    return Pod::Coverage::More::Declared->invocant;
}

sub _value {
    my ( $type, $optional ) = @_;
    return { name => undef, index => 1, type => $type, optional => $optional, invocant => 0 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Declared::MOP - Declarations of the attributes of Moose, Mouse and Moo classes

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Reads the metaclass of a class that L<Moose>, L<Mouse> or L<Moo> built.
A Moo class is read through the Moose metaclass that Moo inflates for it, so reading one loads Moose.

Each attribute declares its accessors, its predicate and its clearer, with the attribute's type constraint,
and a named parameter of the constructor C<new>, unless its C<init_arg> is undef.
A method that a method modifier wraps declares the original method as its C<body>.

=head1 METHODS

=head2 applies_to(package)

Whether L<Moose>, L<Mouse> or L<Moo> built C<package>.

=over 4

=item package - Str - the name of the package

=back

Returns Bool.

    next if !Pod::Coverage::More::Declared::MOP->applies_to('Some::Class');

=head2 declarations(package, names)

The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.

=over 4

=item package - Str - the name of the package

=item names - ArrayRef[Str] - the names of the subs

=back

Returns HashRef, from the name of each declared sub to its declaration.

    my $declared = Pod::Coverage::More::Declared::MOP->declarations( 'Some::Class', ['new'] );

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

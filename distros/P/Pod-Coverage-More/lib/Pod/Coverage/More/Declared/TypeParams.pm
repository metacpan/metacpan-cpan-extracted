# ABSTRACT: Declarations of the signatures of Type::Params
# PODNAME: Pod::Coverage::More::Declared::TypeParams

package Pod::Coverage::More::Declared::TypeParams 0.003;

use 5.036;
use warnings FATAL => q{all};

use Pod::Coverage::More::Declared;

use B ();
use Package::Stash;
use Scalar::Util qw{blessed};


# Whether L<Type::Params> is loaded, so that it can have declared subs of C<package>.
# @param   package  Str  the name of the package
# @returns Bool
# @example next if !Pod::Coverage::More::Declared::TypeParams->applies_to('Some::Class');
sub applies_to {
    return $INC{'Type/Params.pm'} ? 1 : 0;
}

# The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.
# @param   package  Str            the name of the package
# @param   names    ArrayRef[Str]  the names of the subs
# @returns HashRef  from the name of each declared sub to its declaration
# @example my $declared = Pod::Coverage::More::Declared::TypeParams->declarations( 'Some::Class', ['new'] );
sub declarations {
    my ( $class, $package, $names ) = @_;
    my $stash = Package::Stash->new($package);
    my %declared;
    foreach my $name (@$names) {
        my $signature = _signature_of( $stash->get_symbol("&$name") ) or next;
        my @params;
        my $index = 0;
        push @params, Pod::Coverage::More::Declared->invocant if $signature->method;
        $index++ if $signature->method;
        foreach my $param ( @{ $signature->parameters } ) {
            my %where = $signature->is_named ? ( named => $param->name ) : ( index => $index++ );
            push @params, { name => undef, type => $param->type, optional => $param->optional ? 1 : 0, invocant => 0, %where };
        }
        $declared{$name} = {
            via     => 'Type::Params',
            role    => $signature->method ? 'method' : 'function',
            params  => \@params,
            returns => [ $signature->has_returns_scalar ? $signature->returns_scalar : () ],
            body    => $signature->next,
        };
    }
    return \%declared;
}

# The signature object that the wrapper CODE closes over, or nothing when CODE is no wrapper of Type::Params.
sub _signature_of {
    my ($code) = @_;
    my $cv = B::svref_2object($code);
    return if $cv->XSUB || ( $cv->CvFLAGS & B::CVf_CONST );
    my $padlist = $cv->PADLIST;
    my @names   = $padlist->ARRAYelt(0)->ARRAY;
    my @values  = $padlist->ARRAYelt(1)->ARRAY;
    foreach my $index ( 1 .. $#names ) {
        next if B::class( $names[$index] ) eq 'SPECIAL' || ( $names[$index]->PVX // q{} ) ne q{$sig};
        my $value = ${ $values[$index]->object_2svref };
        return $value if blessed($value) && $value->isa('Type::Params::Signature');
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Declared::TypeParams - Declarations of the signatures of Type::Params

=head1 VERSION

version 0.003

=head1 DESCRIPTION

C<signature_for> of L<Type::Params> replaces a sub with a wrapper that checks the arguments and then calls the sub.
The wrapper keeps the signature only as a variable that it closes over.
This provider finds that variable, and reads the parameters, their types, the invocant and the declared return type from it.
It also declares the wrapped sub as the C<body>, so that the analysis reads the code that does the work and not the wrapper.

The first call of the sub replaces the wrapper with compiled code that does not keep the signature,
so a sub that was already called declares nothing.

=head1 METHODS

=head2 applies_to(package)

Whether L<Type::Params> is loaded, so that it can have declared subs of C<package>.

=over 4

=item package - Str - the name of the package

=back

Returns Bool.

    next if !Pod::Coverage::More::Declared::TypeParams->applies_to('Some::Class');

=head2 declarations(package, names)

The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.

=over 4

=item package - Str - the name of the package

=item names - ArrayRef[Str] - the names of the subs

=back

Returns HashRef, from the name of each declared sub to its declaration.

    my $declared = Pod::Coverage::More::Declared::TypeParams->declarations( 'Some::Class', ['new'] );

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

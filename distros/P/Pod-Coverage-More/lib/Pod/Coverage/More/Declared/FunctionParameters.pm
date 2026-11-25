# ABSTRACT: Declarations of the signatures of Function::Parameters
# PODNAME: Pod::Coverage::More::Declared::FunctionParameters

package Pod::Coverage::More::Declared::FunctionParameters 0.003;

use 5.036;
use warnings FATAL => q{all};

use Package::Stash;


# Whether L<Function::Parameters> is loaded, so that it can have declared subs of C<package>.
# @param   package  Str  the name of the package
# @returns Bool
# @example next if !Pod::Coverage::More::Declared::FunctionParameters->applies_to('Some::Class');
sub applies_to {
    return $INC{'Function/Parameters.pm'} ? 1 : 0;
}

# The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.
# @param   package  Str            the name of the package
# @param   names    ArrayRef[Str]  the names of the subs
# @returns HashRef  from the name of each declared sub to its declaration
# @example my $declared = Pod::Coverage::More::Declared::FunctionParameters->declarations( 'Some::Class', ['new'] );
sub declarations {
    my ( $class, $package, $names ) = @_;
    my $stash = Package::Stash->new($package);
    my %declared;
    foreach my $name (@$names) {
        my $info  = Function::Parameters::info( $stash->get_symbol("&$name") ) or next;
        my $index = 0;
        my @params;
        my @positional = ( [ [ $info->invocants ], { invocant => 1 } ], [ [ $info->positional_required ], {} ], [ [ $info->positional_optional ], { optional => 1 } ] );
        foreach my $group (@positional) {
            my ( $list, $extra ) = @$group;
            foreach my $param (@$list) {
                push @params, _param( $param, index => $index++, %$extra );
            }
        }
        my @named = ( [ [ $info->named_required ], {} ], [ [ $info->named_optional ], { optional => 1 } ] );
        foreach my $group (@named) {
            my ( $list, $extra ) = @$group;
            foreach my $param (@$list) {
                push @params, _param( $param, named => _key($param), %$extra );
            }
        }
        push @params, _param( $info->slurpy, index => $index, optional => 1 ) if $info->slurpy;
        $declared{$name} = {
            via     => 'Function::Parameters',
            role    => $info->keyword eq 'method' ? 'method' : 'function',
            params  => \@params,
            returns => [],
        };
    }
    return \%declared;
}

sub _param {
    my ( $param, %where ) = @_;
    return { name => $param->name, type => $param->type, optional => 0, invocant => 0, %where };
}

# The key of a named parameter is its name without the sigil.
sub _key {
    my ($param) = @_;
    return substr( $param->name, 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Declared::FunctionParameters - Declarations of the signatures of Function::Parameters

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Reads the signature of each sub that a keyword of L<Function::Parameters> made, through C<Function::Parameters::info>:
the invocants, the positional and the named parameters, which are optional, and the type of each.

=head1 METHODS

=head2 applies_to(package)

Whether L<Function::Parameters> is loaded, so that it can have declared subs of C<package>.

=over 4

=item package - Str - the name of the package

=back

Returns Bool.

    next if !Pod::Coverage::More::Declared::FunctionParameters->applies_to('Some::Class');

=head2 declarations(package, names)

The declarations of the subs of C<package> that C<names> lists, as L<Pod::Coverage::More::Declared> describes them.

=over 4

=item package - Str - the name of the package

=item names - ArrayRef[Str] - the names of the subs

=back

Returns HashRef, from the name of each declared sub to its declaration.

    my $declared = Pod::Coverage::More::Declared::FunctionParameters->declarations( 'Some::Class', ['new'] );

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

# ABSTRACT: The Type::Tiny constraints that the evidence of an analysis amounts to
# PODNAME: Pod::Coverage::More::Types

package Pod::Coverage::More::Types 0.003;

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Exporter qw{import};
use Type::Registry;
use Type::Tiny::Intersection;
use Type::Tiny::Union;
use Types::Standard qw{Any ArrayRef Bool CodeRef GlobRef HasMethods HashRef InstanceOf Int Maybe Num Object Ref ScalarRef Str Undef};

our @EXPORT_OK = qw{type_of_value type_of_usage type_named};


sub type_of_value {
    my ($evidence) = @_;
    my $type = $evidence->{type};

    if ( $type eq 'number' ) {
        my $value = $evidence->{value};
        return Maybe [Int] if $evidence->{integer} && $evidence->{maybe_undef};
        return Int         if $evidence->{integer};
        return ( defined $value && $value =~ m/\A-?\d+\z/ ) ? Int : Num;
    }
    return Str  if $type eq 'string';
    return Bool if $type eq 'boolean' || $type eq 'context';

    # An empty return gives undef to a caller that wants one value.
    return Undef if $type eq 'undef' || $type eq 'empty';

    return HashRef  if $type eq 'hashref';
    return ArrayRef if $type eq 'arrayref';
    return CodeRef  if $type eq 'coderef';
    return Ref      if $type eq 'ref';
    if ( $type eq 'object' ) {
        my @classes = @{ $evidence->{classes} || [] };
        return InstanceOf [ $classes[0] ] if @classes == 1;
        if ( @classes > 1 ) {
            my @instances;
            foreach my $class (@classes) {
                push @instances, InstanceOf [$class];
            }
            return Type::Tiny::Union->new( type_constraints => \@instances );
        }
        return defined $evidence->{class} ? InstanceOf [ $evidence->{class} ] : Object;
    }
    return;
}


sub type_of_usage {
    my ($usage) = @_;
    my @alternatives;
    push @alternatives, HashRef  if $usage->{hashref};
    push @alternatives, ArrayRef if $usage->{arrayref};
    push @alternatives, CodeRef  if $usage->{coderef};

    # Perl makes a string of a number, so a variable used as both is a string.
    if    ( $usage->{string} )  { push @alternatives, Str }
    elsif ( $usage->{numeric} ) { push @alternatives, Num }

    my $type;
    $type = $alternatives[0]                                             if @alternatives == 1;
    $type = Type::Tiny::Union->new( type_constraints => \@alternatives ) if @alternatives > 1;

    my @methods = @{ $usage->{methods} || [] };
    return $type if !@methods;
    my $duck = HasMethods [@methods];
    return $duck if !$type;
    return Type::Tiny::Intersection->new( type_constraints => [ $type, $duck ] );
}

# The type words of the POD that Pod::Coverage::More has always read, in lower case.
our %POD_WORDS = (
    scalar      => Any,
    mixed       => Any,
    string      => Str,
    integer     => Int,
    float       => Num,
    boolean     => Bool,
    object      => Object,
    scalarref   => ScalarRef,
    arrayref    => ArrayRef,
    hashref     => HashRef,
    coderef     => CodeRef,
    typeglobref => GlobRef,
    array       => ArrayRef,
    hash        => HashRef,
);


sub type_named {
    my ($name) = @_;
    return if !defined $name;
    my $word = $POD_WORDS{ lc $name };
    return $word if $word;

    # No type expression has a %, and the error of a failed lookup takes NAME as a printf format, which warns.
    return if index( $name, q{%} ) >= 0;

    my $registry = Type::Registry->for_class(__PACKAGE__);
    $registry->add_types('Types::Standard') if !$registry->simple_lookup('Str');
    my $type = eval { $registry->lookup($name) };
    return $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Types - The Type::Tiny constraints that the evidence of an analysis amounts to

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Pod::Coverage::More::Types qw{type_of_value type_of_usage type_named};

    my $returned = type_of_value( { type => 'object', class => 'Some::Class' } );    # InstanceOf["Some::Class"]
    my $used     = type_of_usage( { hashref => 1, methods => ['render'] } );        # HashRef&HasMethods["render"]
    my $named    = type_named('ArrayRef[Int]');

=head1 DESCRIPTION

L<Pod::Coverage::More::Analyzer> records evidence about values: what a sub returns, and how it uses each variable.
This module states that evidence as L<Type::Tiny> constraints, so that the types that the code shows,
the types that a class builder or a signature declares, and the types that the POD names can be compared as types.

Each function returns undef when the evidence says nothing about the type.

=head1 FUNCTIONS

=head2 type_of_value(EVIDENCE)

Returns the constraint that a value satisfies, from one HASHREF of evidence that C<classify> of L<Pod::Coverage::More::Analyzer> returns.
A number whose evidence has a true C<integer>, such as the count of an array, is an C<Int>.
With a true C<maybe_undef> as well, as the length of a string, it is a C<Maybe[Int]>.
An object whose evidence names C<classes>, as the numbers of the scope of C<use bignum>, is an instance of one of them.

=over 4

=item EVIDENCE - HashRef - the evidence of one value

=back

Returns a Type::Tiny object, or undef when the evidence says nothing of the type.

    my $type = type_of_value( { type => 'number', integer => 1 } );

=head2 type_of_usage(USAGE)

Returns the constraint that a variable must satisfy for the uses that the HASHREF USAGE records,
as C<analyze_sub> of L<Pod::Coverage::More::Analyzer> reports them.

Each kind of reference, and use as a number or as a string, is one alternative,
because different branches of a sub can use one variable in different ways.
The methods called on the variable apply to all of them.

=over 4

=item USAGE - HashRef - the uses of one variable

=back

Returns a Type::Tiny object, or undef when the uses say nothing of the type.

    my $type = type_of_usage( { hashref => 1, methods => ['name'] } );

=head2 type_named(NAME)

Returns the constraint that NAME names.  NAME is either a type word of the POD that L<Pod::Coverage::More> reads,
in any case, such as C<HASHREF> or C<integer>, or a type expression of L<Types::Standard>, such as C<ArrayRef[Int]>.
A word for a container, C<ARRAY> or C<HASH>, names a reference to one.

=over 4

=item NAME - Str - a type word or a type expression

=back

Returns a Type::Tiny object, or undef when NAME names no type.

    my $type = type_named('ArrayRef[Int]');

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=item *

L<Type::Tiny>

=item *

L<Types::Standard>

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

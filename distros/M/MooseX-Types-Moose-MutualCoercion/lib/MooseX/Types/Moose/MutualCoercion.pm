package MooseX::Types::Moose::MutualCoercion;


# ****************************************************************
# perl dependency
# ****************************************************************

use 5.008_001;


# ****************************************************************
# pragma(ta)
# ****************************************************************

# Moose turns strict/warnings pragmata on,
# however, kwalitee scorer cannot detect such mechanism.
# (Perl::Critic can it, with equivalent_modules parameter)
use strict;
use warnings;


# ****************************************************************
# MOP dependency(-ies)
# ****************************************************************

use MooseX::Types -declare => [qw(
    NumToInt
    ScalarRefToStr      ArrayRefToLines
    StrToClassName
    StrToScalarRef
    StrToArrayRef       LinesToArrayRef
    HashRefToArrayRef   HashKeysToArrayRef  HashValuesToArrayRef
    OddArrayRef         EvenArrayRef
    ArrayRefToHashRef   ArrayRefToHashKeys
    ArrayRefToRegexpRef
)];
use MooseX::Types::Common::String qw(
    NonEmptyStr
);
use MooseX::Types::Moose qw(
    Str
        Num
            Int
        ClassName
        RoleName
    Ref
        ScalarRef
        ArrayRef
        HashRef
        RegexpRef
);


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use Class::Load qw(
    load_class
    is_class_loaded
);


# ****************************************************************
# public class variable(s)
# ****************************************************************

our $VERSION = "0.04";


# ****************************************************************
# namespace cleaner
# ****************************************************************

use namespace::clean;


# ****************************************************************
# subtype(s) and coercion(s)
# ****************************************************************

# ================================================================
# to Int
# ================================================================

subtype NumToInt,
    as Int;

coerce NumToInt,
    from Num,
        via {
            int $_;
        };

# ================================================================
# to Str
# ================================================================

foreach my $type (
    ScalarRefToStr, ArrayRefToLines,
) {
    subtype $type,
        as Str;
}

coerce ScalarRefToStr,
    from ScalarRef[Str],
        via {
            $$_;
        };

coerce ArrayRefToLines,
    from ArrayRef[Str],
        via {
            ( join $/, @$_ ) . $/;
        };

# ================================================================
# to ClassName
# ================================================================

subtype StrToClassName,
    as ClassName;

coerce StrToClassName,
    from NonEmptyStr,
        via {
            _ensure_class_loaded($_);
        };

# ================================================================
# to ScalarRef
# ================================================================

subtype StrToScalarRef,
    as ScalarRef[Str];

coerce StrToScalarRef,
    from Str,
        via {
            \do{ $_ };
        };

# ================================================================
# to ArrayRef
# ================================================================

foreach my $type (
    StrToArrayRef, LinesToArrayRef,
    HashRefToArrayRef, HashKeysToArrayRef, HashValuesToArrayRef,
) {
    subtype $type,
        as ArrayRef;
}

coerce StrToArrayRef,
    from Str,
        via {
            [ $_ ];
        };

coerce LinesToArrayRef,
    from Str,
        via {
            ( my $new_line = $/ ) =~ s{(.)}{[$1]}xmsg;
            [ split m{ (?<= $new_line ) }xms, $_ ];
        };

coerce HashRefToArrayRef,
    from HashRef,
        via {
            my $hashref = $_;
            [
                map {
                    $_, $hashref->{$_};
                } sort keys %$hashref
            ];
        };

coerce HashKeysToArrayRef,
    from HashRef,
        via {
            [ sort keys %$_ ];
        };

coerce HashValuesToArrayRef,
    from HashRef,
        via {
            my $hashref = $_;
            [
                map {
                    $hashref->{$_};
                } sort keys %$hashref
            ];
        };

subtype OddArrayRef,
    as ArrayRef,
        where {
            scalar @$_ % 2;
        };

subtype EvenArrayRef,
    as ArrayRef,
        where {
            ! scalar @$_ % 2;
        };

foreach my $type (OddArrayRef, EvenArrayRef) {
    coerce $type,
        from ArrayRef,
            via {
                push @$_, undef;
                $_;
            };
}

# ================================================================
# to HashRef
# ================================================================

foreach my $type (
    ArrayRefToHashRef, ArrayRefToHashKeys,
) {
    subtype $type,
        as HashRef;
}

coerce ArrayRefToHashRef,
    from EvenArrayRef,
        via {
            my %hash = @$_; # Note: "{ @$_ }" is invalid (need "return").
            \%hash;
        };

coerce ArrayRefToHashKeys,
    from ArrayRef,
        via {
            my %hash;
            @hash{@$_} = ();
            \%hash;
        };

# ================================================================
# to RegexpRef
# ================================================================

subtype ArrayRefToRegexpRef,
    as RegexpRef;

coerce ArrayRefToRegexpRef,
    from ArrayRef,
        via {
            eval {
                require Regexp::Assemble;
            };
            if ($@) {
                my $pattern_string = join '|', @$_;
                qr{$pattern_string};
            }
            else {
                my $regexp = Regexp::Assemble->new;
                foreach my $pattern (@$_) {
                    $regexp->add($pattern);
                }
                $regexp->re;
            }
        };


# ****************************************************************
# subroutine(s)
# ****************************************************************

sub _ensure_class_loaded {
    my $class = shift;

    load_class($class)
        unless is_class_loaded($class);

    return $class;
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=pod

=head1 NAME

MooseX::Types::Moose::MutualCoercion - Mutual coercions for common type constraints of Moose

=head1 VERSION

This document describes
L<MooseX::Types::Moose::MutualCoercion|MooseX::Types::Moose::MutualCoercion>
version C<0.04>.

=head1 SYNOPSIS

    {
        package Foo;
        use Moose;
        use MooseX::Types::Moose::MutualCoercion
            qw(StrToArrayRef ArrayRefToHashKeys);
        has 'thingies' =>
            (is => 'rw', isa => StrToArrayRef, coerce => 1);
        has 'lookup_table' =>
            (is => 'rw', isa => ArrayRefToHashKeys, coerce => 1);
        1;
    }

    my $foo = Foo->new( thingies => 'bar' );
    print $foo->thingies->[0];                              # 'bar'

    $foo->lookup_table( [qw(baz qux)] );
    print 'eureka!'                                         # 'eureka!'
        if grep {
            exists $foo->lookup_table->{$_};
        } qw(foo bar baz);

=head1 TRANSLATIONS

Much of the
L<MooseX::Types::Moose::MutualCoercion|MooseX::Types::Moose::MutualCoercion>
documentation has been translated into other language(s).

=over 4

=item en: English

L<MooseX::Types::Moose::MutualCoercion|MooseX::Types::Moose::MutualCoercion>
(This document)

=item ja: Japanese

L<MooseX::Types::Moose::MutualCoercion::JA|MooseX::Types::Moose::MutualCoercion::JA>

=back

=head1 DESCRIPTION

This module packages several
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints> with coercions,
designed to mutually coerce with the built-in and common types known to
L<Moose|Moose>.

=head1 CONSTRAINTS AND COERCIONS

B<NOTE>: These constraints are not exported by default
but you can request them in an import list like this:

    use MooseX::Types::Moose::MutualCoercion qw(NumToInt ScalarRefToStr);

=head2 To C<< Int >>

=over 4

=item C<< NumToInt >>

A subtype of C<< Int >>.
If you turned C<< coerce >> on, C<< Num >> will become integer.
For example, C<< 3.14 >> will be converted into C<< 3 >>.

=back

=head2 To C<< Str >>

=over 4

=item C<< ScalarRefToStr >>

A subtype of C<< Str >>.
If you turned C<< coerce >> on,
C<< ScalarRef[Str] >> will become dereferenced string.
For example, C<< \do{'foo'} >> will be converted into C<< foo >>.

=item C<< ArrayRefToLines >>

A subtype of C<< Str >>.
If you turned C<< coerce >> on,
all elements of C<< ArrayRef[Str] >> will be joined by C<< $/ >>.
For example, C<< [qw(foo bar baz)] >>
will be converted into C<< foo\nbar\nbaz\n >>.

B<NOTE>: Also adds C<< $/ >> to the last element.

=back

=head2 To C<< ClassName >>

=over 4

=item C<< StrToClassName >>

B<CAVEAT>: This type constraint and coercion is B<DEPRECATED>.
Please use L<MooseX::Types::LoadableClass's LodableClass
|MooseX::Types::LoadableClass/LodableClass> instead of it.
In addition, L<MooseX::Types::LoadableClass|MooseX::Types::LoadableClass>
also has L<LodableRole|MooseX::Types::LoadableClass/LoadableRole>.

A subtype of C<< ClassName >>.
If you turned C<< coerce >> on, C<< NonEmptyStr >>, provided by
L<MooseX::Types::Common::String|MooseX::Types::Common::String>,
will be treated as a class name.
When it is not already loaded, it will be loaded by
L<< Class::Load::load_class()|Class::Load >>.

=back

=head2 To C<< ScalarRef >>

=over 4

=item C<< StrToScalarRef >>

A subtype of C<< ScalarRef[Str] >>.
If you turned C<< coerce >> on, C<< Str >> will be referenced.
For example, C<< foo >> will be converted into C<< \do{'foo'} >>.

=back

=head2 To C<< ArrayRef >>

=over 4

=item C<< StrToArrayRef >>

A subtype of C<< ArrayRef >>.
If you turned C<< coerce >> on,
C<< Str >> will be assigned for the first element of an array reference.
For example, C<< foo >> will be converted into C<< [qw(foo)] >>.

=item C<< LinesToArrayRef >>

A subtype of C<< ArrayRef >>.
If you turned C<< coerce >> on, C<< Str >> will be split by C<< $/ >>
and will be assigned for each element of an array reference.
For example, C<< foo\nbar\nbaz\n >>
will be converted into C<< ["foo\n", "bar\n", "baz\n"] >>.

B<NOTE>: C<< $/ >> was not removed.

=item C<< HashRefToArrayRef >>

A subtype of C<< ArrayRef >>.
If you turned C<< coerce >> on,
C<< HashRef >> will be flattened as an array reference.
For example, C<< {foo => 0, bar => 1} >>
will be converted into C<< [qw(bar 1 foo 0)] >>.

B<NOTE>: Order of keys/values is the same as lexically sorted keys.

=item C<< HashKeysToArrayRef >>

A subtype of C<< ArrayRef >>.
If you turned C<< coerce >> on,
list of lexically sorted keys of C<< HashRef >> will become an array reference.
For example, C<< {foo => 0, bar => 1} >>
will be converted into C<< [qw(bar foo)] >>.

=item C<< HashValuesToArrayRef >>

A subtype of C<< ArrayRef >>.
If you turned C<< coerce >> on,
list of values of C<< HashRef >> will become an array reference.
For example, C<< {foo => 0, bar => 1} >>
will be converted into C<< [qw(1 0)] >>.

B<NOTE>: Order of values is the same as lexically sorted keys.

=item C<< OddArrayRef >>

A subtype of C<< ArrayRef >>, that must have odd elements.
If you turned C<< coerce >> on, C<< ArrayRef >>, that has even elements,
will be pushed C<< undef >> as the last element.
For example, C<< [qw(foo bar)] >>
will be converted into C<< [qw(foo bar), undef] >>.

=item C<< EvenArrayRef >>

A subtype of C<< ArrayRef >>, that must have even elements.
If you turned C<< coerce >> on, C<< ArrayRef >>, that has odd elements,
will be pushed C<< undef >> as the last element.
For example, C<< [qw(foo)] >>
will be converted into C<< [qw(foo), undef] >>.

=back

=head2 To C<< HashRef >>

=over 4

=item C<< ArrayRefToHashRef >>

A subtype of C<< HashRef >>.
If you turned C<< coerce >> on,
all elements of C<< EvenArrayRef >> will be substituted for a hash reference.
For example, C<< [qw(foo 0 bar 1)] >>
will be converted into C<< {foo => 0, bar => 1} >>.

=item C<< ArrayRefToHashKeys >>

A subtype of C<< HashRef >>.
If you turned C<< coerce >> on,
all elements of C<< ArrayRef >> will be substituted
for keys of a hash reference.
For example, C<< [qw(foo bar baz)] >>
will be converted into C<< {foo => undef, bar => undef, baz => undef} >>.

=back

=head2 To C<< RegexpRef >>

=over 4

=item C<< ArrayRefToRegexpRef >>

A subtype of C<< RegexpRef >>.
If you turned C<< coerce >> on, all elements of C<< ArrayRef >>
will be joined with C<< | >> (the meta character for alternation)
and will become a regular expression reference.
For example, C<< [qw(foo bar baz)] >>
will be converted into C<< qr{foo|bar|baz} >>.

B<NOTE>: If L<Regexp::Assemble|Regexp::Assemble> can be loaded dynamically,
namely at runtime, a regular expression reference
will be built with this module.
For example, C<< [qw(foo bar baz)] >>
will be converted into C<< qr{(?:ba[rz]|foo)} >>.

=back

=head1 SEE ALSO

=over 4

=item *

L<Moose::Manual::Types|Moose::Manual::Types>

=item *

L<MooseX::Types|MooseX::Types>

=item *

L<MooseX::Types::Moose|MooseX::Types::Moose>

=item *

L<MooseX::Types::LoadableClass|MooseX::Types::LoadableClass>

=item *

L<MooseX::Types::Common|MooseX::Types::Common>

=item *

About special variable C<< $/ >> (C<< $RS >>, C<< $INPUT_RECORD_SEPARATOR >>).

L<perlvar|perlvar>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<< <bug-moosex-types-moose-mutualcoercion at rt.cpan.org> >>,
or through the web interface
at L<http://rt.cpan.org/Public/Bug/Report.html?Queue=MooseX-Types-Moose-MutualCoercion>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible,
please add as small a sample as you can make of the code
that produces the bug.
And of course, suggestions and patches are welcome.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    % perldoc MooseX::Types::Moose::MutualCoercion

You can also find the Japanese edition of documentation for this module
with the C<perldocjp> command from L<Pod::PerldocJp|Pod::PerldocJp>.

    % perldocjp MooseX::Types::Moose::MutualCoercion::JA

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Moose-MutualCoercion>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-Moose-MutualCoercion>

=item Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-Moose-MutualCoercion>

=item CPAN Ratings

L<http://cpanratings.perl.org/dist/MooseX-Types-Moose-MutualCoercion>

=back

=head1 VERSION CONTROL

This module is maintained using I<Git>.
You can get the latest version from
L<git://github.com/gardejo/p5-moosex-types-moose-mutualcoercion.git>.

=head1 TO DO

=over 4

=item *

More tests

=back

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut

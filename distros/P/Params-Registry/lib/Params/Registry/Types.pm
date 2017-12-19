package Params::Registry::Types;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Tie::IxHash;

use Set::Scalar;
use Set::Infinite;

use DateTime;
use DateTime::Span;
use DateTime::SpanSet;

use Moose::Util::TypeConstraints qw(class_type);

our @TYPES;

BEGIN {
    @TYPES = qw(Type Template TemplateSet Dependency Format XSDdate
                XSDgYearMonth XSDgYear XSDgMonth XSDgDay DateSpan
                DateSpanSet DateRange Currency Decimal3 XSDBool
                NumberRange Set IntSet LCToken UCToken TokenSet
                PositiveInt NegativeInt NonPositiveInt
                NonNegativeInt);
}

use MooseX::Types::Moose qw(ClassName RoleName ArrayRef HashRef CodeRef
                            Undef Maybe Bool Num Int Str);

use MooseX::Types -declare => [@TYPES];

# for Set::Infinite
use constant INF     => Set::Infinite->inf;
use constant NEG_INF => Set::Infinite->minus_inf;

=head1 NAME

Params::Registry::Types - Types for Params::Registry

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Params::Registry::Types qw(:all);

=head1 TYPES

=head2 Type

This is the type for types. XZibit-approved.

=cut

class_type 'MooseX::Types::UndefinedType';
class_type 'MooseX::Types::TypeDecorator';
class_type 'Moose::Meta::TypeConstraint';

subtype Type, as join('|', qw( MooseX::Types::UndefinedType
                               MooseX::Types::TypeDecorator
                               Moose::Meta::TypeConstraint
                               ClassName RoleName Str ));

# yo dawg i herd u liek types so we put a type in yo type so u can
# type whiel u type
coerce Type, from Str, via {
    my $x = shift;
    return Moose::Util::TypeConstraints::find_or_parse_type_constraint($x)
        || class_type($x);
};
# ...that meme will never get old.

=head2 Dependency

A dependency is just a set of keys that both maintains its order and
can be conveniently queried for membership. It is implemented via
L<Tie::IxHash>.

=cut

subtype Dependency, as HashRef[Bool],
    where { my $tied = tied %$_; $tied && $tied->isa('Tie::IxHash') };

sub ixhash_ref {
    tie my %ix, 'Tie::IxHash', @_;
    \%ix;
}

coerce Dependency, from Str, via { ixhash_ref($_[0] => 1) };

coerce Dependency, from ArrayRef, via { ixhash_ref(map { $_ => 1 } @{$_[0]}) };

# actually we don't want this to be exposed because we're usin g
# meaning

# coerce Dependency, from HashRef,
#    via { tie my %ix, 'Tie::IxHash', %{$_[0]}; \%ix };


=head2 Template

This might not be used currently, i don't remember

=cut

class_type Template, { class => 'Params::Registry::Template' };
#coerce Template, from HashRef, via { Params::Registry::Template->new(shift) };

#subtype TemplateSet, as HashRef[HashRef];
#coerce TemplateSet,

=head2 Format

=cut

subtype Format, as CodeRef;
coerce Format, from Str, via { my $x = shift; sub { sprintf $x, shift } };

=head2 PositiveInt

=cut

subtype PositiveInt, as Int, where { $_ > 0 };

=head2 NegativeInt

=cut

subtype NegativeInt, as Int, where { $_ < 0 };

=head2 NonPostiveInt

=cut

subtype NonPositiveInt, as Int, where { $_ <= 0 };

=head2 NonNegativeInt

=cut

subtype NonNegativeInt, as Int, where { $_ >= 0 };

=head2 XSDdate

=cut

class_type XSDdate,     { class => 'DateTime' };

sub _make_date {
    if (@_ == 2) {
        DateTime->last_day_of_month(year => $_[0], month => $_[1]);
    }
    else {
        DateTime->new(year => $_[0], month => $_[1], day => $_[2]);
    }
}

coerce XSDdate, from Str, via { _make_date(split /-+/, $_[0]) };

=head2 XSDgYearMonth

=cut

subtype XSDgYearMonth, as XSDdate;

coerce XSDgYearMonth, from Str, via { _make_date(split(/-/, $_[0], 2)) };

=head2 XSDgYear

=cut

subtype XSDgYear, as Int;

=head2 XSDgMonth

=cut

subtype XSDgMonth, as Int, where { $_[0] > 0 && $_[0] < 13 };

=head2 XSDgDay

=cut

subtype XSDgDay,   as Int, where { $_[0] > 0 && $_[0] < 32 };

=head2 XSDBool

=cut

subtype XSDBool, as Bool;
coerce XSDBool, from Undef, via { 0 };
coerce XSDBool, from Str, via { return ($_[0] =~ /(1|true|on|yes)/i) ? 1 : 0 };

=head2 Currency

=cut

subtype Currency, as Num;
coerce Currency, from Num, via { my $x = int($_[0] * 100); return $x/100 };

=head2 Decimal3

=cut

subtype Decimal3, as Num;
coerce Decimal3, from Num, via { my $x = int($_[0] * 1000); return $x/1000 };

=head2 UCToken

=cut

subtype UCToken, as Str;
coerce UCToken, from Str, via { uc shift };

=head2 LCToken

=cut

subtype LCToken, as Str;
coerce LCToken, from Str, via { lc shift };

=head2 Set

=cut

class_type Set,         { class => 'Set::Scalar' };

=head2 IntSet

=cut

subtype IntSet, as Set;
coerce IntSet, from ArrayRef[Str],
    via { Set::Scalar->new(map { int $_ } @{$_[0]}) };

=head2 TokenSet

=cut

subtype TokenSet, as Set;
coerce TokenSet, from ArrayRef[Str], via { Set::Scalar->new(@{$_[0]}) };

=head2 NumberRange

=cut

class_type NumberRange, { class => 'Set::Infinite' };

coerce NumberRange, from ArrayRef[Maybe[Num]], via {
    my ($s, $e) = @{$_[0]};
    #warn "hi i'm here";
    #warn defined $e;
    #require Data::Dumper;
    #warn Data::Dumper::Dumper
    my ($ds, $de) = (defined $s, defined $e);
    if (!$ds and !$de) {
        ($s, $e) = (NEG_INF, INF);
    }
    elsif (!$ds) {
        $s = NEG_INF;
    }
    elsif (!$de) {
        $e = INF;
    }
    else {
        ($s, $e) = sort { $a <=> $b } map { $_ + 0 } ($s, $e);
    }

    Set::Infinite->new($s, $e);
};

=head2 DateRange

=cut

class_type DateSpan, { class => 'DateTime::Span' };
class_type DateSpanSet, { class => 'DateTime::SpanSet' };

#union DateRange, [DateSpan, DateSpanSet];
subtype DateRange, as DateSpan|DateSpanSet;

sub _make_date_span {
    my ($d1, $d2) = @_;
    $d1 = defined $d1 ? ref $d1 ? $d1 : _make_date(split /-/, $d1) :
        DateTime::Infinite::Past->new;
    $d2 = defined $d2 ? ref $d2 ? $d2 : _make_date(split /-/, $d2) :
        DateTime::Infinite::Future->new;

    my %p;
    @p{qw(start end)} = sort { $a <=> $b } ($d1, $d2);

    DateTime::Span->from_datetimes(%p);
}

coerce DateRange, from ArrayRef[Maybe[Str]],
    via { _make_date_span(@{$_[0]}) };

coerce DateRange, from ArrayRef[Maybe[XSDdate]],
    via { _make_date_span(@{$_[0]}) };

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0> .

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Params::Registry::Types

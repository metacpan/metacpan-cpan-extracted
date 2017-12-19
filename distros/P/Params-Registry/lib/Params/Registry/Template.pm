package Params::Registry::Template;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Params::Registry::Types qw(Type Dependency Format);
use MooseX::Types::Moose    qw(Maybe Bool Int Str ArrayRef CodeRef);
use Try::Tiny;

use Params::Registry::Error;

=head1 NAME

Params::Registry::Template - Template class for an individual parameter

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    my $registry = Params::Registry->new(
        params => [
            # These constructs are passed into
            # the parameter template module.
            {
                # The name is consumed before
                # the object is constructed.
                name       => 'foo',

                # the type of individual values
                type       => 'Num',

                # the composite type with coercion
                composite  => 'NumberRange',

                # format string or sub for individual values
                format     => '%0.2f',

                # do not delete empty values
                empty      => 1,

                # For sets and ranges:
                # fetch range extrema or universal set
                universe   => \&_extrema_from_db,

                # supply an operation that complements the given
                # set/range against the extrema/universe
                complement => \&_range_complement,

                # supply a serialization function
                unwind     => \&_range_to_arrayref,
            },
            {
                name => 'bar',
                # Lengthy definitions can be reused.
                use  => 'foo',
            },
        ],
    );

=head1 METHODS

=head2 new

This constructor is invoked by a factory method in
L<Params::Registry>. All arguments are optional unless specified
otherwise.

=over 4

=item registry

This back-reference to the registry is the only required
argument. Since the template objects are constructed from a factory
inside L<Params::Registry>, it will be supplied automatically.

=cut

has registry => (
    is       => 'ro',
    isa      => 'Params::Registry',
    required => 1,
    weak_ref => 1,
);

=item type

The L<Moose> type of the individual values of the parameter. The
default is C<Str>.

=cut

has type => (
    is      => 'ro',
    isa     => Type,
    lazy    => 1,
    default => sub { Str },
);

=item composite

Specifies a composite type to envelop one or more distinct parameter
values. If a composite type is specified, even single-valued
parameters will be coerced into that composite type as if it was an
C<ArrayRef>. As such, composite types used in this field should
be specified with coercions that expect C<ArrayRef>, like so:

    coerce FooBar => from ArrayRef => via { Foo::Bar->new(@{$_[0]}) };

    # ...
    {
        name      => 'foo',
        type      => 'Str',
        composite => 'FooBar',
        # ...
    },
    # ...

=cut

has composite => (
    is      => 'ro',
    isa     => Type,
    lazy    => 1,
    default => sub { ArrayRef },
);

=item format

Either a format string or a subroutine reference depicting how scalar
values ought to be serialized. The default value is C<%s>.

=cut

has format => (
    is      => 'ro',
    isa     => Format,
    lazy    => 1,
    coerce  => 1,
    default => sub { sub { sprintf '%s', shift } },
);

=item depends

An C<ARRAY> reference containing a list of parameters which I<must>
accompany this one.

=cut

# I know it says ARRAY but the value is more useful as hash keys, so
# these two attributes get coerced into hashrefs.

has _depends => (
    is      => 'ro',
    isa     => Dependency,
    traits  => [qw(Hash)],
    coerce  => 1,
    lazy    => 1,
    init_arg => 'depends',
    default => sub { Params::Registry::Types::ixhash_ref() },
    handles => {
        depends    => 'keys',
        depends_on => 'get',
    },
);

# # XXX HOLY SHIT TRAITS ARE SLOW
# sub depends {
#     keys %{$_[0]->_depends};
# }

=item conflicts

An C<ARRAY> reference containing a list of parameters which I<must
not> be seen with this one.

=cut

has _conflicts => (
    is       => 'ro',
    isa      => Dependency,
    traits   => [qw(Hash)],
    coerce   => 1,
    lazy     => 1,
    init_arg => 'conflicts',
    default  => sub { Params::Registry::Types::ixhash_ref() },
    handles  => {
        conflicts      => 'keys',
        conflicts_with => 'get',
        # make these symmetric in the constructor
        _add_conflict  => 'set',
    },
);

# # XXX HOLY SHIT TRAITS ARE SLOW
# sub conflicts {
#     keys %{$_[0]->_conflicts};
# }

=item consumes

For cascading parameters, an C<ARRAY> reference containing a list of
subsidiary parameters which are consumed to create it. All consumed
parameters are automatically assumed to be in conflict, i.e., it makes
no sense to have both a subsidiary parameter and one that consumes it
in the input at the same time.

=cut

has _consumes => (
    is       => 'ro',
    isa      => Dependency,
    traits   => [qw(Hash)],
    coerce   => 1,
    lazy     => 1,
    init_arg => 'consumes',
    default  => sub { Params::Registry::Types::ixhash_ref() },
    handles  => {
        consumes  => 'keys',
    },
);

# # XXX HOLY SHIT TRAITS ARE SLOW
# sub consumes {
#     keys %{$_[0]->_consumes};
# }

has __consdep => (
    is => 'ro',
    isa => ArrayRef,
    traits => [qw(Array)],
    lazy    => 1,
    default => sub { [ $_[0]->__UGH_CONSDEP ] },
    handles => {
        _consdep => 'elements',
    },
);

# this thing merges 'consumes' and 'depends' together, in order
sub __UGH_CONSDEP {
    my $self = shift;

    my $c = $self->_consumes;
    $c = tied %$c;

    my @out = $c->Keys;
    my %c = map { $_ => 1 } @out;

    # tack this on but only if there is a preprocessor present
    if ($self->preproc) {
        my $d = $self->_depends;
        $d = tied %$d;
        #my $c = $self->_consumes;
        # ordered union of 'consumes' and 'depends'
        push @out, grep { !$c{$_} } $d->Keys;
    }

    @out;
}

# change to 'preprocessor'

# the purpose of the preprocessor is to coalesce values from multiple
# parameters before handing them off to the template processor

# these include the columns listed under 'depends' and 'consumes', the
# difference between the two being that the former remain in the
# resulting master data structure while the latter are removed.

# the preprocessor function should therefore expect a list of array
# refs: (should it? the dependencies will already have been processed)

# change behaviour of 'depends' so that it can be cyclic *unless*
# there is a preprocessor defined

# this means the default has to be undef, so any code that uses the
# default value has to be changed

=item preproc

Supply a C<CODE> reference to a function which coalesces values from
the parameter in context (which may be empty) with other parameters
specified by L</consumes> and L</depends>. The function is expected to
return a result which can be handled by L</process>: either the
appropriate L</composite> type (resulting in a no-op) or a list of
valid primitives. The function is handed the following arguments:

=over 4

=item C<$self>

The L<Params::Registry::Template> instance, to give the function
(really a pseudo-method) access to its members.

=item current raw value

This will be an ARRAY reference containing zero or more elements, I<as
supplied> to the input. It will B<not> be processed.

=item other parameters

All subsequent arguments to the L</preproc> function will represent
the set union of L</consumes> and L</depends>. It will follow the
sequence of keys specified in L</consumes> followed by the sequence in
L</depends> B<minus> those which already appear in L</consumes>.

It is important to note that I<these values will already have been
processed>, so they will be whatever (potentially L</composite>) type
you specify. Make sure you author this function with this expectation.

=back

The result(s) of L</preproc> will be collected into an array and fed
into L</process>. Use L</depends> rather than L</consumes> to supply
other parameters without removing them from the resulting structure.
Note that when L</depends> is used in conjunction with L</preproc>,
the dependencies I<must> be acyclic.

L</preproc> is called either just before L</process> over supplied
data, or in lieu of it.

Here is an example of L</preproc> used to compose a set of parameters
containing integers (e.g., from a legacy HTML form) into a L<DateTime>
object:

    # ...
    {
        name => 'year',
        type => 'Int',
        max  => 1,
    },
    {
        name => 'month',
        type => 'Int',
        max  => 1,
    },
    {
        name => 'day',
        type => 'Int',
        max  => 1,
    },
    {
        name => 'date',

        # this would be defined elsewhere with coercion from a
        # string that matches 'YYYY-MM-DD', for direct input.
        type => 'MyDateTimeType',

        # we don't want multiple values for this parameter.
        max  => 1,

        # in lieu of being explicitly defined in the input, this
        # parameter will be constructed from the following:
        consumes => [qw(year month day)],

        # and this is how it will happen:
        preproc => sub {
            my (undef, undef, $y, $m, $d) = @_;
            DateTime->new(
                year  => $y,
                month => $m,
                day   => $d,
            );
        },
    },
    # ...

=cut

has preproc => (
    is      => 'ro',
    isa     => CodeRef,
);

# =item prefmt
#
# This element is the dual to L</preproc>.
#
# =cut

# =item consumer

# For cascading parameters, a C<CODE> reference to operate on the
# consumed parameters in order to produce the desired I<atomic> value.
# To produce a I<composite> parameter value from multiple existing
# I<values>, define a coercion from C<ArrayRef> to the type supplied
# to the L</composite> property.

# The default consumer function, therefore, simply returns an C<ARRAY>
# reference that collates the values from the parameters defined in
# the L</consumes> property.

# Once again, this functionality exists primarily for the purpose of
# interfacing with HTML forms that lack the latest features. Consider
# the following example:

#     # ...
#     {
#         name => 'year',
#         type => 'Int',
#         max  => 1,
#     },
#     {
#         name => 'month',
#         type => 'Int',
#         max  => 1,
#     },
#     {
#         name => 'day',
#         type => 'Int',
#         max  => 1,
#     },
#     {
#         name => 'date',

#         # this would be defined elsewhere with coercion from a
#         # string that matches 'YYYY-MM-DD', for direct input.
#         type => 'MyDateTimeType',

#         # we don't want multiple values for this parameter.
#         max  => 1,

#         # in lieu of being explicitly defined in the input, this
#         # parameter will be constructed from the following:
#         consumes => [qw(year month day)],

#         # and this is how it will happen:
#         consumer => sub {
#             DateTime->new(
#                 year  => $_[0],
#                 month => $_[1],
#                 day   => $_[2],
#             );
#         },
#     },
#     # ...

# Here, we may have a form which contains a C<date> field for the newest
# browsers that support the new form control, or otherwise generated via
# JavaScript. As a fallback mechanism (e.g. for an older browser, robot,
# or paranoid person), form fields for the C<year>, C<month>, and C<day>
# can also be specified in the markup, and used to generate C<date>.

# =cut

# sub _default_consume {
#     [@_];
# }

# has consumer => (
#     is      => 'ro',
#     isa     => CodeRef,
#     lazy    => 1,
#     default => sub { \&_default_consume },
# );

# =item cardinality

# Either a scalar depicting an exact count, or a two-element C<ARRAY>
# reference depicting the minimum and maximum number of recognized
# values from the point of view of the I<input>. Subsequent values will
# either be truncated or L<shifted left|/shift>. The default setting is
# C<[0, undef]>, i.e. the parameter must have zero or more values. Set
# the minimum cardinality to 1 or higher to make the parameter
# I<required>.

# =cut

# has cardinality => (
#     is      => 'ro',
#     # this complains if you use MooseX::Types
#     isa     => 'ArrayRef[Maybe[Int]]|Int',
#     lazy    => 1,
#     default => sub { [0, undef] },
# );

=item min

The minimum number of values I<required> for the given parameter. Set
to 1 or higher to signal that the parameter is required. The default
value is 0, meaning that the parameter is optional.

=cut

has min => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => 0,
);

=item max

The maximum number of values I<acknowledged> for the given parameter.
Subsequent values will either be truncated to the right or shifted to
the left, depending on the value of the L</shift> property. Setting
this property to 1 will force parameters to be scalar. The default is
C<undef>, which accepts an unbounded list of values.

=cut

has max => (
    is      => 'ro',
    isa     => Maybe[Int],
    lazy    => 1,
    default => sub { undef },
);


=item shift

This boolean value determines the behaviour of input parameter values
that exceed the parameter's maximum cardinality. The default behaviour
is to truncate the list of values at the upper bound.  Setting this
bit instead causes the values for the ascribed parameter to be shifted
off the left side of the list. This enables, for instance, dumb web
applications to simply tack additional parameters onto the end of a
query string without having to parse it.

=cut

has shift => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

=item empty

If a parameter value is C<undef> or the empty string, the default
behaviour is to act like it didn't exist in the input, thus pruning it
from the resulting data and from the serialization. In the event that
an empty value for a given parameter is I<meaningful>, such as in
expressing a range unbounded on one side, this bit can be set, and the
L</default> can be set to either C<undef> or the empty string (or
anything else).

=cut

has empty => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

=item default

This C<default> value is passed through to the application only if the
parameter in question is either missing or empty (if C<empty> is
set). Likewise if the final translation of the input value matches the
default, it will not show up in the canonical serialization. Like
L<Moose>, is expected to be a C<CODE> reference. The subroutine takes
two arguments: this template object, and the
L<Params::Registry::Instance> object.

    default => sub {
        my ($t, $i) = @_;
        # do something...
    },

=cut

has default => (
    is  => 'ro',
    isa => CodeRef|Str,
);

=item universe

For L</Set> and L</Range> parameters, this is a C<CODE> reference
which produces a universal set against which the input can be
negated. In parameter serialization, there are often cases wherein a
shorter string can be achieved by presenting the negated set and
adding the parameter's name to the special parameter
L<Params::Registry/complement>. The subroutine can, for instance,
query a database for the full set in question and return a type
compatible with the parameter instance.

If you specify a universe, you I<must> also specify a L</complement>.

=cut

has _universe => (
    is       => 'ro',
    isa      => CodeRef,
    init_arg => 'universe',
);

# this is the cache for whatever gets generated by the universe function
has _unicache => (
    is  => 'rw',
);

sub universe {
    $_[0]->_unicache;
}

=item complement

For L</Set> and L</Range> parameters, this C<CODE> reference will need
to do the right thing to produce the inverse set.

    {
        # ...
        complement => sub {
            # assuming Set::Scalar
            my ($me, $universe) = @_;
            $me->complement($universe); },
        # ...
    }

This field expects to be used in conjunction with L</universe>.

=cut

has _complement => (
    is       => 'ro',
    isa      => CodeRef,
    init_arg => 'complement',
);

sub complement {
    my ($self, $set) = @_;
    if (my $c = $self->_complement) {
        try {
            $c->($set, $self->_unicache);
        } catch {
            Params::Registry::Error->throw("Could not execute complement: $_");
        };
    }
}

sub has_complement {
    return !!shift->_complement;
}

# XXX what is this bullshit about an unblessed hashref?

# ... C<ARRAY> reference of scalars, or an I<unblessed> C<HASH>
# reference containing valid parameter keys to either scalars or
# C<ARRAY> references of scalars. In the case the subroutine returns a
# C<HASH> reference, the registry will replace the parameter in
# context with the parameters supplied, effectively performing the
# inverse of a composite type coercion function.

=item unwind

Specify a C<CODE> reference to a subroutine which will turn the object
into either a scalar or an C<ARRAY> reference of scalars. To encourage
code reuse, this function is applied before L</reverse> despite the
obvious ability to reverse the resulting list within the function.

The first argument to the subroutine is the template object itself,
and the second is the value to be unwound. Subsequent arguments are
the values of the parameters specified in L</depends>, if present.

    sub my_unwind {
        my ($self, $obj, @depends) = @_;
        # ...
    }

If you don't need any state data from the template, consider the
following idiom:

    {
        # ...
        # assuming the object is a Set::Scalar
        unwind => sub { [sort $_[1]->elements] },
        # ...
    }

For multi-valued parameters, an optional second return value can be
used to indicate that the special
L<complement|Params::Registry/complement> parameter should be set for
this parameter. This is applicable, for instance, to the complement of
a range, which would otherwise be impossible to serialize into a
string.

=cut

has unwind => (
    is  => 'ro',
    isa => CodeRef,
);

=item reverse

For L</Range> parameters, this bit indicates whether the input values
should be interpreted and/or serialized in reverse order. This also
governs the serialization of L</Set> parameters.

=cut

has reverse => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

sub BUILD {
    my $self = shift;

    #my ($u, $c) = ($self->universe, $self->_complement);
    #$self->throw('I have a universe but no complement!') if $u && !$c;
    #$self->throw('I have a complement but no universe!') if $c && !$u;

    $self->refresh;
    #warn $self->type->name;
}

=back

=head2 process @VALS

Validate a list of individual parameter values and (optionally)
construct a L</composite> value.

=cut

sub process {
    my ($self, @in) = @_;

    my $t  = $self->type;
    # XXX get rid of AUTOLOAD garbage
    $t = $t->__type_constraint if ref $t eq 'MooseX::Types::TypeDecorator';
    my $e  = $self->empty;
    my $ac = $t->coercion;

    # filter input
    my @out;
    for my $v (@in) {
        # deal with undef/empty string
        if (!defined $v or $v eq '') {
            # do not append to @out unless 'empty' is set
            next unless $e;

            # normalize to undef
            undef $v;
        }

        if (defined $v) {
            if ($ac) {
                # coerce atomic type
                try {
                    my $tmp = $ac->coerce($v);
                    $v = $tmp;
                } catch {
                    my $err = $_;
                    Params::Registry::Error::Syntax->throw(
                        value   => $v,
                        message => $err,
                    );
                };
            }
            else {
                # check resulting value
                Params::Registry::Error::Syntax->throw(
                    value   => $v,
                    message => "Value '$v' is not a $t") unless $t->check($v);
            }
        }

        push @out, $v;
    }

    # deal with cardinality
    if (my $max = $self->max) {
        # force scalar
        if ($max == 1) {
            return unless @out; # this will be empty
            return $out[0];
        }

        # force cardinality
        splice @out, ($self->shift ? -$max : 0), $max if @out > $max;
    }

    # coerce to composite
    if (my $comp = $self->composite) {
        # XXX again get rid of AUTOLOAD
        $comp = $comp->__type_constraint
            if ref $comp eq 'MooseX::Types::TypeDecorator';
        # try to coerce into composite
        if (my $cc = $comp->coercion) {
            #warn "lol $c";
            return $cc->coerce(\@out);
        }
    }

    # otherwise return list of values
    return wantarray ? @out : \@out;
}


=head2 unprocess $OBJ, @REST

Applies L</unwind> to C<$OBJ> to get an C<ARRAY> reference, then
L</format> over each of the elements to get strings. In list context
it will also return the flag from L</unwind> indicating that the
L<complement|Params::Registry/complement> parameter should be set.

This method is called by L<Params::Registry::Instance/as_string> and
others to produce content which is amenable to serialization. As what
happens there, the content of C<@REST> should be the values of the
parameters specified in L</depends>.

=cut

sub unprocess {
    my ($self, $obj, @rest) = @_;

    # take care of empty property
    unless (defined $obj) {
        if ($self->empty) {
            my $max = $self->max;
            return [''] if defined $max && $max == 1;
            return [] if !defined $max or $max > 1;
        }
        return;
    }

    # i dunno, should we check these types on the way out?

    my $complement;
    if (defined $obj and my $u = $self->unwind) {
        try {
            ($obj, $complement) = $u->($self, $obj, @rest);
        } catch {
            Params::Registry::Error->throw("Could not execute unwind: $_");
        };
    }

    if (defined $obj) {
        $obj = [$obj] unless ref $obj eq 'ARRAY';

    }
    else {
        $obj = [];
    }

    # prune output again
    @$obj = grep { defined $_ } @$obj unless $self->empty;

    # format values
    my $fmt = $self->format;
    # XXX this should really be done once
    #unless (ref $fmt eq 'CODE') {
    #    my $x = $fmt;
    #    $fmt = sub { sprintf $x, shift };
    #}

    my @out = map { defined $_ ? $fmt->($_) : '' } @$obj;
    return wantarray ? (\@out, $complement) : \@out;
}

=head2 refresh

Refreshes stateful information like the universal set, if present.

=cut

sub refresh {
    my $self = shift;
    if (my $u = $self->_universe) {
        my $univ = $u->();
        if (my $t = $self->composite) {
            if (my $c = $t->coercion) {
                $univ = $c->coerce($univ);
            }
        }
        $self->_unicache($univ);
    }

    1;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Params::Registry>

=item

L<Params::Registry::Instance>

=back

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

__PACKAGE__->meta->make_immutable;

1; # End of Params::Registry::Template

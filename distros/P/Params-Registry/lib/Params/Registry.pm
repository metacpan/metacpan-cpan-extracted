package Params::Registry;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw(Maybe Str HashRef ArrayRef);
use Params::Registry::Types qw(Template);

use MooseX::Params::Validate ();

use Params::Registry::Template;
use Params::Registry::Instance;
use Params::Registry::Error;

use URI;
use URI::QueryParam;

=head1 NAME

Params::Registry - Housekeeping for sets of named parameters

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use Params::Registry;

    my $registry = Params::Registry->new(
        # express the global parameter sequence with an arrayref
        params => [
            {
                # see Params::Registry::Template for the full list of
                # attributes
                name => 'foo',
            },
        ],
        # specify groups containing potentially-overlapping subsets of
        # parameters for different aspects of your system
        groups => {
            stuff => [qw(foo)],
        },
        # override the name of the special 'complement' parameter
        complement => 'negate',
    );

    my $instance = eval { $registry->process(\%params) };

    $uri->query($instance->as_string);

=head1 DESCRIPTION

The purpose of this module is to handle a great deal of the
housekeeping around sets of named parameters and their values,
especially as they pertain to web development. Modules like
L<URI::QueryParam> and L<Catalyst> will take a URI query string and
turn it into a HASH reference containing either scalars or ARRAY
references of values, but further processing is almost always needed
to validate the parameters, normalize them, turn them into useful
compound objects, and last but not least, serialize them back into a
canonical string representation. It is likewise important to be able
to encapsulate error reporting around malformed or conflicting input,
at both the syntactical and semantic levels.

While this module was designed with the web in mind, it can be used
wherever a global registry of named parameters is deemed useful.

=over 4

=item Scalar

basically untouched

=item List

basically untouched

=item Tuple

A tuple can be understood as a list of definite length, for which each
position has its own meaning. The contents of a tuple can likewise be
heterogeneous.

=item Set

A standard mathematical set has no duplicate elements and no concept
of sequence.

=item Range

A range can be understood as a span of numbers or number-like objects,
such as L<DateTime> objects.

=item Object

When nothing else will do

=back

=head3 Cascading

There are instances, for example in the case of supporting a legacy
HTML form, when it is useful to combine input parameters. Take for
instance the practice of using drop-down boxes for the year, month and
day of a date in lieu of support for the HTML5 C<datetime> form field,
or access to custom form controls. One would specify C<year>, C<month>
and C<day> parameters, as well as a C<date> parameter which
C<consumes> the former three, C<using> a subroutine reference to do
it. Consumed parameters are deleted from the set.

=head3 Complement

A special parameter, C<complement>, is defined to signal parameters in
the set itself which should be treated as complements to what have
been expressed in the input. This module makes no prescriptions about
how the complement is to be interpreted, with the exception of
parameters whose values are bounded sets or ranges: if a shorter query
string can be achieved by negating the set and removing (or adding)
the parameter's name to the complement, that is what this module will
do.

    # universe of foo = (a .. z)
    foo=a&foo=b&foo=c&complement=foo -> (a .. z) - (a b c)

=head1 METHODS

=head2 new

Instantiate a new parameter registry.

=head3 Arguments

=over 4

=item params

An C<ARRAY> reference of C<HASH> references, containing the specs to
be passed into L<Params::Registry::Template> objects.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %p = MooseX::Params::Validate::validated_hash(
        \@_,
        params     => { isa => 'ArrayRef[Maybe[HashRef]]' },
        complement => { isa => 'Maybe[Str]',                    optional => 1 },
        groups     => { isa => 'HashRef[ArrayRef[Maybe[Str]]]', optional => 1 },
    );

    # fiddle with input and output
    my @entries = @{delete $p{params}};
    $p{params} = {};

    # pass once to separate the templates from their sequence
    my (@seq, %map);
    for my $entry (@entries) {
        my $name = delete $entry->{name};
        push @seq, $name;
        if (my $use = delete $entry->{use}) {
            # TODO: recursive
            $map{$name} = $use;
        }
        # TODO: throw a proper error on duplicate key
        Params::Registry::Error->throw
              ("Parameter $name already exists") if exists $p{params}{$name};

        $p{params}{$name} = $entry;
    }

    # second pass to stitch the reused parameters together
    while (my ($k, $v) = each %map) {
        # TODO throw a proper error if the target isn't found
        my $p = $p{params}{$v} or Params::Registry::Error->throw
            ("Tried to resolve $v for reuse but couldn't find it");

        # overwrite with any new data
        $p{params}{$k} = {%$p, %{$p{params}{$k}}};
    }

    # add param sequence to BUILD
    $p{_sequence} = \@seq;

    $class->$orig(%p);
};

sub BUILD {
    my $self = shift;
    my $p = $self->_params;

    my @seq = @{$self->_sequence};
    my (%rank, @stack);
    for my $k (@seq) {
        my %t = %{$p->{$k}};
        my $x = $p->{$k} = Params::Registry::Template->new
            (%t, registry => $self);
        if ($x->_consdep > 0) {
            # shortcut because only parameters with dependencies will
            # have a rank higher than zero
            $rank{$k} = 1;
            push @stack, $k;
        }
        else {
            $rank{$k} = 0;
        }
    }

    # construct a rank tree

    #my %seen;
    while (my $x = shift @stack) {
        #my %c = map { $_ => 1 } $p->{$x}->consumes;
        my $match = 0;
        for my $c ($p->{$x}->_consdep) {
            $match = 1 if $rank{$x} == $rank{$c};
            # XXX will this actually catch all cycles?
            Params::Registry::Error->throw
                  ("Cycle detected between $x and $c") if $rank{$x} < $rank{$c};
        }

        if ($match) {
            $rank{$x}++;
            push @stack, $x;
        }
    }

    # this makes an array of arrays of key names, in the order to be
    # processed.
    my $r = $self->_ranked;
    for my $k (@seq) {
        my $x = $r->[$rank{$k}] ||= [];
        push @$x, $k;
    }
    # note that any global sequence here would be valid as long as it
    # didn't put a consuming param before one to be consumed

    # XXX it is currently unclear whether two consuming parameters can
    # consume the same parameter.

    # we should also do deps and conflicts here:

    # deps are transitive but asymmetric; A -> B -> C implies A -> C
    # but says nothing about C

    # conflicts are symmetric: A conflicts with B means B conflicts
    # with A.

    # it is nonsensical (and therefore illegal) for parameters to
    # simultaneously depend and conflict.

    #warn Data::Dumper::Dumper($self->_ranked);
}

has _params => (
    is       => 'ro',
    #isa      => HashRef[Template],
    isa      => HashRef,
    traits   => [qw(Hash)],
    #coerce   => 1,
    required => 1,
    init_arg => 'params',
    handles  => {
        template => 'get',
    },
);

has _sequence => (
    is       => 'ro',
    traits   => [qw(Array)],
    isa      => ArrayRef[Str],
    required => 1,
    handles  => {
        sequence => 'elements',
    },
);

has _ranked => (
    is       => 'ro',
#    traits   => [qw(Array)],
    isa      => ArrayRef[ArrayRef[Str]],
    lazy     => 1,
    default  => sub { [] },
#    required => 1,
#    handles  => {
#        sequence => 'elements',
#    },
);

=item groups

A C<HASH> reference such that the keys are names of groups, and the
values are C<ARRAY> references of parameters to include in each group.

=cut

has _groups => (
    is       => 'ro',
    isa      => HashRef[Maybe[ArrayRef[Maybe[Str]]]],
    lazy     => 1,
    default  => sub { {} },
    init_arg => 'groups',
);

=item complement

This is the I<name> of the special parameter used to indicate which
I<other> parameters should have a
L<Params::Registry::Template/complement> operation run over them. The
default name, naturally, is C<complement>. This parameter will always
be added to the query string last.

=cut

has complement => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => 'complement',
);

=back

=head2 process $STR | $URI | \%PARAMS

Turn a L<URI>, query string or C<HASH> reference (such as those found
in L<Catalyst> or L<URI::QueryParam>) into a
L<Params::Registry::Instance>. May croak.

=cut

sub process {
    my $self = shift;

    my $obj;
    if (ref $_[0]) {
        if (Scalar::Util::blessed($_[0]) and $_[0]->isa('URI')) {
            $obj = $_[0]->query_form_hash;
        }
        elsif (ref $_[0] eq 'HASH') {
            $obj = $_[0];
        }
        else {
            Params::Registry::Error->throw
                ('If the argument is a ref, it must be a URI or a HASH ref');
        }
    }
    elsif (@_ == 1 && defined $_[0]) {
        my $x = $_[0];
        $x = "?$x" unless $x =~ /^\?/;
        $obj = URI->new("http://foo/$x")->query_form_hash;
    }
    elsif (@_ > 0 && @_ % 2 == 0) {
        my %x = @_;
        $obj = \%x;
    }
    else {
        Params::Registry::Error->throw
              ('Check your inputs to Params::Registry::process');
    }

    my $instance = Params::Registry::Instance->new(registry => $self);

    $instance->set($obj, -defaults => 1, -force => 1);
}

=head2 template $KEY

Return a particular template from the registry.

=head2 sequence

Return the global sequence of parameters for serialization.

=head2 refresh

Refresh the stateful components of the templates

=cut

sub refresh {
    my $self = shift;
    for my $template (values %{$self->_params}) {
        $template->refresh;
    }
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-params-registry at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Registry>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Params::Registry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Registry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Params-Registry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Params-Registry>

=item * Search CPAN

L<http://search.cpan.org/dist/Params-Registry/>

=back

=head1 SEE ALSO

=over 4

=item

L<Params::Registry::Instance>

=item

L<Params::Registry::Template>

=item

L<Params::Validate>

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

1; # End of Params::Registry

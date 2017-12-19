package Params::Registry::Instance;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Params::Registry::Error;

use Scalar::Util ();
use Try::Tiny;

#use constant INF => 100**100**100;
#use constant NEG_INF => 1 - INF;

=head1 NAME

Params::Registry::Instance - An instance of registered parameters

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

has _registry => (
    is       => 'ro',
    isa      => 'Params::Registry',
    required => 1,
    weak_ref => 1,
    init_arg => 'registry',
);

has _content => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [qw(Hash)],
    lazy     => 1,
    default  => sub { {} },
    handles  => {
        exists => 'exists',
#        get    => 'get',
        keys   => 'keys',
    },
);

has _other => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [qw(Hash)],
    lazy     => 1,
    default  => sub { {} },
    handles  => {
    },
);


=head1 SYNOPSIS

    use Params::Registry;
    use URI;
    use URI::QueryParam;

    my $registry = Params::Registry->new(%enormous_arg_list);

    my $uri = URI->new($str);

    # The instance is created through Params::Registry, which will
    # raise different exceptions for different types of conflict in
    # the parameters.
    my $instance = eval { $registry->process($uri->query_form_hash) };

    # Contents have already been coerced
    my $thingy = $instance->get($key);

    # This will perform type validation and coercion, so if you aren't
    # certain the input is clean, you'll want to wrap this call in an
    # eval.
    eval { $instance->set($key, $val) };

    # Take a subset of parameters peculiar to a certain application.
    my $group = $instance->group($name);

    # This string is guaranteed to be consistent for a given set of
    # parameters and values.
    $uri->query($instance->as_string);

=head1 METHODS

=head2 get $KEY

Retrieve an element of the parameter instance.

=cut

sub get {
    my ($self, $key) = @_;
    my $content = $self->_content;
    return $content->{$key} if exists $content->{$key};

    # otherwise...

    my $t = $self->_registry->template($key);
    my %c = map { $_ => 1 } $self->keys;
    my $c = scalar grep { $c{$_} } $t->conflicts;

    if (!$c and my $d = $t->default) {
        # call the default with both the template *and* the instance
        my $val = $d->($t, $self);

        # this is me being clever
        my $c = $t->composite;
        if ($c = $c->coercion) {
            return $c->coerce($val);
        }

        return $val;
    }

    return;
}

=head2 set \%PARAMS | $KEY, $VAL [, $KEY2, \@VALS2 ...]

Modifies one or more of the parameters in the instance. Attempts to
coerce the input according to the template. Accepts, as values, either
a literal, an C<ARRAY> reference of literals, or the target datatype.
If a <Params::Registry::Template/composite> is specified for a given
key, C<ARRAY> references will be coerced into the appropriate
composite datatype.

Syntax, semantics, cardinality, dependencies and conflicts are all
observed, but cascading is I<not>. This method will throw an exception
if the input can't be reconciled with the L<Params::Registry> that
generated the instance.

=cut

# it isn't clear why '_process' should not admit already-parsed
# values, and why 'set' should not do cascading. they are essentially
# identical. in fact, we may be able to just get rid of '_process'
# altogether in favour of 'set'.

# the difference between 'set' and '_process' is that '_process' runs
# defaults while 'set' does not, and 'set' compares depends/conflicts
# with existing content while '_process' has nothing to compare it to.

# * parameters handed to 'set' may already be parsed, or partially
#   parsed (as in an arrayref of 'type' but not 'composite')

# * dependencies, conflicts, and precursor 'consumes' parameters may
#   be present in the existing data structure

# * dependencies/conflicts can be cleared by passing in 'undef'; to
#   deal with 'empty' parameters, pass in an empty arrayref or
#   arrayref containing only undefs.

# although if the parameters are ranked and inserted ,

sub set {
    my $self = shift;

    # deal with parameters and metaparameters
    my (%p, %meta);
    if (ref $_[0]) {
        Params::Registry::Error->throw
              ('If the first argument is a ref, it has to be a HASH ref')
                  unless ref $_[0] eq 'HASH';
        # params are their own hashref
        %p = %{$_[0]};

        if (ref $_[1]) {
            Params::Registry::Error->throw
                  ('If the first and second arguments are refs, ' .
                       'they both have to be HASH refs')
                      unless ref $_[1] eq 'HASH';

            # metaparams are their own hashref
            %meta = %{$_[1]};
        }
        else {
            Params::Registry::Error->throw
                  ('Expected even number of args for metaparameters')
                      unless @_ % 2 == 1; # note: even is actually odd here

            # metaparams are everything after the hashref
            %meta = @_[1..$#_];
        }
    }
    else {
        Params::Registry::Error->throw
              ('Expected even number of args for metaparameters')
                  unless @_ % 2 == 0; # note: even is actually even here

        # arguments = params
        %p = @_;

        # pull metaparams out of ordinary params
        %meta = map { $_ => delete $p{$_} } qw(-defaults -force);
    }

    # grab the parent object that stores all the configuration data
    my $r = $self->_registry;

    # create a map of params to complement/negate
    my %neg;
    if (my $c = delete $p{$r->complement}) {
        my $x = ref $c;
        Params::Registry::Error->throw
              ('If complement is a reference, it must be an ARRAY reference')
                  if $x and $x ne 'ARRAY';
        map { $neg{$_} = 1 } @{$x ? $c : [$c]};
    }

    # and now for the product
    my %out = %{$self->_content};
    my (%del, %err);
    # the registry has already ranked groups of parameters by order of
    # depends/consumes
    for my $list (@{$r->_ranked}) {
        # each rank has a list of parameters which are roughly in the
        # original sequence provided to the registry
        for my $p (@$list) {

            # normalize input value(s) if present
            my @v;
            if (exists $p{$p}) {
                my $v = $p{$p};
                my $rv = ref $v;
                $v = [$v] if !$rv || $rv ne 'ARRAY';
                @v = @$v;
            }

            # skip if there's nothing to set
            next if @v == 0 and !$meta{-force};

            # retrieve the appropriate template object
            my $t = $r->template($p);

            # run the preprocessor
            my @deps = $t->_consdep;
            if (my $pp = $t->preproc
                    and @deps == grep { exists $out{$_} } @deps) {
                try {
                    # apply the preprocessor
                    @v = $pp->($t, \@v, @out{@deps});

                    # get rid of consumed parameters
                    map { $del{$_} = 1 } $t->consumes;
                } catch {
                    $err{$p} = $_;
                };
            }

            # now we run the main parameter template processor
            if (!$err{$p} and @v > 0) {
                try {
                    my $tmp = $t->process(@v);
                    $out{$p} = $tmp if defined $tmp or $t->empty;
                } catch {
                    $err{$p} = $_;
                };
            }

            # now we test for conflicts
            unless ($err{$p}) {
                my @x = grep { $out{$_} && !$del{$_} } $t->conflicts;
                $err{$p} = Params::Registry::Error->new
                    (sprintf '%s conflicts with %s', $p, join ', ', @x) if @x;
            }


            # XXX what was the problem with this? 2016-05-30

            # elsif ($meta{-defaults} and my $d = $t->default) {
            #     # add a default value unless there are conflicts
            #     my @x = grep { $out{$_} && !$del{$_} } $t->conflicts;
            #     $out{$p} = $d->($t) unless @x;
            # }

            # now handle the complement
            if (!$err{$p} and $neg{$p} and $t->has_complement) {
                $out{$p} = $t->complement($out{$p});
            }
        }
    }

    Params::Registry::Error::Processing->throw(parameters => \%err)
          if keys %err;

    # we waited to delete the contents all at once in case there were
    # dependencies
    map { delete $out{$_} } keys %del;

    # now we replace the content all in one shot
    %{$self->_content} = %out;

    # not sure what else to return
    return $self;
}

=head2 group $KEY

Selects a subset of the instance according to the groups laid out in
the L<Params::Registry> specification, clones them, and returns them
in a C<HASH> reference, suitable for passing into another method.

=cut

sub group {
    my ($self, $key) = @_;

    my %out;
    my @list = @{$self->_registry->_groups->{$key} || []};
    my $c = $self->_content;
    for my $k (@list) {
        # XXX ACTUALLY CLONE THESE (MAYBE)

        # use exists, not defined
        $out{$k} = $c->{$k} if exists $c->{$k};
    }

    \%out;
}

=head2 clone $KEY => $VAL [...] | \%PAIRS

Produces a clone of the instance object, with the supplied parameters
overwritten. Internally, this uses L</set>, so the input must already
be clean, or wrapped in an C<eval>.

=cut

sub clone {
    my $self = shift;
    my %p = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;


    # XXX deep copy?
    my %orig = %{$self->_content};

    # sometimes we only want to clone certain params
    if (defined $p{-only}) {
        my $o = delete $p{-only};
        my %only = map { $_ => 1 } (ref $o ? @$o : $o);
        map { delete $orig{$_} unless $only{$_} } keys %orig if %only;
    }

    my $out = Params::Registry::Instance->new(
        registry => $self->_registry,
        _content => \%orig,
    );

    $out->set(\%p) if keys %p;

    $out;
}

=head2 as_where_clause

Generates a data structure suitable to pass into L<SQL::Abstract>
(e.g., via L<DBIx::Class>).

=cut

sub _do_span {
    my ($span, $universe) = @_;

    my ($s, $e) = ($span->start, $span->end);

    # deal with possibly-empty universe
    my ($us, $ue);
    if ($universe) {
        my $u = $universe->isa('DateTime::SpanSet')
            ? $universe->span : $universe;
        ($us, $ue) = ($u->start, $u->end);
    }

    # adjust for open sets
    my $sop = $span->start_is_open ? '>' : '>=';
    my $eop = $span->end_is_open   ? '<' : '<=';

    # XXX this does not adjust for BETWEEN or when start and end are
    # the same

    my %out;
    if ($s->is_finite and (!$us or $s > $us)) {
        $out{$sop} = $s;
    }
    if ($e->is_finite and (!$ue or $e < $ue)) {
        $out{$eop} = $e;
    }

    # this can be empty and that screws up sql generation
    return \%out if keys %out;
}

# XXX these should really be embedded in the types, no?

# NOTE: we have these functions return the key along with the clause
# to signal that there actually *is* a a clause, because just
# returning undef could be interpreted by SQL::Abstract as IS NULL,
# and we don't want that. Unless we actually *do* want that.

my %TYPES = (
    'Set::Scalar' => sub {
        # any set coming into this sub will already have been complemented
        my ($key, $val, $template) = @_;

        # there is nothing to select
        my $vs = $val->size;
        return if $vs == 0;

        # there is everything to select
        my $comp = $template->complement($val);
        my $cs = $comp->size;
        return if $cs == 0;

        if ($vs > $cs) {
            my @e = $comp->elements;
            return ($key => $cs == 1 ? { '!=' => $e[0] } : { -not_in => \@e });
        }
        else {
            my @e = $val->elements;
            return ($key => $vs == 1 ? $e[0] : { -in => \@e });
        }
    },
    'Set::Infinite' => sub {
        my ($key, $val, $template) = @_;
        return if $val->is_empty;

        # bail out if the span is wider than the universe
        my $universe = $template->universe;
        return if $universe and $val->is_span
            and $val->min <= $universe->min and $val->max >= $universe->max;

        my $inf  = Set::Infinite->inf;
        my $ninf = Set::Infinite->minus_inf;

        my @ranges;
        my ($span, $tail) = $val->first;
        do {
            my ($min, $mop) = $span->min_a;
            my ($max, $xop) = $span->max_a;

            my $closed = !($mop || $xop);
            $mop = $mop ? '>' : '>=';
            $xop = $xop ? '<' : '<=';

            my %rec;
            if ($min == $ninf and $max == $inf) {
                next;
            }
            elsif ($closed and $min > $ninf and $max < $inf) {
                if ($min == $max) {
                    push @ranges, $min;
                }
                else {
                    $rec{-between} = [$min, $max];
                }
            }
            else {
                $rec{$mop} = $min + 0 unless $min == $ninf;
                $rec{$xop} = $max + 0 unless $max == $inf;
            }

            push @ranges, \%rec if keys %rec;

            ($span, $tail) = $tail ? $tail->first : ();
        } while ($span);

        return ($key, $ranges[0]) if @ranges == 1;
        return ($key, \@ranges) if @ranges;
    },
    'DateTime::Span' => sub {
        my ($key, $val, $template) = @_;

        my $out = _do_span($val, $template->universe);
        return ($key, $out) if $out;
    },
    'DateTime::SpanSet' => sub {
        my ($key, $val, $template) = @_;
        my $u = $template->universe;

        my @spans;
        for my $span ($val->as_list) {
            my $rule = _do_span($span, $u);
            push @spans, $rule if $rule;
        }
        return ($key, $spans[0]) if @spans == 1;
        return ($key, \@spans) if @spans;
    },
    # i don't think we have any of these at the moment
    'DateTime::Set' => sub {
    },
    'ARRAY' => sub {
        my ($key, $val) = @_;
        return ($key, { -in => [ @$val ] });
    },
);

sub as_where_clause {
    my $self = shift;
    my %p = @_;

    my %only = map { $_ => 1 } @{$p{only} || []};

    my %out;

    my $r = $self->_registry;

    for my $kin ($self->keys) {
        # skip skeep skorrp
        next if %only && !$only{$kin};

        my $vin = $self->get($kin);

        my $dispatch;
        if (my $ref = ref $vin) {
            unless ($dispatch = $TYPES{$ref}) {
                if (Scalar::Util::blessed($vin)) {
                    for my $t (keys %TYPES) {
                        if ($vin->isa($t)) {
                            $dispatch = $TYPES{$t};
                            last;
                        }
                    }
                }
            }
        }

        my ($kout, $vout);
        if ($dispatch) {
            my $t = $r->template($kin);
            ($kout, $vout) = $dispatch->($kin, $vin, $t);
        }
        else {
            ($kout, $vout) = ($kin, $vin);
        }

        $out{$kout} = $vout if $kout;
    }

    wantarray ? %out : \%out;
}

=head2 as_string

Generates the canonical URI query string according to the template.

=cut

sub as_string {
    my $self = shift;
    my $r = $self->_registry;

    # this just creates [key => \@values], ...
    my (@out, %comp);
    for my $k ($r->sequence) {
        # skip unless the parameter is present. this gets around
        # 'empty'-marked params that we don't actually have.
        next unless $self->exists($k);

        my $t = $r->template($k);
        my $v = $self->get($k);

        # get dependencies
        my @dep = map { $self->get($_) } $t->depends;

        # retrieve un-processed ARRAY ref
        (my $obj, $comp{$k}) = $t->unprocess($v, @dep);

        # skip empties
        next unless defined $obj;

        # accumulate
        push @out, [$k, $obj];
    }

    # XXX we have to handle complements here

    # for sets/composites, check if displaying '&complement=key' is
    # shorter than just displaying the contents of the set
    # (e.g. &key=val&key=val&key=val... it almost certainly will be).

    # XXX we *also* need to handle escaping

    return join '&', map { my $x = $_->[0]; map { "$x=$_" } @{$_->[1]} } @out;
}

=head2 make_uri $URI

Accepts a L<URI> object and returns a clone of that object with its
query string overwritten with the contents of the instance. This is a
convenience method for idioms like:

    my $new_uri = $instance->clone(foo => undef)->make_uri($old_uri);

As expected, this will produce a new instance with the C<foo>
parameter removed, which is then used to generate a URI, suitable for
a link.

=cut

sub make_uri {
    my ($self, $uri) = @_;
    $uri = $uri->clone->canonical;
    $uri->query($self->as_string);
    $uri;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Params::Registry>

=item

L<Params::Registry::Template>

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

1; # End of Params::Registry::Instance

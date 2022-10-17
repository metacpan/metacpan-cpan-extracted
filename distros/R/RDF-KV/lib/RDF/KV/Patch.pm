package RDF::KV::Patch;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use RDF::Trine qw(iri blank literal);

use URI::BNode;

=head1 NAME

RDF::KV::Patch - Representation of RDF statements to be added or removed

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    my $patch = RDF::KV::Patch->new;

    $patch->add_this($s, $p, $o, $g);
    $patch->remove_this($s, $p, undef, $g); # a wildcard

    $patch->apply($model); # an RDF::Trine::Model instance

=head1 DESCRIPTION

This module is designed to represent a I<diff> for RDF graphs. You add
statements to its I<add> or I<remove> sides, then you L</apply> them
to a L<RDF::Trine::Model> object. This should probably be part of
L<RDF::Trine> if there isn't something like this in there already.

=cut

# positive statements
has _pos => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

# negative statements/wildcards
has _neg => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

=head1 METHODS

=head2 new

Stub constructor, nothing of interest.

=cut

=head2 add_this { $S, $P, $O | $statement } [, $graph ]

Add a statement, or set of terms, to the I<add> side of the patch.

This method and its siblings are fairly robust, and can take a wide
variety of inputs, from triple and quad statements, to individual
subject/predicate/object/graph objects, to string literals, to
variable nodes, to undef. They are processed by the following scheme:

=over 4

=item

If passed a L<RDF::Trine::Statement>, it will be unwound into its
respective components. The C<graph> attribute of a L<quad
statement|RDF::Trine::Statement::Quad> supersedes any given graph
parameter.

=item

The empty string, C<undef>, and L<RDF::Trine::Node::Variable> objects
are considered to be wildcards, which are only legal in the
I<negative> side of the patch, since they don't make sense on the
positive side. Placing wildcards in all three of the subject,
predicate and object positions will raise an exception, because if
carried out it would completely empty the graph. If you're sure you
want to do that, you should use another mechanism.

=item

I<Subjects> are coerced from string literals to L<URI> and
L<URI::BNode> instances and from there to
L<RDF::Trine::Node::Resource> and L<RDF::Trine::Node::Blank>
instances, respectively.

=item

I<Predicates> are always coerced from string literals or L<URI> objects
into L<RDF::Trine::Node::Resource> objects.

=item

I<Objects> are coerced from either string literals or C<ARRAY>
references into L<RDF::Trine::Node::Literal> instances, the latter
case mimicking L<that class's
constructor|RDF::Trine::Node::Literal/new>. URIs or blank nodes must
already be at least instances of L<URI> or L<URI::BNode>, if not
L<RDF::Trine::Node::Resource> or L<RDF::Trine::Node::Blank>. Note: the
empty string is considered a wildcard, so if you want an actual empty
string, you will need to pass in an L<RDF::Trine::Node::Literal> with
that value.

=back

=cut

sub _validate {
    # oh undef vs empty string, you're so cute.
    my ($s, $p, $o, $g) =
        map { defined $_ && !ref $_ && $_ eq '' ? undef : $_ } @_;

    if (defined $s) {
        if (Scalar::Util::blessed($s)) {
            if ($s->isa('RDF::Trine::Statement')) {
                # move $p to $g
                if (defined $p) {
                    $g = $p;
                    undef $p;
                }

                # unpack statement
                if ($s->isa('RDF::Trine::Statement::Quad')) {
                    ($s, $p, $o, $g) =
                        map { $s->$_ } qw(subject predicate object graph);
                }
                else {
                    ($s, $p, $o) = map { $s->$_ } qw(subject predicate object);
                }
            }
            elsif ($s->isa('URI::BNode')) {
                $s = blank($s->opaque);
            }
            elsif ($s->isa('URI')) {
                $s = iri($s->as_string);
            }
            elsif ($s->isa('RDF::Trine::Node::Variable')) {
                $s = undef;
            }
            else {
                # dunno
            }
        }
        else {
            # dunno
            $s = URI::BNode->new($s);
            $s = $s->scheme eq '_' ? blank($s->opaque) : iri($s->as_string);
        }
    }

    # predicate will always be an iri
    if (defined $p) {
        if (Scalar::Util::blessed($p)) {
            if ($p->isa('URI')) {
                $p = iri($p->as_string);
            }
            elsif ($p->isa('RDF::Trine::Node::Variable')) {
                $p = undef;
            }
            else {
                # dunno
            }
        }
        else {
            $p = iri("$p");
        }
    }

    if (defined $o) {
        if (my $ref = ref $o) {
            if (Scalar::Util::blessed($o)) {
                if ($o->isa('URI::BNode')) {
                    $o = blank($o->opaque);
                }
                elsif ($o->isa('URI')) {
                    $o = iri($o->as_string);
                }
                elsif ($o->isa('RDF::Trine::Node::Variable')) {
                    $o = undef;
                }
                else {
                    # dunno
                }
            }
            elsif ($ref eq 'ARRAY') {
                my ($lv, $lang, $dt) = @$o;
                if (ref $dt and Scalar::Util::blessed($dt)) {
                    $dt = $dt->can('uri_value') ? $dt->uri_value :
                        $dt->can('as_string') ? $dt->as_string : "$dt";
                }
                $o = literal($lv, $lang, $dt);
            }
            else {
                # dunno
            }
        }
        else {
            $o = literal($o);
        }
    }

    if (defined $g) {
        if (Scalar::Util::blessed($g)) {
            if ($g->isa('RDF::Trine::Node')) {
                # do nothing
            }
            elsif ($g->isa('URI')) {
                # scheme is not guaranteed to be present
                $g = ($g->scheme || '') eq '_' ?
                    blank($g->opaque) : iri($g->as_string);
            }
            else {
                # dunno
            }
        }
        else {
            # apparently rdf 1.1 graph identifiers can be bnodes
            $g = URI::BNode->new($g);
            # ditto scheme
            $g = ($g->scheme || '') eq '_' ?
                blank($g->opaque) : iri($g->as_string);
        }
    }

    return ($s, $p, $o, $g);
}

sub _add_either {
    my ($set, $s, $p, $o, $g) = @_;
    # clobber graph, subject and predicate to strings; bnode will be _:
    ($g, $s, $p) = map {
        defined $_ ? $_->isa('RDF::Trine::Node::Blank') ?
            $_->sse : ref $_ ? $_->uri_value : $_ : '' } ($g, $s, $p);

    $set->{$g}         ||= {};
    $set->{$g}{$s}     ||= {};
    $set->{$g}{$s}{$p} ||= [{}, {}];

    if ($o) {
        if ($o->isa('RDF::Trine::Node::Literal')) {
            my $l  = $o->literal_value_language;
            my $d  = $o->literal_datatype;
            my $ld = $d ? "^$d" : $l ? "\@$l" : '';
            my $x  = $set->{$g}{$s}{$p}[1]{$ld} ||= {};
            $x->{$o->literal_value} = 1;
        }
        elsif ($o->isa('RDF::Trine::Node::Variable')) {
            $set->{$g}{$s}{$p} = 1;
        }
        else {
            $o = $o->isa('RDF::Trine::Node::Blank') ? $o->sse : $o->uri_value;
            $set->{$g}{$s}{$p}[0]{$o} = 1;
        }
    }
    else {
        $set->{$g}{$s}{$p} = 1;
    }
}

sub add_this {
    my $self = shift;
    my ($s, $p, $o, $g) = _validate(@_);
    Carp::croak('It makes no sense in this context to add a partial statement')
          unless 3 == grep { ref $_ } ($s, $p, $o);

    my $ret = $g ? RDF::Trine::Statement::Quad->new($s, $p, $o, $g) :
        RDF::Trine::Statement->new($s, $p, $o);
    #warn $ret;

    _add_either($self->_pos, $s, $p, $o, $g);

    $ret;
}

=head2 dont_add_this { $S, $P, $O | $statement } [, $graph ]

Remove a statement, or set of terms, from the I<add> side of the patch.

=cut

sub dont_add_this {
    my $self = shift;
    my ($s, $p, $o, $g) = _validate(@_);
}

=head2 remove_this { $S, $P, $O | $statement } [, $graph ]

Add a statement, or set of terms, to the I<remove> side of the patch.

=cut

sub remove_this {
    my $self = shift;
    my ($s, $p, $o, $g) = _validate(@_);

    #warn Data::Dumper::Dumper([$s, $p, $o, $g]);

    Carp::croak('If you want to nuke the whole graph, just do that directly')
          unless 1 <= grep { ref $_ } ($s, $p, $o);

    my $ret = $g ? RDF::Trine::Statement::Quad->new($s, $p, $o, $g) :
        RDF::Trine::Statement->new($s, $p, $o);

    _add_either($self->_neg, $s, $p, $o, $g);

    $ret;
}

=head2 dont_remove_this { $S, $P, $O | $statement } [, $graph ]

Remove a statement, or set of terms, from the I<remove> side of the
patch.

=cut

sub dont_remove_this {
    my $self = shift;
    my ($s, $p, $o, $g) = _validate(@_);
}

=head2 to_add

In list context, returns an array of statements to add to the
graph. In scalar context, returns an L<RDF::Trine::Iterator>.

=cut

sub to_add {
    my $self = shift;
    my @out;
    _traverse($self->_pos, sub {
                  my $stmt = defined $_[3] ?
                      RDF::Trine::Statement::Quad->new(@_)
                        : RDF::Trine::Statement->new(@_[0..2]);
                  push @out, $stmt;
              });
    wantarray ? @out : RDF::Trine::Iterator->new(\@out, 'graph');
}

=head2 to_remove

In list context, returns an array of statements to remove from the
graph. In scalar context, returns an L<RDF::Trine::Iterator>.

=cut

sub to_remove {
    my $self = shift;
    my @out;
    _traverse($self->_neg, sub {
                  my $stmt = defined $_[3] ?
                      RDF::Trine::Statement::Quad->new(@_)
                        : RDF::Trine::Statement->new(@_[0..2]);
                  push @out, $stmt;
              });
    wantarray ? @out : RDF::Trine::Iterator->new(\@out, 'bindings');
}

=head2 apply { $model | $remove, $add }

Apply the patch to an L<RDF::Trine::Model> object. Statements are
removed first, then added. Transactions
(i.e. L<RDF::Trine::Model/begin_bulk_ops>) are your responsibility.

Alternatively, supply the C<remove> and C<add> functions directly:

  sub _remove_or_add {
    my ($subject, $predicate, $object, $graph) = @_;

    # do stuff ...

    # return value is ignored
  }

Inputs will be either L<RDF::Trine::Node> objects, or C<undef>, in the
case of C<remove>.

=cut

sub _node {
    my $x = shift;
    return $x eq '' ? undef : $x =~ /^_:(.*)/ ? bnode($1) : iri($x);
}

# holy lol @ this
sub _traverse {
    my ($structure, $callback) = @_;

    for my $gg (keys %{$structure}) {
        my $g = _node($gg);
        for my $ss (keys %{$structure->{$gg}}) {
            my $s = _node($ss);
            for my $pp (keys %{$structure->{$gg}{$ss}}) {
                my $gsp = $structure->{$gg}{$ss}{$pp};
                my $p = _node($pp);
                if (!ref $gsp or $gsp->[0]{''}) {
                    #warn 'lul';
                    $callback->($s, $p, undef, $g);
                }
                else {
                    for my $oo (keys %{$gsp->[0]}) {
                        my $o = _node($oo);
                        #warn "lul $o";
                        $callback->($s, $p, $o, $g);
                    }
                    for my $ld (keys %{$gsp->[1]}) {
                        my ($t, $v) = ($ld =~ /^(.)(.*)$/);
                        my @args = $t ? $t eq '@' ?
                            ($v, undef) : (undef, $v) : ();
                        # of course the datatype is always a string
                        # here so no need to check it for blessedness
                        for my $ll (keys %{$gsp->[1]{$ld}}) {
                            my $o = literal($ll, @args);
                            #warn 'lul';
                            $callback->($s, $p, $o, $g);
                        }
                    }
                }
            }
        }
    }
}

sub _apply {
    my ($self, $model) = @_;

    $model->begin_bulk_ops;

    _traverse($self->_neg, sub {
                  #warn join(' ', map { defined $_ ? $_ : '(undef)' } @_);
                  # fuuuuuuck this quad semantics shit
                  my @n = map { $_[$_] } (0..3);

                  #warn "found context $n[3]" if defined $n[3];

                  $model->remove_statements
                      (defined $n[3] ? @n[0..3] : @n[0..2]) });
    _traverse($self->_pos,
              sub {
                  #warn "found context $_[3]" if defined $_[3];
                  my $stmt = defined $_[3] ?
                      RDF::Trine::Statement::Quad->new(@_)
                            : RDF::Trine::Statement->new(@_[0..2]);
                  #warn $stmt->sse;
                  $model->add_statement($stmt);
              });

    $model->end_bulk_ops;

    1;
}

sub apply {
    my ($self, $remove, $add) = @_;

    # note remove may be a coderef or a model
    if (ref $remove eq 'CODE') {
        _traverse($self->_neg, $remove);
        _traverse($self->_pos, $add) if $add;
        return 1;
    }
    $self->_apply($remove) if Scalar::Util::blessed($remove);
}

=head1 SEE ALSO

=over 4

=item L<RDF::KV>

=item L<RDF::Trine::Model>

=item L<RDF::Trine::Statement>

=item L<RDF::Trine::Node>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

__PACKAGE__->meta->make_immutable;

1;

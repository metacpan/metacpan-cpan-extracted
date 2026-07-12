package Mojolicious::Plugin::Fondation::Model::DBIx::Async::ResultSet;
$Mojolicious::Plugin::Fondation::Model::DBIx::Async::ResultSet::VERSION = '0.03';
# ABSTRACT: Fondation ResultSet — with() for fluent prefetch (many_to_many + has_many)

use strict;
use warnings;
use base 'DBIx::Class::Async::ResultSet';

# ─── with() — declare relationships to prefetch ───────────────────────────
#
#   $rs->with('groups')            # many_to_many
#   $rs->with('orders')            # has_many
#   $rs->with('groups', 'orders')  # both at once
#
# Many_to_many relationships are discovered via the _fondation_many_to_many
# metadata hash (populated by many_to_many_async). Has_many relationships
# are discovered via DBIx::Class's has_relationship().
#
# All metadata is stored on the ResultSet and consumed by all(), find(),
# and (indirectly) search().

sub with {
    my ($self, @names) = @_;

    my $source  = $self->result_source;
    my $class   = $source->result_class
        or die "Cannot resolve result_class for source";

    no strict 'refs';
    my $mtm_meta = \%{ $class . '::_fondation_many_to_many' };

    for my $name (@names) {

        # 1. Check many_to_many registry
        if ($mtm_meta && (my $meta = $mtm_meta->{$name})) {
            # many_to_many → { pivot_rel => target_rel }
            $self->{_fondation_with}{ $meta->{rel} } = $meta->{f_rel};
            next;
        }

        # 2. Check DBIx::Class relationship
        if ($source->has_relationship($name)) {
            my $rel_info = $source->relationship_info($name);
            if (($rel_info->{attrs}{accessor} // '') eq 'multi') {
                # has_many → direct prefetch, no pivot
                push @{ $self->{_fondation_with_has_many} }, $name;
                next;
            }
            die "Relationship '$name' on $class is 'single' (belongs_to/might_have), "
                . "not a has_many or many_to_many";
        }

        die "No many_to_many or has_many relationship '$name' on $class";
    }

    return $self;
}

# ─── all() — execute query with prefetch if with() was called ─────────────

sub all {
    my ($self) = @_;
    return $self->SUPER::all
        unless $self->{_fondation_with} || $self->{_fondation_with_has_many};

    my $schema = $self->{_schema_instance};
    my $source = $self->result_source->source_name;
    my $cond   = $self->{_attrs}{where} // {};

    return $schema->search_with_prefetch($source, $cond, $self->_build_prefetch);
}

# ─── find() — single-row lookup with prefetch ─────────────────────────────
#
# DBIx::Class::Async::ResultSet::find() is a Future → single row.
# When prefetch is active, we use search_with_prefetch + collapse => 1
# to get the row with nested data in a single query, then return the
# first result (Future→row, matching the original find() contract).

sub find {
    my ($self, @args) = @_;
    return $self->SUPER::find(@args)
        unless $self->{_fondation_with} || $self->{_fondation_with_has_many};

    my $schema = $self->{_schema_instance};
    my $source = $self->result_source->source_name;

    # Build the condition from find() arguments (same dispatch as DBIC)
    my $cond;
    if (@args == 1 && !ref $args[0]) {
        # Single scalar → primary key lookup (qualify column for JOINs)
        my @pks = $self->result_source->primary_columns;
        $cond = { 'me.' . $pks[0] => $args[0] };
    }
    elsif (@args == 1 && ref $args[0] eq 'HASH') {
        $cond = $args[0];
    }
    else {
        # Multi-column PK or unknown → fall back to SUPER
        return $self->SUPER::find(@args);
    }

    return $schema->search_with_prefetch($source, $cond, $self->_build_prefetch)
        ->then(sub {
            my ($rows) = @_;
            return $rows && @$rows ? $rows->[0] : undef;
        });
}

# ─── search() — propagate with() metadata to the new ResultSet ────────────

sub search {
    my ($self, $cond, $attrs) = @_;
    my $rs = $self->SUPER::search($cond, $attrs);
    $rs->{_fondation_with}          = $self->{_fondation_with}
        if $self->{_fondation_with};
    $rs->{_fondation_with_has_many} = $self->{_fondation_with_has_many}
        if $self->{_fondation_with_has_many};
    return $rs;
}

# ─── _build_prefetch — merge many_to_many and has_many into one hashref ────

sub _build_prefetch {
    my ($self) = @_;
    my %prefetch = %{ $self->{_fondation_with} // {} };

    for my $rel (@{ $self->{_fondation_with_has_many} // [] }) {
        # has_many: direct prefetch, no nested relationship.
        # Don't overwrite if a many_to_many already set a nested
        # value for the same key (e.g. user_group => 'group').
        $prefetch{$rel} //= undef;
    }

    return \%prefetch;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Model::DBIx::Async::ResultSet - Fondation ResultSet — with() for fluent prefetch (many_to_many + has_many)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # many_to_many
  $c->model('user')->with('groups')->all;

  # has_many
  $c->model('user')->with('orders')->all;

  # both at once — single query
  $c->model('user')->with('groups', 'orders')->all;

  # chained with search
  $c->model('user')->with('groups')->search({ active => 1 })->all;

  # find() with prefetch — single query, returns row or undef
  $c->model('user')->with('groups')->find($id);

=head1 DESCRIPTION

C<Mojolicious::Plugin::Fondation::Model::DBIx::Async::ResultSet> extends
L<DBIx::Class::Async::ResultSet> with a C<with()> method that
declares relationships to prefetch. The C<all()> and C<find()>
overrides delegate to C<search_with_prefetch>, ensuring a single
query with all nested data.

C<with()> accepts one or more relationship names:

=over

=item *

B<many_to_many> — discovered via the C<_fondation_many_to_many>
package hash populated by L<DBIx::Class::Relationship::ManyToMany::Async>.
Stored as C<< { pivot => target } >> in the prefetch hash.

=item *

B<has_many> — discovered via L<DBIx::Class::ResultSource/has_relationship>
with C<accessor eq 'multi'>. Stored as C<< { relation => undef } >>,
meaning direct prefetch without nesting.

=item *

B<belongs_to / might_have> — rejected with a clear error. These
single-accessor relationships don't need prefetch (they're resolved
via a simple foreign key lookup).

=back

When the same key appears in both many_to_many and has_many
(e.g. C<with('groups', 'user_group')> where both resolve to the
C<user_group> pivot), the many_to_many value wins (C<//=> guard),
since its nested prefetch already includes the has_many data.

The C<search()> override propagates the prefetch metadata to the
new ResultSet, so chaining C<with(...)->search({...})->all> works
correctly.

The model helper in L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>
re-blesses every ResultSet into this class, making C<with()> available
on all C<< $c->model(...) >> calls.

=head1 NAME

Mojolicious::Plugin::Fondation::Model::DBIx::Async::ResultSet — fluent prefetch for DBIx::Class::Async

=head1 METHODS

=head2 with

  $rs = $rs->with(@relation_names);

Stores prefetch metadata on the ResultSet. Does not execute a query.
Returns C<$self> for chaining.

=head2 all

  my $rows = $schema->await($rs->with('groups')->all);

If C<with()> was called, delegates to C<search_with_prefetch> for a
single-query prefetch. Otherwise falls back to the standard
L<DBIx::Class::Async::ResultSet/all>.

=head2 find

  my $row = $schema->await($rs->with('groups')->find($id));

If C<with()> was called, uses C<search_with_prefetch> with a qualified
primary-key condition (C<me.id>) for a single-query lookup. Returns
the first row or C<undef>. Falls back to the standard C<find()> for
multi-column primary keys.

=head2 search

  my $new_rs = $rs->with('groups')->search({ active => 1 });

Returns a new ResultSet (same class) with the prefetch metadata copied.
Subsequent C<all()> or C<find()> will use the prefetch.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>,
L<DBIx::Class::Async::ResultSet>,
L<DBIx::Class::Relationship::ManyToMany::Async>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

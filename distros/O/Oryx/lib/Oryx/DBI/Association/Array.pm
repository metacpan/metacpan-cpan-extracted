package Oryx::DBI::Association::Array;

use Oryx::DBI::Association::Reference;

use base qw(Oryx::Association::Array);

sub create {
    my ($self, $query, $proto) = @_;
}

sub retrieve {
    my ($self, $query, $id) = @_;
}

sub update {
    my ($self, $query, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;
    my $sql = SQL::Abstract->new;

    my $lt_name = $self->link_table;
    my @lt_flds = $self->link_fields;

    unless (tied(@$value)) {
	my @list = @$value;
	$self->construct($obj);
	my $i = 0;
	grep { tied(@$value)->_set_created($i++, $_) } @list;
	my %lt_where = ($lt_flds[0] => $obj->id);
	my $stmnt = $sql->delete($lt_name, \%lt_where);
	my $sth = $obj->dbh->prepare($stmnt);
	my @bind = $sql->values(\%lt_where);
	$sth->execute(@bind);
	$sth->finish;

	tied(@$value)->deleted({});
	tied(@$value)->updated({});
    }

    my (@bind, %lt_fieldvals, %lt_where, $stmnt, $sth);
    if (%{tied(@$value)->deleted}) {
	%lt_where = ($lt_flds[0] => $obj->id, $lt_flds[2] => '');

	$stmnt = $sql->delete($lt_name, \%lt_where);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($index, $thing) = each %{tied(@$value)->deleted}) {
	    $lt_where{$lt_flds[2]} = $index;
	    @bind = $sql->values(\%lt_where);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(@$value)->deleted({});
    }

    if (%{tied(@$value)->created}) {
	@lt_fieldvals{@lt_flds} = ($obj->id, '', '');

	$stmnt = $sql->insert($lt_name, \%lt_fieldvals);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($index, $thing) = each %{tied(@$value)->created}) {
	    $lt_fieldvals{$lt_flds[1]} = defined $thing ? $thing->{id} : undef;
	    $lt_fieldvals{$lt_flds[2]} = $index;
	    @bind = $sql->values(\%lt_fieldvals);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(@$value)->created({});
    }

    if (%{tied(@$value)->updated}) {
	%lt_where = ( $lt_flds[0] => $obj->id, $lt_flds[2] => '' );
	%lt_fieldvals = ( $lt_flds[1] => '' );

	$stmnt = $sql->update($lt_name, \%lt_fieldvals, \%lt_where);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($index, $thing) = each %{tied(@$value)->updated}) {
	    $lt_fieldvals{$lt_flds[1]} = defined $thing ? $thing->{id} : undef;
	    $lt_where{$lt_flds[2]} = $index;
	    @bind = $sql->values(\%lt_fieldvals);
	    push @bind, $sql->values(\%lt_where);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(@$value)->updated({});
    }

    $self->update_backrefs($obj, @$value);

    $obj->dbh->commit;
}

sub delete {
    my $self = shift;
    my ($query, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;

    if ($self->constraint eq 'Composition') {
	# cascade the delete
	while (my $thing = pop @$value) {
	    $thing->delete;
	}
    } elsif ($self->constraint eq 'Aggregation') {
	# just clear the Array
	@$value = ();
    }

    $self->update(@_);
}

sub search {
    my ($self, $query) = @_;
}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj);

    my @list;
    if ($obj->{$assoc_name}) {
	@list = @{$obj->{$assoc_name}};
    }

    $obj->{$assoc_name} = [ ] unless $obj->{$assoc_name};
    tie @{$obj->{$assoc_name}}, __PACKAGE__, @args;

    if (@list) {
	my $i = 0;
	grep { tied(@{$obj->{$assoc_name}})->_set_created($i++, $_) } @list;

	my $tieobj = tied(@{$obj->{$assoc_name}});
	my $sql = SQL::Abstract->new;
	my $lt_name = $self->link_table;
	my @lt_flds = $self->link_fields;

	my %lt_where = ($lt_flds[0] => $obj->id);
	my $stmnt = $sql->delete($lt_name, \%lt_where);
	my $sth = $obj->dbh->prepare($stmnt);
	my @bind = $sql->values(\%lt_where);
	$sth->execute(@bind);
	$sth->finish;

	$tieobj->deleted({});
	$tieobj->updated({});
    }
}

# Fill an array ref with ids from the link table and order by 'meta'.
# The ids are each tied to a Reference value type which will retrieve
# the referenced object (lazy loading)
sub load {
    my ($self, $owner) = @_;

    my $lt_name = $self->link_table;
    my ($s_id_field, $t_id_field, $meta_field) = $self->link_fields;

    my (@fields, %where, @order);
    @fields = ($t_id_field, '_seq');
    $where{$s_id_field} = $owner->id;
    @order = ('_seq');

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->select($lt_name, \@fields, \%where, \@order);

    my $sth = $owner->dbh->prepare_cached($stmnt);
    $sth->execute(@bind);

    my $Array = [ ];
    my ($oid, $idx, @args);
    my @ids_seq = $sth->fetchall;
    for (my $x = 0; $x < @ids_seq; $x++) {
	$oid = $ids_seq[$x]->[0];
	$idx = $ids_seq[$x]->[1];
	@args = ($self, $oid);
	$Array->[$idx] = Oryx::DBI::Association::Reference->TIESCALAR(@args);
    }

    $sth->finish;
    return $Array;
}

sub fetch {
    my ($self, $thing, $owner) = @_;
    if (ref $thing eq 'Oryx::DBI::Association::Reference') {
	return $thing->FETCH();
    }
    return $thing;
}

sub store {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

sub link_fields {
    my $self = shift;
    return ("source_id", "target_id", '_seq');
}

1;
__END__

=head1 NAME

Oryx::DBI::Association::Array - DBI implementation of array asssociations

=head1 SYNOPSIS

See L<Oryx::Association::Array>.

=head1 DESCRIPTION

This is the implementation of L<Oryx::Association::Array> for use with L<Oryx::DBI> connections.

=head1 GUTS

This is just a quick run-down of implementation details as of this writing to help introduce users to the database internals. These details may change with future releases and might have changed since this documentation was written.

An array association is stored into the database as a separate table named for the tables linked and the role of the link:

  <source>_<role>_<target>

within the table there will be exactly three fields:

=over

=item source_id

This will be the ID field for the source table in the link.

=item target_id

This will be the ID field for the target table in the link.

=item _seq

This is used to order the links in the array. The ordering is unique for the tuple (source_id, _seq).

=back

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBI>, L<Oryx::Association::Array>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

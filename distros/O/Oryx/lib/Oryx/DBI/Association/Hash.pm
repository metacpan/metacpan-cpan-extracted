package Oryx::DBI::Association::Hash;

use Oryx::DBI::Association::Reference;

use base qw(Oryx::Association::Hash);

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

    my (@bind, %lt_fieldvals, %lt_where, $stmnt, $sth);
    if (%{tied(%$value)->deleted}) {
	%lt_where = ($lt_flds[0] => $obj->id, $lt_flds[2] => '');

	$stmnt = $sql->delete($lt_name, \%lt_where);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($key, $thing) = each %{tied(%$value)->deleted}) {
	    $lt_where{$lt_flds[2]} = $key;
	    @bind = $sql->values(\%lt_where);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(%$value)->deleted({});
    }

    if (%{tied(%$value)->created}) {
	@lt_fieldvals{@lt_flds} = ($obj->id, '', '');

	$stmnt = $sql->insert($lt_name, \%lt_fieldvals);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($key, $thing) = each %{tied(%$value)->created}) {
	    $lt_fieldvals{$lt_flds[1]} = defined $thing ? $thing->{id} : undef;
	    $lt_fieldvals{$lt_flds[2]} = $key;
	    @bind = $sql->values(\%lt_fieldvals);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(%$value)->created({});
    }

    if (%{tied(%$value)->updated}) {
	%lt_where = ( $lt_flds[0] => $obj->id, $lt_flds[2] => '' );
	%lt_fieldvals = ( $lt_flds[1] => '' );

	$stmnt = $sql->update($lt_name, \%lt_fieldvals, \%lt_where);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($key, $thing) = each %{tied(%$value)->updated}) {
	    $lt_fieldvals{$lt_flds[1]} = defined $thing ? $thing->id : undef;
	    $lt_where{$lt_flds[2]} = $key;
	    @bind = $sql->values(\%lt_fieldvals);
	    push @bind, $sql->values(\%lt_where);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(%$value)->updated({});
    }

    $self->update_backrefs($obj, values %$value);

    $obj->dbh->commit;
}

sub delete {
    my $self = shift;
    my ($query, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;

    if ($self->constraint eq 'Composition') {
	# composition, so cascade the delete
	foreach my $thing (values %$value) {
	    $thing->delete;
	}
    } elsif ($self->constraint eq 'Aggregation') {
	# aggregation so just clear the Hash
	%$value = ();
    }

    $self->update(@_);
}

sub search {

}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj);

    my %hash;
    if ($obj->{$assoc_name}) {
	%hash = %{$obj->{$assoc_name}};
    }

    $obj->{$assoc_name} = { } unless $obj->{$assoc_name};
    tie %{$obj->{$assoc_name}}, __PACKAGE__, @args;

    if (%hash) {
	warn "got prefil hash";
	while (my ($k, $v) = each %hash) {
	    warn "set_created $k => $v";
	    tied(%{$obj->{$assoc_name}})->_set_created($k, $v);
	}
    
	my $tieobj = tied(%{$obj->{$assoc_name}});
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

sub load {
    my ($self, $owner) = @_;

    my $lt_name = $self->link_table;
    my ($source_id, $target_id, $_key) = $self->link_fields;

    my (@fields, %where);
    @fields = ($target_id, $_key);

    $DEBUG && $self->_carp("load : OWNER => $owner, ID => ".$owner->id);

    $where{$source_id} = $owner->id;

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->select($lt_name, \@fields, \%where);

    my $sth = $owner->dbh->prepare_cached($stmnt);
    $sth->execute(@bind);

    my $Hash = { }; my @args;
    my @ids_keys = $sth->fetchall;
    for (my $x = 0; $x < @ids_keys; $x++) {
	@args = ($self, $ids_keys[$x]->[0]);
	tie $Hash->{$ids_keys[$x]->[1]},
	  'Oryx::DBI::Association::Reference', @args;
    }
    $sth->finish;

    return $Hash;

}

sub fetch {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

sub store {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

sub link_fields {
    my $self = shift;
    return ("source_id", "target_id", '_key');
}

1;
__END__

=head1 NAME

Oryx::DBI::Association::Hash - DBI implementation of hash associations

=head1 SYNOPSIS

See L<Oryx::Association::Hash>.

=head1 DESCRIPTION

This provdes an implementation of hash associations with connections made via L<Oryx::DBI>.

=head1 GUTS

This is just a quick run-down of implementation details as of this writing to help introduce users to the database internals. These details may change with future releases and might have changed since this documentation was written.

A hash association is stored into the database as a separate table named for the tables linked and the role of the link:

  <source>_<role>_<target>

within the table there will be exactly three fields:

=over

=item source_id

This will be the ID field for the source table in the link.

=item target_id

This will be the ID field for the target table in the link.

=item _key

This is the key used to identify the target from the source. This will be unique for the tuple (source_id, _key).

=back

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBI>, L<Oryx::Association::Hash>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

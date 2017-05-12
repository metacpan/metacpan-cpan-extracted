package Oryx::DBI::Association::Reference;

use base qw(Oryx::Association::Reference);

sub create {
    my ($self, $query, $proto) = @_;
}

sub retrieve {
    my ($self, $query, $id) = @_;
    push @{$query->{fields}}, $self->role
}

sub search {
    my ($self, $query) = @_;
    push @{$query->{fields}}, $self->role
}

sub update {
    my ($self, $query, $obj) = @_;
    my $accessor = $self->role;
    if (tied($obj->{$accessor})->changed) {
	my $sql = SQL::Abstract->new;

	my $s_table = $self->source->table;
	my $f_key = $self->role;
	my %fieldvals = ();
	my %where = (id => $obj->id);

	$fieldvals{$f_key} = $obj->$accessor->id;
	my ($stmnt, @bind) = $sql->update($s_table, \%fieldvals, \%where);

	my $sth = $obj->dbh->prepare($stmnt);
	$sth->execute(@bind);
	$sth->finish;
    }
}

sub delete {
    my $self = shift;
    my ($query, $obj) = @_;
    if ($self->constraint eq 'Composition') {
	my $accessor = $self->role;
	my $value = $obj->$accessor;
	$value->delete;
    }
    $self->update(@_);
}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj->{$self->role});
    tie $obj->{$assoc_name}, __PACKAGE__, @args;
}

1;
__END__

=head1 NAME

Oryx::DBI::Association::Reference - DBI implementation of reference associations

=head1 SYNOPSIS

See L<Oryx::Association::Reference>.

=head1 DESCRIPTION

This is an implementation of simple reference associations for connections made via the L<Oryx::DBI> class.

=head1 GUTS

This is just a quick run-down of implementation details as of this writing to help introduce users to the database internals. These details may change with future releases and might have changed since this documentation was written.

References are implemented as additional fields in the source table linking to the foreign table. The field will have the same name as the foreign table.

=head1 SEE ALSO

L<Oryx>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

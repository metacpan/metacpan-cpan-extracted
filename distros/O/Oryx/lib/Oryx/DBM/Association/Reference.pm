package Oryx::DBM::Association::Reference;

use base qw(Oryx::Association::Reference);

sub create {
    my ($self, $proto, $param) = @_;
}

sub retrieve {
    my ($self, $proto, $id) = @_;
    my $f_key = $self->class->table."_id";
    my $f_id  = $proto->{ $f_key };
    $proto->{ $f_key } = $self->class->dbm->get( $f_id )
      if defined $f_id;
}

sub update {
    my ($self, $proto, $obj) = @_;
    my $accessor = $self->role;
    if (tied($obj->{$accessor})->changed) {
	my $f_key = $self->class->table.'_id';
	if (ref($obj->$accessor)) {
	    $proto->{ $f_key } = $obj->$accessor->id;
	} else {
	    $proto->{ $f_key } = $obj->$accessor;
	}
    }
}

sub delete {
    my $self = shift;
    my ($proto, $obj) = @_;
    if ($self->constraint eq 'Composition') {
	# cascade the delete
	my $accessor = $self->role;
	$obj->$accessor->dbm->delete($obj->id);
    }
    $self->update(@_);
}

sub search {

}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args;
    if ($obj->{$assoc_name} and defined $obj->{$assoc_name}->{id}) {
	@args = ($self, $obj->{$assoc_name}->{id});
    } else {
	@args = ($self, $obj->{$self->class->table.'_id'});
    }
    tie $obj->{$assoc_name}, __PACKAGE__, @args;
}

1;
__END__

=head1 NAME

Oryx::DBM::Association::Reference - DBM implementation of reference associations

=head1 SYNOPSIS

See L<Oryx::Association::Reference>.

=head1 DESCRIPTION

This class implements the reference association for classes stored within L<Oryx::DBM> connections.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBM>, L<Oryx::Association::Reference>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

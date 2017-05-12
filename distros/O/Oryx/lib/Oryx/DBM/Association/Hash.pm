package Oryx::DBM::Association::Hash;

use Oryx::DBM::Association::Reference;

use base qw(Oryx::Association::Hash);
use Data::Dumper;
use Carp qw(carp);

our $DEBUG = 1;

sub create {
    my ($self, $proto, $param) = @_;
}

sub retrieve {
    my ($self, $proto, $id) = @_;
}

sub update {
    my ($self, $proto, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->{$accessor} || { };

    $proto->{$accessor} = { };
    @{ $proto->{$accessor} }{ keys %$value } = map { $_->id } values %$value;
    $DEBUG && $self->_carp("[update]: proto => '.$proto.' value => ".Dumper($proto->{$accessor}));

    if (%{tied(%$value)->deleted}) {
        while (my ($key, $thing) = each %{tied(%$value)->deleted}) {
            delete($proto->{$accessor}->{$key});
        }
        tied(%$value)->deleted({});
    }
    if (%{tied(%$value)->created}) {
        while (my ($key, $thing) = each %{tied(%$value)->created}) {
            $proto->{$accessor}->{$key} = defined $thing ? $thing->id : undef;
        }
        tied(%$value)->created({});
    }
    if (%{tied(%$value)->updated}) {
        while (my ($key, $thing) = each %{tied(%$value)->updated}) {
            $proto->{$accessor}->{$key} = defined $thing ? $thing->id : undef;
        }
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

    $obj->{$assoc_name} = { } unless $obj->{$assoc_name};
    tie %{$obj->{$assoc_name}}, __PACKAGE__, @args;

    $DEBUG && $self->_carp("constructed $obj, accessor => $assoc_name, returns => ".Dumper($obj->{$assoc_name}));
}

sub load {
    my ($self, $owner) = @_;

    my $Hash = { $owner->{$self->role} ? %{ $owner->{$self->role} } : () };
    my @args;
    foreach (keys(%$Hash)) {
	@args = ($self, $Hash->{$_});
	tie $Hash->{$_}, 'Oryx::DBM::Association::Reference', @args;
    }
    warn "Hash load => ".Dumper($Hash);
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

1;
__END__

=head1 NAME

Oryx::DBM::Association::Hash - DBM implementation of hash associations

=head1 SYNOPSIS

See L<Oryx::Association::Hash>.

=head1 DESCRIPTION

This class contains the implementation of hash associations for classes stored via an L<Oryx::DBM> connection.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBM>, L<Oryx::Association::Hash>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

package Oryx::DBM::Association::Array;

use Oryx::DBM::Association::Reference;
use Data::Dumper;

use base qw(Oryx::Association::Array);

our $DEBUG = 0;

sub create {
    my ($self, $proto, $param) = @_;
}

sub retrieve {
    my ($self, $proto, $id) = @_;
    $DEBUG && $self->_carp('[retrieve]: '.Dumper($proto));
}

sub update {
    my ($self, $proto, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->{$accessor} || [ ];

    $proto->{$accessor} = [ map { $_->{id} } @$value ];
    $DEBUG && $self->_carp("[update]: proto => '.$proto.' value => ".Dumper($proto->{$accessor}));

    if (%{tied(@$value)->deleted}) {
        while (my ($index, $thing) = each %{tied(@$value)->deleted}) {
            delete($proto->{$accessor}->[$index]); 
        }
        tied(@$value)->deleted({});
    }
    if (%{tied(@$value)->updated}) {
        while (my ($index, $thing) = each %{tied(@$value)->updated}) {
            $proto->{$accessor}->[$index] = defined $thing ? $thing->id : undef; 
        }
        tied(@$value)->updated({});
    }
    if (%{tied(@$value)->created}) {
        while (my ($index, $thing) = each %{tied(@$value)->created}) {
            $proto->{$accessor}->[$index] = defined $thing ? $thing->id : undef; 
        }
        tied(@$value)->created({});
    }

    $self->update_backrefs($obj, @$value);
}

sub delete {
    my $self = shift;
    my ($proto, $obj) = @_;
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

    $obj->{$assoc_name} = [ ] unless $obj->{$assoc_name};
    tie @{$obj->{$assoc_name}}, __PACKAGE__, @args;
 
    $DEBUG && $self->_carp("constructed $obj, accessor => $assoc_name, returns => ".Dumper($obj->{$assoc_name}));
}

sub load {
    my ($self, $owner) = @_;

    warn "IS THE ARRAY TIED? => ".tied($owner->{$self->role});
    # take a copy of the DBM array
    my $assoc_name = $self->role;
    my $Array = [ $owner->{$self->role} ? @{ $owner->{$self->role} } : () ];

    $DEBUG && $self->_carp('load: array => '.Dumper($Array).' owner => '.$owner);

    my @args;
    for (my $x = 0; $x < @$Array; $x++) {
	@args = ($self, $Array->[$x]);
	$Array->[$x] = Oryx::DBM::Association::Reference->TIESCALAR(@args);
    }

    return $Array;
}

sub fetch {
    my ($self, $thing, $owner) = @_;
    if (ref $thing eq 'Oryx::DBM::Association::Reference') {
	return $thing->FETCH();
    }
    return $thing;
}

sub store {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

1;
__END__

=head1 NAME

Oryx::DBM::Association::Array - DBM implementation or array associations

=head1 SYNOPSIS

See L<Oryx::Association::Array>.

=head1 DESCRIPTION

This class handles the implementation of array associations for connections using L<Oryx::DBM>.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBM>, L<Oryx::Association::Array>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

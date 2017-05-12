package Oryx::DBI::Attribute;

use Oryx::Value;

use base qw(Oryx::Attribute);

sub create {
    my ($self, $query, $param) = @_;
    my $attr_name = $self->name;
    $param->{$attr_name} = $self->deflate($param->{$attr_name});
}

sub retrieve {
    my ($self, $query, $values) = @_;
    push @{$query->{fields}}, $self->name;
}

sub update {
    my ($self, $query, $object) = @_;
    my $attr_name = $self->name;
    my $value = $object->$attr_name;
    $query->{fieldvals}->{$attr_name} = $self->deflate($value);
}

sub search {
    my ($self, $query) = @_;
    push @{$query->{fields}}, $self->name;
}

1;
__END__

=head1 NAME

Oryx::DBI::Attribute - DBI implementation of attributes

=head1 SYNOPSIS

See L<Oryx::Attribute>.

=head1 DESCRIPTION

This class provides the implementation of attributes for Oryx classes stored via an L<Oryx::DBI> connection.

=head1 GUTS

This is just a quick run-down of implementation details as of this writing to help introduce users to the database internals. These details may change with future releases and might have changed since this documentation was written.

Each attribute is stored in a field with the name given. The types used will be the type determined by the C<type2sql()> method of the appropriate L<Oryx::DBI::Util> implementation for the current connection. 

The work of serializing and unserializing data is handled by L<Oryx::Value> implementations while this class handles the work of making sure the data is actually stored and loaded when requested.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBI>, L<Oryx::Attribute>, L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

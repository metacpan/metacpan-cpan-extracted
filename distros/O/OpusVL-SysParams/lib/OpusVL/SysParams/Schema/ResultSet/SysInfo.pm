package OpusVL::SysParams::Schema::ResultSet::SysInfo;

use Moose;
extends 'DBIx::Class::ResultSet';
use JSON;


sub ordered
{
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search(undef, {
        order_by => ["$me.label", "$me.name"],
    });
}



sub set
{
	my $self  = shift;
	my $name  = shift;
	my $value = shift;
    my $data_type = shift;

	my $info = $self->find_or_new({
        name  => $name,
    });

    $info->set_column(value => JSON->new->allow_nonref->encode($value));
    if ($data_type) {
        $info->set_column(data_type => $data_type);
    }

    if (! $info->data_type) {
        $info->set_type_from_value($value);
    }

    $info->update_or_insert;

	return $value;
}

sub get
{
	my $self = shift;
	my $name = shift;

	my $info = $self->find
	({
		name => $name
	});

	return $info ? JSON->new->allow_nonref->decode($info->value) : undef;
}

sub del 
{
	my $self = shift;
	my $name = shift;

	my $info = $self->find
	({
		name => $name
	});

	return $info ? $info->delete : undef;
}

sub key_names
{
    my $self = shift;

    return $self->search(undef, { order_by => 'name' })->get_column('name')->all;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::SysParams::Schema::ResultSet::SysInfo

=head1 VERSION

version 0.20

=head1 SYNOPSIS

This is the ResultSet that actually stores and gets results from DBIx::Class.

    $schema->resultset('SysInfo')->set('test.param', 1);
    $schema->resultset('SysInfo')->get('test.param');
    $schema->resultset('SysInfo')->del('test.param');

This is used by the L<OpusVL::SysParams> object.

=head1 METHODS

=head2 get

Get a system parameter. The key name will only be meaningful if the same string
has already been provided to L</set> at some point in the past, or created via
the L<OpusVL::AppKitX::SysParams> interface.

=head2 set

=over

=item B<$name>

=item B<$value>

=item B<$data_type>

=back

Set a system parameter.  The key name is simply a string.  It's suggested you use some 
kind of schema like 'system.key' to prevent name clashes with other unoriginal programmers.

The value and data type should correspond. A guess will be made, if you don't
provide the data type. Any value that can be JSON-encoded should work (i.e. no
CODE refs), but see L<OpusVL::SysParams::Schema::Result::SysInfo> for the list
of options for data type, and hence value type.

=head2 del

Delete a system parameter.

=head2 key_names

Returns the keys of the system parameters.

=head2 ordered

Returns a resultset with an ordering applied.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2016 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

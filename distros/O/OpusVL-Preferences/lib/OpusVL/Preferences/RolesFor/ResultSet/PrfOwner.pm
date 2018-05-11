
package OpusVL::Preferences::RolesFor::ResultSet::PrfOwner;

use strict;
use warnings;
use Moose::Role;
use Carp;

sub prf_get_default
{
	my $self = shift;
	my $name = shift;

	my $defaults = $self->prf_defaults;

	return
		unless defined $defaults;

	my $def = $defaults->find ({ name => $name });

	return 
		unless defined $def;

	return $def->default_value;
}

sub prf_set_default
{
	my $self  = shift;
	my $name  = shift;
	my $value = shift;
	
	$self->setup_owner_type;
	$self->prf_defaults->update_or_create
	({
		name          => $name,
		default_value => $value
	});
}

sub setup_owner_type
{
	my $self   = shift;
	my $schema = $self->result_source->schema;
	my $source = $self->result_source;

	return $schema->resultset ('PrfOwnerType')->setup_from_source ($source);
}

sub get_owner_type
{
	my $self   = shift;
	my $schema = $self->result_source->schema;
	my $source = $self->result_source;

	return $schema->resultset ('PrfOwnerType')->get_from_source ($source);
}

sub prf_defaults
{
	my $self   = shift;
	my $schema = $self->result_source->schema;
	my $type   = $self->setup_owner_type;      # we always want a result here

	return $type->prf_defaults;
}

sub prf_preferences
{
    my $self = shift;
    return $self->search_related('prf_owner')->search_related('prf_preferences');
}

sub with_fields
{
    my ($self, $args) = @_;

    my @params;
    my @joins;
    my $x = 1;
    # well this sucks, we need to figure out if these are encrypted fields.
    # we can't do this entirely at the DB layer.
    my $schema = $self->result_source->schema;
    my $crypto = $schema->encryption_client;
    if($crypto)
    {
        # no point in checking for encryption unless we have a crypto object setup.
        my $fields = $self->prf_defaults->search({ 
            name => { -in => [keys %$args] }, 
            encrypted => 1,
        });
        for my $f ($fields->all)
        {
            # encrypt the values.
            # since this is a search do it deterministicly
            # this won't find values for fields that weren't encrypted deterministicly
            # but we can't find them anyway, so this will effectively fail closed.
            # which is about as good as it gets.
            # we could emit a warning when they try to search one of those fields though.
            unless($f->unique_field || $f->searchable)
            {
                my $name = $f->name;
                carp "Field $name is being searched for it's encrypted and does not have the searchable flag set so we will probably not find any results.";
            }
            $self->_encrypt_query_values($crypto, $args, $f->name);
        }
    }
    for my $name (keys %$args)
    {
        my $alias = $x == 1 ? "prf_preferences" : "prf_preferences_$x";
        my $value = $args->{$name};
        push @params, {
            "$alias.name" => $name,
            "$alias.value" => $value,
        };
        push @joins, 'prf_preferences';
        $x++;
    }
    return $self->search({ -and => \@params }, {
        join => { prf_owner => \@joins }
    });
}

sub select_extra_fields
{
    my ($self, @names) = @_;

    my @params;
    my @joins;
    my $x = 1;
    my %aliases;
    for my $name (@names)
    {
        my $alias = $x == 1 ? "_by_name" : "_by_name_$x";
        push @params, $name;
        push @joins, '_by_name';
        $aliases{$name} = $alias;
        $x++;
    }
    my $rs = $self->search(undef, {
        bind => \@params,
        join => { prf_owner => \@joins },
    });
    return { rs => $rs, aliases => \%aliases };
}

sub prefetch_extra_fields
{
    my ($self, @names) = @_;

    my @params;
    my @joins;
    my $x = 1;
    my %aliases;
    my @columns;
    for my $name (@names)
    {
        my $alias = $x == 1 ? "_by_name" : "_by_name_$x";
        push @params, $name;
        push @columns, { "extra_$name" => "$alias.value" };
        push @joins, '_by_name';
        $aliases{$name} = $alias;
        $x++;
    }
    my $rs = $self->search(undef, {
        bind => \@params,
        # Doing this manually since prefetch tries to be too clever
        # by collapsing stuff and then providing no way to get to the dat
        # as it doesn't consider multiple joins of the same relationship
        # to be sane.
        # Also our data should be flat (there should only be 1 or 0 row we're joining to
        # so we don't need to do that collapse business.
        join => { prf_owner => \@joins },
        '+columns' => \@columns,
    });
    return { rs => $rs, aliases => \%aliases };
}

sub join_by_name
{
    my $self = shift;
    my $name = shift;
    $self->search(undef, {
        join => [{ 'prf_owner' => '_by_name' }],
        bind => [ $name ],
    });
}

sub validate_extra_parameter
{
    my $self = shift;
    my $field = shift;
    my $params = shift;
    my $unique_validator = shift;
    my $id = shift;

    if($field->required)
    {
        return 'Must specify ' . $field->name unless exists $params->{$field->name};
    }
    if($field->unique_field)
    {
        # check to see if it's unique
        my $p = {
            prf_owner_type_id => $field->prf_owner_type_id,
        };
        $p->{id} = $id if $id;
        my $error = $unique_validator->validate('global_fields_' . $field->name, 
                                                $params->{$field->name}, $p, 
                                                { label => $field->comment });
        return $error if $error;
    }
    # FIXME: ought to check types.
}

sub validate_extra_parameters
{
    my $self = shift;
    my $params = shift;
    my $unique_validator = shift;
    my $id = shift;

    # check them against their defaults.
    my @fields = $self->prf_defaults->active;
    for my $field (@fields)
    {
        my $error = $self->validate_extra_parameter($field, $params, $unique_validator, $id);
        return $error if $error;
    }
}

sub _encrypt_query_values
{
    my $self = shift;
    my $crypto = shift;
    my $hash = shift;
    my $new_key = shift;
    my $val = $hash->{$new_key};

    if(ref $val eq 'HASH')
    {
        my @ops = keys %$val;
        for my $op (@ops)
        {
            if($op =~ /-?ident/)
            {
                # skip this.
                return;
            }
            if(ref $val->{$op} eq 'ARRAY')
            {
                my @encrypted = map { 
                    $crypto->encrypt_deterministic($_) 
                } @{$val->{$op}};
                $val->{$op} = \@encrypted;
            }
            elsif(ref $val->{$op} eq 'HASHREF')
            {
                # I have no idea what to do with this.
                # going to stop here.
                carp 'Unrecognised search query, not encrypting possible reference to token number';
            }
            elsif(!ref $val->{$op})
            {
                # convert what we assume is a single value.
                my $value = $val->{$op};
                if($op =~ /like/i)
                {
                    # NOTE:
                    # this could cause some fun and games.
                    $value =~ s/[%?]//g;
                }
                my $enc = $crypto->encrypt_deterministic($value);
                $val->{$op} = $enc;
            }
        }
    }
    else
    {
        my $new_value = $crypto->encrypt_deterministic($val);
        $hash->{$new_key} = $new_value;
    }
}


return 1;


=head1 DESCRIPTION

=head1 METHODS

=head2 prf_get_default

=head2 prf_set_default

=head2 setup_owner_type

=head2 get_owner_type

=head2 prf_defaults

=head2 with_fields

Searches the objecs with fields that match.  Pass it a hash of 
name => value pairs and it will return a resultset of all 
the owners that match all the requirements.  If you want to use 
ilikes, you can, just like regular DBIC searches.  It will figure
out the hard relationship stuff for you.

    my $rs = Owner->with_fields({ 
        'simple_test' => 'test',
        'second_test' => { -ilike => 'test2' },
    });

=head2 validate_extra_parameters

=head2 validate_extra_parameter

=head2 join_by_name

Returns a resultset joined to the preferences with the name specified.

    $rs->join_by_name('test');

=head2 select_extra_fields

Returns a resultset joined to the preferences with the names specified.
Similar to join_by_name but it makes multiple joins for each name.

It returns the new resultset and a list of the field -> aliases so that
you can then do whatever you want with them.

    my $info = $rs->select_extra_fields('test', 'test2');
    my $new_rs = $info->{rs};
    my $aliases = $info->{aliases};

=head2 prefetch_extra_fields

Select the extra fields when searching the resultset.
It select's them as C<extra_$fieldname>.  These values are
accessible via C<get_column>

It returns a hashref like L<select_extra_fields> with rs and an alias map.

    my $info = $rs->prefetch_extra_fields('field1', 'field2');
    my $new_rs = $info->{rs};
    my @all = $new_rs->all;
    my $field1 = $all[0]->get_column('extra_field1');

=head2 prf_preferences

Returns a resultset of all the preferences relating to this type of PrfOwner.

=head1 ATTRIBUTES


=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

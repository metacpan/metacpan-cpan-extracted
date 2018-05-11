
package OpusVL::Preferences::RolesFor::Result::PrfOwner;

=head1 DESCRIPTION

If you are using DBIx::Class::Schema::Loader add the necessary link fields manually, otherwise 
add the following line to add the fields to your result class.

    __PACKAGE__->prf_owner_init;

=head1 SYNOPSIS

=head1 METHODS

=head2 prf_owner_init

Tries to add the columns and relationships for your result class.  Call it like this,

    __PACKAGE__->prf_owner_init;

Your mileage may vary.

=head2 prf_defaults

ResultSet for the defaults.

=head2 prf_preferences

ResultSet of the preference values.

=head2 prf_get

Gets the setting.  If the object doesn't have the setting specified but there is a 
default, the default will be returned.

=head2 prf_set

Sets the setting for the object.

=head2 prf_reset

Resets the settings against the object.  prf_get may still return a value if there is a default 
for the setting.

=head2 preferences_to_array

Returns an array of the current results preferences.

    $object->preferences_to_array();
    # [{
    #     name => $_->name, 
    #     value => $_->value,
    #     param => # assocaited PrfDefault parameter definition.
    # } ];

=head2 safe_preferences_in_array

Returns the same as preferences_to_array but instead of the param object it returns the 
field label.  The safe refers to the fact that all the items in the hash are base types
and therefore are trivially serializable.

=head2 safe_prefs_to_hash

Returns the same as safe_prefs_to_hash but converts it to a hash for easier use.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2011 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

use strict;
use warnings;
use Moose::Role;

=head2 prf_id_column

Provides the default column that contains the preferences identifier.

If your Result doesn't have a standard integer primary key called 'id', override
this with the name of another column that I<is> an identifying integer

=cut

sub prf_id_column {'id'}

sub prf_owner_init
{
	my $class = shift;

	$class->add_columns
	(
		prf_owner_type_id =>
		{
			data_type      => 'integer',
			is_nullable    => 1,
			is_foreign_key => 1
		}
	);

	$class->belongs_to
	(
		prf_owner => 'OpusVL::Preferences::Schema::Result::PrfOwner',
		{
			'foreign.prf_owner_id'      => 'self.' . $class->prf_id_column,
			'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
		}
	);

	$class->belongs_to
	(
		prf_owner_type => 'OpusVL::Preferences::Schema::Result::PrfOwnerType',
		{
			'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
		}
	);
}

after insert => sub
{
	my $self   = shift;
	my $schema = $self->result_source->schema;
	my $type   = $schema->resultset ('PrfOwnerType')->setup_from_source ($self->result_source);

	# Ensure that any auto-generated values have been populated (in case the
	# prf_id column is not a primary key)
	$self->discard_changes;
	my $prf_id_column = $self->prf_id_column;
	$schema->resultset('PrfOwner')->create
	({
		prf_owner_id      => $self->$prf_id_column,
		prf_owner_type_id => $type->prf_owner_type_id
	});
	
	$self->update ({ prf_owner_type_id => $type->prf_owner_type_id });
};

sub prf_defaults
{
	my $self = shift;

	return $self->prf_owner_type->prf_defaults;
}

sub prf_preferences
{
	# this could maybe be achieved with a proper DBIx::Class relationship, but
	# this will do for now

	my $self = shift;

	return $self->prf_owner->prf_preferences;
}

sub preferences_to_array
{
    my $self = shift;

    my $preferences = $self->prf_preferences;
    my @expanded;
    for my $pref ($preferences->all)
    {
        my $param = $self->prf_defaults->find({ name => $pref->name });
        push @expanded, {
            name => $pref->name, 
            value => $param->decryption_routine->($pref->value),
            param => $param,
        };
    }
    my @d = sort { 
        $a->{param}->display_order <=> $b->{param}->display_order 
    } @expanded;
    return \@d;
}

sub safe_preferences_in_array
{
    my $self = shift;
    my $extra_params = $self->preferences_to_array;
    my @cleaned_up = map { { 
        name => $_->{name},
        value => $_->{value},
        label => $_->{param}->comment,
    } } @$extra_params;
    return \@cleaned_up;
}

sub safe_prefs_to_hash
{
    my $self = shift;
    my $info = $self->safe_preferences_in_array;
    my %hash = map { $_->{name} => $_->{value} } @$info;
    return \%hash;
}

sub prf_get
{
	my $self = shift;
	my $name = shift;

	my $default = $self->prf_defaults->search ({ name => $name })->first;
    die "Field $name not setup" unless $default;

	my $pref = $self->prf_preferences->search ({ name => $name })->first;
    my $value;
    $value = $pref->value if $pref;
    if($default->encrypted)
    {
        if($pref)
        {
            my $schema = $self->result_source->schema;
            my $crypto = $schema->encryption_client;
            if($crypto)
            {
                $value = $crypto->decrypt($value);
            }
        }
    }
    return $value if defined $value;

    # FIXME: should probably look at encrypting defaults,
    # although, then again, do we need to?
	return $default->default_value
		if defined $default;

	return;
}

sub _clear_out_inactive_unique_values
{
    my $self = shift;
    my $prefname = shift;
    my $field = shift;

    my $schema = $self->result_source->schema;
    my $obj_rs = $schema->resultset($self->prf_owner_type->owner_resultset);
    if($obj_rs->can('inactive_for_unique_params'))
    {
        my $rs = $obj_rs->inactive_for_unique_params;
        $rs->search_related('prf_owner')->search_related('prf_preferences', 
           { 
               "prf_preferences.name" => $prefname, 
               "prf_preferences.prf_owner_type_id" => $field->prf_owner_type_id, 
           }
        )->search_related('unique_value')->delete;
    }
}

sub prf_set
{
	my $self     = shift;
	my $prefname = shift;
	my $value    = shift;

	my $allprefs = $self->prf_preferences;
	
	my $pref = $allprefs->search ({ name => $prefname })->first;
	my $field = $self->prf_defaults->search ({ name => $prefname })->first;
	unless($field)
	{
		die "Field $prefname not setup.";
	}

    if($field->encrypted)
    {
        my $schema = $self->result_source->schema;
        my $crypto = $schema->encryption_client;

        # if we need to search or ensure unique values,
        # then we have to use deterministic encryption
        # which is less secure, but still encrypted.

        if($crypto)
        {
            if($field->unique_field || $field->searchable)
            {
                $value = $crypto->encrypt_deterministic($value);
            }
            else
            {
                $value = $crypto->encrypt($value);
            }
        }
    }
	if ($pref)
	{
		$pref->update ({ value => $value });

        if($field->unique_field)
        {
            $self->_clear_out_inactive_unique_values($prefname, $field);
            my $unique_val = $pref->unique_value;
            if($unique_val)
            {
                my $place_holder = $value;
                if($field->data_type eq 'email')
                {
                    $place_holder = lc $value; 
                }
                $unique_val->value($place_holder);
                $unique_val->update;
            }
            else
            {
                $pref->create_related('unique_value', { value => $value });
            }
        }
	}
	else
	{
        my $data = {
			name  => $prefname,
			value => $value
		};
        if($field->unique_field)
        {
            $self->_clear_out_inactive_unique_values($prefname, $field);
            my $place_holder = $value;
            if($field->data_type eq 'email')
            {
                $place_holder = lc $value; 
            }
            $data->{unique_value} = { value => $place_holder };
        }
		$allprefs->create($data);
	}
}

sub prf_reset
{
	my $self = shift;
	my $name = shift;

    my $val = $self->prf_preferences->search ({ 'me.name' => $name });
    $val->search_related('unique_value')->delete;
	$val->delete;
}

return 1;


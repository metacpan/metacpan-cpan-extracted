
package OpusVL::Preferences::Schema::Result::PrfDefault;

use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
use OpusVL::Text::Util qw/mask_text/;

extends 'DBIx::Class::Core';

__PACKAGE__->table("prf_defaults");

__PACKAGE__->add_columns
(
	prf_owner_type_id =>
	{
		data_type   => "integer",
		is_nullable => 0,
	},

	name =>
	{
		data_type   => "varchar",
		is_nullable => 0,
	},

	default_value =>
	{
		data_type   => "varchar",
		is_nullable => 0,
	},

	data_type =>
	{
		data_type   => 'varchar',
		is_nullable => 1
	},

	comment =>
	{
		data_type   => 'varchar',
		is_nullable => 1
	},

    required =>
    {
        data_type => 'boolean',
        is_nullable => 1,
        default_value => 0,
    },
    active => 
    {
        data_type => 'boolean',
        is_nullable => 1,
        default_value => 1,
    },
    hidden => 
    {
        data_type => 'boolean',
        is_nullable => 1,
    },
    gdpr_erasable =>
    {
        data_type => 'boolean',
        is_nullable => 1,
    },

    audit => {
        data_type => 'boolean',
        is_nullable => 1,
    },

    display_on_search => 
    {
        data_type => 'boolean',
        is_nullable => 1,
    },
    searchable =>
    {
        data_type => 'boolean',
        default_value => 1,
        is_nullable => 0,
    },
    # note: this isn't stricly enforced by the module.
    # NOTE: might need to switch this to validator class
    unique_field => 
    {
        data_type => 'boolean',
        is_nullable => 1,
    },
    ajax_validate => 
    {
        data_type => 'boolean',
        is_nullable => 1,
    },

    display_order => 
    {
        data_type => 'int',
        is_nullable => 0,
        default_value => 1,
    },
    confirmation_required =>
    {
        data_type => 'boolean',
        is_nullable => 1,
    },
    encrypted => 
    {
        data_type => 'boolean',
        is_nullable => 1,
    },

	display_mask =>
	{
		data_type   => 'varchar',
		is_nullable => 0,
        default_value => '(.*)',
	},
	mask_char =>
	{
		data_type   => 'varchar',
		is_nullable => 0,
        default_value => '*',
	},
);


__PACKAGE__->set_primary_key(qw/prf_owner_type_id name/);
__PACKAGE__->has_many
(
	values => "OpusVL::Preferences::Schema::Result::PrfDefaultValues",
	{
		"foreign.name"      => "self.name",
		"foreign.prf_owner_type_id" => "self.prf_owner_type_id",
	},
);

__PACKAGE__->has_many
(
	preferences => "OpusVL::Preferences::Schema::Result::PrfPreference",
	{
		"foreign.name"      => "self.name",
		"foreign.prf_owner_type_id" => "self.prf_owner_type_id",
	},
);


__PACKAGE__->belongs_to
(
	owner_type => 'OpusVL::Preferences::Schema::Result::PrfOwnerType',
	{
		'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
	}
);

sub form_options
{
    my $self = shift;
    my @options = map { [ $_->value, $_->value ] } $self->values->sorted;
    return \@options;
}

sub hash_key
{
    my $self = shift;
    return $self->name;
}

# FIXME: deal with encryption.

around update => sub {
    my $orig = shift;
    my $self = shift;
    my $update = shift;
    $update  //= {};
    $self->set_inflated_columns($update);

    my $schema = $self->result_source->schema;
    my $txn = $schema->txn_scope_guard;
    my %updated_columns = ($self->get_dirty_columns);
    $self->$orig;
    if(exists $updated_columns{unique_field})
    {
        my $obj_rs = $schema->resultset($self->owner_type->owner_resultset);
        if($self->unique_field)
        {
            # create the unique values
            my $rs = $obj_rs;
            if($obj_rs->can('active_for_unique_params'))
            {
                $rs = $obj_rs->active_for_unique_params;
            }
            my $params = $rs->search_related('prf_owner')->search_related('prf_preferences', 
                { 
                    "prf_preferences.name" => $self->name, 
                }
            );
            # this kind of sucks, it would be a lot neater to do an insert based on the query.
            # perhaps I could do a select and get the query then do the insert simply?
            map { $_->create_related('unique_value', { value => $_->value }) } $params->all;
        }
        else
        {
            # wipe them out.
            $self->preferences->search_related('unique_value')->delete;
        }
    }
    $txn->commit;
};

sub decryption_routine
{
    my $self = shift;
    if($self->encrypted)
    {
        my $schema = $self->result_source->schema;
        my $crypto = $schema->encryption_client;
        if($crypto)
        {
            return sub { return $crypto->decrypt(shift) };
        }
    }
    return sub { shift; };
}

sub encryption_routine
{
    my $self = shift;
    if($self->encrypted)
    {
        my $schema = $self->result_source->schema;
        my $crypto = $schema->encryption_client;
        if($crypto)
        {
            if($self->unique_value || $self->searchable)
            {
                return sub { return $crypto->decrypt(shift) };
            }
        }
    }
    return sub { shift; };
}

sub mask_function
{
    my $self = shift;
    return sub {
        my $val = shift;
        return $val unless length $self->mask_char;
        return mask_text($self->mask_char, $self->display_mask, $val);
    };
}

return 1;

=head1 DESCRIPTION

This table, despite its name, actually holds the field I<definitions> for the
preferences.

Each field definition is stored against the prf_owner_types table, which maps
the host schema's table and resultset class to an internal ID.

Thus we define the fields available to a prf_owner, different per type.

=head1 METHODS

=head2 form_options

=head1 ATTRIBUTES

=head2 values

=head2 prf_owner_type_id

=head2 name

=head2 default_value

=head2 data_type

=head2 comment

=head2 required

=head2 active

=head2 hidden

=head2 hash_key

Returns a string convenient for use in hashes based on the parameter name.

=head2 encrypted

A flag indicating if the field is encrypted.  This requires the symmetric encryption 
keys to be setup on the Schema object.

Note that methods like C<prefetch_extra_fields> and C<select_extra_fields> will return
the value encrypted and you will need to decrypt the values yourself.

This can be done like this,

    $schema->crypto->decrypt($r->value);

Searches using with_fields will work if the field has either of the
properties, C<searchable> or C<unique_field> set.  They will switch
the encryption to use a deterministic mode which will allow searches of full
values to work.  Partial value searching will not.

If you're searching the dataset manually you will need to encrypt your search
term with the C<encrypt_deterministic> function.

    $schema->crypto->encrypt_deterministic($val);

The prf_get and prf_set functions will deal with the encryption seamlessly.

Changing this flag on an existing dataset, or the other flags will not cause
any data to be encrypted or decrypted.  You will need to do that sort of 
maintenance manually.

=head2 decryption_routine

Returns a subref with code to decrypt a value for storage.  If encryption is
not turned on or configured this will simply return the raw value.

=head2 encryption_routine

Returns a subref with code to encrypt a value for storage.  If encryption is
not turned on or configured this will simply return the raw value.

=head2 display_mask

Display mask for sensitive fields.  A regex specifying which characters to display
and which to mask out.  Use captures to identify the characters to display, the rest
will be masked out.

For instance, '(\d{3}).*(\d{4})' will display the first 3 digits, and the last 4.

Note that if the regex does not match at all it will blank out the whole string.

The default is set to (.*) which means no characters are hidden out of the box.

Note that this won't save you from security bugs in your own code, only leaks
of valid outputs from your programs.

=head2 mask_char

Character to use when masking out sensitive data.

Defaults to *

=head2 mask_function

Provides a subref that will mask values of this field.

    my $mask = $field->mask_function;
    $mask->($value->value);

=cut

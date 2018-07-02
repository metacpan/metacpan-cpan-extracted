package OpusVL::FB11X::Preferences::Role::ParameterValueEditing;

use 5.010;
use Moose::Role;
use Switch::Plain 'sswitch';

sub add_prefs_defaults
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    my $defaults = $args->{defaults};
    my $resultset = $args->{resultset};
    my $object = $args->{object};

    my $field_rs = $resultset ? $resultset->prf_defaults : $object->prf_defaults;
    my @fields = $field_rs->active->all;
    for my $field (@fields)
    {
        my $value;
        if($object) {
            $value = $object->prf_get($field->name);
        } else {
            $value = $field->default_value;
        }
        if($field->can('confirmation_required') && $field->confirmation_required)
        {
            $defaults->{'confirm_global_fields_' . $field->name} = $value;
        }
        $defaults->{'global_fields_' . $field->name} = $value;
    }
    return $defaults;
}

# DEBT: I don't know how to decouple this from the token processor because it's
# doing audit trail stuff. The Brain architecture needs to be more mature to do
# that.
sub update_prefs_values
{
    my ($self, $c, $object) = @_;

    # FIXME: to use two methods below instead.
    my $form = $c->stash->{form};
    my @fields = $object->prf_defaults->active->all;
    my $params = OpusVL::FB11::Hive->service('sysparams')->for_component('preferences');

    for my $field (@fields)
    {
        my $name = $field->name;
        my $value = $form->param_value('global_fields_' . $name);
        unless($object->prf_get($name) eq $value)
        {
            if ($field->audit) {
                #my $url = $c->uri_for(
                #    $c->controller('Modules::TokenFunctions')
                #        ->action_for('view', [ $object->id ])
                #);

                my $details = {
                    evt_type => 'pref_change',
                    fmt_args => {
                        token => $object->safe_name,
                        field => $field->name,
                        encrypted_data => $field->encrypted,
                    },
                };
                unless($field->encrypted)
                {
                    $details->{fmt_args}->{old_value} = $object->prf_get($name);
                    $details->{fmt_args}->{new_value} = $value;
                }
                $object->evt_raise_event($details);
            }

            if (($params->get('audit.email.alerts')||'') =~ /yes/i) {
                my $phone_field = $params->get('audit.phone.field');
                if ($field->name eq 'email' or $field->name eq $phone_field) {
                    #($self, $c, $event, $user, $outlet, $amount, $transaction_type, $token, $to)
                    my $to = $field->name eq 'email' ? $object->prf_get('email') : $value;

                    if ($field->name eq $phone_field) { $object->prf_set($name, $value); }
                    # DEBT: We need a mail service in the hive
                    $c->controller('TokenFunctions')->_send_email(
                        $c,
                        undef,
                        $c->user,
                        undef,
                        undef,
                        'audit_' . $field->name,
                        $object,
                        $object->prf_get('email'),
                    );
                }
            }
            $object->prf_set($name, $value);
        }
    }
}

sub get_prefs_values_from_form
{
    my ($self, $c, $object) = @_;

    my @fields = $object->prf_defaults->active->all;
    return $self->collect_values_from_form($c, @fields);
}

sub collect_values_from_form
{
    my ($self, $c, @fields) = @_;
    return $self->collect_values_from_form_ex($c, {}, @fields);
}

sub collect_values_from_form_ex
{
    my ($self, $c, $args, @fields) = @_;
    my $form = $c->stash->{form};
    $args //= {};
    $args->{prefix} //= 'global_fields_';

    my $values = {};

    for my $field (@fields)
    {
        my $name = $field->name;
        my $value = $c->req->param($args->{prefix} . $name);
        
        # strip whitespace
        if ($value) {
            $value =~ s/^\s+//g;
            $value =~ s/\s+$//g;
        }

        $values->{$name} = $value;
    }
    return $values;
}

sub prefs_hash_to_array
{
    my $self = shift;
    my $rs = shift;
    my $hash = shift;

    my @d = sort { $a->{param}->display_order <=> $b->{param}->display_order 
                    || $a->{param}->name cmp $b->{param}->name } 
            map { { 
                name => $_, 
                value => $hash->{$_}, 
                param => $rs->prf_defaults->find({ name => $_ }),
            } } keys %$hash;
    return @d;
}

sub update_prefs_from_hash
{
    my ($self, $object, $hash) = @_;

    for my $name (keys %$hash)
    {
        my $value = $hash->{$name};
        unless($object->prf_get($name) eq $value)
        {
            $object->prf_set($name, $value);
        }
    }
}

sub construct_global_data_form
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    my $source = $args->{resultset} || $args->{object};
    my $search = $args->{search_form};

    my @fields = $search ? $source->prf_defaults->for_search_criteria
                         : $source->prf_defaults->active->display_order;
    $self->construct_form_fields($c, $search, @fields);
    unless($search)
    {
        my $owner_id = $source->can('get_owner_type') ? $source->get_owner_type->id : $source->prf_owner_type_id;
        my $form = $c->stash->{form};
        my $global_fields = $form->get_all_element('prf_fields');
        $global_fields->element({
            name => 'prf_owner_type_id',
            type => 'Hidden',
            default => $owner_id,
        });
        unless($form->get_all_element('id'))
        {
            $global_fields->element({
                name => 'id',
                type => 'Hidden',
                default => $source->id,
            });
        }
    }
}

sub construct_global_data_search_form
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    $args->{search_form} = 1;
    return $self->construct_global_data_form($c, $args);
}

sub construct_form_fields
{
    my ($self, $c, $search, @fields) = @_;
    return $self->construct_form_fields_ex($c, $search, {}, @fields);
}

sub construct_form_fields_ex
{
    my $self = shift;
    my $c = shift;
    my $search = shift;
    my $args = shift;
    $args //= {};
    $args->{fieldset} //= 'prf_fields';
    $args->{no_fields} //= 'no_fields';
    $args->{prefix} //= 'global_fields_';

    my @fields = @_;

    my $form = $c->stash->{form};

    if(@fields)
    {
        my $global_fields = $form->get_all_element($args->{fieldset});
        my $no_fields = $form->get_all_element($args->{no_fields});
        for my $field (@fields)
        {
            my $details;
            my $extra = "li";
            my $name = $args->{prefix}.$field->name;
            $details = {
                type => 'Text',
                label => $field->comment,
                name => $name,
            };
            sswitch ($field->data_type)
            {
                case 'email': {
                    $details->{constraints} = [ { type => 'Email' } ];
                    $details->{filters} = [ { type => 'TrimEdges' } ];
                }
                case 'textarea': {
                    $details->{type} = 'Textarea';
                    $details->{filters} = [ { type => 'TrimEdges' } ];
                }
                case 'number': {
                    $details->{constraints} = [ { type => 'Number' } ];
                    $details->{filters} = [ { type => 'TrimEdges' } ];
                    $extra = '';
                }
                case 'boolean': {
                    $details->{type} = 'Checkbox';
                    $extra = '';
                }
                case 'date': {
                    $details->{attributes} = {
                        autocomplete => 'off',
                        class => 'date_picker',
                    };
                    $details->{size} = 12;
                    $details->{inflators} = {
                        type => 'DateTime',
                        strptime => '%Y-%m-%d 00:00:00',
                        parser => {
                            strptime => '%d/%m/%Y',
                        }
                    };
                    $details->{deflator} = {
                        type => 'Strftime',
                        strftime => '%d/%m/%Y',
                    };
                    $extra = '';
                }
                case 'integer': {
                    $details->{constraints} = [ { type => 'Integer' } ];
                    $details->{filters} = [ { type => 'TrimEdges' } ];
                    $extra = '';
                }
                case 'select': {
                    $details->{type} = 'Select';
                    $details->{empty_first} = 1;
                    $details->{options} = $field->form_options;
                    $extra = '';
                }
            }
            $details->{attributes} = {} unless exists $details->{attributes};
            $details->{attributes}->{class} .= ' ' if($details->{attributes}->{class});
            $details->{attributes}->{class} .= $name;
            my %extra_field;
            if($search)
            {
                $details->{type} = 'Text' if($details->{type} eq 'Textarea');
                $details->{name} =~ s/^(\Q$args->{prefix}\E)/$1_/;
                $details->{name} = $details->{name} . ' ' . $extra 
                    if $extra;
            }
            else
            {
                if($field->required) # note this isn't applied for searches
                {
                    $details->{constraints} = [] unless(exists $details->{constraints});
                    push @{$details->{constraints}}, { type => 'Required' };
                    $details->{label} .= ' *';
                }
                if($field->can('unique_field') && $field->unique_field)
                {
                    $details->{validator} = [] unless(exists $details->{validator});
                    push @{$details->{validator}}, { 
                        # DEBT: I've updated this to FB11 but it should belong to us!
                        # But this whole module is debt so ugh
                        type => '+OpusVL::FB11::TokenProcessor::Admin::FormFu::Validator::UniquePreference',
                    };
                }
                if($field->can('ajax_validate') && $field->ajax_validate)
                {
                    $details->{javascript} = "\$(function() { instant_validation('$name') });";
                }
                if($field->can('confirmation_required') && $field->confirmation_required)
                {
                    %extra_field = %$details;
                    my $original_name = $extra_field{name};
                    my $missmatch_msg = 'The ' . lc($field->comment) . ' fields do not match';
                    $extra_field{name} = 'confirm_' . $original_name;
                    $extra_field{label} = 'Confirm ' . $extra_field{label};
                    delete $extra_field{javascript} if exists $extra_field{javascript};
                    delete $extra_field{validator} if exists $extra_field{validator};
                    $extra_field{constraints} = [] unless(exists $extra_field{constraints});
                    push @{$extra_field{constraints}}, { type => 'Equal', message => $missmatch_msg, others => $original_name };
                }
            }
            my $element = $global_fields->element($details);
            my $extra_element = $global_fields->element(\%extra_field) if %extra_field;
        }
        $global_fields->remove_element($no_fields);
    }
    # NOTE: caller must call $form->process afterwards
}

sub field_type_info
{
    my ($self, $c, $fields, @field_list) = @_;

    for my $field (@field_list)
    {
        my $name = $field->name;
        my $field_name = "extra_field_$name";
        my $field_info = {
            name => $field_name,
            type => $field->data_type,
            label => $field->comment,
        };
        if($field->data_type eq 'select')
        {
            $field_info->{options} = $field->form_options;
        }
        if($field->required)
        {
            $field_info->{required} = 1;
        }
        if($field->can('unique_field') && $field->unique_field)
        {
            $field_info->{unique_field} = 1;
        }
        push @$fields, $field_info;
    }
}

1;

=head1 NAME

OpusVL::AppKitX::TokenProcessor::Admin::Role::ParameterValueEditing

=head1 DESCRIPTION

=head1 METHODS

=head2 add_prefs_defaults

=head2 update_prefs_values

=head2 get_prefs_values_from_form

=head2 collect_values_from_form

=head2 prefs_hash_to_array

=head2 update_prefs_from_hash

=head2 construct_global_data_form

=head2 construct_global_data_search_form

=head2 construct_form_fields

=head2 field_type_info


=head1 ATTRIBUTES


=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

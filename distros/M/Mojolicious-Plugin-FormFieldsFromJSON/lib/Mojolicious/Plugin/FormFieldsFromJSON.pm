package Mojolicious::Plugin::FormFieldsFromJSON;
use Mojo::Base 'Mojolicious::Plugin';

# ABSTRACT: create form fields based on a definition in a JSON file

our $VERSION = '1.01';

use Carp;
use File::Basename;
use File::Spec;
use IO::Dir;
use List::Util qw(first);

use Mojo::Asset::File;
use Mojo::Collection;
use Mojo::ByteStream;
use Mojo::File;
use Mojo::JSON qw(decode_json);

use Mojolicious ();

has dir => sub {["."]} ;

my $selected_value = Mojolicious->VERSION < 6.16 ? 'selected' : undef;
my $checked_value  = Mojolicious->VERSION < 6.16 ? 'checked'  : undef;

sub register {
    my ($self, $app, $config) = @_;

    $config //= {};

    if ( $config->{template_file} ) {
        $config->{template} = Mojo::File->new( $app->home, 'templates', $config->{template_file} )->slurp;
        $config->{template} //= $app->renderer->get_data_template( $config->{template_file} );
    }
  
    my %configs;
    if(ref $config->{dir} eq "ARRAY"){
        @{$self->dir} = @{$config->{dir}}; 
    }
    else{
        @{$self->dir} = ($config->{dir});
    }
  
    my %valid_types = (
        %{ $config->{types} || {} },
        text     => 1,
        checkbox => 1,
        select   => 1,
        radio    => 1,
        hidden   => 1,
        textarea => 1,
        password => 1,
    );

    my %configfiles;
    $app->helper(
        forms => sub {
            if( %configfiles ) {
                return sort keys %configfiles;
            }

            for my $dir (@{$self->dir}){
                my $dir = IO::Dir->new( $dir );

                FILE:
                while ( my $file = $dir->read ) {
                    next FILE if $file !~ m{\.json\z};

                    my $filename = basename $file;
                    $filename    =~ s{\.json\z}{};

                    $configfiles{$filename} = 1;
                }
            }

            return sort keys %configfiles;
        }
    );

    $app->helper(
        "form_fields_from_json_dir" => sub {return $self->dir}
    );

    $app->helper(
        fields => sub {
            my ($c, $file, $params) = @_;

            if ( !$configs{$file} ) {
                $self->_load_config_from_file($c, \%configs, $file);
            }

            my @fields;
            my @fields_long;
            for my $field ( @{ $configs{$file} } ) {
                my $name = $field->{label} // $field->{name} // '';
                push @fields, $name;
                push @fields_long, +{ label => $name, name => $field->{name} // '' };
            }

            if ( $params and $params->{hash} ) {
                return @fields_long;
            }

            return @fields;
        }
    );

    $app->helper(
        'validate_form_fields' => sub {
            my ($c, $file) = @_;
  
            return '' if !$file;
  
            if ( !$configs{$file} ) {
                $self->_load_config_from_file($c, \%configs, $file);
            }
  
            return '' if !$configs{$file};
  
            my $config = $configs{$file};

            my $validation = $c->validation;

            my $params_hash = $c->req->params->to_hash;
            my @param_names = keys %{ $params_hash || {} };

            my %params = map{ $_ => $c->every_param( $_ ) }@param_names;
            $validation->input( \%params );

            my %errors;
  
            FIELD:
            for my $field ( @{ $config } ) {
                if ( 'HASH' ne ref $field ) {
                    $app->log->error( 'Field definition must be a HASH - skipping field' );
                    next FIELD;
                }

                if ( !$field->{validation} ) {
                    next FIELD;
                }

                if ( 'HASH' ne ref $field->{validation} ) {
                    $app->log->warn( 'Validation settings must be a HASH - skipping field' );
                    next FIELD;
                }

                my $name         = $field->{name} // $field->{label} // '';
                my $global_error = 1;

                if ( $field->{validation}->{required} ) {
                    $validation->required( $name );

                    my $value  = $field->{validation}->{required};
                    if ( ref $value && 'HASH' eq ref $value ) {
                        $global_error = $value->{msg} // 1;
                    }
                }
                else {
                    $validation->optional( $name );
                }

                RULE:
                for my $rule ( sort keys %{ $field->{validation} } ) {
                    last RULE if !defined $params{$name};

                    next RULE if $rule eq 'required';

                    my $value  = $field->{validation}->{$rule};
                    my $ref    = ref $value;
                    my $method = $rule;
                    my $error  = 1;

                    my @params;

                    if ( !$ref ) {
                        @params = $value;
                    }
                    elsif ( $ref eq 'ARRAY' ) {
                        @params = @{ $value };
                    }
                    elsif ( $ref eq 'HASH' ) {
                        @params = ref $value->{args} ? @{ $value->{args} } : $value->{args};
                        $error  = $value->{msg} // 1;
                    }

                    eval{
                        $validation->check( $method, @params );
                        1;
                    } or do {
                        $app->log->error( "Validating $name with rule $method failed: $@" );
                    };

                    if ( $validation->has_error( $name ) ) {
                        $errors{$name} = $error;
                        last RULE;
                    }
                }

                if ( $validation->has_error( $name ) && !defined $errors{$name} ) {
                    $errors{$name} = $global_error;
                }
            }

            return %errors;
        }
    );

    $app->helper(
        'form_fields' => sub {
            my ($c, $file, %params) = @_;

            # get form config
            return '' if !$self->_load_config_from_file($c, \%configs, $file);
            return '' if !$configs{$file} && !ref $file;
            my $field_config = $configs{$file} || $file;

            my @fields;

            my %fields_to_show = map { $_ => 1 } @{ $params{fields} || [] };

            FIELD:
            for my $field ( @{$field_config} ) {
                next FIELD if %fields_to_show && !$fields_to_show{ $field->{name} };

                my $field_content = $self->_build_form_field($c, $field, \%params, $config, \%valid_types);

                if (length $field_content) {
                    push @fields, $field_content;
                }
            }

            return Mojo::ByteStream->new( join "\n\n", @fields );
        }
    );

    $app->helper(
        'form_field_by_name' => sub {
            my ($c, $file, $field_name, %params) = @_;

            # get form config
            return '' if !$self->_load_config_from_file($c, \%configs, $file);
            return '' if !$configs{$file} && !ref $file;
            my $field_config = $configs{$file} || $file;

            # find field config
            my @fields_filtered = grep {
                $_->{name} eq $field_name
            } @{ $field_config };

            return '' if !(scalar @fields_filtered);

            return $self->_build_form_field($c, $fields_filtered[0], \%params, $config, \%valid_types);
        }
    );
}

sub _load_config_from_file {
    my ($self, $c, $configs, $file) = @_;

    return 0 if !$file;

    if ( !$configs->{$file} && !ref $file ) {
        my $path;

        # search until first match
        my $i=0;
        do {
            my $_path= File::Spec->catfile( $self->dir->[$i], $file . '.json' );
            $path = $_path if -r $_path;
        } while ( not defined $path and ++$i <= $#{$self->dir} );

        if( not defined $path){
            $c->app->log->error( "FORMFIELDS $file: not found in directories" );
            $c->app->log->error( "  $_") for @{$self->dir};
            return 0;
        }

        eval {
            my $content     = Mojo::Asset::File->new( path => $path )->slurp;
            $configs->{$file} = decode_json $content;
        } or do {
            $c->app->log->error( "FORMFIELDS $file: $@" );
            return 0;
        };

        if ( 'ARRAY' ne ref $configs->{$file} ) {
            $c->app->log->error( 'Definition JSON must be an ARRAY' );
            return 0;
        }
    }

    return 1;
}

sub _build_form_field {
    my ($self, $c, $field, $params, $plugin_config, $valid_types) = @_;


    if ( 'HASH' ne ref $field ) {
        $c->app->log->error( 'Field definition must be an HASH - skipping field' );
        return '';
    }

    my $type      = lc $field->{type};
    my $orig_type = $type;

    if ( $plugin_config->{alias} && $plugin_config->{alias}->{$type} ) {
        $type = $plugin_config->{alias}->{$type};
    }

    if ( !$valid_types->{$type} ) {
        $c->app->log->warn( "Invalid field type $type - falling back to 'text'" );
        $type = 'text';
    }

    if ( $plugin_config->{global_attributes} && $type ne 'hidden' && 'HASH' eq ref $plugin_config->{global_attributes} ) {

        ATTRIBUTE:
        for my $attribute ( keys %{ $plugin_config->{global_attributes} } ) {
            $field->{attributes}->{$attribute} //= '';

            my $field_attr  = $field->{attributes}->{$attribute};
            my $global_attr = $plugin_config->{global_attributes}->{$attribute};

            next ATTRIBUTE if $field_attr =~ m{\Q$global_attr};

            my $space = length $field_attr ? ' ' : '';

            $field->{attributes}->{$attribute}  .= $space . $global_attr;
        }
    }

    if ( $field->{translate_sublabels} && $plugin_config->{translation_method} && !$field->{translation_method} ) {
        $field->{translation_method} = $plugin_config->{translation_method};
    }

    my $sub        = $self->can( '_' . $type );
    my $form_field = $self->$sub( $c, $field, %{ $params } );

    $form_field = Mojo::ByteStream->new( $form_field );

    my $template = $field->{template} // $plugin_config->{templates}->{$orig_type} // $plugin_config->{template};

    if ( $template && $type ne 'hidden' ) {
        my $label = $field->{label} // '';
        my $loc   = $plugin_config->{translation_method};

        if ( $plugin_config->{translate_labels} && $loc && 'CODE' eq ref $loc ) {
            $label = $loc->($c, $label);
        }

        $form_field = Mojo::ByteStream->new(
            $c->render_to_string(
                inline  => $template,
                id      => $field->{id} // $field->{name} // $field->{label} // '',
                label   => $label,
                field   => $form_field,
                message => $field->{msg}  // '',
                info    => $field->{info} // '',
            )
        );
#        $c->app->log->debug("rendered formfield: ".$form_field);
    }

    return $form_field;
}

sub _hidden {
    my ($self, $c, $field, %params) = @_;

    my $name  = $field->{name} // $field->{label} // '';

    my $from_stash_key = $params{from_stash};
    my $from_stash     = $from_stash_key ?
        $c->stash( $from_stash_key )->{$name} :
        undef;

    my $value = $params{$name}->{data} // $from_stash //
        $c->stash( $name ) // $c->param( $name ) //
        $field->{data} // '';

    my $id    = $field->{id} // $name;
    my %attrs = %{ $field->{attributes} || {} };

    return $c->hidden_field( $name, $value, id => $id, %attrs );
}

sub _text {
    my ($self, $c, $field, %params) = @_;

    my $name  = $field->{name} // $field->{label} // '';

    my $from_stash_key = $params{from_stash};
    my $from_stash     = $from_stash_key ?
        $c->stash( $from_stash_key )->{$name} :
        undef;

    my $value = $params{$name}->{data} // $from_stash //
        $c->stash( $name ) // $c->param( $name ) //
        $field->{data} // '';

    my $id    = $field->{id} // $name;
    my %attrs = %{ $field->{attributes} || {} };

    return $c->text_field( $name, $value, id => $id, %attrs );
}

sub _select {
    my ($self, $c, $field, %params) = @_;

    my $name   = $field->{name} // $field->{label} // '';

    my $from_stash_key = $params{from_stash};
    my $from_stash     = $from_stash_key ?
        $c->stash( $from_stash_key )->{$name} :
        undef;

    my $field_params = $params{$name} || {},

    my %select_params = (
       disabled => $self->_get_highlighted_values( $field, 'disabled' ),
       selected => $self->_get_highlighted_values( $field, 'selected' ),
    );

    my $stash_values = $c->every_param( $name );
    if (scalar(@{ $stash_values || [] }) == 0 && defined( $c->stash( $name ))){
        my $local_stash = $c->stash( $name );
        $stash_values = ref $local_stash ? $local_stash : [ $local_stash ];
    }

    if ( $from_stash ) {
        $stash_values = ref $from_stash ? $from_stash : [ $from_stash ];
    }

    my $reset;
    if ( @{ $stash_values || [] } ) {
        $select_params{selected} = $self->_get_highlighted_values(
            +{ selected => $stash_values },
            'selected',
        );

        $reset = 1;
    }

    for my $key ( qw/disabled selected/ ) {
        my $hashref = $self->_get_highlighted_values( $field_params, $key );
        if ( keys %{ $hashref } ) {
            $select_params{$key} = $hashref;
        }
    }

    if ( $field_params->{data} ) {
        $select_params{data} = $field_params->{data};
    }

    my @values = $self->_get_select_values( $c, $field, %select_params );
    my $id     = $field->{id} // $name;
    my %attrs  = %{ $field->{attributes} || {} };

    if ( $field->{multiple} ) {
        $attrs{multiple} = 'multiple';
        $attrs{size}     = $field->{size} || 5;
    }

    my @selected = keys %{ $select_params{selected} };
    if ( @selected ) {
        my $single = scalar @selected;
        my $param  = $single == 1 ? $selected[0] : \@selected;
        $c->param( $name, $param );
    }

    my $select_field = $c->select_field( $name, [ @values ], id => $id, %attrs );

    # reset parameters
    if ( $reset ) {
        my $single = scalar @{ $stash_values };
        my $param  = $single == 1 ? $stash_values->[0] : $stash_values;
        $c->param( $name, $param );
    }

    return $select_field;
}

sub _get_highlighted_values {
    my ($self, $field, $key) = @_;

    return +{} if !$field->{$key};

    my %highlighted;

    if ( !ref $field->{$key} ) {
        my $value = $field->{$key};
        $highlighted{$value} = 1;
    }
    elsif ( 'ARRAY' eq ref $field->{$key} ) {
        for my $value ( @{ $field->{$key} } ) {
            $highlighted{$value} = 1;
        }
    }

    return \%highlighted;
}

sub _get_select_values {
    my ($self, $c, $field, %params) = @_;

    my $data = $params{data} || $field->{data} || [];
    if ( $field->{data_cb} ) {
        my @parts   = split /::/, $field->{data_cb};
        my $subname = pop @parts;
        my $class   = join '::', @parts;
        my $sub     = $class->can( $subname );
        $data       = $sub->() if $sub;
    }

    my @values;
    if ( 'ARRAY' eq ref $data ) {
        @values = $self->_transform_array_values( $data, %params );
    }
    elsif( 'HASH' eq ref $data ) {
        @values = $self->_transform_hash_values( $c, $data, %params );
    }

    return @values;
}

sub _transform_hash_values {
    my ($self, $c, $data, %params) = @_;

    my @values;
    my $numeric = 1;
    my $counter = 0;
    my %mapping;

    KEY:
    for my $key ( keys %{ $data } ) {
        if ( ref $data->{$key} ) {
            my @group_values = $self->_get_select_values( $c, +{ data => $data->{$key} }, %params );
            $values[$counter] = Mojo::Collection->new( $key => \@group_values );
            $mapping{$key} = $counter;
        }
        else {
            my %opts;

            $opts{disabled} = 'disabled'      if $params{disabled}->{$key};
            $opts{selected} = $selected_value if $params{selected}->{$key};
            #$opts{selected} = undef if $params{selected}->{$key};

            $values[$counter] = [ $data->{$key} => $key, %opts ];
            $mapping{$key}    = $counter;
        }

        $counter++;
    }

    if ( first{ $_ =~ m{[^0-9]} }keys %mapping ) {
        $numeric = 0;
    }

    my @sorted_keys = $numeric ? 
        sort { $a <=> $b }keys %mapping :
        sort { $a cmp $b }keys %mapping;

    my @indexes = @mapping{ @sorted_keys };

    my @sorted_values = @values[ @indexes ];

    return @sorted_values;
}

sub _transform_array_values {
    my ($self, $data, %params) = @_;

    my @values;
    my $numeric = 1;

    for my $value ( @{ $data } ) {
        if ( $numeric && $value =~ m{[^0-9]} ) {
            $numeric = 0;
        }

        my %opts;

        $opts{disabled} = 'disabled'      if $params{disabled}->{$value};
        $opts{selected} = $selected_value if $params{selected}->{$value};
        #$opts{selected} = undef if $params{selected}->{$value};

        push @values, [ $value => $value, %opts ];
    }

    @values = $numeric ?
        sort{ $a->[0] <=> $b->[0] }@values :
        sort{ $a->[0] cmp $b->[0] }@values;

    return @values;
}

sub _radio {
    my ($self, $c, $field, %params) = @_;

    my $name  = $field->{name} // $field->{label} // '';
    my $id    = $field->{id} // $name;
    my %attrs = %{ $field->{attributes} || {} };

    my $data   = $params{$name}->{data} // $field->{data} // [];
    my @values = ref $data ? @{ $data } : ($data);

    my $field_params = $params{$name} || {},

    my %select_params = (
       disabled => $self->_get_highlighted_values( $field, 'disabled' ),
       selected => $self->_get_highlighted_values( $field, 'selected' ),
    );

    my $stash_values = $c->every_param( $name );
    if (scalar(@{ $stash_values || [] }) == 0 && defined( $c->stash( $name ))){
        my $local_stash = $c->stash( $name );
        $stash_values = ref $local_stash ? $local_stash : [ $local_stash ];
    }
    my $reset;
    if ( @{ $stash_values || [] } ) {
        $select_params{selected} = $self->_get_highlighted_values(
            +{ selected => $stash_values },
            'selected',
        );
        $reset = 1;
    }

    for my $key ( qw/disabled selected/ ) {
        my $hashref = $self->_get_highlighted_values( $field_params, $key );
        if ( keys %{ $hashref } ) {
            $select_params{$key} = $hashref;
        }
    }

    my @selected = keys %{ $select_params{selected} };
    if ( @selected ) {
        my $single = scalar @selected;
        my $param  = $single == 1 ? $selected[0] : \@selected;
        $c->param( $name, $param );
    }

    my $radiobuttons = '';
    for my $radio_value ( @values ) {
        my %value_attributes;

        if ( $select_params{disabled}->{$radio_value} ) {
            $value_attributes{disabled} = 'disabled';
        }

        if ( $select_params{selected}->{$radio_value} ) {
            $value_attributes{checked} = $checked_value;
        }

        my $local_label = '';
        if ( $field->{show_value} ) {
            $local_label = $radio_value;
        }

        my $loc = $field->{translation_method};
        if ( length $local_label && $field->{translate_sublabels} && $loc && 'CODE' eq ref $loc ) {
            $local_label = $loc->($c, $local_label);
        }

        $local_label = " " . $local_label if length $local_label;

        $radiobuttons .= $c->radio_button(
            $name => $radio_value,
            id => $id,
            %attrs,
            %value_attributes,
        ) . "$local_label\n";

        if ( defined $field->{after_element} ) {
            $radiobuttons .= $field->{after_element};
        }
    }

    if ( $reset ) {
        my $single = scalar @{ $stash_values };
        my $param  = $single == 1 ? $stash_values->[0] : $stash_values;
        $c->param( $name, $param );
    }

    return $radiobuttons;
}

sub _checkbox {
    my ($self, $c, $field, %params) = @_;

    my $name  = $field->{name} // $field->{label} // '';
    my $id    = $field->{id} // $name;
    my %attrs = %{ $field->{attributes} || {} };

    my $data   = $params{$name}->{data} // $field->{data} // [];
    my @values = ref $data ? @{ $data } : ($data);

    my $field_params = $params{$name} || {},

    my %select_params = (
       disabled => $self->_get_highlighted_values( $field, 'disabled' ),
       selected => $self->_get_highlighted_values( $field, 'selected' ),
    );

    my $stash_values = $c->every_param( $name );
    if (scalar(@{ $stash_values || [] }) == 0 && defined( $c->stash( $name ))){
        my $local_stash = $c->stash( $name );
        $stash_values = ref $local_stash ? $local_stash : [ $local_stash ];
    }
    my $reset;
    if ( @{ $stash_values || [] } ) {
        $select_params{selected} = $self->_get_highlighted_values(
            +{ selected => $stash_values },
            'selected',
        );
        $c->param( $name, '' );
        $reset = 1;
    }

    for my $key ( qw/disabled selected/ ) {
        my $hashref = $self->_get_highlighted_values( $field_params, $key );
        if ( keys %{ $hashref } ) {
            $select_params{$key} = $hashref;
        }
    }

    my @selected = keys %{ $select_params{selected} };
    if ( @selected ) {
        my $single = scalar @selected;
        my $param  = $single == 1 ? $selected[0] : \@selected;
        $c->param( $name, $param );
    }

    my $checkboxes = '';
    for my $checkbox_value ( @values ) {
        my %value_attributes;

        if ( $select_params{disabled}->{$checkbox_value} ) {
            $value_attributes{disabled} = 'disabled';
        }

        if ( $select_params{selected}->{$checkbox_value} ) {
            $value_attributes{checked} = $checked_value;
        }

        my $local_label = '';
        if ( $field->{show_value} ) {
            $local_label = $checkbox_value;
        }

        my $loc = $field->{translation_method};
        if ( length $local_label && $field->{translate_sublabels} && $loc && 'CODE' eq ref $loc ) {
            $local_label = $loc->($c, $local_label);
        }

        $local_label = " " . $local_label if length $local_label;

        $checkboxes .= $c->check_box(
            $name => $checkbox_value,
            id => $id,
            %attrs,
            %value_attributes,
        ) . "$local_label\n";

        if ( defined $field->{after_element} ) {
            $checkboxes .= $field->{after_element};
        }
    }

    if ( $reset ) {
        my $single = scalar @{ $stash_values };
        my $param  = $single == 1 ? $stash_values->[0] : $stash_values;
        $c->param( $name, $param );
    }

    return $checkboxes;
}

sub _textarea {
    my ($self, $c, $field, %params) = @_;

    my $name  = $field->{name} // $field->{label} // '';
    my $value = $params{$name}->{data} // $c->stash( $name ) // $c->param( $name ) // $field->{data} // '';
    my $id    = $field->{id} // $name;
    my %attrs = %{ $field->{attributes} || {} };

    return $c->text_area( $name, $value, id => $id, %attrs );
}

sub _password {
    my ($self, $c, $field, %params) = @_;

    my $name  = $field->{name} // $field->{label} // '';
    my $value = $params{$name}->{data} // $c->stash( $name ) // $c->param( $name ) // $field->{data} // '';
    my $id    = $field->{id} // $name;
    my %attrs = %{ $field->{attributes} || {} };

    return $c->password_field( $name, value => $value, id => $id, %attrs );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::FormFieldsFromJSON - create form fields based on a definition in a JSON file

=head1 VERSION

version 1.01

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('FormFieldsFromJSON');

  # Mojolicious::Lite
  plugin 'FormFieldsFromJSON';

=head1 DESCRIPTION

L<Mojolicious::Plugin::FormFieldsFromJSON> is a L<Mojolicious> plugin.

=head1 NAME

Mojolicious::Plugin::FormFieldsFromJSON - create form fields based on a definition in a JSON file

=head1 VERSION

version 0.32

=head1 CONFIGURATION

You can configure some settings for the plugin:

=over 4

=item * dir

The directory where the json files for form field configuration are located

  $self->plugin( 'FormFieldsFromJSON' => {
    dir => '/home/mojo/fields',
  });

You can also pass an arrayreference with directory names. This will help when you
store the JSON files where your templates are...

  $self->plugin( 'FormFieldsFromJSON' => {
    dir => [
      '/home/mojo/templates/admin/json',
      '/home/mojo/templates/author/json',
      '/home/mojo/templates/guest/json',
    ]
  });

=item * template

With template you can define a template for the form fields.

  $self->plugin( 'FormFieldsFromJSON' => {
    template => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
  });

See L<Templates|Mojolicious::Plugin::FormFieldsFromJSON/Templates>.

=item * templates

With template you can define type specific templates for the form fields.

  plugin 'FormFieldsFromJSON' => {
    templates => {
      text => '<%= $label %>: <%= $field %>',
    },
  };

See L<Templates|Mojolicious::Plugin::FormFieldsFromJSON/Templates>.

=item * global_attributes

With I<global_attributes>, you can define attributes that should be set for every field 
(except hidden fields)

  plugin 'FormFieldsFromJSON' => {
    global_attributes => {
      class => 'important-field',
    },
  };

So with this configuration

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name"
    },
    {
        "label" : "Background",
        "type" : "text",
        "name" : "background"
    }
 ]

You get

     <input class="important-field" id="name" name="name" type="text" value="" />
     <input class="important-field" id="background" name="background" type="text" value="" />

=item * alias

Using aliases can help you a lot. Given you want to have several forms where the user can
define a color (e.g. by using I<bootstrap-colorpicker>), you don't want to define the special
templates in each form. Instead you can define those fiels as I<type> "color" and use an alias:

  plugin 'FormFieldsFromJSON' => {
    template  => '<%= $label %>: <%= $field %>',
    templates => {
      color => '<%= $label %> (color): <%= $field %>',
    },
    alias => {
      color => 'text',
    },
  };

The alias defines that "color" fields are "text" fields.

So with this configuration

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name"
    },
    {
        "label" : "Background",
        "type" : "color",
        "name" : "background"
    }
 ]

You get

     <label for="name">Name:</label><div><input id="name" name="name" type="text" value="" /></div>
     <label for="background">Background (color):</label><div><input id="background" name="background" type="text" value="" /></div>

=item * translate_labels

If I<translate_labels> is true, the labels for the templates are translated. You have to provide a
I<translation_method|Mojolicious::Plugin::FormFieldsFromJSON/Translation_method>, too.

  plugin 'FormFieldsFromJSON' => {
    template           => '<%= $label %>: <%= $field %>',
    translate_labels   => 1,
    translation_method => \&loc,
  };

For more details see I<Translation|Mojolicious::Plugin::FormFieldsFromJSON/Translation>.

=item * translation_method

If I<translate_labels> is true, the labels for the templates are translated. You have to provide a
I<translation_method|Mojolicious::Plugin::FormFieldsFromJSON/Translation_method>, too.

  plugin 'FormFieldsFromJSON' => {
    template           => '<%= $label %>: <%= $field %>',
    translate_labels   => 1,
    translation_method => \&loc,
  };

For more details see I<Translation|Mojolicious::Plugin::FormFieldsFromJSON/Translation>.

=item * types

If you have written a plugin that implements a new "type" of input field, you can allow this type by passing
I<types> when you load the plugin.

  plugin 'FormFieldsFromJSON' => {
    types => {
        'testfield' => 1,
    },
  };

Now you can use 

  [
    {
      "label" : "Name",
      "type" : "testfield",
      "name" : "name"
    }
  ]

For more details see L<Additional Types|/New Types>.

=back

=head1 HELPER

=head2 form_fields

C<form_fields> returns a string with all configured fields "translated" to HTML.

  $controller->form_fields( 'formname' );

Given this configuration:

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name"
    },
    {
        "label" : "City",
        "type" : "text",
        "name" : "city"
    }
 ]

You'll get

 <input id="name" name="name" type="text" value="" />
 <input id="city" name="city" type="text" value="" />

=head3 dynamic config

Instead of a formname, you can pass a config:

  $controller->form_fields(
    [
      {
        "label" : "Name",
        "type" : "testfield",
        "name" : "name"
      }
    ]
  );

This way, you can build your forms dynamically (e.g. based on database entries).

=head2 validate_form_fields

This helper validates the input. It uses the L<Mojolicious::Validator::Validation> and it
validates all fields defined in the configuration file.

For more details see L<Validation|Mojolicious::Plugin::FormFieldsFromJSON/Validation>.

=head2 forms

This method returns a list of forms. That means the filenames of all .json files
in the configured directory.

  my @forms = $controller->forms;

The filenames are returned without the file suffix .json.

=head2 fields

C<fields()> returns a list of fields (label or name).

  my @fieldnames = $controller->fields('formname');

If your configuration looks like

 [
   {
     "label" : "Email",
     "name"  : "email",
     "type"  : "text"
   },
   {
     "name"  : "password",
     "type"  : "password"
   }
 ]

You get

  (
    Email,
    password
  )

=head1 FIELD DEFINITIONS

This plugin supports several form fields:

=over 4

=item * text

=item * checkbox

=item * radio

=item * select

=item * textarea

=item * password

=item * hidden

=back

Those fields have the following definition items in common:

=over 4

=item * name

The name of the field. If you do not pass an id for the field in the I<attributes>-field, the name is also
taken for the field id.

=item * label

If a template is used, this value is passed for C<$label>. If the translation feature is used, the label
is translated.

=item * type

One of the above mentioned types. Please note, that you can add own types.

=item * data

For I<text>, I<textarea>, I<password> and I<hidden> this is the value for the field. This can be set in various ways:

=over 4

=item 1. Data passed in the code like

  $c->form_fields( 'form', fieldname => { data => 'test' } );

=item 2. Data passed via stash

  $c->stash( fieldname => 'test' );

=item 3. Data in the request

=item 4. Data defined in the field configuration

=item 5. Data passed via stash - part two

  $c->stash( any_name => { fieldname => 'test' } );
  $c->form_fields( 'form', from_stash => 'any_name' );

=back

For I<select>, I<checkbox> and I<radio> fields, I<data> contains the possible values.

=item * attributes

Attributes of the field like "class":

  attributes => {
    class => 'button'
  }

If I<global_attributes> are defined, then the values are added, so that

  plugin( 'FormFieldsFromJSON' => {
    global_attributes => {
      class => 'button-danger',
    }
  });

and the I<attributes> field as shown, then the field has two classes: I<button> and I<button-danger>. In the
field the classes mentioned in field config come first.

  <button class="button button-danger" ...>

=back

=head1 EXAMPLES

The following sections should give you an idea what's possible with this plugin

=head2 text

With type I<text> you get a simple text input field.

=head3 A simple text field

This is the configuration for a simple text field:

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name"
    }
 ]

And the generated form field looks like

 <input id="name" name="name" type="text" value="" />

=head3 Set CSS classes

If you want to set a CSS class, you can use the C<attributes> field:

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name",
        "attributes" : {
            "class" : "W75px"
        }
    }
 ]

And the generated form field looks like

 <input class="W75px" id="name" name="name" type="text" value="" />

=head3 Text field with predefined value

Sometimes, you want to predefine a value shown in the text field. Then you can
use the C<data> field:

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name",
        "data" : "default value"
    }
 ]

This will generate this input field:

  <input id="name" name="name" type="text" value="default value" />

=head2 select

=head3 Simple: Value = Label

When you have a list of values for a select field, you can define
an array reference:

  [
    {
      "type" : "select",
      "name" : "language",
      "data" : [
        "de",
        "en"
      ]
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="de">de</option>
      <option value="en">en</option>
  </select>

=head3 Preselect a value

You can define

  [
    {
      "type" : "select",
      "name" : "language",
      "data" : [
        "de",
        "en"
      ],
      "selected" : "en"
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="de">de</option>
      <option value="en" selected="selected">en</option>
  </select>

If a key named as the select exists in the stash, those values are preselected
(this overrides the value defined in the .json):

  $c->stash( language => 'en' );

and

  [
    {
      "type" : "select",
      "name" : "language",
      "data" : [
        "de",
        "en"
      ]
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="de">de</option>
      <option value="en" selected="selected">en</option>
  </select>

=head3 Multiselect

  [
    {
      "type" : "select",
      "name" : "languages",
      "data" : [
        "de",
        "en",
        "cn",
        "jp"
      ],
      "multiple" : 1,
      "size" : 3
    }
  ]

This creates the following select field:

  <select id="languages" name="languages" multiple="multiple" size="3">
      <option value="cn">cn</option>
      <option value="de">de</option>
      <option value="en">en</option>
      <option value="jp">jp</option>
  </select>

=head3 Preselect multiple values

  [
    {
      "type" : "select",
      "name" : "languages",
      "data" : [
        "de",
        "en",
        "cn",
        "jp"
      ],
      "multiple" : 1,
      "selected" : [ "en", "de" ]
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="cn">cn</option>
      <option value="de" selected="selected">de</option>
      <option value="en" selected="selected">en</option>
      <option value="jp">jp</option>
  </select>

=head3 Values != Label

  [
    {
      "type" : "select",
      "name" : "language",
      "data" : {
        "de" : "German",
        "en" : "English"
      }
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="en">English</option>
      <option value="de">German</option>
  </select>

=head3 Option groups

  [
    {
      "type" : "select",
      "name" : "language",
      "data" : {
        "EU" : {
          "de" : "German",
          "en" : "English"
        },
        "Asia" : {
          "cn" : "Chinese",
          "jp" : "Japanese"
        }
      }
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="en">English</option>
      <option value="de">German</option>
  </select>

=head3 Disable values

  [
    {
      "type" : "select",
      "name" : "languages",
      "data" : [
        "de",
        "en",
        "cn",
        "jp"
      ],
      "multiple" : 1,
      "disabled" : [ "en", "de" ]
    }
  ]

This creates the following select field:

  <select id="language" name="language">
      <option value="cn">cn</option>
      <option value="de" disabled="disabled">de</option>
      <option value="en" disabled="disabled">en</option>
      <option value="jp">jp</option>
  </select>

=head2 radio

For radiobuttons, you can use two ways: You can either configure
form fields for each value or you can define a list of values in
the C<data> field. With the first way, you can create radiobuttons
where the template (if any defined) is applied to each radiobutton.
With the second way, the radiobuttons are handled as one single 
field in the template.

=head3 A single radiobutton

Given the configuration

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : "internal"
    }
 ]

You get

=head3 Two radiobuttons configured separately

With the configuration

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : "internal"
    },
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : "external"
    }
 ]

You get

=head3 Two radiobuttons as a group

And with

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : ["internal", "external" ]
    }
 ]

You get

=head3 Two radiobuttons configured separately - with template

Define template:

  plugin 'FormFieldsFromJSON' => {
    dir      => './conf',
    template => '<%= $label %>: <%= $form %>';
  };

Config:

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : "internal"
    },
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : "external"
    }
 ]

Fields:

  Name: <input id="type" name="type" type="radio" value="internal" />
  
  
  
  Name: <input id="type" name="type" type="radio" value="external" />

=head3 Two radiobuttons as a group - with template

Same template definition as above, but given this field config:

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : ["internal", "external" ]
    }
 ]

You get this:

  Name: <input id="type" name="type" type="radio" value="internal" />
  <input id="type" name="type" type="radio" value="external" />

=head3 Two radiobuttons - one checked

Config:

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "data" : ["internal", "external" ],
        "selected" : ["internal"]
    }
 ]

Field:

  <input checked="checked" id="type" name="type" type="radio" value="internal" />
  <input id="type" name="type" type="radio" value="external" />

=head3 Radiobuttons with HTML after every element

When you want to add some HTML code after every element - e.g. a C<< <br /> >> -
you can use I<after_element>

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "after_element" : "<br />",
        "data" : ["internal", "external" ]
    }
 ]

Fields:

  <input id="type" name="type" type="radio" value="internal" />
  <br /><input id="type" name="type" type="radio" value="external" />
  <br />

=head3 Radiobuttons with values shown as label

When you want to show the value as a label, you can use I<show_value>.

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "show_value" : 1,
        "data" : ["internal", "external" ]
    }
 ]

Creates

  <input id="type" name="type" type="radio" value="internal" /> internal
  <input id="type" name="type" type="radio" value="external" /> external

=head3 Radiobuttons with translated values for "sublabels"

If you want to show the "sublabels" and want them to be translated, you can
use I<translate_sublabels>

 [
    {
        "label" : "Name",
        "type" : "radio",
        "name" : "type",
        "show_value" : 1,
        "translate_sublabels" : 1,
        "data" : ["internal", "external" ]
    }
 ]

Given this plugin is used this way:

  plugin 'FormFieldsFromJSON' => {
      dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
      translation_method => \&loc,
  };
  
  sub loc {
      my ($c, $value) = @_;
  
      my %translation = ( internal => 'intern', external => 'extern' );
      return $translation{$value} // $value;
  };

You'll get

  <input id="type" name="type" type="radio" value="internal" /> intern
  <input id="type" name="type" type="radio" value="external" /> extern

=head2 checkbox

For checkboxes, you can use two ways: You can either configure
form fields for each value or you can define a list of values in
the C<data> field. With the first way, you can create checkboxes
where the template (if any defined) is applied to each checkbox.
With the second way, the checkboxes are handled as one single 
field in the template.

=head3 A single checkbox

Given the configuration

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : "internal"
    }
 ]

You get

=head3 Two checkboxes configured separately

With the configuration

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : "internal"
    },
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : "external"
    }
 ]

You get

=head3 Two checkboxes as a group

And with

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : ["internal", "external" ]
    }
 ]

You get

=head3 Two checkboxes configured separately - with template

Define template:

  plugin 'FormFieldsFromJSON' => {
    dir      => './conf',
    template => '<%= $label %>: <%= $form %>';
  };

Config:

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : "internal"
    },
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : "external"
    }
 ]

Fields:

  Name: <input id="type" name="type" type="checkbox" value="internal" />
  
  
  
  Name: <input id="type" name="type" type="checkbox" value="external" />

=head3 Two checkboxes as a group - with template

Same template definition as above, but given this field config:

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : ["internal", "external" ]
    }
 ]

You get this:

  Name: <input id="type" name="type" type="checkbox" value="internal" />
  <input id="type" name="type" type="checkbox" value="external" />

=head3 Two checkboxes - one checked

Config:

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "data" : ["internal", "external" ],
        "selected" : ["internal"]
    }
 ]

Field:

  <input checked="checked" id="type" name="type" type="checkbox" value="internal" />
  <input id="type" name="type" type="checkbox" value="external" />

=head3 Checkboxes with HTML after every element

When you want to add some HTML code after every element - e.g. a C<< <br /> >> -
you can use I<after_element>

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "after_element" : "<br />",
        "data" : ["internal", "external", "unknown" ]
    }
 ]

Fields:

  <input id="type" name="type" type="checkbox" value="internal" />
  <br /><input id="type" name="type" type="checkbox" value="external" />
  <br /><input id="type" name="type" type="checkbox" value="unknown" />
  <br />

=head3 Checkboxes with values shown as label

When you want to show the value as a label, you can use I<show_value>.

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "show_value" : 1,
        "data" : ["internal", "external" ]
    }
 ]

Creates

  <input id="type" name="type" type="checkbox" value="internal" /> internal
  <input id="type" name="type" type="checkbox" value="external" /> external

=head3 Checkboxes with translated values for "sublabels"

If you want to show the "sublabels" and want them to be translated, you can
use I<translate_sublabels>

 [
    {
        "label" : "Name",
        "type" : "checkbox",
        "name" : "type",
        "show_value" : 1,
        "translate_sublabels" : 1,
        "data" : ["internal", "external" ]
    }
 ]

Given this plugin is used this way:

  plugin 'FormFieldsFromJSON' => {
      dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
      translation_method => \&loc,
  };
  
  sub loc {
      my ($c, $value) = @_;
  
      my %translation = ( internal => 'intern', external => 'extern' );
      return $translation{$value} // $value;
  };

You'll get

  <input id="type" name="type" type="checkbox" value="internal" /> intern
  <input id="type" name="type" type="checkbox" value="external" /> extern

=head2 textarea

This type is very similar to L<text|Mojolicious::Plugin::FormFieldsFromJSON/text>.

=head3 A simple textarea

This is the configuration for a simple text field:

 [
    {
        "type" : "textarea",
        "name" : "message",
        "data" : "Current message"
    }
 ]

And the generated form field looks like

  <textarea id="message" name="message">Current message</textarea>

=head3 A textarea with defined number of columns and rows

This is the configuration for a simple text field:

 [
    {
        "type" : "textarea",
        "name" : "message",
        "data" : "Current message",
        "attributes" : {
            "cols" : 80,
            "rows" : 10
        }
    }
 ]

And the generated textarea looks like

  <textarea cols="80" id="message" name="message" rows="10">Current message</textarea>

=head2 password

This type is very similar to L<text|Mojolicious::Plugin::FormFieldsFromJSON/text>.
You can use the very same settings as for text fields, so we show only a simple
example here:

=head3 A simple password field

This is the configuration for a simple text field:

 [
    {
        "type" : "password",
        "name" : "user_password"
    }
 ]

And the generated form field looks like

 <input id="user_password" name="password" type="password" value="" />

=head1 Templates

Especially when you work with frameworks like Bootstrap, you want to 
your form fields to look nice. For that the form fields are within
C<div>s or other HTML elements.

To make your life easier, you can define templates. Either a "global"
one, a type specific template or a template for one field.

For hidden fields, no template is applied!

=head2 A global template

When you load the plugin this way

  $self->plugin( 'FormFieldsFromJSON' => {
    template => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
  });

and have a configuration that looks like

You get

  <label for="name">Name:</label><div><input id="name" name="name" type="text" value="" /></div>
  
   
  <label for="password">Password:</label><div><input id="password" name="password" type="text" value="" /></div>

=head2 A type specific template

When you want to use a different template for select fields, you can use a
different template for that kind of fields:

  plugin 'FormFieldsFromJSON' => {
    dir       => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
    template  => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
    templates => {
      select => '<%= $label %>: <%= $field %>',
    },
  };

With a configuration file like 

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name"
    }
    {
        "label" : "Country",
        "type" : "select",
        "name" : "country",
        "data" : [ "au" ]
    }
 ]

You get 

  <label for="name">Name:</label><div><input id="name" name="name" type="text" value="" /></div>
  
   
  Country: <select id="country" name="country"><option value="au">au</option></select>

=head2 A field specific template

When you want to use a different template for a specific field, you can use the
C<template> field in the configuration file.

  plugin 'FormFieldsFromJSON' => {
    dir       => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
    template  => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
  };

With a configuration file like 

 [
    {
        "label" : "Name",
        "type" : "text",
        "name" : "name"
    }
    {
        "label" : "Country",
        "type" : "select",
        "name" : "country",
        "data" : [ "au" ],
        "template" : "<%= $label %>: <%= $field %>"
    }
 ]

You get 

  <label for="name">Name:</label><div><input id="name" name="name" type="text" value="" /></div>
  
   
  Country: <select id="country" name="country"><option value="au">au</option></select>

=head2 Template variables

You get three template variables for free:

=over 4

=item * $label

If a label is defined in the field configuration

=item * $field

The form field (HTML)

=item * $id

The id for the field. If no id is defined, the name of the field is set.

=back

=head1 Validation

You can define some validation rules in your config file. And when you call C<validate_form_fields>, the
fields defined in the configuration file are validated.

L<Mojolicious::Validator::Validation> is shipped with some basic validation checks:

=over 4

=item * in

=item * size

=item * like

=item * equal_to

=back

There is L<Mojolicious::Plugin::AdditionalValidationChecks> with some more basic checks. And you can also
define your own checks.

The I<validation> field is a hashref where the name of the check is the key
and the parameters for the check can be defined in the value:

  "validation" : {
      "size" : [ 2, 5 ]
  },

This will call C<< ->size(2,5) >>. If you want to pass a single parameter,
you can set a scalar:

  "validation" : {
      "equal_to" : "foo"
  },

Validation checks are done in asciibetical order.

=head2 Check a string for its length

This is a simple check for the length of a string

 [
    {
        "label" : "Name",
        "type" : "text",
        "validation" : {
            "size" : [ 2, 5 ]
        },
        "name" : "name"
    }
 ]

Then you can call C<validate_form_fields>:

  my %errors = $c->validate_form_fields( $config_name );

In the returned hash, you get the fieldnames as keys where a validation check fails.

=head2 A mandatory string

If you have mandatory fields, you can define them as required

 [
    {
        "label" : "Name",
        "type" : "text",
        "validation" : {
            "required" : "name"
        },
        "name" : "name"
    }
 ]

=head2 Provide your own error message

With the simple configuration seen above, the C<%error> hash contains the value "1" for
each invalid field. If you want to get a better error message, you can define a hash
in the validation config

 [
    {
        "label" : "Name",
        "type" : "text",
        "validation" : {
            "like" : { "args" : [ "es" ], "msg" : "text must contain 'es'" },
            "size" : { "args" : [ 2, 5 ], "msg" : "length must be between 2 and 5 chars" }
        },
        "name" : "name"
    }
 ]

Examples:

  text   | error
  -------+---------------------------------
  test   |
  t      | text must contain 'es'
  tester | length must be between 2 and 5 chars

=head1 Translation

Most webapplications nowadays are internationalized, therefor this module
provides some support for translations.

If I<translate_labels> is set to a true value, a template is used and
I<translation_method> is given, the labels are translated.

=head2 translation_method

I<translation_method> has to be a reference to a subroutine.

=head3 An example for translation

Load and configure the plugin:

  plugin 'FormFieldsFromJSON' => {
    dir                => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
    template           => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
    translate_labels   => 1,
    translation_method => \&loc,
  };

The translation method gets two parameters:

=over 4

=item * the controller object

=item * the label

=back

  sub loc {
      my ($c, $value) = @_;
  
      my %translation = ( Address => 'Adresse' );
      return $translation{$value} // $value;
  };

This can be a more complex subroutine that makes use of any translation framework.

Given this field configuration file:

 [
    {
        "label" : "Address",
        "type" : "text",
        "name" : "name"
    }
 ]

You'll get

  <label for="name">Adresse:</label><div><input id="name" name="name" type="text" value="" /></div>

=head2 Internationalization

There is more about internationalization (i18n) than just translation. There are
dates, ranges, order of characters etc. But that can't be covered within this
single module. There are more Mojolicious plugins that provide more features
about i18n:

=over 4

=item * L<Mojolicious::Plugin::I18N>

=item * L<Mojolicious::Plugin::TagHelpersI18N>

=item * L<Mojolicious::Plugin::I18NUtils>

=item * L<Mojolicious::Plugin::CountryDropDown>

=back

You can combine these plugins with this plugin. An example is available at
L<the code repository|http://github.com/reneeb/Mojolicious-Plugin-FormFieldsFromJSON/tree/master/example>.

=head2 New Types

The field types supported by this plugin might not enough for you. Then you can create your own plugin
and add new types. For example, dates in L<OTRS|http://otrs.org> are shown as three dropdowns: one for
the day, one for the month and finally one for the year.

Wouldn't it be nice to define only one field in your config and the rest is DWIM (Do what I mean)?
It would.

So you can write your own Mojolicious plugin where the register subroutine does nothing. And you define
a subroutine called C<Mojolicious::Plugin::FormFieldsFromJSON::_date> where those dropdowns are created.

Then just do:

  plugin 'WhateverYouHaveChosen';
  plugin 'FormFieldsFromJSON' => {
    types => {
        'date' => 1,
    },
  };

Now you can use 

  [
    {
      "label" : "Release date",
      "type" : "date",
      "name" : "release"
    }
  ]

The subroutine gets these parameters:

=over 4

=item * The plugin object (Mojolicious::Plugin::FormFieldsFromJSON object)

So you can use the methods defined in this plugin, for example to create
dropdowns, textfields, ...

=item * The controller object (Whatever controller called C<form_fields> method)

So you can use all the Mojolicious power!

=item * The field config

Whatever you defined in you .json config file for that field

=item * A params hash 

Whatever is passed as parameters to the C<form_fields> method.

=back

As an example, you can see L<Mojolicious::Plugin::FormFieldsFromJSON::Date>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

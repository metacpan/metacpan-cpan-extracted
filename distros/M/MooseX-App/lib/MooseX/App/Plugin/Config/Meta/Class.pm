# ============================================================================
package MooseX::App::Plugin::Config::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

around 'command_proto' => sub {
    my ($orig,$self,$metaclass) = @_;

    my ($result,$errors) = $self->$orig($metaclass);
    delete $result->{config}
        unless defined $result->{config};

    return $self->proto_config($metaclass,$result,$errors);
};

sub proto_config {
    my ($self,$metaclass,$result,$errors) = @_;

    # Check if we have a config
    return ($result,$errors)
        unless defined $result->{config};

    # Read config
    my $config_file = Path::Class::File->new($result->{config});

    unless (-e $config_file->stringify) {
        push(@{$errors},
            $self->command_message(
                header          => "Could not find config file '".$config_file->stringify."'",
                type            => "error",
            ),
        );
        return ($result,$errors);
    }

    my $config_file_name = $config_file->stringify;
    my $configs = Config::Any->load_files({
        files   => [ $config_file_name ],
        use_ext => 1,
    });

    my $command_name = $self->command_class_to_command($metaclass->name);

    my ($config_data) = values %{$configs->[0]};

    # Merge
    $config_data->{global} ||= {};
    $config_data->{$command_name} ||= {};

    # Set config data
    $result->{config} = $result->{config};
    $result->{_config_data} = $config_data;

    # Lopp all attributes

    foreach my $attribute ($self->command_usage_attributes($metaclass,'all')) {
        my $attribute_name = $attribute->name;
        next
            if $attribute_name eq 'config' || $attribute_name eq 'help_flag';
        $result->{$attribute_name} = $config_data->{global}{$attribute_name}
            if defined $config_data->{global}{$attribute_name};
        $result->{$attribute_name} = $config_data->{$command_name}{$attribute_name}
            if defined $config_data->{$command_name}{$attribute_name};
    }

    return ($result,$errors);
};

1;
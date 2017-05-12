# ============================================================================
package MooseX::App::Plugin::Depends::Meta::Class;
# ============================================================================

use Moose::Role;
use namespace::autoclean;

around 'command_check_attributes' => sub {
    my ($orig, $self, $command_meta, $errors, $params) = @_;
    $command_meta ||= $self;

    ATTR:
    foreach my $attribute ( $self->command_usage_attributes($command_meta, 'all') ) {
        next ATTR
            unless defined $params->{ $attribute->cmd_name_primary };
        next ATTR
            unless $attribute->can('depends')
            && ref($attribute->depends) eq 'ARRAY'
            && scalar @{ $attribute->depends } > 0;

    OPT:
    foreach my $required_option ( @{ $attribute->depends } ) {
        next OPT
            if defined $params->{$required_option};

        my $error_msg = "Option "
            . "'" . $attribute->cmd_name_primary . "'"
            . " requires '$required_option' to be defined";

        push @$errors,
            $self->command_message(
               header => $error_msg,
               type   => 'error',
            );
        }
    }

    return $self->$orig($command_meta, $errors, $params);
};

1;

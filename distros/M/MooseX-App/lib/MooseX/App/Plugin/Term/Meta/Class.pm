# ============================================================================
package MooseX::App::Plugin::Term::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use IO::Interactive qw(is_interactive);

around 'command_check_attributes' => sub {
    my ($orig,$self,$command_meta,$errors,$params) = @_;

    $command_meta ||= $self;

    if (scalar @{$errors} == 0
        && is_interactive()) {

        my $prompt = 1;
        foreach my $attribute ($self->command_usage_attributes($command_meta,'all')) {
            if ($attribute->is_required
                && ! exists $params->{$attribute->name}
                && (! $attribute->can('cmd_term') || $attribute->cmd_term == 0 )) {
                $prompt = 0;
            }
        }

        if ($prompt) {
            foreach my $attribute ($self->command_usage_attributes($command_meta,'all')) {
                next
                    unless $attribute->can('cmd_term')
                    && $attribute->cmd_term;

                if (! defined $params->{$attribute->name}) {
                    my $return = $attribute->cmd_term_read();
                    $params->{$attribute->name} = $return
                        if defined $return;
                }
            }

        }
    }

    return $self->$orig($command_meta,$errors,$params);
};

1;
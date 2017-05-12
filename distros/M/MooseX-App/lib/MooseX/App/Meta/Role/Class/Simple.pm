# ============================================================================
package MooseX::App::Meta::Role::Class::Simple;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

around 'command_usage_header' => sub {
    my ($orig,$self) = @_;

    my $caller = $self->app_base;

    my $usage;
    # Get usage from command if available
    if ($self->can('command_usage')
        && $self->command_usage_predicate) {
        $usage = MooseX::App::Utils::format_text($self->command_usage);
    }

    # Autobuild usage
    unless ($usage) {
        my $command = $caller;
        my @parameter= $self->command_usage_attributes($self,'parameter');
        foreach my $attribute (@parameter) {
            if ($attribute->is_required) {
                $command .= " <".$attribute->cmd_usage_name.'>';
            } else {
                $command .= ' ['.$attribute->cmd_usage_name.']';
            }
        }
        $usage = MooseX::App::Utils::format_text("$command [long options...]
$caller --help")
    }

    return $self->command_message(
        header  => 'usage:',
        body    => $usage
    ); # LOCALIZE
};

1;
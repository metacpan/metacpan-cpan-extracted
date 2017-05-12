# ============================================================================
package MooseX::App::Plugin::MutexGroup::Meta::Class;
# ============================================================================

use Moose::Role;
use namespace::autoclean;

around 'command_check_attributes' => sub {
    my ( $orig, $self, $command_meta, $errors, $params ) = @_;
    $command_meta ||= $self;

    my %mutex_groups;
    foreach my $attribute (
        $self->command_usage_attributes( $command_meta, 'all' ) ) {
        push @{ $mutex_groups{ $attribute->mutexgroup } }, $attribute
            if $attribute->can('mutexgroup')
            && defined $attribute->mutexgroup;
    }

    foreach my $options ( values %mutex_groups ) {
        my @initialized_options =
            grep { defined $params->{ $_->name } }
            @$options;

        unless ( scalar @initialized_options == 1 ) {
            my $error_msg;

            if (scalar @initialized_options == 0) {
                my $last = pop @$options;
                $error_msg = "Either ".
                    join(",", map { $_->cmd_name_primary } @$options).
                    " or ".
                    $last->cmd_name_primary.
                    " must be specified";
            } else {
                my @list = map { $_->cmd_name_primary } @initialized_options;
                my $last = pop(@list);

                $error_msg = "Options ".
                    join(",",@list).
                    " and ".
                    $last.
                    " are mutally exclusive";
            }

            push @$errors,
                $self->command_message(
                header => $error_msg,
                type   => "error",
            );
        }
    }

    return $self->$orig( $command_meta, $errors, $params );
};

1;

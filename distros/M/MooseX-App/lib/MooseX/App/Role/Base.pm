# ============================================================================
package MooseX::App::Role::Base;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub initialize_command_class {
    my ($class,$command_class,%args) = @_;

    my $meta = $class->meta;

    Moose->throw_error('initialize_command_class is a class method')
        if blessed($class);

    my ($ok,$error) = Class::Load::try_load_class($command_class);
    unless ($ok) {
        Moose->throw_error($error);
    }

    my $command_meta = $command_class->meta || $meta;

    # Build MooseX::App::ParsedArgv and set hints
    my $parsed_argv = MooseX::App::ParsedArgv->instance();
    my $hints = $meta->command_parser_hints($command_meta);
    $parsed_argv->hints_fixedvalue($hints->{fixedvalue});
    $parsed_argv->hints_novalue($hints->{novalue});
    if ($meta->app_permute) {
        $parsed_argv->hints_permute($hints->{permute});
    }

    my ($proto_result,$proto_errors) = $meta->command_proto($command_meta);

    # TODO return some kind of null class object
    return
        unless defined $proto_result;

    my @errors = @{$proto_errors};

    # Return user-requested help
    if ($proto_result->{help_flag}) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_command($command_class->meta),
        );
    }

    my ($result,$errors) = $meta->command_args($command_meta);
    push(@errors,@{$errors});

    my %params;
    if ($meta->app_prefer_commandline) {
        %params = (
            %args,              # configs passed to new
            %{ $proto_result }, # config params
            %{ $result },       # params from CLI
        );
    } else {
        %params = (
            %{ $proto_result }, # config params
            %{ $result },       # params from CLI
            %args,              # configs passed to new
        );
    }

    $meta->command_check_attributes($command_meta,\@errors,\%params);

    if (scalar @errors) {
        return MooseX::App::Message::Envelope->new(
            @errors,
            $meta->command_usage_command($command_meta),
            1, # exitcode
        );
    }

    my $command_object = $command_class->new(
        %params,
        extra_argv          => [ $parsed_argv->extra ],
    );

    if (scalar @errors) {
        return MooseX::App::Message::Envelope->new(
            @errors,
            $meta->command_usage_command($command_meta),
            1, # exitcode
        );
    }

    return $command_object;
}


1;
package SignalWire::Skills::Builtin::Datetime;
use strict;
use warnings;
use Moo;
use POSIX qw(strftime);
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('datetime', __PACKAGE__);

has '+skill_name'        => (default => sub { 'datetime' });
has '+skill_description' => (default => sub { 'Get current date, time, and timezone information' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;

    $self->define_tool(
        name        => 'get_current_time',
        description => 'Get the current time, optionally in a specific timezone',
        parameters  => {
            type       => 'object',
            properties => {
                timezone => { type => 'string', description => 'Timezone (e.g. UTC, US/Eastern)', default => 'UTC' },
            },
        },
        handler => sub {
            my ($args, $raw) = @_;
            my $tz = $args->{timezone} // 'UTC';
            local $ENV{TZ} = $tz;
            POSIX::tzset();
            my $time = strftime('%H:%M:%S %Z', localtime);
            POSIX::tzset();  # Reset
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                response => "The current time in $tz is $time"
            );
        },
    );

    $self->define_tool(
        name        => 'get_current_date',
        description => 'Get the current date',
        parameters  => {
            type       => 'object',
            properties => {
                timezone => { type => 'string', description => 'Timezone (e.g. UTC, US/Eastern)', default => 'UTC' },
            },
        },
        handler => sub {
            my ($args, $raw) = @_;
            my $tz = $args->{timezone} // 'UTC';
            local $ENV{TZ} = $tz;
            POSIX::tzset();
            my $date = strftime('%Y-%m-%d', localtime);
            POSIX::tzset();
            require SignalWire::SWAIG::FunctionResult;
            return SignalWire::SWAIG::FunctionResult->new(
                response => "The current date in $tz is $date"
            );
        },
    );
}

sub _get_prompt_sections {
    return [{
        title   => 'Date and Time Information',
        body    => 'You can get the current date and time in any timezone.',
        bullets => [
            'Use get_current_time to get the current time',
            'Use get_current_date to get the current date',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
    };
}

1;

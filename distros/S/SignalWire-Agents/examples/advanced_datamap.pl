#!/usr/bin/env perl
# Advanced DataMap Features Demo
#
# Demonstrates all comprehensive DataMap features including:
# - Expressions with patterns and nomatch output
# - Advanced webhook features (headers, form_param, require_args)
# - Post-webhook expressions
# - Fallback chains and global error keys
# - Array processing with foreach

use strict;
use warnings;
use lib 'lib';
use JSON ();
use SignalWire::Agents;
use SignalWire::Agents::DataMap;
use SignalWire::Agents::SWAIG::FunctionResult;

# 1. Expression-based command processor
my $command_processor = SignalWire::Agents::DataMap->new('command_processor')
    ->description('Process user commands with pattern matching')
    ->parameter('command', 'string', 'User command to process', required => 1)
    ->parameter('target', 'string', 'Optional target for the command')
    ->expression(
        '${args.command}', '^start',
        SignalWire::Agents::SWAIG::FunctionResult->new('Starting process: ${args.target}'),
    )
    ->expression(
        '${args.command}', '^stop',
        SignalWire::Agents::SWAIG::FunctionResult->new('Stopping process: ${args.target}'),
    )
    ->expression(
        '${args.command}', '^status',
        SignalWire::Agents::SWAIG::FunctionResult->new('Checking status of: ${args.target}'),
        nomatch_output => SignalWire::Agents::SWAIG::FunctionResult->new(
            'Unknown command: ${args.command}. Try start, stop, or status.'
        ),
    );

# 2. Advanced webhook with headers and form encoding
my $advanced_api = SignalWire::Agents::DataMap->new('advanced_api_tool')
    ->description('API tool with advanced webhook features')
    ->parameter('action', 'string', 'Action to perform', required => 1)
    ->parameter('data', 'string', 'Data to send')
    ->webhook('POST', 'https://api.example.com/advanced',
        headers => {
            'Authorization' => 'Bearer ${token}',
            'User-Agent'    => 'SignalWire-Agent/1.0',
        },
    )
    ->output(SignalWire::Agents::SWAIG::FunctionResult->new('API result: ${response.data}'))
    ->webhook('GET', 'https://backup-api.example.com/simple',
        headers => { Accept => 'application/json' },
    )
    ->output(SignalWire::Agents::SWAIG::FunctionResult->new('Backup result: ${response.data}'))
    ->fallback_output(SignalWire::Agents::SWAIG::FunctionResult->new(
        'All APIs are currently unavailable'
    ))
    ->global_error_keys(['error', 'fault', 'exception']);

# 3. Form encoding submission
my $form_tool = SignalWire::Agents::DataMap->new('form_submission_tool')
    ->description('Submit form data using form encoding')
    ->parameter('name',    'string', 'User name',       required => 1)
    ->parameter('email',   'string', 'User email',      required => 1)
    ->parameter('message', 'string', 'Message content',  required => 1)
    ->webhook('POST', 'https://forms.example.com/submit',
        headers => {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'X-API-Key'    => '${api_key}',
        },
    )
    ->params({
        name    => '${args.name}',
        email   => '${args.email}',
        message => '${args.message}',
    })
    ->output(SignalWire::Agents::SWAIG::FunctionResult->new(
        'Form submitted successfully for ${args.name}'
    ))
    ->error_keys(['error', 'validation_errors']);

# 4. Conditional logic with expressions and fallback
my $calculator = SignalWire::Agents::DataMap->new('smart_calculator')
    ->description('Smart calculator with conditional responses')
    ->parameter('expression', 'string', 'Mathematical expression', required => 1)
    ->parameter('format',     'string', 'Output format (simple/detailed)')
    ->expression(
        '${args.expression}', '^\s*\d+\s*[+\-*/]\s*\d+\s*$',
        SignalWire::Agents::SWAIG::FunctionResult->new(
            'Quick calculation: ${args.expression} = @{expr ${args.expression}}'
        ),
    )
    ->expression(
        '${args.format}', '^detailed$',
        SignalWire::Agents::SWAIG::FunctionResult->new(
            'Detailed: ${args.expression} = @{expr ${args.expression}}'
        ),
    )
    ->fallback_output(SignalWire::Agents::SWAIG::FunctionResult->new(
        'Expression: ${args.expression} Result: @{expr ${args.expression}}'
    ));

# Display all demo tool definitions
my @demos = (
    ['Expression Demo',        $command_processor],
    ['Advanced Webhook Demo',  $advanced_api],
    ['Form Encoding Demo',     $form_tool],
    ['Conditional Logic Demo', $calculator],
);

my $json = JSON->new->utf8->canonical->pretty;

for my $pair (@demos) {
    my ($name, $dm) = @$pair;
    print "\n" . ('=' x 50) . "\n";
    print "$name\n";
    print '=' x 50, "\n";
    print $json->encode($dm->to_swaig_function);
}

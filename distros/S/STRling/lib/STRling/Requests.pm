package STRling::Requests;

use 5.010;
use strict;
use warnings;

# STRling-public-arity: source_compile_request=1..2
sub source_compile_request {
    my ($source, $options) = @_;
    $options ||= {};
    my $specification = defined($options->{specification_version}) ? "$options->{specification_version}" : '1.0-draft.1';
    my $frontend = defined($options->{frontend_id}) ? "$options->{frontend_id}" : 'strling.semantic';
    my $request = {
        contract_version => '1.0.0',
        specification_version => $specification,
        input => {
            kind => 'source',
            document => {
                contract_version => '1.0.0',
                source_id => defined($options->{source_id}) ? "$options->{source_id}" : 'src:perl.adapter',
                specification_version => $specification,
                frontend => {
                    id => $frontend,
                    dialect_version => defined($options->{frontend_version}) ? "$options->{frontend_version}" : '1.0.0',
                },
                content => {
                    kind => 'inline', encoding => 'utf-8',
                    media_type => defined($options->{media_type}) ? "$options->{media_type}" : ($frontend eq 'strling.regex-compat' ? 'text/x-strling-regex-compat' : 'text/x-strling-semantic'),
                    text => "$source",
                },
                provenance => { kind => 'authored' },
            },
        },
        requested_outputs => $options->{requested_outputs} || ['semantic', 'analysis'],
        compiler_options => $options->{compiler_options} || {
            partial_semantics => 'forbid',
            diagnostic_policy => { minimum_severity => 'hint' },
        },
    };
    $request->{target_profile} = $options->{target_profile_reference} if exists $options->{target_profile_reference};
    return $request;
}

# STRling-public-arity: stdlib_helper=2..3
sub stdlib_helper {
    my ($step_id, $helper_id, $parameters) = @_;
    return {
        step_id => "$step_id", operation => 'stdlib_helper',
        arguments => { helper_id => "$helper_id", parameters => $parameters || {} },
    };
}

# STRling-public-arity: simply_builder_request=2..3
sub simply_builder_request {
    my ($steps, $root_step_id, $identity_namespace) = @_;
    return {
        protocol_version => '1.1.0', contract_version => '1.0.0',
        specification_version => '1.0-draft.1',
        identity_namespace => defined($identity_namespace) ? $identity_namespace : 'perl.adapter',
        semantic_options => {
            case_matching => 'sensitive', text_model => 'unicode_scalar_values',
            builtin_character_domain => 'unicode', wildcard_line_terminators => 'exclude',
        },
        steps => $steps, root_step_id => "$root_step_id",
        compile => {
            requested_outputs => ['semantic', 'analysis'],
            compiler_options => {
                partial_semantics => 'forbid',
                diagnostic_policy => { minimum_severity => 'hint' },
            },
        },
    };
}

1;

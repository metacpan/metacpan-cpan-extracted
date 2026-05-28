package SignalWire::SWAIG::FunctionResult;
use strict;
use warnings;
use Moo;
use JSON ();

has 'response' => (
    is      => 'rw',
    default => sub { '' },
);

has 'action' => (
    is      => 'rw',
    default => sub { [] },
);

has 'post_process' => (
    is      => 'rw',
    default => sub { 0 },
);

# Constructor: new(response => "text") or new("text") or new("text", post_process => 1)
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    if (@args == 1 && !ref $args[0]) {
        return $class->$orig(response => $args[0]);
    }
    if (@args >= 1 && !ref $args[0] && $args[0] !~ /^(response|action|post_process)$/) {
        my $resp = shift @args;
        return $class->$orig(response => $resp, @args);
    }
    return $class->$orig(@args);
};

# --- Core methods ---

sub set_response {
    my ($self, $response) = @_;
    $self->response($response);
    return $self;
}

sub set_post_process {
    my ($self, $post_process) = @_;
    $self->post_process($post_process ? 1 : 0);
    return $self;
}

sub add_action {
    my ($self, $name, $data) = @_;
    push @{ $self->action }, { $name => $data };
    return $self;
}

sub add_actions {
    my ($self, $actions) = @_;
    push @{ $self->action }, @$actions;
    return $self;
}

# --- Call Control ---

sub connect {
    my ($self, $destination, %opts) = @_;
    my $final = exists $opts{final} ? $opts{final} : 1;
    my $from  = $opts{from};

    my $connect_params = { to => $destination };
    $connect_params->{from} = $from if defined $from;

    my $swml_action = {
        SWML => {
            sections => {
                main => [{ connect => $connect_params }],
            },
            version => '1.0.0',
        },
        transfer => $final ? 'true' : 'false',
    };

    push @{ $self->action }, $swml_action;
    return $self;
}

sub swml_transfer {
    my ($self, $dest, $ai_response, %opts) = @_;
    my $final = exists $opts{final} ? $opts{final} : 1;

    my $swml_action = {
        SWML => {
            version  => '1.0.0',
            sections => {
                main => [
                    { set      => { ai_response => $ai_response } },
                    { transfer => { dest        => $dest } },
                ],
            },
        },
        transfer => $final ? 'true' : 'false',
    };

    push @{ $self->action }, $swml_action;
    return $self;
}

sub hangup {
    my ($self) = @_;
    return $self->add_action('hangup', JSON::true);
}

sub hold {
    my ($self, $timeout) = @_;
    $timeout //= 300;
    $timeout = 0   if $timeout < 0;
    $timeout = 900 if $timeout > 900;
    return $self->add_action('hold', $timeout);
}

sub wait_for_user {
    my ($self, %opts) = @_;
    my $enabled      = $opts{enabled};
    my $timeout      = $opts{timeout};
    my $answer_first = $opts{answer_first};

    my $value;
    if ($answer_first) {
        $value = 'answer_first';
    } elsif (defined $timeout) {
        $value = $timeout;
    } elsif (defined $enabled) {
        $value = $enabled ? JSON::true : JSON::false;
    } else {
        $value = JSON::true;
    }
    return $self->add_action('wait_for_user', $value);
}

sub stop {
    my ($self) = @_;
    return $self->add_action('stop', JSON::true);
}

# --- State & Data ---

sub update_global_data {
    my ($self, $data) = @_;
    return $self->add_action('set_global_data', $data);
}

sub remove_global_data {
    my ($self, $keys) = @_;
    return $self->add_action('unset_global_data', $keys);
}

sub set_metadata {
    my ($self, $data) = @_;
    return $self->add_action('set_meta_data', $data);
}

sub remove_metadata {
    my ($self, $keys) = @_;
    return $self->add_action('unset_meta_data', $keys);
}

sub swml_user_event {
    my ($self, $event_data) = @_;
    my $swml_action = {
        sections => {
            main => [{
                user_event => { event => $event_data },
            }],
        },
        version => '1.0.0',
    };
    return $self->add_action('SWML', $swml_action);
}

sub swml_change_step {
    my ($self, $step_name) = @_;
    return $self->add_action('change_step', $step_name);
}

sub swml_change_context {
    my ($self, $context_name) = @_;
    return $self->add_action('change_context', $context_name);
}

sub switch_context {
    my ($self, %opts) = @_;
    my $system_prompt = $opts{system_prompt};
    my $user_prompt   = $opts{user_prompt};
    my $consolidate   = $opts{consolidate};
    my $full_reset    = $opts{full_reset};

    if ($system_prompt && !$user_prompt && !$consolidate && !$full_reset) {
        return $self->add_action('context_switch', $system_prompt);
    }

    my %ctx;
    $ctx{system_prompt} = $system_prompt if $system_prompt;
    $ctx{user_prompt}   = $user_prompt   if $user_prompt;
    $ctx{consolidate}   = JSON::true     if $consolidate;
    $ctx{full_reset}    = JSON::true     if $full_reset;
    return $self->add_action('context_switch', \%ctx);
}

sub replace_in_history {
    my ($self, $text) = @_;
    $text //= JSON::true;
    return $self->add_action('replace_in_history', $text);
}

# --- Media ---

sub say {
    my ($self, $text) = @_;
    return $self->add_action('say', $text);
}

sub play_background_file {
    my ($self, $filename, %opts) = @_;
    my $wait = $opts{wait};
    if ($wait) {
        return $self->add_action('playback_bg', { file => $filename, wait => JSON::true });
    }
    return $self->add_action('playback_bg', $filename);
}

sub stop_background_file {
    my ($self) = @_;
    return $self->add_action('stop_playback_bg', JSON::true);
}

sub record_call {
    my ($self, %opts) = @_;
    my $control_id = $opts{control_id};
    my $stereo     = $opts{stereo}    // 0;
    my $format     = $opts{format}    // 'wav';
    my $direction  = $opts{direction} // 'both';

    die "format must be 'wav' or 'mp3'" unless $format eq 'wav' || $format eq 'mp3';
    die "direction must be 'speak', 'listen', or 'both'"
        unless $direction eq 'speak' || $direction eq 'listen' || $direction eq 'both';

    my %params = (
        stereo    => $stereo ? JSON::true : JSON::false,
        format    => $format,
        direction => $direction,
    );
    $params{control_id} = $control_id if $control_id;

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ record_call => \%params }] },
    };
    return $self->execute_swml($swml_doc);
}

sub stop_record_call {
    my ($self, %opts) = @_;
    my $control_id = $opts{control_id};
    my %params;
    $params{control_id} = $control_id if $control_id;

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ stop_record_call => \%params }] },
    };
    return $self->execute_swml($swml_doc);
}

# --- Speech & AI ---

sub add_dynamic_hints {
    my ($self, $hints) = @_;
    return $self->add_action('add_dynamic_hints', $hints);
}

sub clear_dynamic_hints {
    my ($self) = @_;
    push @{ $self->action }, { clear_dynamic_hints => {} };
    return $self;
}

sub set_end_of_speech_timeout {
    my ($self, $ms) = @_;
    return $self->add_action('end_of_speech_timeout', $ms);
}

sub set_speech_event_timeout {
    my ($self, $ms) = @_;
    return $self->add_action('speech_event_timeout', $ms);
}

sub toggle_functions {
    my ($self, $toggles) = @_;
    return $self->add_action('toggle_functions', $toggles);
}

sub enable_functions_on_timeout {
    my ($self, $enabled) = @_;
    $enabled //= 1;
    return $self->add_action('functions_on_speaker_timeout', $enabled ? JSON::true : JSON::false);
}

sub enable_extensive_data {
    my ($self, $enabled) = @_;
    $enabled //= 1;
    return $self->add_action('extensive_data', $enabled ? JSON::true : JSON::false);
}

sub update_settings {
    my ($self, $settings) = @_;
    return $self->add_action('settings', $settings);
}

# --- Advanced ---

sub execute_swml {
    my ($self, $swml_content, %opts) = @_;
    my $transfer = $opts{transfer} // 0;

    my $swml_data;
    if (ref $swml_content eq 'HASH') {
        # Deep-copy to avoid mutating caller's data
        $swml_data = JSON::decode_json(JSON::encode_json($swml_content));
    } elsif (!ref $swml_content) {
        # String - try parsing as JSON
        eval {
            $swml_data = JSON::decode_json($swml_content);
        };
        if ($@) {
            $swml_data = { raw_swml => $swml_content };
        }
    } else {
        die "swml_content must be a string or hashref";
    }

    if ($transfer) {
        $swml_data->{transfer} = 'true';
    }

    return $self->add_action('SWML', $swml_data);
}

sub join_conference {
    my ($self, $name, %opts) = @_;
    die "name cannot be empty" unless defined $name && length $name;

    my $muted = $opts{muted} // 0;
    my $beep  = $opts{beep}  // 'true';

    # Simple form: no options set
    if (!$muted && $beep eq 'true' && !keys %opts) {
        my $swml_doc = {
            version  => '1.0.0',
            sections => { main => [{ join_conference => $name }] },
        };
        return $self->execute_swml($swml_doc);
    }

    my %params = (name => $name);
    $params{muted} = JSON::true if $muted;
    $params{beep}  = $beep      if $beep ne 'true';

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ join_conference => \%params }] },
    };
    return $self->execute_swml($swml_doc);
}

sub join_room {
    my ($self, $name) = @_;
    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ join_room => { name => $name } }] },
    };
    return $self->execute_swml($swml_doc);
}

sub sip_refer {
    my ($self, $to_uri) = @_;
    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ sip_refer => { to_uri => $to_uri } }] },
    };
    return $self->execute_swml($swml_doc);
}

sub tap {
    my ($self, $uri, %opts) = @_;
    my $control_id = $opts{control_id};
    my $direction  = $opts{direction} // 'both';
    my $codec      = $opts{codec}     // 'PCMU';

    die "direction must be 'speak', 'hear', or 'both'"
        unless $direction eq 'speak' || $direction eq 'hear' || $direction eq 'both';
    die "codec must be 'PCMU' or 'PCMA'"
        unless $codec eq 'PCMU' || $codec eq 'PCMA';

    my %params = (uri => $uri);
    $params{control_id} = $control_id if $control_id;
    $params{direction}  = $direction  if $direction ne 'both';
    $params{codec}      = $codec      if $codec ne 'PCMU';

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ tap => \%params }] },
    };
    return $self->execute_swml($swml_doc);
}

sub stop_tap {
    my ($self, %opts) = @_;
    my $control_id = $opts{control_id};
    my %params;
    $params{control_id} = $control_id if $control_id;

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ stop_tap => \%params }] },
    };
    return $self->execute_swml($swml_doc);
}

sub send_sms {
    my ($self, %opts) = @_;
    my $to_number   = $opts{to_number}   // die "to_number is required";
    my $from_number = $opts{from_number} // die "from_number is required";
    my $body        = $opts{body};
    my $media       = $opts{media};
    my $tags        = $opts{tags};
    my $region      = $opts{region};

    die "Either body or media must be provided" unless $body || $media;

    my %sms_params = (
        to_number   => $to_number,
        from_number => $from_number,
    );
    $sms_params{body}   = $body   if $body;
    $sms_params{media}  = $media  if $media;
    $sms_params{tags}   = $tags   if $tags;
    $sms_params{region} = $region if $region;

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ send_sms => \%sms_params }] },
    };
    return $self->execute_swml($swml_doc);
}

sub pay {
    my ($self, %opts) = @_;
    my $connector_url = $opts{payment_connector_url} // die "payment_connector_url required";
    my $input_method  = $opts{input_method}  // 'dtmf';
    my $timeout       = $opts{timeout}       // 5;
    my $max_attempts  = $opts{max_attempts}  // 1;
    my $ai_response   = $opts{ai_response}   // 'The payment status is ${pay_result}, do not mention anything else about collecting payment if successful.';

    my %pay_params = (
        payment_connector_url => $connector_url,
        input                 => $input_method,
        payment_method        => $opts{payment_method} // 'credit-card',
        timeout               => "$timeout",
        max_attempts          => "$max_attempts",
        security_code         => (($opts{security_code} // 1) ? 'true' : 'false'),
        token_type            => $opts{token_type}  // 'reusable',
        currency              => $opts{currency}    // 'usd',
        language              => $opts{language}    // 'en-US',
        voice                 => $opts{voice}       // 'woman',
        valid_card_types      => $opts{valid_card_types} // 'visa mastercard amex',
    );

    my $postal = $opts{postal_code} // 1;
    if (ref $postal || $postal =~ /^[01]$/) {
        $pay_params{postal_code} = $postal ? 'true' : 'false';
    } else {
        $pay_params{postal_code} = $postal;
    }

    $pay_params{status_url}    = $opts{status_url}    if $opts{status_url};
    $pay_params{charge_amount} = $opts{charge_amount} if $opts{charge_amount};
    $pay_params{description}   = $opts{description}   if $opts{description};
    $pay_params{parameters}    = $opts{parameters}    if $opts{parameters};
    $pay_params{prompts}       = $opts{prompts}       if $opts{prompts};

    my $swml_doc = {
        version  => '1.0.0',
        sections => {
            main => [
                { set => { ai_response => $ai_response } },
                { pay => \%pay_params },
            ],
        },
    };
    return $self->execute_swml($swml_doc);
}

# --- RPC ---

sub execute_rpc {
    my ($self, %opts) = @_;
    my $method  = $opts{method}  // die "method is required";
    my $params  = $opts{params};
    my $call_id = $opts{call_id};
    my $node_id = $opts{node_id};

    my %rpc_params = (method => $method);
    $rpc_params{call_id} = $call_id if $call_id;
    $rpc_params{node_id} = $node_id if $node_id;
    $rpc_params{params}  = $params  if $params;

    my $swml_doc = {
        version  => '1.0.0',
        sections => { main => [{ execute_rpc => \%rpc_params }] },
    };
    return $self->execute_swml($swml_doc);
}

sub rpc_dial {
    my ($self, %opts) = @_;
    my $to_number   = $opts{to_number}   // die "to_number is required";
    my $from_number = $opts{from_number} // die "from_number is required";
    my $dest_swml   = $opts{dest_swml}   // die "dest_swml is required";
    my $device_type = $opts{device_type} // 'phone';

    return $self->execute_rpc(
        method => 'dial',
        params => {
            devices => {
                type   => $device_type,
                params => {
                    to_number   => $to_number,
                    from_number => $from_number,
                },
            },
            dest_swml => $dest_swml,
        },
    );
}

sub rpc_ai_message {
    my ($self, %opts) = @_;
    my $call_id      = $opts{call_id}      // die "call_id is required";
    my $message_text = $opts{message_text} // die "message_text is required";
    my $role         = $opts{role}         // 'system';

    return $self->execute_rpc(
        method  => 'ai_message',
        call_id => $call_id,
        params  => {
            role         => $role,
            message_text => $message_text,
        },
    );
}

sub rpc_ai_unhold {
    my ($self, %opts) = @_;
    my $call_id = $opts{call_id} // die "call_id is required";

    return $self->execute_rpc(
        method  => 'ai_unhold',
        call_id => $call_id,
        params  => {},
    );
}

sub simulate_user_input {
    my ($self, $text) = @_;
    return $self->add_action('user_input', $text);
}

# --- Payment helpers (class methods) ---

sub create_payment_prompt {
    my ($class_or_self, %opts) = @_;
    my $for_situation = $opts{for_situation} // die "for_situation is required";
    my $actions       = $opts{actions}       // die "actions is required";
    my $card_type     = $opts{card_type};
    my $error_type    = $opts{error_type};

    my %prompt = (
        for     => $for_situation,
        actions => $actions,
    );
    $prompt{card_type}  = $card_type  if $card_type;
    $prompt{error_type} = $error_type if $error_type;

    return \%prompt;
}

sub create_payment_action {
    my ($class_or_self, $action_type, $phrase) = @_;
    return { type => $action_type, phrase => $phrase };
}

sub create_payment_parameter {
    my ($class_or_self, $name, $value) = @_;
    return { name => $name, value => $value };
}

# --- Serialization ---

sub to_hash {
    my ($self) = @_;
    my %result;

    $result{response} = $self->response if length $self->response;

    if (@{ $self->action }) {
        $result{action} = $self->action;
        $result{post_process} = JSON::true if $self->post_process;
    }

    # Ensure at least one of response or action
    if (!keys %result) {
        $result{response} = 'Action completed.';
    }

    return \%result;
}

sub to_json {
    my ($self) = @_;
    return JSON::encode_json($self->to_hash);
}

1;

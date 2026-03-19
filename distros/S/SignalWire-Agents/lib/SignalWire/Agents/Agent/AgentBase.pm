package SignalWire::Agents::Agent::AgentBase;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(hmac_sha256_hex);
use POSIX qw(strftime);
use Scalar::Util qw(blessed reftype);
use Storable qw(dclone);
use Carp qw(croak);

# ---------- attributes ----------

has name               => (is => 'rw', default => sub { 'agent' });
has route              => (is => 'rw', default => sub { '/' });
has host               => (is => 'rw', default => sub { '0.0.0.0' });
has port               => (is => 'rw', default => sub { $ENV{PORT} || 3000 });
has basic_auth_user    => (is => 'rw', lazy => 1, builder => '_build_basic_auth_user');
has basic_auth_password => (is => 'rw', lazy => 1, builder => '_build_basic_auth_password');

# Call settings
has auto_answer   => (is => 'rw', default => sub { 1 });
has record_call   => (is => 'rw', default => sub { 0 });
has record_format => (is => 'rw', default => sub { 'mp4' });
has record_stereo => (is => 'rw', default => sub { 1 });

# Prompt system
has prompt_text         => (is => 'rw', default => sub { '' });
has post_prompt         => (is => 'rw', default => sub { '' });
has use_pom             => (is => 'rw', default => sub { 1 });
has pom_sections        => (is => 'rw', default => sub { [] });

# Tool registry
has tools      => (is => 'rw', default => sub { {} });
has tool_order => (is => 'rw', default => sub { [] });

# AI config
has hints              => (is => 'rw', default => sub { [] });
has pattern_hints      => (is => 'rw', default => sub { [] });
has languages          => (is => 'rw', default => sub { [] });
has pronunciations     => (is => 'rw', default => sub { [] });
has params             => (is => 'rw', default => sub { {} });
has global_data        => (is => 'rw', default => sub { {} });
has native_functions   => (is => 'rw', default => sub { [] });

# Internal settings
has internal_fillers     => (is => 'rw', default => sub { undef });
has debug_events_level   => (is => 'rw', default => sub { 0 });

# Includes and LLM params
has function_includes       => (is => 'rw', default => sub { [] });
has prompt_llm_params       => (is => 'rw', default => sub { {} });
has post_prompt_llm_params  => (is => 'rw', default => sub { {} });

# Verb insertion points
has pre_answer_verbs   => (is => 'rw', default => sub { [] });
has post_answer_verbs  => (is => 'rw', default => sub { [] });
has post_ai_verbs      => (is => 'rw', default => sub { [] });
has answer_config      => (is => 'rw', default => sub { {} });

# Context system (lazy)
has context_builder => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_context_builder',
);

# Callbacks
has dynamic_config_callback => (is => 'rw', default => sub { undef });
has summary_callback        => (is => 'rw', default => sub { undef });
has debug_event_handler     => (is => 'rw', default => sub { undef });

# URLs
has webhook_url       => (is => 'rw', default => sub { undef });
has post_prompt_url   => (is => 'rw', default => sub { undef });
has proxy_url_base    => (is => 'rw', lazy => 1, builder => '_build_proxy_url_base');
has swaig_query_params => (is => 'rw', default => sub { {} });

# Session manager (built in BUILD)
has session_manager => (is => 'rw');

# Skill manager
has skill_manager => (is => 'rw', lazy => 1, builder => '_build_skill_manager');

# ---------- builders ----------

sub _build_basic_auth_user {
    my ($self) = @_;
    return $ENV{SWML_BASIC_AUTH_USER} || $self->name;
}

sub _build_basic_auth_password {
    my ($self) = @_;
    return $ENV{SWML_BASIC_AUTH_PASSWORD} || _generate_random_password();
}

sub _build_proxy_url_base {
    return $ENV{SWML_PROXY_URL_BASE} || undef;
}

sub _build_context_builder {
    require SignalWire::Agents::Contexts::ContextBuilder;
    return SignalWire::Agents::Contexts::ContextBuilder->new;
}

sub _build_skill_manager {
    my ($self) = @_;
    require SignalWire::Agents::Skills::SkillManager;
    return SignalWire::Agents::Skills::SkillManager->new(agent => $self);
}

sub BUILD {
    my ($self) = @_;

    # Strip trailing slash from route
    my $r = $self->route;
    $r =~ s{/+$}{} if $r ne '/';
    $self->route($r);

    # Initialize session manager
    require SignalWire::Agents::Security::SessionManager;
    $self->session_manager(
        SignalWire::Agents::Security::SessionManager->new(token_expiry_secs => 3600)
    );
}

# ---------- Prompt methods ----------

sub set_prompt_text {
    my ($self, $text) = @_;
    $self->prompt_text($text);
    return $self;
}

sub set_post_prompt {
    my ($self, $text) = @_;
    $self->post_prompt($text);
    return $self;
}

sub prompt_add_section {
    my ($self, $title, $body, %opts) = @_;
    my $section = {
        title => $title,
        body  => $body // '',
    };
    $section->{bullets} = $opts{bullets} if $opts{bullets};
    push @{ $self->pom_sections }, $section;
    return $self;
}

sub prompt_add_subsection {
    my ($self, $parent_title, $title, $body, %opts) = @_;
    for my $sec (@{ $self->pom_sections }) {
        if ($sec->{title} eq $parent_title) {
            $sec->{subsections} //= [];
            my $sub = { title => $title, body => $body // '' };
            $sub->{bullets} = $opts{bullets} if $opts{bullets};
            push @{ $sec->{subsections} }, $sub;
            last;
        }
    }
    return $self;
}

sub prompt_add_to_section {
    my ($self, $title, %opts) = @_;
    for my $sec (@{ $self->pom_sections }) {
        if ($sec->{title} eq $title) {
            if ($opts{body}) {
                $sec->{body} .= "\n" . $opts{body};
            }
            if ($opts{bullets}) {
                $sec->{bullets} //= [];
                push @{ $sec->{bullets} }, @{ $opts{bullets} };
            }
            last;
        }
    }
    return $self;
}

sub prompt_has_section {
    my ($self, $title) = @_;
    for my $sec (@{ $self->pom_sections }) {
        return 1 if $sec->{title} eq $title;
    }
    return 0;
}

sub get_prompt {
    my ($self) = @_;
    if ($self->use_pom && @{ $self->pom_sections }) {
        return $self->pom_sections;
    }
    return $self->prompt_text;
}

# ---------- Tool methods ----------

sub define_tool {
    my ($self, %opts) = @_;
    my $name        = $opts{name}        // croak("define_tool requires 'name'");
    my $description = $opts{description} // '';
    my $parameters  = $opts{parameters}  // { type => 'object', properties => {} };
    my $handler     = $opts{handler};

    my $tool_def = {
        function    => $name,
        description => $description,
        parameters  => $parameters,
        (defined $handler ? (_handler => $handler) : ()),
    };

    # Merge any extra fields (fillers, meta_data_token, etc.)
    for my $k (keys %opts) {
        next if $k =~ /^(name|description|parameters|handler)$/;
        $tool_def->{$k} = $opts{$k};
    }

    $self->tools->{$name} = $tool_def;
    # Maintain insertion order
    push @{ $self->tool_order }, $name
        unless grep { $_ eq $name } @{ $self->tool_order };

    return $self;
}

sub register_swaig_function {
    my ($self, $func_def) = @_;
    my $name = $func_def->{function} // croak("register_swaig_function needs 'function' key");
    $self->tools->{$name} = $func_def;
    push @{ $self->tool_order }, $name
        unless grep { $_ eq $name } @{ $self->tool_order };
    return $self;
}

sub define_tools {
    my ($self, @tool_defs) = @_;
    for my $t (@tool_defs) {
        if (ref $t eq 'HASH') {
            if (exists $t->{function}) {
                $self->register_swaig_function($t);
            } else {
                $self->define_tool(%$t);
            }
        }
    }
    return $self;
}

sub on_function_call {
    my ($self, $name, $args, $raw_data) = @_;
    my $tool = $self->tools->{$name};
    return undef unless $tool && $tool->{_handler};
    return $tool->{_handler}->($args, $raw_data);
}

# ---------- AI Config methods ----------

sub add_hint {
    my ($self, $hint) = @_;
    push @{ $self->hints }, $hint;
    return $self;
}

sub add_hints {
    my ($self, @h) = @_;
    push @{ $self->hints }, @h;
    return $self;
}

sub add_pattern_hint {
    my ($self, $pattern) = @_;
    push @{ $self->pattern_hints }, $pattern;
    return $self;
}

sub add_language {
    my ($self, %lang) = @_;
    push @{ $self->languages }, \%lang;
    return $self;
}

sub set_languages {
    my ($self, $langs) = @_;
    $self->languages($langs);
    return $self;
}

sub add_pronunciation {
    my ($self, %pron) = @_;
    push @{ $self->pronunciations }, \%pron;
    return $self;
}

sub set_pronunciations {
    my ($self, $prons) = @_;
    $self->pronunciations($prons);
    return $self;
}

sub set_param {
    my ($self, $key, $value) = @_;
    $self->params->{$key} = $value;
    return $self;
}

sub set_params {
    my ($self, $p) = @_;
    $self->params({ %{ $self->params }, %$p });
    return $self;
}

sub set_global_data {
    my ($self, $data) = @_;
    $self->global_data($data);
    return $self;
}

sub update_global_data {
    my ($self, $data) = @_;
    $self->global_data({ %{ $self->global_data }, %$data });
    return $self;
}

sub set_native_functions {
    my ($self, $funcs) = @_;
    $self->native_functions($funcs);
    return $self;
}

sub set_internal_fillers {
    my ($self, $fillers) = @_;
    $self->internal_fillers($fillers);
    return $self;
}

sub add_internal_filler {
    my ($self, $filler) = @_;
    if (!defined $self->internal_fillers) {
        $self->internal_fillers([]);
    }
    push @{ $self->internal_fillers }, $filler;
    return $self;
}

sub enable_debug_events {
    my ($self, $level) = @_;
    $level //= 1;
    $self->debug_events_level($level);
    return $self;
}

sub add_function_include {
    my ($self, $include) = @_;
    push @{ $self->function_includes }, $include;
    return $self;
}

sub set_function_includes {
    my ($self, $includes) = @_;
    $self->function_includes($includes);
    return $self;
}

sub set_prompt_llm_params {
    my ($self, %p) = @_;
    $self->prompt_llm_params({ %{ $self->prompt_llm_params }, %p });
    return $self;
}

sub set_post_prompt_llm_params {
    my ($self, %p) = @_;
    $self->post_prompt_llm_params({ %{ $self->post_prompt_llm_params }, %p });
    return $self;
}

# ---------- Verb management ----------

sub add_pre_answer_verb {
    my ($self, $verb_name, $verb_config) = @_;
    push @{ $self->pre_answer_verbs }, { $verb_name => $verb_config };
    return $self;
}

sub add_post_answer_verb {
    my ($self, $verb_name, $verb_config) = @_;
    push @{ $self->post_answer_verbs }, { $verb_name => $verb_config };
    return $self;
}

sub add_post_ai_verb {
    my ($self, $verb_name, $verb_config) = @_;
    push @{ $self->post_ai_verbs }, { $verb_name => $verb_config };
    return $self;
}

sub clear_pre_answer_verbs {
    my ($self) = @_;
    $self->pre_answer_verbs([]);
    return $self;
}

sub clear_post_answer_verbs {
    my ($self) = @_;
    $self->post_answer_verbs([]);
    return $self;
}

sub clear_post_ai_verbs {
    my ($self) = @_;
    $self->post_ai_verbs([]);
    return $self;
}

sub set_answer_config {
    my ($self, $config) = @_;
    $self->answer_config($config);
    return $self;
}

# ---------- Contexts ----------

sub define_contexts {
    my ($self) = @_;
    return $self->context_builder;
}

sub contexts {
    my ($self) = @_;
    return $self->context_builder;
}

# ---------- Skills ----------

sub add_skill {
    my ($self, $skill_name, $params) = @_;
    $params //= {};
    return $self->skill_manager->load_skill($skill_name, undef, $params);
}

sub remove_skill {
    my ($self, $skill_name) = @_;
    return $self->skill_manager->unload_skill($skill_name);
}

sub list_skills {
    my ($self) = @_;
    return $self->skill_manager->list_skills;
}

sub has_skill {
    my ($self, $skill_name) = @_;
    return $self->skill_manager->has_skill($skill_name);
}

# ---------- Web / callback setters ----------

sub set_dynamic_config_callback {
    my ($self, $cb) = @_;
    $self->dynamic_config_callback($cb);
    return $self;
}

sub set_web_hook_url {
    my ($self, $url) = @_;
    $self->webhook_url($url);
    return $self;
}

sub set_post_prompt_url {
    my ($self, $url) = @_;
    $self->post_prompt_url($url);
    return $self;
}

sub manual_set_proxy_url {
    my ($self, $url) = @_;
    $self->proxy_url_base($url);
    return $self;
}

sub add_swaig_query_params {
    my ($self, %params) = @_;
    $self->swaig_query_params({ %{ $self->swaig_query_params }, %params });
    return $self;
}

sub clear_swaig_query_params {
    my ($self) = @_;
    $self->swaig_query_params({});
    return $self;
}

sub on_summary {
    my ($self, $cb) = @_;
    $self->summary_callback($cb);
    return $self;
}

sub on_debug_event {
    my ($self, $cb) = @_;
    $self->debug_event_handler($cb);
    return $self;
}

# ---------- URL construction ----------

sub _build_webhook_url {
    my ($self, $request_env) = @_;
    # If explicit override set, use it
    return $self->webhook_url if defined $self->webhook_url;

    my $base = $self->_detect_proxy_url($request_env);
    my $route = $self->route eq '/' ? '' : $self->route;
    my $url = $base . $route . '/swaig';

    # Append query params
    if (%{ $self->swaig_query_params }) {
        my @parts;
        for my $k (sort keys %{ $self->swaig_query_params }) {
            push @parts, "$k=" . ($self->swaig_query_params->{$k} // '');
        }
        $url .= '?' . join('&', @parts);
    }

    return $url;
}

sub _build_post_prompt_url {
    my ($self, $request_env) = @_;
    return $self->post_prompt_url if defined $self->post_prompt_url;
    my $base = $self->_detect_proxy_url($request_env);
    my $route = $self->route eq '/' ? '' : $self->route;
    return $base . $route . '/post_prompt';
}

sub _detect_proxy_url {
    my ($self, $env) = @_;

    return $self->proxy_url_base if defined $self->proxy_url_base;

    $env //= {};

    # Check X-Forwarded headers
    my $proto = $env->{HTTP_X_FORWARDED_PROTO};
    my $fhost = $env->{HTTP_X_FORWARDED_HOST};
    if ($proto && $fhost) {
        return "${proto}://${fhost}";
    }

    # Check X-Original-URL
    my $orig = $env->{HTTP_X_ORIGINAL_URL};
    return $orig if $orig;

    # Fallback to server config
    my $scheme = ($env->{HTTPS} || $env->{'psgi.url_scheme'} || 'http');
    $scheme = 'https' if $scheme eq 'on';
    my $host = $env->{HTTP_HOST} || $self->host . ':' . $self->port;
    return "${scheme}://${host}";
}

sub get_full_url {
    my ($self, %opts) = @_;
    my $base = $self->proxy_url_base // ('http://' . $self->host . ':' . $self->port);
    my $route = $self->route eq '/' ? '' : $self->route;
    my $url = $base . $route;
    if ($opts{include_auth}) {
        my $user = $self->basic_auth_user;
        my $pass = $self->basic_auth_password;
        $url =~ s{^(https?://)}{$1${user}:${pass}\@};
    }
    return $url;
}

# ---------- render_swml (5-phase pipeline) ----------

sub render_swml {
    my ($self, $request_env) = @_;
    $request_env //= {};

    my $webhook_url     = $self->_build_webhook_url($request_env);
    my $post_prompt_url = $self->_build_post_prompt_url($request_env);

    # Embed auth credentials in webhook URL
    my $auth_user = $self->basic_auth_user;
    my $auth_pass = $self->basic_auth_password;
    $webhook_url =~ s{^(https?://)}{$1${auth_user}:${auth_pass}\@}
        unless $webhook_url =~ /\@/;
    $post_prompt_url =~ s{^(https?://)}{$1${auth_user}:${auth_pass}\@}
        unless $post_prompt_url =~ /\@/;

    my @main_section;

    # Phase 1: Pre-answer verbs
    push @main_section, @{ $self->pre_answer_verbs };

    # Phase 2: Answer verb
    if ($self->auto_answer) {
        my %answer_params = (max_duration => 14400);
        %answer_params = (%answer_params, %{ $self->answer_config }) if %{ $self->answer_config };
        push @main_section, { answer => \%answer_params };
    }

    # Record call if enabled
    if ($self->record_call) {
        push @main_section, { record_call => {
            format => $self->record_format,
            stereo => $self->record_stereo ? JSON::true : JSON::false,
        }};
    }

    # Phase 3: Post-answer verbs
    push @main_section, @{ $self->post_answer_verbs };

    # Phase 4: AI verb
    my $ai = $self->_build_ai_verb($webhook_url, $post_prompt_url);
    push @main_section, { ai => $ai };

    # Phase 5: Post-AI verbs
    push @main_section, @{ $self->post_ai_verbs };

    my $doc = {
        version  => '1.0.0',
        sections => { main => \@main_section },
    };

    return $doc;
}

sub _build_ai_verb {
    my ($self, $webhook_url, $post_prompt_url) = @_;

    my %ai;

    # Prompt
    my $prompt = $self->get_prompt;
    if (ref $prompt eq 'ARRAY') {
        # POM mode
        $ai{prompt} = { pom => $prompt };
    } else {
        $ai{prompt} = { text => $prompt } if $prompt;
    }

    # Merge prompt LLM params
    if (%{ $self->prompt_llm_params }) {
        $ai{prompt} //= {};
        for my $k (keys %{ $self->prompt_llm_params }) {
            $ai{prompt}{$k} = $self->prompt_llm_params->{$k};
        }
    }

    # Post prompt
    if ($self->post_prompt && $self->post_prompt ne '') {
        $ai{post_prompt} = { text => $self->post_prompt };
        if (%{ $self->post_prompt_llm_params }) {
            for my $k (keys %{ $self->post_prompt_llm_params }) {
                $ai{post_prompt}{$k} = $self->post_prompt_llm_params->{$k};
            }
        }
    }

    $ai{post_prompt_url} = $post_prompt_url if $post_prompt_url;

    # Params
    $ai{params} = { %{ $self->params } } if %{ $self->params };

    # Hints
    my @all_hints = @{ $self->hints };
    push @all_hints, @{ $self->pattern_hints };
    $ai{hints} = \@all_hints if @all_hints;

    # Languages
    $ai{languages} = $self->languages if @{ $self->languages };

    # Pronunciations
    $ai{pronounce} = $self->pronunciations if @{ $self->pronunciations };

    # SWAIG
    my $swaig = {};

    # Build function list
    my @functions;
    for my $fname (@{ $self->tool_order }) {
        my $tool = $self->tools->{$fname};
        next unless $tool;
        my %func = %$tool;
        delete $func{_handler};    # Don't include handler in SWML
        $func{web_hook_url} //= $webhook_url;
        push @functions, \%func;
    }
    $swaig->{functions} = \@functions if @functions;

    # Native functions
    $swaig->{native_functions} = $self->native_functions
        if @{ $self->native_functions };

    # Includes
    $swaig->{includes} = $self->function_includes
        if @{ $self->function_includes };

    $ai{SWAIG} = $swaig if %$swaig;

    # Global data
    $ai{global_data} = { %{ $self->global_data } }
        if %{ $self->global_data };

    # Internal fillers
    if (defined $self->internal_fillers) {
        $ai{params} //= {};
        $ai{params}{internal_fillers} = $self->internal_fillers;
    }

    # Debug events
    if ($self->debug_events_level > 0) {
        $ai{params} //= {};
        $ai{params}{debug_events} = $self->debug_events_level;
    }

    # Contexts
    if ($self->context_builder && $self->context_builder->has_contexts) {
        $ai{context_switch} = $self->context_builder->to_hashref;
    }

    return \%ai;
}

# ---------- PSGI / Plack ----------

sub psgi_app {
    my ($self) = @_;
    return $self->_build_psgi_app;
}

sub _build_psgi_app {
    my ($self) = @_;
    require Plack::Request;

    my $route = $self->route;
    $route = '' if $route eq '/';

    my $agent = $self;

    # Build the core app as a plain PSGI sub
    my $core_app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $path = $req->path_info;

        # Normalize path
        $path =~ s{/+$}{} unless $path eq '/';

        # Health/ready endpoints (no auth)
        if ($path eq '/health') {
            return [200, ['Content-Type' => 'application/json'],
                [encode_json({ status => 'healthy', agent => $agent->name })]];
        }
        if ($path eq '/ready') {
            return [200, ['Content-Type' => 'application/json'],
                [encode_json({ status => 'ready' })]];
        }

        # Auth check for protected routes
        my $expected_route  = $route eq '' ? '/' : $route;
        my $is_swaig       = ($path eq "$route/swaig");
        my $is_post_prompt  = ($path eq "$route/post_prompt");
        my $is_main         = ($path eq $expected_route || ($route ne '' && $path eq "$route/"));

        # Root agent: treat '/' as main
        if ($route eq '' && $path eq '/') {
            $is_main = 1;
        }

        if ($is_main || $is_swaig || $is_post_prompt) {
            my $auth_ok = $agent->_check_auth($env);
            unless ($auth_ok) {
                return [401,
                    ['Content-Type' => 'text/plain', 'WWW-Authenticate' => 'Basic realm="SignalWire Agent"'],
                    ['Unauthorized']];
            }
        }

        # Route dispatch
        if ($is_main && ($req->method eq 'GET' || $req->method eq 'POST')) {
            return $agent->_handle_swml($env, $req);
        }
        elsif ($is_swaig && $req->method eq 'POST') {
            return $agent->_handle_swaig($env, $req);
        }
        elsif ($is_post_prompt && $req->method eq 'POST') {
            return $agent->_handle_post_prompt($env, $req);
        }

        return [404, ['Content-Type' => 'text/plain'], ['Not Found']];
    };

    # Maximum request body size: 1MB
    my $max_body_size = 1_048_576;

    # Wrap with body size limit and security headers middleware
    my $app_with_middleware = sub {
        my $env = shift;

        # Enforce body size limit by actually reading the body
        if ($env->{REQUEST_METHOD} eq 'POST' || $env->{REQUEST_METHOD} eq 'PUT') {
            my $input = $env->{'psgi.input'};
            if ($input) {
                my $body = '';
                my $total = 0;
                my $buf;
                while (my $read = $input->read($buf, 8192)) {
                    $total += $read;
                    if ($total > $max_body_size) {
                        return [413, ['Content-Type' => 'application/json',
                                      'X-Content-Type-Options' => 'nosniff',
                                      'X-Frame-Options' => 'DENY',
                                      'Cache-Control' => 'no-store'],
                            [encode_json({ error => 'Request body too large' })]];
                    }
                    $body .= $buf;
                }
                # Replace psgi.input with the buffered content so handlers can re-read
                open my $new_input, '<', \$body;
                $env->{'psgi.input'} = $new_input;
                $env->{CONTENT_LENGTH} = length($body);
            }
        }

        my $res = $core_app->($env);
        if (ref $res eq 'ARRAY') {
            push @{ $res->[1] },
                'X-Content-Type-Options' => 'nosniff',
                'X-Frame-Options'        => 'DENY',
                'Cache-Control'          => 'no-store';
        }
        return $res;
    };

    return $app_with_middleware;
}

sub _check_auth {
    my ($self, $env) = @_;
    my $auth_header = $env->{HTTP_AUTHORIZATION} // '';
    return 0 unless $auth_header =~ /^Basic\s+(.+)$/i;
    my $decoded = eval { decode_base64($1) } // '';
    my ($user, $pass) = split(/:/, $decoded, 2);
    return 0 unless defined $user && defined $pass;

    # Timing-safe comparison using HMAC (constant-time, no length leak)
    my $expected_user = $self->basic_auth_user;
    my $expected_pass = $self->basic_auth_password;

    my $user_ok = _timing_safe_eq($user, $expected_user);
    my $pass_ok = _timing_safe_eq($pass, $expected_pass);

    return ($user_ok && $pass_ok) ? 1 : 0;
}

sub _timing_safe_eq {
    my ($a, $b) = @_;
    # HMAC-based constant-time comparison: no length leak
    my $key = 'signalwire-timing-safe-comparison';
    my $hmac_a = hmac_sha256_hex($a, $key);
    my $hmac_b = hmac_sha256_hex($b, $key);
    return $hmac_a eq $hmac_b;
}

sub _handle_swml {
    my ($self, $env, $req) = @_;

    my $agent = $self;

    # If dynamic config callback is set, clone and apply
    if ($self->dynamic_config_callback) {
        $agent = $self->_clone_for_request;
        my $query_params = $req->query_parameters->as_hashref_mixed;
        my $body_params  = {};
        if ($req->method eq 'POST' && $req->content_length) {
            eval { $body_params = decode_json($req->content) };
        }
        my $headers = {};
        for my $k (keys %$env) {
            if ($k =~ /^HTTP_(.+)/) {
                $headers->{lc($1)} = $env->{$k};
            }
        }
        $self->dynamic_config_callback->($query_params, $body_params, $headers, $agent);
    }

    my $swml = $agent->render_swml($env);
    my $json = encode_json($swml);

    return [200, ['Content-Type' => 'application/json'], [$json]];
}

sub _handle_swaig {
    my ($self, $env, $req) = @_;

    my $body = eval { decode_json($req->content) };
    unless ($body && ref $body eq 'HASH') {
        return [400, ['Content-Type' => 'application/json'],
            [encode_json({ error => 'Invalid JSON' })]];
    }

    my $func_name = $body->{function};
    unless ($func_name && exists $self->tools->{$func_name}) {
        return [404, ['Content-Type' => 'application/json'],
            [encode_json({ error => 'Function not found' })]];
    }

    # Extract args
    my $args = {};
    if ($body->{argument} && ref $body->{argument}{parsed} eq 'ARRAY'
        && @{ $body->{argument}{parsed} }) {
        $args = $body->{argument}{parsed}[0] // {};
    }

    my $result = $self->on_function_call($func_name, $args, $body);
    unless (defined $result) {
        return [500, ['Content-Type' => 'application/json'],
            [encode_json({ error => 'Handler returned no result' })]];
    }

    # Serialize result
    my $response;
    if (blessed($result) && $result->can('to_hash')) {
        $response = $result->to_hash;
    } elsif (ref $result eq 'HASH') {
        $response = $result;
    } else {
        $response = { response => "$result" };
    }

    return [200, ['Content-Type' => 'application/json'], [encode_json($response)]];
}

sub _handle_post_prompt {
    my ($self, $env, $req) = @_;

    my $body = eval { decode_json($req->content) };
    $body //= {};

    if ($self->summary_callback) {
        my $summary = undef;
        if ($body->{post_prompt_data}) {
            $summary = $body->{post_prompt_data}{parsed}
                    // $body->{post_prompt_data}{raw};
        }
        $self->summary_callback->($summary, $body);
    }

    return [200, ['Content-Type' => 'application/json'],
        [encode_json({ status => 'ok' })]];
}

# ---------- Clone for dynamic config ----------

sub _clone_for_request {
    my ($self) = @_;
    my %init;
    for my $attr (qw(name route host port auto_answer record_call record_format
                     record_stereo prompt_text post_prompt use_pom
                     debug_events_level)) {
        $init{$attr} = $self->$attr;
    }
    # Deep copy complex attributes
    $init{pom_sections}        = dclone($self->pom_sections);
    $init{tools}               = dclone($self->tools);
    $init{tool_order}          = [ @{ $self->tool_order } ];
    $init{hints}               = [ @{ $self->hints } ];
    $init{pattern_hints}       = [ @{ $self->pattern_hints } ];
    $init{languages}           = dclone($self->languages);
    $init{pronunciations}      = dclone($self->pronunciations);
    $init{params}              = { %{ $self->params } };
    $init{global_data}         = dclone($self->global_data);
    $init{native_functions}    = [ @{ $self->native_functions } ];
    $init{function_includes}   = dclone($self->function_includes);
    $init{prompt_llm_params}   = { %{ $self->prompt_llm_params } };
    $init{post_prompt_llm_params} = { %{ $self->post_prompt_llm_params } };
    $init{pre_answer_verbs}    = dclone($self->pre_answer_verbs);
    $init{post_answer_verbs}   = dclone($self->post_answer_verbs);
    $init{post_ai_verbs}       = dclone($self->post_ai_verbs);
    $init{answer_config}       = { %{ $self->answer_config } };
    $init{swaig_query_params}  = { %{ $self->swaig_query_params } };
    $init{basic_auth_user}     = $self->basic_auth_user;
    $init{basic_auth_password} = $self->basic_auth_password;
    $init{webhook_url}         = $self->webhook_url;
    $init{post_prompt_url}     = $self->post_prompt_url;
    $init{proxy_url_base}      = $self->proxy_url_base;
    $init{internal_fillers}    = defined $self->internal_fillers
                                    ? dclone($self->internal_fillers) : undef;
    $init{session_manager}     = $self->session_manager;

    my $clone = (ref $self)->new(%init);
    return $clone;
}

# ---------- run / serve ----------

sub run {
    my ($self, %opts) = @_;
    $self->serve(%opts);
}

sub serve {
    my ($self, %opts) = @_;
    my $app  = $self->psgi_app;
    my $host = $opts{host} // $self->host;
    my $port = $opts{port} // $self->port;

    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--host'   => $host,
        '--port'   => $port,
        '--server' => 'HTTP::Server::PSGI',
    );
    $runner->run($app);
}

# ---------- helpers ----------

sub _generate_random_password {
    # Use /dev/urandom for cryptographically secure random bytes.
    # Die on failure rather than falling back to a weak password.
    my $bytes = '';
    if (open my $fh, '<:raw', '/dev/urandom') {
        my $read = read($fh, $bytes, 32);
        close $fh;
        if (defined $read && $read == 32) {
            # Convert to hex string (64 chars)
            return unpack('H*', $bytes);
        }
    }
    die "FATAL: Cannot generate secure random password - /dev/urandom unavailable or read failed. "
      . "Set SWML_BASIC_AUTH_PASSWORD environment variable instead.\n";
}

sub extract_sip_username {
    my ($class_or_self, $body) = @_;
    # Extract SIP username from a request body (hashref).
    # Looks in standard SignalWire fields for the SIP caller identity.
    return undef unless ref $body eq 'HASH';

    # Check call.from field (e.g., "sip:user@domain")
    my $from = $body->{call}{from}
            // $body->{sip_from}
            // $body->{from}
            // '';

    if ($from =~ m{^sip:([^@]+)\@}i) {
        return $1;
    }

    # Check for a direct caller_id_number
    if (my $cid = $body->{call}{caller_id_number} // $body->{caller_id_number}) {
        return $cid;
    }

    return undef;
}

1;

package SignalWire::Contexts;
use strict;
use warnings;
use JSON ();

our $MAX_CONTEXTS        = 50;
our $MAX_STEPS_PER_CONTEXT = 100;

# Reserved tool names auto-injected by the runtime when contexts/steps are
# present. User-defined SWAIG tools must not collide with these names:
#   - next_step / change_context are injected when valid_steps or
#     valid_contexts is set so the model can navigate the flow.
#   - gather_submit is injected while a step's gather_info is collecting
#     answers.
# ContextBuilder->validate rejects any agent that registers a user tool
# sharing one of these names (see the validation in
# SignalWire::Contexts::ContextBuilder::validate below).
our %RESERVED_NATIVE_TOOL_NAMES = (
    next_step       => 1,
    change_context  => 1,
    gather_submit   => 1,
);

# ==========================================================================
# GatherQuestion
# ==========================================================================
package SignalWire::Contexts::GatherQuestion;
use Moo;
use JSON ();

has 'key'       => (is => 'ro', required => 1);
has 'question'  => (is => 'ro', required => 1);
has 'type'      => (is => 'ro', default => sub { 'string' });
has 'confirm'   => (is => 'ro', default => sub { 0 });
has 'prompt'    => (is => 'ro', default => sub { undef });
has 'functions' => (is => 'ro', default => sub { undef });

sub to_hash {
    my ($self) = @_;
    my %d = (key => $self->key, question => $self->question);
    $d{type}      = $self->type      if $self->type ne 'string';
    $d{confirm}   = JSON::true       if $self->confirm;
    $d{prompt}    = $self->prompt     if defined $self->prompt;
    $d{functions} = $self->functions  if defined $self->functions;
    return \%d;
}

# ==========================================================================
# GatherInfo
# ==========================================================================
package SignalWire::Contexts::GatherInfo;
use Moo;

has '_questions'        => (is => 'rw', default => sub { [] });
has '_output_key'       => (is => 'rw', default => sub { undef });
has '_completion_action' => (is => 'rw', default => sub { undef });
has '_prompt'           => (is => 'rw', default => sub { undef });

sub add_question {
    my ($self, %opts) = @_;
    my $q = SignalWire::Contexts::GatherQuestion->new(
        key       => $opts{key},
        question  => $opts{question},
        type      => $opts{type}      // 'string',
        confirm   => $opts{confirm}   // 0,
        prompt    => $opts{prompt},
        functions => $opts{functions},
    );
    push @{ $self->_questions }, $q;
    return $self;
}

sub to_hash {
    my ($self) = @_;
    die "gather_info must have at least one question" unless @{ $self->_questions };
    my %d = (questions => [ map { $_->to_hash } @{ $self->_questions } ]);
    $d{prompt}            = $self->_prompt            if defined $self->_prompt;
    $d{output_key}        = $self->_output_key        if defined $self->_output_key;
    $d{completion_action} = $self->_completion_action  if defined $self->_completion_action;
    return \%d;
}

# ==========================================================================
# Step
# ==========================================================================
package SignalWire::Contexts::Step;
use Moo;
use JSON ();

has 'name' => (is => 'ro', required => 1);

has '_text'             => (is => 'rw', default => sub { undef });
has '_step_criteria'    => (is => 'rw', default => sub { undef });
has '_functions'        => (is => 'rw', default => sub { undef });
has '_valid_steps'      => (is => 'rw', default => sub { undef });
has '_valid_contexts'   => (is => 'rw', default => sub { undef });
has '_sections'         => (is => 'rw', default => sub { [] });
has '_gather_info'      => (is => 'rw', default => sub { undef });
has '_end'              => (is => 'rw', default => sub { 0 });
has '_skip_user_turn'   => (is => 'rw', default => sub { 0 });
has '_skip_to_next_step' => (is => 'rw', default => sub { 0 });
has '_reset_system_prompt' => (is => 'rw', default => sub { undef });
has '_reset_user_prompt'   => (is => 'rw', default => sub { undef });
has '_reset_consolidate'   => (is => 'rw', default => sub { 0 });
has '_reset_full_reset'    => (is => 'rw', default => sub { 0 });

sub set_text {
    my ($self, $text) = @_;
    die "Cannot use set_text() when POM sections have been added"
        if @{ $self->_sections };
    $self->_text($text);
    return $self;
}

sub add_section {
    my ($self, $title, $body) = @_;
    die "Cannot add POM sections when set_text() has been used"
        if defined $self->_text;
    push @{ $self->_sections }, { title => $title, body => $body };
    return $self;
}

sub add_bullets {
    my ($self, $title, $bullets) = @_;
    die "Cannot add POM sections when set_text() has been used"
        if defined $self->_text;
    push @{ $self->_sections }, { title => $title, bullets => $bullets };
    return $self;
}

sub set_step_criteria {
    my ($self, $criteria) = @_;
    $self->_step_criteria($criteria);
    return $self;
}

#
# set_functions — set which non-internal functions are callable while this
# step is active.
#
# IMPORTANT — inheritance behavior:
#   If you do NOT call this method, the step inherits whichever function
#   set was active on the previous step (or the previous context's last
#   step). The server-side runtime only resets the active set when a step
#   explicitly declares its `functions` field. This is the most common
#   source of bugs in multi-step agents: forgetting set_functions on a
#   later step lets the previous step's tools leak through. Best practice
#   is to call set_functions explicitly on every step that should differ
#   from the previous one.
#
# Keep the per-step active set small: LLM tool selection accuracy
# degrades noticeably past ~7-8 simultaneously-active tools per call.
# Use per-step whitelisting to partition large tool collections.
#
# Arguments:
#   $functions — one of:
#     - arrayref of function names (whitelist)
#     - empty arrayref []         (explicit disable-all)
#     - the string "none"         (synonym for [])
#
# Internal functions (e.g. gather_submit, hangup_hook) are ALWAYS protected
# and cannot be deactivated by this whitelist. The native navigation tools
# next_step and change_context are injected automatically when
# set_valid_steps / set_valid_contexts is used; they are not affected by
# this list and do not need to appear in it.
#
sub set_functions {
    my ($self, $functions) = @_;
    $self->_functions($functions);
    return $self;
}

sub set_valid_steps {
    my ($self, $steps) = @_;
    $self->_valid_steps($steps);
    return $self;
}

sub set_valid_contexts {
    my ($self, $contexts) = @_;
    $self->_valid_contexts($contexts);
    return $self;
}

#
# set_end — mark this step as terminal for the step flow.
#
# IMPORTANT: end=1 does NOT end the conversation or hang up the call.
# It exits step mode entirely after this step executes — clearing the
# steps list, current step index, valid_steps, and valid_contexts. The
# agent keeps running, but operates only under the base system prompt
# and the context-level prompt; no more step instructions are injected
# and no more next_step tool is offered.
#
# To actually end the call, call a hangup tool or define a hangup hook.
#
sub set_end {
    my ($self, $end) = @_;
    $self->_end($end ? 1 : 0);
    return $self;
}

sub set_skip_user_turn {
    my ($self, $skip) = @_;
    $self->_skip_user_turn($skip ? 1 : 0);
    return $self;
}

sub set_skip_to_next_step {
    my ($self, $skip) = @_;
    $self->_skip_to_next_step($skip ? 1 : 0);
    return $self;
}

sub set_gather_info {
    my ($self, %opts) = @_;
    $self->_gather_info(SignalWire::Contexts::GatherInfo->new(
        _output_key       => $opts{output_key},
        _completion_action => $opts{completion_action},
        _prompt           => $opts{prompt},
    ));
    return $self;
}

#
# add_gather_question — add a question to this step's gather_info.
# set_gather_info() must be called before this method.
#
# IMPORTANT — gather mode locks function access:
#   While the model is asking gather questions, the runtime forcibly
#   deactivates ALL of the step's other functions. The only callable
#   tools during a gather question are:
#
#     - gather_submit (the native answer-submission tool)
#     - Whatever names you pass in this question's `functions` option
#
#   next_step and change_context are also filtered out — the model
#   cannot navigate away until the gather completes. This is by design:
#   it forces a tight ask → submit → next-question loop.
#
#   If a question needs to call out to a tool (e.g. validate an email,
#   geocode a ZIP), list that tool name in this question's `functions`
#   option. Functions listed here are active ONLY for this question.
#
sub add_gather_question {
    my ($self, %opts) = @_;
    die "Must call set_gather_info() before add_gather_question()"
        unless defined $self->_gather_info;
    $self->_gather_info->add_question(%opts);
    return $self;
}

sub clear_sections {
    my ($self) = @_;
    $self->_sections([]);
    $self->_text(undef);
    return $self;
}

sub set_reset_system_prompt {
    my ($self, $sp) = @_;
    $self->_reset_system_prompt($sp);
    return $self;
}

sub set_reset_user_prompt {
    my ($self, $up) = @_;
    $self->_reset_user_prompt($up);
    return $self;
}

sub set_reset_consolidate {
    my ($self, $c) = @_;
    $self->_reset_consolidate($c ? 1 : 0);
    return $self;
}

sub set_reset_full_reset {
    my ($self, $fr) = @_;
    $self->_reset_full_reset($fr ? 1 : 0);
    return $self;
}

sub _render_text {
    my ($self) = @_;
    return $self->_text if defined $self->_text;

    die "Step '" . $self->name . "' has no text or POM sections defined"
        unless @{ $self->_sections };

    my @parts;
    for my $sec (@{ $self->_sections }) {
        if (exists $sec->{bullets}) {
            push @parts, "## $sec->{title}";
            push @parts, map { "- $_" } @{ $sec->{bullets} };
        } else {
            push @parts, "## $sec->{title}";
            push @parts, $sec->{body};
        }
        push @parts, '';
    }
    my $text = join("\n", @parts);
    $text =~ s/\s+$//;
    return $text;
}

sub to_hash {
    my ($self) = @_;
    my %d = (
        name => $self->name,
        text => $self->_render_text,
    );

    $d{step_criteria}  = $self->_step_criteria  if defined $self->_step_criteria;
    $d{functions}      = $self->_functions       if defined $self->_functions;
    $d{valid_steps}    = $self->_valid_steps     if defined $self->_valid_steps;
    $d{valid_contexts} = $self->_valid_contexts  if defined $self->_valid_contexts;
    $d{end}            = JSON::true              if $self->_end;
    $d{skip_user_turn} = JSON::true              if $self->_skip_user_turn;
    $d{skip_to_next_step} = JSON::true           if $self->_skip_to_next_step;

    my %reset;
    $reset{system_prompt} = $self->_reset_system_prompt if defined $self->_reset_system_prompt;
    $reset{user_prompt}   = $self->_reset_user_prompt   if defined $self->_reset_user_prompt;
    $reset{consolidate}   = JSON::true                  if $self->_reset_consolidate;
    $reset{full_reset}    = JSON::true                  if $self->_reset_full_reset;
    $d{reset} = \%reset if keys %reset;

    $d{gather_info} = $self->_gather_info->to_hash if defined $self->_gather_info;

    return \%d;
}

# ==========================================================================
# Context
# ==========================================================================
package SignalWire::Contexts::Context;
use Moo;
use JSON ();

has 'name' => (is => 'ro', required => 1);

has '_steps'           => (is => 'rw', default => sub { {} });
has '_step_order'      => (is => 'rw', default => sub { [] });
has '_valid_contexts'  => (is => 'rw', default => sub { undef });
has '_valid_steps'     => (is => 'rw', default => sub { undef });
has '_initial_step'    => (is => 'rw', default => sub { undef });
has '_post_prompt'     => (is => 'rw', default => sub { undef });
has '_system_prompt'   => (is => 'rw', default => sub { undef });
has '_system_prompt_sections' => (is => 'rw', default => sub { [] });
has '_consolidate'     => (is => 'rw', default => sub { 0 });
has '_full_reset'      => (is => 'rw', default => sub { 0 });
has '_user_prompt'     => (is => 'rw', default => sub { undef });
has '_isolated'        => (is => 'rw', default => sub { 0 });
has '_prompt_text'     => (is => 'rw', default => sub { undef });
has '_prompt_sections' => (is => 'rw', default => sub { [] });
has '_enter_fillers'   => (is => 'rw', default => sub { undef });
has '_exit_fillers'    => (is => 'rw', default => sub { undef });

sub add_step {
    my ($self, $name, %opts) = @_;
    die "Step '$name' already exists in context '" . $self->name . "'"
        if exists $self->_steps->{$name};
    die "Maximum steps per context ($SignalWire::Contexts::MAX_STEPS_PER_CONTEXT) exceeded"
        if keys %{ $self->_steps } >= $SignalWire::Contexts::MAX_STEPS_PER_CONTEXT;

    my $step = SignalWire::Contexts::Step->new(name => $name);
    $self->_steps->{$name} = $step;
    push @{ $self->_step_order }, $name;

    $step->add_section('Task', $opts{task})     if defined $opts{task};
    $step->add_bullets('Process', $opts{bullets}) if defined $opts{bullets};
    $step->set_step_criteria($opts{criteria})     if defined $opts{criteria};
    $step->set_functions($opts{functions})         if defined $opts{functions};
    $step->set_valid_steps($opts{valid_steps})     if defined $opts{valid_steps};

    return $step;
}

sub get_step {
    my ($self, $name) = @_;
    return $self->_steps->{$name};
}

sub remove_step {
    my ($self, $name) = @_;
    if (exists $self->_steps->{$name}) {
        delete $self->_steps->{$name};
        $self->_step_order([ grep { $_ ne $name } @{ $self->_step_order } ]);
    }
    return $self;
}

sub move_step {
    my ($self, $name, $position) = @_;
    die "Step '$name' not found in context '" . $self->name . "'"
        unless exists $self->_steps->{$name};
    my @order = grep { $_ ne $name } @{ $self->_step_order };
    splice @order, $position, 0, $name;
    $self->_step_order(\@order);
    return $self;
}

#
# set_initial_step — set which step the context starts on when entered.
#
# By default, a context starts on its first step (index 0). Use this
# to skip a preamble step on re-entry via change_context.
#
sub set_initial_step {
    my ($self, $step_name) = @_;
    $self->_initial_step($step_name);
    return $self;
}

sub set_valid_contexts {
    my ($self, $contexts) = @_;
    $self->_valid_contexts($contexts);
    return $self;
}

sub set_valid_steps {
    my ($self, $steps) = @_;
    $self->_valid_steps($steps);
    return $self;
}

sub set_post_prompt {
    my ($self, $pp) = @_;
    $self->_post_prompt($pp);
    return $self;
}

sub set_system_prompt {
    my ($self, $sp) = @_;
    die "Cannot use set_system_prompt() when POM sections have been added for system prompt"
        if @{ $self->_system_prompt_sections };
    $self->_system_prompt($sp);
    return $self;
}

sub set_consolidate {
    my ($self, $c) = @_;
    $self->_consolidate($c ? 1 : 0);
    return $self;
}

sub set_full_reset {
    my ($self, $fr) = @_;
    $self->_full_reset($fr ? 1 : 0);
    return $self;
}

sub set_user_prompt {
    my ($self, $up) = @_;
    $self->_user_prompt($up);
    return $self;
}

#
# set_isolated — mark this context as isolated. Entering it wipes
# conversation history.
#
# When isolated=1 and the context is entered via change_context, the
# runtime wipes the conversation array. The model starts fresh with only
# the new context's system_prompt + step instructions, with no memory of
# prior turns.
#
# EXCEPTION — reset overrides the wipe:
#   If the context also has a reset configuration (via set_consolidate
#   or set_full_reset), the wipe is skipped in favor of the reset
#   behavior. Use reset with consolidate=1 to summarize prior history
#   into a single message instead of dropping it entirely.
#
# Use cases: switching to a sensitive billing flow that should not see
# prior small-talk; handing off to a different agent persona; resetting
# after a long off-topic detour.
#
sub set_isolated {
    my ($self, $iso) = @_;
    $self->_isolated($iso ? 1 : 0);
    return $self;
}

sub add_system_section {
    my ($self, $title, $body) = @_;
    die "Cannot add POM sections for system prompt when set_system_prompt() has been used"
        if defined $self->_system_prompt;
    push @{ $self->_system_prompt_sections }, { title => $title, body => $body };
    return $self;
}

sub add_system_bullets {
    my ($self, $title, $bullets) = @_;
    die "Cannot add POM sections for system prompt when set_system_prompt() has been used"
        if defined $self->_system_prompt;
    push @{ $self->_system_prompt_sections }, { title => $title, bullets => $bullets };
    return $self;
}

sub set_prompt {
    my ($self, $prompt) = @_;
    die "Cannot use set_prompt() when POM sections have been added"
        if @{ $self->_prompt_sections };
    $self->_prompt_text($prompt);
    return $self;
}

sub add_section {
    my ($self, $title, $body) = @_;
    die "Cannot add POM sections when set_prompt() has been used"
        if defined $self->_prompt_text;
    push @{ $self->_prompt_sections }, { title => $title, body => $body };
    return $self;
}

sub add_bullets {
    my ($self, $title, $bullets) = @_;
    die "Cannot add POM sections when set_prompt() has been used"
        if defined $self->_prompt_text;
    push @{ $self->_prompt_sections }, { title => $title, bullets => $bullets };
    return $self;
}

sub set_enter_fillers {
    my ($self, $fillers) = @_;
    $self->_enter_fillers($fillers) if ref $fillers eq 'HASH';
    return $self;
}

sub set_exit_fillers {
    my ($self, $fillers) = @_;
    $self->_exit_fillers($fillers) if ref $fillers eq 'HASH';
    return $self;
}

sub add_enter_filler {
    my ($self, $lang, $fillers) = @_;
    if ($lang && ref $fillers eq 'ARRAY') {
        $self->_enter_fillers({}) unless defined $self->_enter_fillers;
        $self->_enter_fillers->{$lang} = $fillers;
    }
    return $self;
}

sub add_exit_filler {
    my ($self, $lang, $fillers) = @_;
    if ($lang && ref $fillers eq 'ARRAY') {
        $self->_exit_fillers({}) unless defined $self->_exit_fillers;
        $self->_exit_fillers->{$lang} = $fillers;
    }
    return $self;
}

sub _render_prompt {
    my ($self) = @_;
    return $self->_prompt_text if defined $self->_prompt_text;
    return undef unless @{ $self->_prompt_sections };
    return _render_sections($self->_prompt_sections);
}

sub _render_system_prompt {
    my ($self) = @_;
    return $self->_system_prompt if defined $self->_system_prompt;
    return undef unless @{ $self->_system_prompt_sections };
    return _render_sections($self->_system_prompt_sections);
}

sub _render_sections {
    my ($sections) = @_;
    my @parts;
    for my $sec (@$sections) {
        if (exists $sec->{bullets}) {
            push @parts, "## $sec->{title}";
            push @parts, map { "- $_" } @{ $sec->{bullets} };
        } else {
            push @parts, "## $sec->{title}";
            push @parts, $sec->{body};
        }
        push @parts, '';
    }
    my $text = join("\n", @parts);
    $text =~ s/\s+$//;
    return $text;
}

sub to_hash {
    my ($self) = @_;
    die "Context '" . $self->name . "' has no steps defined"
        unless keys %{ $self->_steps };

    my %d = (
        steps => [ map { $self->_steps->{$_}->to_hash } @{ $self->_step_order } ],
    );

    $d{valid_contexts} = $self->_valid_contexts if defined $self->_valid_contexts;
    $d{valid_steps}    = $self->_valid_steps    if defined $self->_valid_steps;
    $d{initial_step}   = $self->_initial_step   if defined $self->_initial_step;
    $d{post_prompt}    = $self->_post_prompt    if defined $self->_post_prompt;

    my $sp = $self->_render_system_prompt;
    $d{system_prompt} = $sp if defined $sp;

    $d{consolidate} = JSON::true if $self->_consolidate;
    $d{full_reset}  = JSON::true if $self->_full_reset;
    $d{user_prompt} = $self->_user_prompt if defined $self->_user_prompt;
    $d{isolated}    = JSON::true if $self->_isolated;

    if (@{ $self->_prompt_sections }) {
        $d{pom} = $self->_prompt_sections;
    } elsif (defined $self->_prompt_text) {
        $d{prompt} = $self->_prompt_text;
    }

    $d{enter_fillers} = $self->_enter_fillers if defined $self->_enter_fillers;
    $d{exit_fillers}  = $self->_exit_fillers  if defined $self->_exit_fillers;

    return \%d;
}

# ==========================================================================
# ContextBuilder
# ==========================================================================
#
# SignalWire::Contexts::ContextBuilder
#
# Builder for multi-step, multi-context AI agent workflows.
#
# A ContextBuilder owns one or more Contexts; each Context owns an ordered
# list of Steps. Only one context and one step is active at a time. Per
# chat turn, the runtime injects the current step's instructions as a
# system message, then asks the LLM for a response.
#
# Native tools auto-injected by the runtime:
#
#   When a step (or its enclosing context) declares valid_steps or
#   valid_contexts, the runtime auto-injects two native tools so the
#   model can navigate the flow:
#
#     - next_step(step => enum)       — present when valid_steps is set
#     - change_context(context => enum) — present when valid_contexts is set
#
#   A third native tool — gather_submit — is injected during gather_info
#   questioning. These three names are reserved: ContextBuilder->validate
#   rejects any agent that defines a SWAIG tool with one of these names.
#   See %SignalWire::Contexts::RESERVED_NATIVE_TOOL_NAMES.
#
# Function whitelisting (Step->set_functions):
#
#   Each step may declare a functions whitelist. The whitelist is applied
#   in-memory at the start of each LLM turn. CRITICALLY: if a step does
#   NOT declare a functions field, it INHERITS the previous step's active
#   set. See Step->set_functions for details and examples.
#
package SignalWire::Contexts::ContextBuilder;
use Moo;
use JSON ();
use Scalar::Util ();

has '_contexts'      => (is => 'rw', default => sub { {} });
has '_context_order' => (is => 'rw', default => sub { [] });
# Weak reference to the owning agent so validate() can check
# user-defined tool names against RESERVED_NATIVE_TOOL_NAMES. Set via
# attach_agent(); AgentBase->define_contexts wires this up automatically.
has '_agent' => (is => 'rw', default => sub { undef });

sub attach_agent {
    my ($self, $agent) = @_;
    $self->_agent($agent);
    Scalar::Util::weaken($self->{_agent}) if defined $agent;
    return $self;
}

sub reset {
    my ($self) = @_;
    $self->_contexts({});
    $self->_context_order([]);
    return $self;
}

sub add_context {
    my ($self, $name) = @_;
    die "Context '$name' already exists" if exists $self->_contexts->{$name};
    die "Maximum number of contexts ($SignalWire::Contexts::MAX_CONTEXTS) exceeded"
        if keys %{ $self->_contexts } >= $SignalWire::Contexts::MAX_CONTEXTS;

    my $ctx = SignalWire::Contexts::Context->new(name => $name);
    $self->_contexts->{$name} = $ctx;
    push @{ $self->_context_order }, $name;
    return $ctx;
}

sub get_context {
    my ($self, $name) = @_;
    return $self->_contexts->{$name};
}

sub has_contexts {
    my ($self) = @_;
    return scalar(keys %{ $self->_contexts }) ? 1 : 0;
}

sub validate {
    my ($self) = @_;
    die "At least one context must be defined" unless keys %{ $self->_contexts };

    # Single context must be "default"
    if (keys %{ $self->_contexts } == 1) {
        my ($name) = keys %{ $self->_contexts };
        die 'When using a single context, it must be named "default"'
            unless $name eq 'default';
    }

    # Each context must have steps
    for my $cname (keys %{ $self->_contexts }) {
        my $ctx = $self->_contexts->{$cname};
        die "Context '$cname' must have at least one step"
            unless keys %{ $ctx->_steps };
    }

    # Validate initial_step references a real step in the context
    for my $cname (keys %{ $self->_contexts }) {
        my $ctx = $self->_contexts->{$cname};
        if (defined $ctx->_initial_step) {
            die "Context '$cname' has initial_step='${\$ctx->_initial_step}' "
                . "but that step does not exist. Available steps: ["
                . join(', ', map { "'$_'" } sort keys %{ $ctx->_steps })
                . "]"
                unless exists $ctx->_steps->{ $ctx->_initial_step };
        }
    }

    # Validate step references in valid_steps
    for my $cname (keys %{ $self->_contexts }) {
        my $ctx = $self->_contexts->{$cname};
        for my $sname (keys %{ $ctx->_steps }) {
            my $step = $ctx->_steps->{$sname};
            if (defined $step->_valid_steps) {
                for my $vs (@{ $step->_valid_steps }) {
                    next if $vs eq 'next';
                    die "Step '$sname' in context '$cname' references unknown step '$vs'"
                        unless exists $ctx->_steps->{$vs};
                }
            }
        }
    }

    # Validate context references (context-level and step-level)
    for my $cname (keys %{ $self->_contexts }) {
        my $ctx = $self->_contexts->{$cname};
        if (defined $ctx->_valid_contexts) {
            for my $vc (@{ $ctx->_valid_contexts }) {
                die "Context '$cname' references unknown context '$vc'"
                    unless exists $self->_contexts->{$vc};
            }
        }
        for my $sname (keys %{ $ctx->_steps }) {
            my $step = $ctx->_steps->{$sname};
            if (defined $step->_valid_contexts) {
                for my $vc (@{ $step->_valid_contexts }) {
                    die "Step '$sname' in context '$cname' references unknown context '$vc'"
                        unless exists $self->_contexts->{$vc};
                }
            }
        }
    }

    # Validate gather_info
    for my $cname (keys %{ $self->_contexts }) {
        my $ctx = $self->_contexts->{$cname};
        for my $sname (keys %{ $ctx->_steps }) {
            my $step = $ctx->_steps->{$sname};
            if (defined $step->_gather_info) {
                die "Step '$sname' in context '$cname' has gather_info with no questions"
                    unless @{ $step->_gather_info->_questions };

                my %seen;
                for my $q (@{ $step->_gather_info->_questions }) {
                    die "Step '$sname' in context '$cname' has duplicate gather_info question key '${\$q->key}'"
                        if $seen{ $q->key }++;
                }

                my $action = $step->_gather_info->_completion_action;
                if (defined $action) {
                    if ($action eq 'next_step') {
                        my $idx;
                        my @order = @{ $ctx->_step_order };
                        for my $i (0 .. $#order) {
                            if ($order[$i] eq $sname) { $idx = $i; last }
                        }
                        die "Step '$sname' in context '$cname' has gather_info "
                            . "completion_action='next_step' but it is the last "
                            . "step in the context. Either "
                            . "(1) add another step after '$sname', "
                            . "(2) set completion_action to the name of an "
                            . "existing step in this context to jump to it, or "
                            . "(3) set completion_action=undef (default) to "
                            . "stay in '$sname' after gathering completes."
                            if defined $idx && $idx >= $#order;
                    } elsif (!exists $ctx->_steps->{$action}) {
                        my @available = sort keys %{ $ctx->_steps };
                        die "Step '$sname' in context '$cname' has gather_info "
                            . "completion_action='$action' but '$action' is not "
                            . "a step in this context. Valid options: "
                            . "'next_step' (advance to the next sequential "
                            . "step), undef (stay in the current step), or "
                            . "one of [" . join(', ', map { "'$_'" } @available) . "].";
                    }
                }
            }
        }
    }

    # Validate that user-defined tools do not collide with reserved
    # native tool names. The runtime auto-injects next_step /
    # change_context / gather_submit when contexts/steps are present, so
    # user tools sharing those names would never be called.
    if (defined $self->_agent && $self->_agent->can('list_tool_names')) {
        my @registered = $self->_agent->list_tool_names;
        my @colliding;
        for my $name (@registered) {
            push @colliding, $name
                if exists $SignalWire::Contexts::RESERVED_NATIVE_TOOL_NAMES{$name};
        }
        if (@colliding) {
            my @sorted = sort @colliding;
            my @reserved = sort keys %SignalWire::Contexts::RESERVED_NATIVE_TOOL_NAMES;
            die "Tool name(s) ["
                . join(', ', map { "'$_'" } @sorted)
                . "] collide with reserved native tools auto-injected by "
                . "contexts/steps. The names ["
                . join(', ', map { "'$_'" } @reserved)
                . "] are reserved and cannot be used for user-defined SWAIG "
                . "tools when contexts/steps are in use. Rename your "
                . "tool(s) to avoid the collision.";
        }
    }
}

sub to_hash {
    my ($self) = @_;
    $self->validate;

    my %result;
    for my $cname (@{ $self->_context_order }) {
        $result{$cname} = $self->_contexts->{$cname}->to_hash;
    }
    return \%result;
}

# Back to main package
package SignalWire::Contexts;

# Python parity: signalwire.core.contexts.create_simple_context(name='default')
# is a module-level free function. Perl invocation forms supported:
#   - SignalWire::Contexts::create_simple_context('mycontext')   # free fn
#   - SignalWire::Contexts->create_simple_context('mycontext')   # class method
# Both forms collapse to a single optional ``$name`` argument.
sub create_simple_context {
    my ($name) = @_;
    if (defined $name && !ref($name) && $name eq __PACKAGE__) {
        # Class-method invocation form — drop the receiver, shift remaining.
        shift;
        $name = $_[0];
    }
    $name //= 'default';
    return SignalWire::Contexts::Context->new(name => $name);
}

1;

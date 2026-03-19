package SignalWire::Agents::Contexts;
use strict;
use warnings;
use JSON ();

our $MAX_CONTEXTS        = 50;
our $MAX_STEPS_PER_CONTEXT = 100;

# ==========================================================================
# GatherQuestion
# ==========================================================================
package SignalWire::Agents::Contexts::GatherQuestion;
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
package SignalWire::Agents::Contexts::GatherInfo;
use Moo;

has '_questions'        => (is => 'rw', default => sub { [] });
has '_output_key'       => (is => 'rw', default => sub { undef });
has '_completion_action' => (is => 'rw', default => sub { undef });
has '_prompt'           => (is => 'rw', default => sub { undef });

sub add_question {
    my ($self, %opts) = @_;
    my $q = SignalWire::Agents::Contexts::GatherQuestion->new(
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
package SignalWire::Agents::Contexts::Step;
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
    $self->_gather_info(SignalWire::Agents::Contexts::GatherInfo->new(
        _output_key       => $opts{output_key},
        _completion_action => $opts{completion_action},
        _prompt           => $opts{prompt},
    ));
    return $self;
}

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
package SignalWire::Agents::Contexts::Context;
use Moo;
use JSON ();

has 'name' => (is => 'ro', required => 1);

has '_steps'           => (is => 'rw', default => sub { {} });
has '_step_order'      => (is => 'rw', default => sub { [] });
has '_valid_contexts'  => (is => 'rw', default => sub { undef });
has '_valid_steps'     => (is => 'rw', default => sub { undef });
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
    die "Maximum steps per context ($SignalWire::Agents::Contexts::MAX_STEPS_PER_CONTEXT) exceeded"
        if keys %{ $self->_steps } >= $SignalWire::Agents::Contexts::MAX_STEPS_PER_CONTEXT;

    my $step = SignalWire::Agents::Contexts::Step->new(name => $name);
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
package SignalWire::Agents::Contexts::ContextBuilder;
use Moo;
use JSON ();

has '_contexts'      => (is => 'rw', default => sub { {} });
has '_context_order' => (is => 'rw', default => sub { [] });

sub add_context {
    my ($self, $name) = @_;
    die "Context '$name' already exists" if exists $self->_contexts->{$name};
    die "Maximum number of contexts ($SignalWire::Agents::Contexts::MAX_CONTEXTS) exceeded"
        if keys %{ $self->_contexts } >= $SignalWire::Agents::Contexts::MAX_CONTEXTS;

    my $ctx = SignalWire::Agents::Contexts::Context->new(name => $name);
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
                        die "Step '$sname' in context '$cname' has gather_info completion_action='next_step' but it is the last step"
                            if defined $idx && $idx >= $#order;
                    } elsif (!exists $ctx->_steps->{$action}) {
                        die "Step '$sname' in context '$cname' has gather_info completion_action='$action' but step '$action' does not exist";
                    }
                }
            }
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
package SignalWire::Agents::Contexts;

sub create_simple_context {
    my ($class, $name) = @_;
    $name //= 'default';
    return SignalWire::Agents::Contexts::Context->new(name => $name);
}

1;

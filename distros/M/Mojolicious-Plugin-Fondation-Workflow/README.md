# NAME

Mojolicious::Plugin::Fondation::Workflow - Workflow plugin — state machines with UI and authorization for Fondation

# VERSION

version 0.01

# SYNOPSIS

    # In your Fondation config
    plugin 'Fondation' => {
        dependencies => ['Fondation::Workflow'],
    };

    # With a workflow YAML file
    plugin 'Fondation' => {
        dependencies => ['Fondation::Workflow'],
        'Fondation::Workflow' => {
            workflows => {
                approval => 'share/workflows/approval.yaml',
            },
        },
    };

    # In a controller
    my $wf = $c->workflow('approval');
    my $wf = $c->workflow('approval', $resource_id);

    # With context
    my $wf = $c->workflow('approval', undef, { user_id => 42 });

    # Or as a hashref
    my $wf = $c->workflow({
        type        => 'approval',
        resource_id => $id,
        context     => { user_id => 42 },
    });

# DESCRIPTION

Fondation::Workflow wraps [Workflow](https://metacpan.org/pod/Workflow) (the CPAN state-machine module) for
[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation).  It provides:

- A `workflow` helper for controllers to create and fetch workflow instances
- Multi-persister support — DB-backed workflows via `Workflow::Persister::DBI`
and file-backed wizards via `Workflow::Persister::File` (declared in YAML)
- A [Proxy](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow%3A%3AProxy) that wraps raw
`Workflow` objects with convenience methods (`actions`, `state_fondation`,
`execute`, `add_history`, `emit_hook`)
- Cross-plugin schema relations — when [Fondation::User](https://metacpan.org/pod/Fondation%3A%3AUser) is present,
`WorkflowHistory` gets a `belongs_to` relation to `User`

## Dependency graph

Workflow declares NO hard dependencies (`dependencies => []`).
Soft ordering: `after => ['Fondation::Model::DBIx::Async']`.

This means Workflow can boot without a database backend — essential for
wizards like [Fondation::Setup](https://metacpan.org/pod/Fondation%3A%3ASetup) that use `Workflow::Persister::File`.
When `Fondation::Model::DBIx::Async` IS present, the `after` hint ensures
Workflow loads after it, so the `models` default (`Workflow`, `WorkflowHistory`)
is picked up by `Action::DBIx`.

# NAME

Mojolicious::Plugin::Fondation::Workflow - State-machine workflows with UI, authorization and hooks for Fondation

# VERSION

version 0.02

# CONFIGURATION

## workflows

A hashref mapping workflow types to YAML file paths:

    'Fondation::Workflow' => {
        workflows => {
            approval => 'share/workflows/approval.yaml',
        },
    },

Each YAML file follows the [Workflow](https://metacpan.org/pod/Workflow) format (`type`, `initial_state`, `state`,
`action`) with Fondation extensions:

- `fondation` blocks on states and actions — carry UI metadata
(`label`, `color`, `icon`, `group`) used by the Bootstrap renderer
- `persister_config` — declare additional persisters per workflow
(e.g. `Workflow::Persister::File` for DB-free wizards)

## persister

DBI persister configuration for DB-backed workflows:

    'Fondation::Workflow' => {
        persister => {
            dsn      => 'dbi:SQLite:dbname=data/app.db',
            user     => '',
            password => '',
        },
    },

The persister name is always `FondationWorkflow`.  If no DSN is configured,
the plugin logs a warning but does not die — file-backed workflows can still
operate.

# HELPERS

## $c->workflow($type, $resource\_id?, $context?)

Returns a [Mojolicious::Plugin::Fondation::Workflow::Proxy](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow%3A%3AProxy) wrapping a
[Workflow](https://metacpan.org/pod/Workflow) instance.

- `$type` — workflow type (must match a key in `workflows` config)
- `$resource_id` — optional.  If given, fetches an existing workflow via
`fetch_workflow`.  If `undef`, creates a new workflow.
- `$context` — optional hashref.  Stored in the workflow's context via
`$wf->context->param($context)`.  Only used when creating.

Can also be called with a single hashref:

    $c->workflow({ type => 'approval', resource_id => $id, context => {...} });

# CROSS-PLUGIN RELATIONS

During `fondation_finalyze`, if [Fondation::User](https://metacpan.org/pod/Fondation%3A%3AUser) is present in the registry,
a `belongs_to` relation is added:

    WorkflowHistory -> belongs_to -> User (foreign.id = self.user_id)

This makes `$history_entry->user` available in DBIC queries without
requiring Workflow to hard-depend on the User plugin.

# SEE ALSO

- [Mojolicious::Plugin::Fondation::Workflow::Proxy](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow%3A%3AProxy) — workflow wrapper with convenience methods
- [Mojolicious::Plugin::Fondation::Workflow::UI::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow%3A%3AUI%3A%3ABootstrap) — Bootstrap 5 UI renderer
- [Mojolicious::Plugin::Fondation::Setup](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ASetup) — setup wizard that uses file-persisted workflows
- [Workflow](https://metacpan.org/pod/Workflow) — the CPAN state-machine module
- [Workflow::Persister::DBI](https://metacpan.org/pod/Workflow%3A%3APersister%3A%3ADBI) — DBI-backed persistence
- [Workflow::Persister::File](https://metacpan.org/pod/Workflow%3A%3APersister%3A%3AFile) — file-backed persistence (no DB required)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

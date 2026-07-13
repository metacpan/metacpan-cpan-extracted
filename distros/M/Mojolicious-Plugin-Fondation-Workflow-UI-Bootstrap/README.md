# NAME

Mojolicious::Plugin::Fondation::Workflow::UI::Bootstrap — Bootstrap 5 UI components for Fondation::Workflow

# VERSION

version 0.01

# SYNOPSIS

    # myapp.conf
    'Fondation::Workflow::UI::Bootstrap' => {};

    # In a template (EP)
    %= workflow_state($wf)
    %= workflow_actions($wf)
    %= workflow_progress($wf)
    %= workflow_history($wf)

    # Mermaid.js graph (raw, for inclusion in a <pre> or mermaid block)
    %= workflow_graph($wf)

# DESCRIPTION

Fondation::Workflow::UI::Bootstrap provides five template helpers that render
Bootstrap 5 markup for [Fondation::Workflow](https://metacpan.org/pod/Fondation%3A%3AWorkflow) instances. Each helper takes a
[Mojolicious::Plugin::Fondation::Workflow::Proxy](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow%3A%3AProxy) object and returns an HTML
string ready to embed in `.ep` templates.

## Dependencies

This plugin requires [Fondation::Layout::Bootstrap](https://metacpan.org/pod/Fondation%3A%3ALayout%3A%3ABootstrap) and [Fondation::Workflow](https://metacpan.org/pod/Fondation%3A%3AWorkflow)
to be loaded.

# HELPERS

All helpers are available on the controller object (`$c`) and return an empty
string when passed `undef` or an invalid workflow reference.

## workflow\_state

    %= workflow_state($wf)
    %= workflow_state($wf, class => 'ms-2')

Renders a Bootstrap 5 badge for the current workflow state. The badge uses the
state's `fondation` metadata (`label`, `color`, `icon`) from the workflow
YAML definition:

- `label` — badge text (falls back to the raw state name)
- `color` — Bootstrap background class (`bg-success`, `bg-primary`, etc.)
- `icon` — Bootstrap Icons name (e.g. `check-circle`, `pencil-square`)

Extra attributes are merged into the badge's `class` attribute.

Output example:

    <span class="badge bg-warning"><i class="bi bi-pencil-square me-1"></i>Draft</span>

## workflow\_actions

    %= workflow_actions($wf)
    %= workflow_actions($wf, class => 'mt-2')

Renders a Bootstrap 5 `btn-group` containing action buttons for every action
available in the current state. Each button carries:

- `data-action` — the action name (for JavaScript handlers)
- `data-confirm` — optional confirmation message (from `fondation.confirm`)
- Color, icon, and label from the action's `fondation` metadata

Output example:

    <div class="btn-group" role="group">
      <button class="btn btn-sm btn-primary workflow-action" data-action="submit">
        <i class="bi bi-send me-1"></i>Submit
      </button>
    </div>

## workflow\_progress

    %= workflow_progress($wf)

Renders a text-based state tree showing the workflow's progression. The current
state is highlighted with its configured color, visited past states show a green
checkmark, and future states appear greyed out.

The helper reconstructs the effective path from history, eliminating backtracked
branches (e.g. if the user went `in_progress` → `blocked` → `in_progress`,
"blocked" is not shown as visited on the final path). Cycle detection prevents
infinite recursion on circular graphs.

Output is wrapped in `<div class="workflow-progress font-monospace small">`.

## workflow\_history

    %= workflow_history($wf)

Renders a vertical timeline of all history entries for the workflow. Each entry
shows the action name, timestamp, and optional description.

Output example:

    <div class="workflow-history">
      <div class="d-flex align-items-start mb-2">
        <div class="me-2 text-primary">●</div>
        <div>
          <strong>submit</strong>
          <span class="text-muted small">2026-07-12 14:30:00</span>
          <br><small class="text-muted">looks good</small>
        </div>
      </div>
    </div>

## workflow\_graph

    %= workflow_graph($wf)

Returns a raw Mermaid.js `flowchart TD` diagram definition — not HTML. Embed
it in a `<pre class="mermaid">` block or pass it to a Mermaid renderer.

Nodes are styled with three CSS classes:

- `current` — blue filled node (the active state)
- `visited` — green filled nodes (states on the current path before the active one)
- `future` — grey outlined nodes (unvisited branches)

The helper uses the same history-based backtracking logic as `workflow_progress`
to determine which nodes are visited.

Include Mermaid.js in your layout to render the diagram:

    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <script>mermaid.initialize({ startOnLoad: true });</script>

# WORKFLOW YAML METADATA

Each state and action in the workflow YAML can carry a `fondation` block with
UI metadata consumed by these helpers:

    state:
      - name: draft
        fondation:
          label: Draft        # display name
          color: warning      # Bootstrap bg-* suffix
          icon: pencil-square # Bootstrap Icons name
        action:
          - name: submit
            fondation:
              label: Submit
              color: primary
              icon: send
              confirm: Are you sure?

If a `fondation` block is absent, helpers fall back to the raw name and
`bg-secondary` color.

# SEE ALSO

- [Mojolicious::Plugin::Fondation::Workflow](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow) — the workflow engine
- [Mojolicious::Plugin::Fondation::Workflow::Proxy](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow%3A%3AProxy) — workflow wrapper with convenience methods
- [Mojolicious::Plugin::Fondation::Layout::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ALayout%3A%3ABootstrap) — Bootstrap 5 layout
- [Workflow](https://metacpan.org/pod/Workflow) — the CPAN state-machine module

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

package Mojolicious::Plugin::Fondation::Workflow::UI::Bootstrap;

# ABSTRACT: Bootstrap 5 UI components for Fondation::Workflow
#
# Provides template helpers for rendering workflow state badges,
# action buttons, history timelines, progress bars, and Mermaid.js graphs.

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Layout::Bootstrap',
            'Fondation::Workflow',
        ],
    };
}

sub register ($self, $app, $conf) {

    # ── workflow_state($wf) — state badge ──────────────────────────────

    $app->helper(workflow_state => sub ($c, $wf, %attrs) {
        return '' unless $wf && ref $wf;
        my $state = $wf->state;
        my $label = $wf->state_label;
        my $color = $wf->state_color;
        my $icon  = $wf->state_icon;

        my $icon_html = $icon ? qq{<i class="bi bi-$icon me-1"></i>} : '';
        my $class = join ' ', 'badge', "bg-$color", ($attrs{class} // '');
        return qq{<span class="$class">$icon_html$label</span>};
    });

    # ── workflow_actions($wf) — action buttons ────────────────────────

    $app->helper(workflow_actions => sub ($c, $wf, %attrs) {
        return '' unless $wf && ref $wf;
        my $actions = $wf->actions;
        return '' unless $actions && @$actions;

        my $html = '';
        for my $a (@$actions) {
            my $color = "btn-$a->{color}";
            my $icon  = $a->{icon} ? qq{<i class="bi bi-$a->{icon} me-1"></i>} : '';
            my $confirm = $a->{confirm} ? qq{ data-confirm="$a->{confirm}"} : '';
            $html .= qq{<button class="btn btn-sm $color workflow-action"$confirm data-action="$a->{name}">$icon$a->{label}</button>\n};
        }
        my $class = join ' ', 'btn-group', ($attrs{class} // '');
        return qq{<div class="$class" role="group">$html</div>};
    });

    # ── workflow_progress($wf) — state graph/tree ────────────────────

    $app->helper(workflow_progress => sub ($c, $wf, %attrs) {
        return '' unless $wf;
        my $current = $wf->state;

        my $config  = $wf->_workflow_config;
        my $states  = $config->{state} // [];
        return '' unless @$states;

        # Build adjacency map: state_name => [next_state_names...]
        # and metadata map: state_name => { label, color, icon }
        my (%next, %meta);
        for my $s (@$states) {
            my $name = $s->{name};
            my $fd   = $s->{fondation} // {};
            $meta{$name} = {
                label => $c->l($fd->{label} // $name),
                color => $fd->{color} // 'secondary',
                icon  => $fd->{icon},
            };
            my $actions = $s->{action} // [];
            $next{$name} = [ map { $_->{resulting_state} } @$actions ];
        }

        # Reconstruct the effective path from history (eliminate backtracks).
        # When the user goes block→unblock (back to in_progress) and then
        # resolve→resolved, "blocked" is a dead-end branch — it should not
        # appear as visited on the current path.
        my @history = @{ $wf->history // [] };
        my @path;          # ordered chain of states on the current path
        my %path_set;      # fast lookup
        for my $h (@history) {
            my $s = $h->{state} // '';
            next unless $s;
            # Backtracking: if we reach a state already in the path,
            # truncate everything after it.
            if ($path_set{$s}) {
                while (@path && $path[-1] ne $s) {
                    delete $path_set{pop @path};
                }
                next;
            }
            push @path, $s;
            $path_set{$s} = 1;
        }
        # Always mark current state as on-path
        $path_set{$current} = 1 unless $path_set{$current};
        my %visited = %path_set;

        # Recursive tree builder (tracks path to avoid cycles)
        my $render;
        $render = sub ($state_name, $prefix = '', $is_last = 0, $depth = 0, $seen = {}) {
            return '' unless exists $meta{$state_name};
            return qq{<div class="wf-node"><span class="wf-prefix text-muted small">$prefix</span>}
                 . qq{<span class="badge bg-light text-muted border">↩ $meta{$state_name}{label} (cycle)</span></div>\n}
                if $seen->{$state_name};

            my $m   = $meta{$state_name};
            my $label = $m->{label};
            my $color = $m->{color};
            my $icon  = $m->{icon} ? qq{<i class="bi bi-$m->{icon} me-1"></i>} : '';

            my $is_current = $state_name eq $current;
            my $is_visited = $visited{$state_name} && !$is_current;

            my $badge_class = $is_current  ? "bg-$color"
                            : $is_visited  ? 'bg-success'
                            :                'bg-light text-muted border';
            my $marker = $is_current  ? '●'
                       : $is_visited  ? '✓'
                       :                '○';

            my $connector = $depth > 0 ? ($is_last ? ' └─ ' : ' ├─ ') : '';
            my $html = qq{<div class="wf-node">};
            $html .= qq{<span class="wf-prefix text-muted small">$prefix$connector</span>};
            $html .= qq{<span class="badge $badge_class">$icon$marker $label</span>};
            $html .= qq{</div>\n};

            my @children = @{ $next{$state_name} // [] };
            return $html unless @children;

            my $child_prefix = $depth > 0
                ? ($is_last ? '   ' : ' │ ')
                : '';
            my $full_prefix  = $prefix . $child_prefix;

            my %child_seen = (%$seen, $state_name => 1);
            for my $i (0 .. $#children) {
                my $child     = $children[$i];
                my $child_last = $i == $#children;
                $html .= $render->($child, $full_prefix, $child_last, $depth + 1, \%child_seen);
            }
            return $html;
        };

        my $initial = $config->{initial_state} // $states->[0]{name};
        return qq{<div class="workflow-progress font-monospace small">\n}
             . $render->($initial)
             . qq{</div>};
    });

    # ── workflow_history($wf) — history timeline ──────────────────────

    $app->helper(workflow_history => sub ($c, $wf, %attrs) {
        return '' unless $wf && ref $wf;
        my $entries = $wf->history;
        return '' unless $entries && @$entries;

        my $html = qq{<div class="workflow-history">};
        for my $e (@$entries) {
            my $action  = $e->{action}  // '';
            my $state   = $e->{state}   // '';
            my $user    = $e->{user}    // '';
            my $date    = $e->{date}    // '';
            my $desc    = $e->{description} // '';
            $html .= qq{<div class="d-flex align-items-start mb-2">};
            $html .= qq{<div class="me-2 text-primary">●</div>};
            $html .= qq{<div>};
            $html .= qq{<strong>$action</strong>};
            $html .= qq{ <span class="text-muted small">$date</span>} if $date;
            $html .= qq{<br><small class="text-muted">$desc</small>} if $desc;
            $html .= qq{</div></div>};
        }
        $html .= '</div>';
        return $html;
    });

    # ── workflow_graph($wf) — Mermaid.js state diagram ────────────────

    $app->helper(workflow_graph => sub ($c, $wf, %attrs) {
        return '' unless $wf && ref $wf;

        my $config = $wf->_workflow_config;
        my $states = $config->{state} // [];
        return '' unless @$states;

        my $current = $wf->state;

        # Build adjacency + metadata
        my (%next, %meta);
        for my $s (@$states) {
            my $name = $s->{name};
            my $fd   = $s->{fondation} // {};
            $meta{$name} = {
                name  => $name,
                label => $c->l($fd->{label} // $name),
                color => $fd->{color} // 'secondary',
            };
            my $actions = $s->{action} // [];
            $next{$name} = $actions;
        }

        # Determine path set (same backtracking logic as progress)
        my @history = @{ $wf->history // [] };
        my (@path, %path_set);
        for my $h (@history) {
            my $s = $h->{state} // '';
            next unless $s;
            if ($path_set{$s}) {
                while (@path && $path[-1] ne $s) { delete $path_set{pop @path} }
                next;
            }
            push @path, $s; $path_set{$s} = 1;
        }
        $path_set{$current} = 1 unless $path_set{$current};

        # Short safe IDs for Mermaid
        my $sid = sub ($name) { 'S_' . ($name =~ s/[^a-zA-Z0-9]/_/gr) };
        my @visited_nodes;
        my @future_nodes;
        my $current_node = '';

        # Classify nodes
        for my $s_name (sort keys %meta) {
            my $id = $sid->($s_name);
            if ($s_name eq $current) {
                $current_node = $id;
            } elsif ($path_set{$s_name}) {
                push @visited_nodes, $id;
            } else {
                push @future_nodes, $id;
            }
        }

        # Generate edges with action labels
        my @lines;
        my @sorted = sort { $a->{name} cmp $b->{name} } values %meta;
        for my $s (@sorted) {
            my $s_name  = $s->{name};
            my $from_id = $sid->($s_name);
            for my $action (@{ $next{$s_name} // [] }) {
                my $to_name   = $action->{resulting_state};
                my $to_id     = $sid->($to_name);
                my $label     = $action->{name} // '';
                my $fd        = $action->{fondation} // {};
                $label = $fd->{label} if $fd->{label};
                my $from_label = $meta{$s_name}{label};
                my $to_label   = $meta{$to_name}{label};
                push @lines, qq{    ${from_id}["$from_label"] -->|"$label"| ${to_id}["$to_label"]};
            }
        }

        my $mermaid = "flowchart TD\n"
            . join("\n", @lines) . "\n"
            . "\n"
            . "    classDef visited fill:#198754,color:#fff,stroke:#198754\n"
            . "    classDef current fill:#0d6efd,color:#fff,stroke:#0d6efd,stroke-width:3px\n"
            . "    classDef future  fill:#e9ecef,color:#6c757d,stroke:#dee2e6\n";

        $mermaid .= "    class $current_node current\n" if $current_node;
        $mermaid .= "    class " . join(',', @visited_nodes) . " visited\n" if @visited_nodes;
        $mermaid .= "    class " . join(',', @future_nodes)  . " future\n"  if @future_nodes;

        return $mermaid;
    });

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow::UI::Bootstrap — Bootstrap 5 UI components for Fondation::Workflow

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  # myapp.conf
  'Fondation::Workflow::UI::Bootstrap' => {};

  # In a template (EP)
  %= workflow_state($wf)
  %= workflow_actions($wf)
  %= workflow_progress($wf)
  %= workflow_history($wf)

  # Mermaid.js graph (raw, for inclusion in a <pre> or mermaid block)
  %= workflow_graph($wf)

=head1 DESCRIPTION

Fondation::Workflow::UI::Bootstrap provides five template helpers that render
Bootstrap 5 markup for L<Fondation::Workflow> instances. Each helper takes a
L<Mojolicious::Plugin::Fondation::Workflow::Proxy> object and returns an HTML
string ready to embed in C<.ep> templates.

=head2 Dependencies

This plugin requires L<Fondation::Layout::Bootstrap> and L<Fondation::Workflow>
to be loaded.

=head1 HELPERS

All helpers are available on the controller object (C<$c>) and return an empty
string when passed C<undef> or an invalid workflow reference.

=head2 workflow_state

  %= workflow_state($wf)
  %= workflow_state($wf, class => 'ms-2')

Renders a Bootstrap 5 badge for the current workflow state. The badge uses the
state's C<fondation> metadata (C<label>, C<color>, C<icon>) from the workflow
YAML definition:

=over

=item C<label> — badge text (falls back to the raw state name)

=item C<color> — Bootstrap background class (C<bg-success>, C<bg-primary>, etc.)

=item C<icon> — Bootstrap Icons name (e.g. C<check-circle>, C<pencil-square>)

=back

Extra attributes are merged into the badge's C<class> attribute.

Output example:

  <span class="badge bg-warning"><i class="bi bi-pencil-square me-1"></i>Draft</span>

=head2 workflow_actions

  %= workflow_actions($wf)
  %= workflow_actions($wf, class => 'mt-2')

Renders a Bootstrap 5 C<btn-group> containing action buttons for every action
available in the current state. Each button carries:

=over

=item C<data-action> — the action name (for JavaScript handlers)

=item C<data-confirm> — optional confirmation message (from C<fondation.confirm>)

=item Color, icon, and label from the action's C<fondation> metadata

=back

Output example:

  <div class="btn-group" role="group">
    <button class="btn btn-sm btn-primary workflow-action" data-action="submit">
      <i class="bi bi-send me-1"></i>Submit
    </button>
  </div>

=head2 workflow_progress

  %= workflow_progress($wf)

Renders a text-based state tree showing the workflow's progression. The current
state is highlighted with its configured color, visited past states show a green
checkmark, and future states appear greyed out.

The helper reconstructs the effective path from history, eliminating backtracked
branches (e.g. if the user went C<in_progress> → C<blocked> → C<in_progress>,
"blocked" is not shown as visited on the final path). Cycle detection prevents
infinite recursion on circular graphs.

Output is wrapped in C<< <div class="workflow-progress font-monospace small"> >>.

=head2 workflow_history

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

=head2 workflow_graph

  %= workflow_graph($wf)

Returns a raw Mermaid.js C<flowchart TD> diagram definition — not HTML. Embed
it in a C<< <pre class="mermaid"> >> block or pass it to a Mermaid renderer.

Nodes are styled with three CSS classes:

=over

=item C<current> — blue filled node (the active state)

=item C<visited> — green filled nodes (states on the current path before the active one)

=item C<future> — grey outlined nodes (unvisited branches)

=back

The helper uses the same history-based backtracking logic as C<workflow_progress>
to determine which nodes are visited.

Include Mermaid.js in your layout to render the diagram:

  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({ startOnLoad: true });</script>

=head1 WORKFLOW YAML METADATA

Each state and action in the workflow YAML can carry a C<fondation> block with
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

If a C<fondation> block is absent, helpers fall back to the raw name and
C<bg-secondary> color.

=head1 SEE ALSO

=over

=item L<Mojolicious::Plugin::Fondation::Workflow> — the workflow engine

=item L<Mojolicious::Plugin::Fondation::Workflow::Proxy> — workflow wrapper with convenience methods

=item L<Mojolicious::Plugin::Fondation::Layout::Bootstrap> — Bootstrap 5 layout

=item L<Workflow> — the CPAN state-machine module

=back

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

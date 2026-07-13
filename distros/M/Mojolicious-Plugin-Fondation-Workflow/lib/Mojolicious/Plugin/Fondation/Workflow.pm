package Mojolicious::Plugin::Fondation::Workflow;
$Mojolicious::Plugin::Fondation::Workflow::VERSION = '0.01';
# ABSTRACT: Workflow plugin — state machines with UI and authorization for Fondation

use Mojo::Base 'Mojolicious::Plugin', -signatures;


use Workflow::Factory;
use Workflow::Persister::DBI;
use Mojolicious::Plugin::Fondation::Workflow::Proxy;

sub fondation_meta {
    return {
        dependencies => [],
        after        => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            workflow_dir      => 'share/workflows',
            persister_file_dir => 'data/setup',
            models => {
                workflow         => { source => 'Workflow' },
                workflow_history => { source => 'WorkflowHistory' },
            },
        },
        setup => {
            label       => 'Workflow',
            description => 'Workflow engine configuration',
            parameters  => [
                {
                    key         => 'workflow_dir',
                    label       => 'Workflow directory',
                    type        => 'string',
                    default     => 'share/workflows',
                    required    => 1,
                    placeholder => 'share/workflows',
                },
                {
                    key         => 'persister_file_dir',
                    label       => 'File persister directory',
                    type        => 'string',
                    default     => 'data/setup',
                    required    => 1,
                    placeholder => 'data/setup',
                },
                {
                    key         => 'models.workflow.source',
                    label       => 'Workflow table source',
                    type        => 'string',
                    default     => 'Workflow',
                    required    => 1,
                },
                {
                    key         => 'models.workflow_history.source',
                    label       => 'Workflow History table source',
                    type        => 'string',
                    default     => 'WorkflowHistory',
                    required    => 1,
                },
            ],
        },
    };
}

sub register ($self, $app, $config) {
    my $workflows     = $config->{workflows}   || {};
    my $persister_cfg  = $config->{persister}  || {};

    # ── Initialize Workflow::Factory ──────────────────────────────────

    my $factory = Workflow::Factory->instance;

    # Configure the DBI persister (default for DB-backed workflows)
    if ($persister_cfg->{dsn}) {
        $factory->add_config(
            persister => {
                name     => 'FondationWorkflow',
                class    => 'Workflow::Persister::DBI',
                dsn      => $persister_cfg->{dsn},
                user     => $persister_cfg->{user}     || '',
                password => $persister_cfg->{password} || '',
            },
        );
    } else {
        $self->log->warn("No DSN configured — DB-backed workflows will fail");
    }

    # Load all workflow YAML files
    my $workflow_dir = $config->{workflow_dir} // 'share/workflows';

    # Auto-discover YAML files if no explicit workflows configured
    unless (%$workflows) {
        my $dir = $app->home->child($workflow_dir);
        if (-d $dir) {
            $dir->list({ dir => 0 })->each(sub ($file, $idx) {
                return unless $file->basename =~ /^(.+)\.ya?ml$/i;
                my $type = $1;
                $workflows->{$type} = $file->to_string;
            });
        }
    }

    my %registered_persisters;
    foreach my $type (keys %$workflows) {
        my $file = $workflows->{$type};
        my $path = $file;
        $self->log->info("Loading '$type' from $path");

        require YAML;
        my $config_data = YAML::LoadFile($path);

        # Register additional persisters declared in the YAML
        # (e.g. Workflow::Persister::File for wizards that don't need a DB)
        if (my $persisters = $config_data->{persister_config}) {
            for my $p (@$persisters) {
                my $name = $p->{name} or next;
                next if $registered_persisters{$name}++;
                # Set default path for File persistors and create the directory
                if (($p->{class} // '') eq 'Workflow::Persister::File') {
                    $p->{path} //= $config->{persister_file_dir} // 'data/setup';
                    my $dir = $app->home->child($p->{path});
                    $dir->make_path unless -d $dir;
                }
                $factory->add_config(persister => $p);
                $self->log->info("Registered persister '$name' ($p->{class})");
            }
        }

        $factory->add_config(
            workflow => [ $config_data ],
            action   => [ $config_data ],
        );
    }

    # ── Helper: $c->workflow() ───────────────────────────────────────

    $app->helper(workflow => sub ($c, $type, $resource_id = undef, $context = undef) {
        if (ref $type eq 'HASH') {
            $context     = $type->{context};
            $resource_id = $type->{resource_id};
            $type        = $type->{type};
        }

        my $wf;
        if (defined $resource_id) {
            # fetch_workflow may die (e.g. Persister::File throws persist_error
            # when the file no longer exists after a cleanup)
            $wf = eval { $factory->fetch_workflow($type, $resource_id) };
            return undef unless $wf;
        } else {
            $wf = $factory->create_workflow($type, $context);
        }

        return Mojolicious::Plugin::Fondation::Workflow::Proxy->new(
            wf      => $wf,
            factory => $factory,
            c       => $c,
            type    => $type,
        );
    });

    return $self;
}

sub fondation_finalyze ($self, $app, $long_name) {
    my $registry = $app->fondation->registry;

    # Cross-plugin relation: WorkflowHistory → User (who did the action)
    if ($registry->{'Mojolicious::Plugin::Fondation::User'}) {
        my $history_class = 'Mojolicious::Plugin::Fondation::Workflow::Schema::Result::WorkflowHistory';

        $history_class->belongs_to(
            'user',
            'Mojolicious::Plugin::Fondation::User::Schema::Result::User',
            { 'foreign.id' => 'self.user_id' },
        );
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow - Workflow plugin — state machines with UI and authorization for Fondation

=head1 VERSION

version 0.01

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Fondation::Workflow wraps L<Workflow> (the CPAN state-machine module) for
L<Mojolicious::Plugin::Fondation>.  It provides:

=over

=item * A C<workflow> helper for controllers to create and fetch workflow instances

=item * Multi-persister support — DB-backed workflows via C<Workflow::Persister::DBI>
and file-backed wizards via C<Workflow::Persister::File> (declared in YAML)

=item * A L<Proxy|Mojolicious::Plugin::Fondation::Workflow::Proxy> that wraps raw
C<Workflow> objects with convenience methods (C<actions>, C<state_fondation>,
C<execute>, C<add_history>, C<emit_hook>)

=item * Cross-plugin schema relations — when L<Fondation::User> is present,
C<WorkflowHistory> gets a C<belongs_to> relation to C<User>

=back

=head2 Dependency graph

Workflow declares NO hard dependencies (C<dependencies =E<gt> []>).
Soft ordering: C<after =E<gt> ['Fondation::Model::DBIx::Async']>.

This means Workflow can boot without a database backend — essential for
wizards like L<Fondation::Setup> that use C<Workflow::Persister::File>.
When C<Fondation::Model::DBIx::Async> IS present, the C<after> hint ensures
Workflow loads after it, so the C<models> default (C<Workflow>, C<WorkflowHistory>)
is picked up by C<Action::DBIx>.

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow - State-machine workflows with UI, authorization and hooks for Fondation

=head1 VERSION

version 0.02

=head1 CONFIGURATION

=head2 workflows

A hashref mapping workflow types to YAML file paths:

  'Fondation::Workflow' => {
      workflows => {
          approval => 'share/workflows/approval.yaml',
      },
  },

Each YAML file follows the L<Workflow> format (C<type>, C<initial_state>, C<state>,
C<action>) with Fondation extensions:

=over

=item C<fondation> blocks on states and actions — carry UI metadata
(C<label>, C<color>, C<icon>, C<group>) used by the Bootstrap renderer

=item C<persister_config> — declare additional persisters per workflow
(e.g. C<Workflow::Persister::File> for DB-free wizards)

=back

=head2 persister

DBI persister configuration for DB-backed workflows:

  'Fondation::Workflow' => {
      persister => {
          dsn      => 'dbi:SQLite:dbname=data/app.db',
          user     => '',
          password => '',
      },
  },

The persister name is always C<FondationWorkflow>.  If no DSN is configured,
the plugin logs a warning but does not die — file-backed workflows can still
operate.

=head1 HELPERS

=head2 $c->workflow($type, $resource_id?, $context?)

Returns a L<Mojolicious::Plugin::Fondation::Workflow::Proxy> wrapping a
L<Workflow> instance.

=over

=item C<$type> — workflow type (must match a key in C<workflows> config)

=item C<$resource_id> — optional.  If given, fetches an existing workflow via
C<fetch_workflow>.  If C<undef>, creates a new workflow.

=item C<$context> — optional hashref.  Stored in the workflow's context via
C<< $wf->context->param($context) >>.  Only used when creating.

=back

Can also be called with a single hashref:

  $c->workflow({ type => 'approval', resource_id => $id, context => {...} });

=head1 CROSS-PLUGIN RELATIONS

During C<fondation_finalyze>, if L<Fondation::User> is present in the registry,
a C<belongs_to> relation is added:

  WorkflowHistory -> belongs_to -> User (foreign.id = self.user_id)

This makes C<< $history_entry->user >> available in DBIC queries without
requiring Workflow to hard-depend on the User plugin.

=head1 SEE ALSO

=over

=item L<Mojolicious::Plugin::Fondation::Workflow::Proxy> — workflow wrapper with convenience methods

=item L<Mojolicious::Plugin::Fondation::Workflow::UI::Bootstrap> — Bootstrap 5 UI renderer

=item L<Mojolicious::Plugin::Fondation::Setup> — setup wizard that uses file-persisted workflows

=item L<Workflow> — the CPAN state-machine module

=item L<Workflow::Persister::DBI> — DBI-backed persistence

=item L<Workflow::Persister::File> — file-backed persistence (no DB required)

=back

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

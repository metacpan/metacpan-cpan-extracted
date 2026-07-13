package Mojolicious::Plugin::Fondation::Setup::Controller::Setup;
$Mojolicious::Plugin::Fondation::Setup::Controller::Setup::VERSION = '0.02';
# ABSTRACT: Setup wizard controller — plugin selection, workflow wizard, and .conf generation

use Mojo::Base 'Mojolicious::Controller', -signatures;
use version;

use Mojo::File 'path';
use Mojo::Loader;
use Mojo::Util qw(encode);
use YAML::XS qw(Dump);
use Workflow::Factory;
use Mojolicious::Plugin::Fondation::Setup::MetaCPAN;

# ──────────────────────────────────────────────────────────────────────
# GET /setup/plugins — plugin selection page
# ──────────────────────────────────────────────────────────────────────

sub plugins ($self) {
    $self->render_later;

    # Read existing conf file to pre-select already configured plugins
    my %already_selected;
    my $moniker   = $self->app->moniker;
    my $conf_path = $self->app->home->child("$moniker.conf");
    if (-f $conf_path) {
        my $conf = do($conf_path->to_string);
        if ($conf && $conf->{Fondation} && $conf->{Fondation}{dependencies}) {
            for my $dep (@{$conf->{Fondation}{dependencies}}) {
                my $name = ref $dep eq 'HASH' ? (keys %$dep)[0] : $dep;
                $name = "Mojolicious::Plugin::$name" unless $name =~ /^Mojolicious::/;
                $already_selected{$name} = 1;
            }
        }
    }

    my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;
    $mc->discover_p($self->app)->then(sub ($plugins) {
        $self->stash(plugins => $plugins, already_selected => \%already_selected);
        $self->render(template => 'setup/plugins');
    })->catch(sub ($err) {
        $self->stash(error => "Failed to fetch plugins: $err", already_selected => \%already_selected);
        $self->render(template => 'setup/plugins');
    });
}

# ──────────────────────────────────────────────────────────────────────
# GET /setup/discover — async API: fetch plugin list from MetaCPAN
# ──────────────────────────────────────────────────────────────────────

sub discover ($self) {
    $self->render_later;
    my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;
    $mc->discover_p($self->app)->then(sub ($plugins) {
        $self->render(json => { plugins => $plugins });
    })->catch(sub ($err) {
        $self->render(json => { error => "$err" }, status => 500);
    });
}

# ──────────────────────────────────────────────────────────────────────
# POST /setup/start — build workflow from selected plugins and redirect to wizard
# ──────────────────────────────────────────────────────────────────────

sub start ($self) {
    my @selected = @{ $self->every_param('selected_plugins') // [] };
    return $self->reply->not_found unless @selected;

    # Collect setup parameters from selected plugins' fondation_meta
    my $conf_config = $self->_parse_conf_for_plugins(@selected);
    my $params      = $self->_collect_setup_params($conf_config, @selected);

    unless (@$params) {
        $self->flash(error => 'No configurable parameters found in selected plugins.');
        return $self->redirect_to('setup_plugins');
    }

    # Build the workflow YAML data structure
    my $yaml_data = $self->_build_workflow_data($params);

    # Register with Workflow::Factory (in-memory, no file needed)
    my $factory = Workflow::Factory->instance;

    # Ensure the persister directory exists
    my $persister_path = $self->_persister_file_dir;
    my $persister_dir  = $self->app->home->child($persister_path);
    $persister_dir->make_path unless -d $persister_dir;

    $factory->add_config(
        persister => [{
            name  => 'SetupFile',
            class => 'Workflow::Persister::File',
            path  => $persister_dir->to_string,
        }],
        workflow => [ $yaml_data ],
        action   => [ $yaml_data ],
    );

    # Create the workflow instance
    my $wf = $factory->create_workflow('setup', undef);
    return $self->reply->not_found unless $wf;

    # Store selected plugins in context for conf generation later
    $wf->context->param(_plugins => join(',', @selected));

    # Track which selected plugins are not yet installed, and their versions
    my @not_installed;
    my %installed_versions;
    for my $class (@selected) {
        my $pm = $class =~ s{::}{/}gr . '.pm';
        unless ($INC{$pm} || eval "require $class; 1") {
            push @not_installed, $class;
        } else {
            my $ver = eval { $class->VERSION } // 'unknown';
            $installed_versions{$class} = $ver;
        }
    }
    $wf->context->param(_not_installed     => join(',', @not_installed)) if @not_installed;
    $wf->context->param(_installed_versions => join(',', map { "$_=$installed_versions{$_}" } sort keys %installed_versions));
    $factory->save_workflow($wf);

    $self->cookie(
        setup_wizard_id => $wf->id,
        { path => '/', httponly => 1 }
    );

    $self->redirect_to('setup_wizard');
}

# ──────────────────────────────────────────────────────────────────────
# GET /setup — show the setup wizard
# ──────────────────────────────────────────────────────────────────────

sub wizard ($self) {
    $self->render_later;

    my $wf_id = $self->cookie('setup_wizard_id');
    my $wf;

    if ($wf_id) {
        $wf = $self->workflow('setup', $wf_id);
    }

    unless ($wf) {
        # No workflow yet — redirect to plugin selection
        return $self->redirect_to('setup_plugins');
    }

    return $self->reply->not_found unless $wf;

    my %context;
    my $raw_context = $wf->wf->context->param;
    if (ref $raw_context eq 'HASH') {
        %context = %$raw_context;
    }

    my $selected_plugins = [ split /,/, ($context{_plugins} // '') ];

    $self->stash(
        wf              => $wf,
        context         => \\%context,
        is_done         => $wf->state eq 'setup_done',
        is_review       => $wf->state eq 'setup_review',
        conf_path       => $context{_conf_path},
        config_loaded   => $INC{'Mojolicious/Plugin/Config.pm'} ? 1 : 0,
        selected_plugins => $selected_plugins,
        not_installed   => [ split /,/, ($context{_not_installed} // '') ],
    );

    # Check for upgrades via MetaCPAN
    my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;
    $mc->discover_p($self->app)->then(sub ($plugins) {
        my %cpan_version;
        $cpan_version{$_->{module_class}} = $_->{version} for @$plugins;

        my @upgradable;
        for my $class (@$selected_plugins) {
            my $installed = $self->_installed_version_for($class);
            next unless defined $installed;
            my $cpan = $cpan_version{$class} or next;
            if (version->parse($cpan) > version->parse($installed)) {
                push @upgradable, {
                    module_class => $class,
                    installed    => $installed,
                    cpan         => $cpan,
                };
            }
        }
        $self->stash(upgradable => \\@upgradable);
        $self->render(template => 'setup/wizard');
    })->catch(sub ($err) {
        $self->app->log->warn("MetaCPAN upgrade check failed: $err");
        $self->stash(upgradable => []);
        $self->render(template => 'setup/wizard');
    });
}

# ──────────────────────────────────────────────────────────────────────
# POST /setup/execute — process form data and execute a workflow action
# ──────────────────────────────────────────────────────────────────────

sub execute ($self) {
    my $wf_id  = $self->cookie('setup_wizard_id');
    my $action = $self->param('action');

    return $self->reply->not_found unless $wf_id && $action;

    my $wf = $self->workflow('setup', $wf_id);
    return $self->reply->not_found unless $wf;

    unless ($wf->can($action)) {
        $self->flash(error => "Action '$action' is not available in current state.");
        return $self->redirect_to('setup_wizard');
    }

    if ($action ne 'back') {
        my $state_meta = $wf->state_fondation;
        for my $p (@{ $state_meta->{parameters} // [] }) {
            my $val = $self->param($p->{key});
            $wf->wf->context->param($p->{key} => $val) if defined $val;
        }
    }

    eval { $wf->execute($action); };
    if ($@) {
        $self->flash(error => "Execution failed: $@");
    }

    if ($wf->state eq 'setup_done') {
        # Generate the .conf file from collected context values
        my $conf = $self->_generate_conf($wf);
        $wf->wf->context->param(_conf_path => $conf);
    }

    $self->redirect_to('setup_wizard');
}

# ──────────────────────────────────────────────────────────────────────
# GET /setup/reset — reset the wizard
# ──────────────────────────────────────────────────────────────────────

sub reset ($self) {
    $self->cookie(setup_wizard_id => '', { path => '/', expires => 1 });
    $self->redirect_to('setup_plugins');
}

# ══════════════════════════════════════════════════════════════════════
# INTERNAL METHODS
# ══════════════════════════════════════════════════════════════════════

# Read persister_file_dir from Workflow's merged config (via app manager)
sub _persister_file_dir ($self) {
    my $reg = $self->app->manager->registry;
    my $wf  = $reg->{'Mojolicious::Plugin::Fondation::Workflow'};
    return $wf ? ($wf->{config}{persister_file_dir} // 'data/setup') : 'data/setup';
}

# Resolve a dotted key path in a config hash (e.g. backends.main.dsn).
# Handles flattened array notation: backends => [main => { dsn => '...' }]
sub _resolve_config_value ($self, $config, $key_path) {
    $key_path =~ s/^\+//;
    my @parts  = split /\./, $key_path;
    my $current = $config;

    for my $part (@parts) {
        if (ref $current eq 'HASH') {
            return undef unless exists $current->{$part};
            $current = $current->{$part};
        }
        elsif (ref $current eq 'ARRAY') {
            my $found = 0;
            for (my $i = 0; $i < @$current; $i += 2) {
                if ($current->[$i] eq $part) {
                    $current = $current->[$i + 1];
                    $found = 1;
                    last;
                }
            }
            return undef unless $found;
        }
        else {
            return undef;
        }
    }

    return $current unless ref $current;
    return undef;
}

# Parse the existing conf file and extract per-plugin config hashes.
# Returns { $full_class => $config_hash }
sub _parse_conf_for_plugins ($self, @classes) {
    my %plugin_config;

    my $moniker   = $self->app->moniker;
    my $conf_path = $self->app->home->child("$moniker.conf");
    return \%plugin_config unless -f $conf_path;

    my $conf = do($conf_path->to_string);
    return \%plugin_config unless $conf && $conf->{Fondation} && $conf->{Fondation}{dependencies};

    for my $dep (@{$conf->{Fondation}{dependencies}}) {
        if (ref $dep eq 'HASH') {
            my ($name, $cfg) = %$dep;
            $name = "Mojolicious::Plugin::$name" unless $name =~ /^Mojolicious::/;
            $plugin_config{$name} = $cfg;
        }
    }
    return \%plugin_config;
}

# Collect setup parameters from selected plugin classes (via fondation_meta).
# $conf_config is an optional hashref from parsing the conf file: { $class => $config }
sub _collect_setup_params ($self, $conf_config, @classes) {
    my @params;

    for my $class (@classes) {
        my $meta = eval {
            my $err = Mojo::Loader::load_class($class);
            die $err if $err;
            $class->can('fondation_meta') ? $class->fondation_meta : undef;
        };
        unless ($meta) {
            $self->app->log->warn("Setup: no fondation_meta for $class: $@");
            next;
        }
        my $setup = $meta->{setup} or do {
            $self->app->log->debug("Setup: $class has no setup block");
            next;
        };

        my $short = $class;
        $short =~ s/^Mojolicious::Plugin:://;
        my $label = $setup->{label} // $short;
        my $desc  = $setup->{description} // '';

        # Try to get the plugin's config from the conf file
        my $plugin_conf = $conf_config && $conf_config->{$class};

        for my $param (@{ $setup->{parameters} // [] }) {
            my $key = $param->{key} or next;

            # Resolve current value: conf file > default
            my $current_value = $param->{default};
            if ($plugin_conf) {
                my $val = $self->_resolve_config_value($plugin_conf, $key);
                $current_value = $val if defined $val;
            }

            push @params, {
                plugin_short  => $short,
                plugin_label  => $label,
                plugin_desc   => $desc,
                key           => $key,
                label         => $param->{label} // $key,
                type          => $param->{type} // 'string',
                default       => $param->{default},
                current       => $current_value,
                required      => $param->{required} ? 1 : 0,
                min           => $param->{min},
                max           => $param->{max},
                placeholder   => $param->{placeholder},
                options       => $param->{options},
            };
        }
    }

    return \@params;
}

# Build the workflow data structure from collected parameters.
sub _build_workflow_data ($self, $params) {
    my @params = @$params;

    # Group parameters by plugin
    my @plugin_groups;
    my %seen_plugin;
    for my $p (@params) {
        my $short = $p->{plugin_short};
        unless (exists $seen_plugin{$short}) {
            push @plugin_groups, {
                plugin_short => $short,
                label        => $p->{plugin_label},
                description  => $p->{plugin_desc},
                parameters   => [],
            };
            $seen_plugin{$short} = scalar @plugin_groups - 1;
        }
        push @{$plugin_groups[$seen_plugin{$short}]{parameters}}, $p;
    }

    # Build states
    my @states;
    my $prev_state;

    for (my $i = 0; $i < @plugin_groups; $i++) {
        my $group   = $plugin_groups[$i];
        my $state   = $self->_plugin_state_name($group->{plugin_short});
        my $is_last = ($i == @plugin_groups - 1);

        my $state_actions = [];
        if ($i > 0) {
            push @$state_actions, { name => 'back', resulting_state => $prev_state };
        }
        if ($is_last) {
            push @$state_actions, { name => 'next', resulting_state => 'setup_review' };
        } else {
            my $next_state = $self->_plugin_state_name($plugin_groups[$i+1]{plugin_short});
            push @$state_actions, { name => 'next', resulting_state => $next_state };
        }

        my @parameters;
        for my $p (@{$group->{parameters}}) {
            my $pm = {
                key      => $p->{key},
                type     => $p->{type},
                label    => $p->{label},
                default  => $p->{default},
                current  => $p->{current},
                required => $p->{required},
            };
            $pm->{min}         = $p->{min} if defined $p->{min};
            $pm->{max}         = $p->{max} if defined $p->{max};
            $pm->{placeholder} = $p->{placeholder} if defined $p->{placeholder};
            $pm->{options}     = $p->{options} if $p->{options};
            push @parameters, $pm;
        }

        push @states, {
            name      => $state,
            fondation => {
                label       => $group->{label},
                plugin      => $group->{plugin_short},
                description => $group->{description},
                parameters  => \@parameters,
            },
            action => $state_actions,
        };

        $prev_state = $state;
    }

    # Review state
    push @states, {
        name      => 'setup_review',
        fondation => { label => 'Review' },
        action    => [
            { name => 'back', resulting_state => $prev_state },
            { name => 'save', resulting_state => 'setup_done' },
        ],
    };

    # Done state (terminal)
    push @states, {
        name      => 'setup_done',
        fondation => { label => 'Done', color => 'success', icon => 'check-circle' },
        action    => [],
    };

    return {
        type         => 'setup',
        initial_state => $states[0]{name},
        persister    => 'SetupFile',
        fondation    => {
            label       => 'Application Setup',
            description => 'Configure your application',
        },
        state  => \@states,
        action => [
            { name => 'next', class => 'Workflow::Action::Null',
              fondation => { label => 'Next', color => 'primary', icon => 'arrow-right', group => 'navigation' } },
            { name => 'back', class => 'Workflow::Action::Null',
              fondation => { label => 'Back', color => 'secondary', icon => 'arrow-left', group => 'navigation' } },
            { name => 'save', class => 'Workflow::Action::Null',
              fondation => { label => 'Save Configuration', color => 'success', icon => 'check', group => 'main' } },
        ],
    };
}

# Derive a state name from a plugin short name.
sub _plugin_state_name ($self, $plugin_short) {
    my $name = $plugin_short;
    $name =~ s/Fondation:://g;
    $name = lc($name);
    $name =~ s/::/_/g;
    $name =~ s/[^a-z0-9_]+/_/g;
    $name =~ s/_+/_/g;
    $name =~ s/^_|_$//g;
    return "setup_${name}";
}

# Generate the .conf file from collected context values.
sub _generate_conf ($self, $wf) {
    my $context = $wf->wf->context->param;
    my %ctx = ref $context eq 'HASH' ? %$context : ();

    my $plugins_str = delete $ctx{_plugins} || '';
    my @plugins = split /,/, $plugins_str;

    # Build key→plugin mapping from fondation_meta setup parameters
    my %key_to_plugin;
    for my $plugin_class (@plugins) {
        my $meta = eval {
            my $err = Mojo::Loader::load_class($plugin_class);
            die $err if $err;
            $plugin_class->can('fondation_meta') ? $plugin_class->fondation_meta : undef;
        };
        next unless $meta && $meta->{setup} && $meta->{setup}{parameters};
        for my $p (@{ $meta->{setup}{parameters} }) {
            $key_to_plugin{ $p->{key} } = $plugin_class if $p->{key};
        }
    }

    # Build per-plugin config.
    # Keys with "+" prefix (e.g. +backends.main.dsn) indicate the first
    # segment is an arrayref and the second is a name within it.
    my %plugin_config;
    for my $key (sort keys %ctx) {
        next unless defined $ctx{$key} && $ctx{$key} ne '';
        next if $key eq 'workflow_id';
        my $plugin = $key_to_plugin{$key} or next;

        my $is_array = ($key =~ s/^\+//);
        my @parts    = split /\./, $key;
        my $target   = ($plugin_config{$plugin} //= {});

        if ($is_array) {
            # +backends.main.dsn → $parts[0]=backends, $parts[1]=name, $parts[2..]=subkeys
            my $array_key = $parts[0];   # backends
            my $name      = $parts[1];   # main
            # Ensure $target->{backends} is an arrayref
            $target->{$array_key} //= [];
            # Find or create the named entry
            my $entry;
            for (my $j = 0; $j < @{$target->{$array_key}}; $j += 2) {
                if ($target->{$array_key}[$j] eq $name) {
                    $entry = $target->{$array_key}[$j+1];
                    last;
                }
            }
            unless ($entry) {
                $entry = {};
                push @{$target->{$array_key}}, $name, $entry;
            }
            # Navigate remaining subkeys
            $target = $entry;
            for my $i (2 .. $#parts - 1) {
                $target->{$parts[$i]} //= {};
                $target = $target->{$parts[$i]};
            }
            $target->{$parts[-1]} = $ctx{"+$key"};  # leaf value
        } else {
            # Plain dotted key → nested hash
            for my $i (0 .. $#parts - 1) {
                $target->{$parts[$i]} //= {};
                $target = $target->{$parts[$i]};
            }
            $target->{$parts[-1]} = $ctx{$key};
        }
    }

    # Build Fondation wrapper
    my @deps;
    for my $plugin (@plugins) {
        (my $short = $plugin) =~ s/^Mojolicious::Plugin:://;
        if (my $cfg = $plugin_config{$plugin}) {
            push @deps, { $short => $cfg };
        } else {
            push @deps, $short;
        }
    }

    my $short = 'Fondation';
    $short =~ s/^Mojolicious::Plugin:://;
    my %conf = ( $short => { dependencies => \@deps } );

    my $moniker   = $self->app->moniker;
    my $conf_path = $self->app->home->child("$moniker.conf");

    require Data::Dumper;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Quotekeys = 0;

    my $content = Data::Dumper::Dumper(\%conf);
    $conf_path->spurt(encode('UTF-8', $content));

    $self->app->log->info("Configuration saved to $conf_path");
    return $conf_path->to_string;
}

sub _installed_version_for ($self, $class) {
    my $pm = $class =~ s{::}{/}gr . '.pm';
    return undef unless $INC{$pm} || eval "require $class; 1";
    return eval { $class->VERSION } // undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::Controller::Setup - Setup wizard controller — plugin selection, workflow wizard, and .conf generation

=head1 VERSION

version 0.02

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

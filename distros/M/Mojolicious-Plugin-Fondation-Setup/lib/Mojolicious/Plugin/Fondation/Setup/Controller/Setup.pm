package Mojolicious::Plugin::Fondation::Setup::Controller::Setup;
$Mojolicious::Plugin::Fondation::Setup::Controller::Setup::VERSION = '0.04';
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
                my $name = ref $dep ? (keys %$dep)[0] : $dep;
                $name = "Mojolicious::Plugin::$name" unless $name =~ /^Mojolicious::/;
                $already_selected{$name} = 1;
            }
        }
    }

    # Pre-select plugins passed via ?selected= from the retry link
    if (my $sel = $self->param('selected')) {
        $already_selected{$_} = 1 for split /,/, $sel;
    }

    my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;
    $mc->discover_p($self->app)->then(sub ($plugins) {
        # Merge locally-developed plugins. Local version + CPAN metadata.
        my $dev = $self->_discover_dev_plugins;
        my %dev_by_class = map { $_->{module_class} => $_ } @$dev;
        for my $p (@$plugins) {
            $p->{is_dev} = 0;
            $p->{cpan_version} = $p->{version};
            if (my $d = $dev_by_class{$p->{module_class}}) {
                # Local wins for version/installed, keep CPAN metadata
                $p->{is_dev}            = 1;
                $p->{installed}         = 1;
                $p->{installed_version} = $d->{installed_version};
            }
            # Compare installed vs CPAN versions
            $p->{upgrade_available} = 0;
            $p->{release_pending}   = 0;
            if ($p->{installed_version} && $p->{version}) {
                my $local = version->parse($p->{installed_version});
                my $cpan  = version->parse($p->{version});
                $p->{upgrade_available} = 1 if $cpan  > $local;
                $p->{release_pending}   = 1 if $local > $cpan;
            }
        }
        # Add dev-only plugins not on MetaCPAN
        my %seen_cpan = map { $_->{module_class} => 1 } @$plugins;
        for my $d (@$dev) {
            next if $seen_cpan{$d->{module_class}};
            push @$plugins, $d;
        }
        $self->stash(plugins => $plugins, already_selected => \%already_selected);
        $self->render(template => 'setup/plugins');
    })->catch(sub ($err) {
        # MetaCPAN failed — still show local plugins if available
        my $dev = $self->_discover_dev_plugins;
        if (@$dev) {
            $_->{is_dev} = 1 for @$dev;
            $self->stash(plugins => $dev, already_selected => \%already_selected);
            $self->render(template => 'setup/plugins');
        } else {
            $self->stash(error => "Failed to fetch plugins: $err", already_selected => \%already_selected);
            $self->render(template => 'setup/plugins');
        }
    });
}

# ──────────────────────────────────────────────────────────────────────
# GET /setup/discover — async API: fetch plugin list from MetaCPAN
# ──────────────────────────────────────────────────────────────────────

sub discover ($self) {
    $self->render_later;
    my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;
    $mc->discover_p($self->app)->then(sub ($plugins) {
        my $dev = $self->_discover_dev_plugins;
        my %dev_by_class = map { $_->{module_class} => $_ } @$dev;
        for my $p (@$plugins) {
            $p->{is_dev} = 0;
            $p->{cpan_version} = $p->{version};
            if (my $d = $dev_by_class{$p->{module_class}}) {
                $p->{is_dev}            = 1;
                $p->{installed}         = 1;
                $p->{installed_version} = $d->{installed_version};
            }
            $p->{upgrade_available} = 0;
            $p->{release_pending}   = 0;
            if ($p->{installed_version} && $p->{version}) {
                my $local = version->parse($p->{installed_version});
                my $cpan  = version->parse($p->{version});
                $p->{upgrade_available} = 1 if $cpan  > $local;
                $p->{release_pending}   = 1 if $local > $cpan;
            }
        }
        my %seen_cpan = map { $_->{module_class} => 1 } @$plugins;
        for my $d (@$dev) {
            next if $seen_cpan{$d->{module_class}};
            push @$plugins, $d;
        }
        $self->render(json => { plugins => $plugins });
    })->catch(sub ($err) {
        my $dev = $self->_discover_dev_plugins;
        if (@$dev) {
            $_->{is_dev} = 1 for @$dev;
            $self->render(json => { plugins => $dev });
        } else {
            $self->render(json => { error => "$err" }, status => 500);
        }
    });
}

# ──────────────────────────────────────────────────────────────────────
# POST /setup/start — build workflow from selected plugins and redirect to wizard
# ──────────────────────────────────────────────────────────────────────

sub start ($self) {
    my @selected = @{ $self->every_param('selected_plugins') // [] };
    return $self->reply->not_found unless @selected;

    # Separate installed from not-yet-installed plugins.
    # Only installed plugins can have their fondation_meta loaded.
    my (@installed, @not_installed);
    my %installed_versions;
    for my $class (@selected) {
        my $pm = $class =~ s{::}{/}gr . '.pm';
        if ($INC{$pm} || eval "require $class; 1") {
            push @installed, $class;
            my $ver = eval { $class->VERSION } // 'unknown';
            $installed_versions{$class} = $ver;
        } elsif ($self->_is_dev_plugin($class)) {
            # Plugin is in dev_plugins_dir but not in @INC.
            # Add its lib/ to @INC so that its own use/require statements work,
            # then load it so fondation_meta is available.
            my $dev_dir = $self->_dev_plugins_dir;
            (my $rel = "$pm") =~ s{::}{/}g;
            my @found = glob("$dev_dir/Mojolicious-Plugin-Fondation-*/lib/$rel");
            if (@found && -f $found[0]) {
                # The lib/ dir is two levels up from the .pm file
                # e.g. .../Mojolicious-Plugin-Fondation-Model-DBIx-Async/lib/
                my $lib_dir = $found[0];
                $lib_dir =~ s{/lib/.*}{/lib};
                unshift @INC, $lib_dir if -d $lib_dir;
                eval { require "$found[0]"; 1 };
                if (!$@) {
                    push @installed, $class;
                    my $ver = eval { $class->VERSION } // 'unknown';
                    $installed_versions{$class} = $ver;
                    next;
                }
            }
            push @not_installed, $class;
        } else {
            push @not_installed, $class;
        }
    }

    # Collect setup parameters from installed plugins only.
    # If any plugin is not installed, skip config — the wizard will show
    # install instructions first. Config can be done after installation.
    my $conf_config = $self->_parse_conf_for_plugins(@selected);
    my $params      = @not_installed ? [] : $self->_collect_setup_params($conf_config, @installed);

    unless (@$params || @not_installed) {
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
        context         => \%context,
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
        $self->stash(upgradable => \@upgradable);
        $self->render(template => 'setup/wizard');
    })->catch(sub ($err) {
        $self->app->log->debug("MetaCPAN upgrade check failed: $err");
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
    return \%plugin_config unless $conf;

    for my $class (@classes) {
        (my $short = $class) =~ s/^Mojolicious::Plugin:://;
        my $cfg = $conf->{$short};
        $plugin_config{$class} = $cfg if $cfg && ref $cfg eq 'HASH';
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
            $self->app->log->debug("Setup: no fondation_meta for $class: $@");
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

    # No configurable parameters — go straight to review
    unless (@plugin_groups) {
        return {
            type          => 'setup',
            initial_state => 'setup_review',
            persister     => 'SetupFile',
            fondation     => {
                label       => 'Application Setup',
                description => 'Configure your application',
            },
            state => [
                {
                    name      => 'setup_review',
                    fondation => { label => 'Review' },
                    action    => [
                        { name => 'save', resulting_state => 'setup_done' },
                    ],
                },
                {
                    name      => 'setup_done',
                    fondation => { label => 'Done', color => 'success', icon => 'check-circle' },
                    action    => [],
                },
            ],
            action => [
                { name => 'save', class => 'Workflow::Action::Null',
                  fondation => { label => 'Save Configuration', color => 'success', icon => 'check', group => 'main' } },
            ],
        };
    }

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

    # Build Fondation wrapper — dependencies as plain strings (no config)
    my @deps;
    for my $plugin (@plugins) {
        (my $short = $plugin) =~ s/^Mojolicious::Plugin:://;
        push @deps, $short;
    }

    my %conf = ( Fondation => { dependencies => \@deps } );

    # Add each plugin's config at root level so $app->config->{$short} works
    for my $plugin (@plugins) {
        next unless $plugin_config{$plugin};
        (my $short = $plugin) =~ s/^Mojolicious::Plugin:://;
        $conf{$short} = $plugin_config{$plugin};
    }

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

# Read dev_plugins_dir from the Fondation manager config (not app config).
sub _dev_plugins_dir ($self) {
    my $manager = $self->app->manager;
    return $manager ? ($manager->config->{dev_plugins_dir} // undef) : undef;
}

# Check whether a plugin class lives under dev_plugins_dir.
# Returns true if the .pm file is found in any scanned dev subdirectory.
sub _is_dev_plugin ($self, $class) {
    my $dev_dir = $self->_dev_plugins_dir
        or return 0;

    (my $rel = "$class.pm") =~ s{::}{/}g;

    my @dev = glob("$dev_dir/Mojolicious-Plugin-Fondation-*/lib/$rel");
    return @dev > 0;
}

# Scan dev_plugins_dir for locally-developed Fondation plugins.
# Returns an arrayref of plugin hashes (same shape as discover_p).
sub _discover_dev_plugins ($self) {
    my $dev_dir = $self->_dev_plugins_dir
        or return [];

    my @plugins;
    my @dirs = glob("$dev_dir/Mojolicious-Plugin-Fondation-*");
    for my $dir (@dirs) {
        next unless -d $dir;
        (my $dist = $dir) =~ s{.*/}{};  # Mojolicious-Plugin-Fondation-Foo-Bar

        # Derive module class from directory name
        (my $module_class = $dist) =~ s/^Mojolicious-Plugin-//;
        $module_class = "Mojolicious::Plugin::$module_class";
        $module_class =~ s/-/::/g;

        # Dev plugins are always installed; loading is deferred to start().
        # Extract metadata from source without triggering register().
        my ($abstract, $version, $deps) = ('', '', []);
        my $pm = "$module_class.pm";
        $pm =~ s{::}{/}g;
        my $pm_path = "$dir/lib/$pm";
        if (-f $pm_path) {
            open my $fh, '<', $pm_path or next;
            my $src = do { local $/; <$fh> };
            close $fh;

            # Extract version: try $VERSION in source, then dist.ini
            if ($src =~ /\$VERSION\s*=\s*['"]?([^'";]+)/) {
                $version = $1;
            } else {
                my $ini = "$dir/dist.ini";
                if (-f $ini) {
                    open my $fh2, '<', $ini or next;
                    while (my $line = <$fh2>) {
                        if ($line =~ /^version\s*=\s*(\S+)/) {
                            $version = $1;
                            last;
                        }
                    }
                    close $fh2;
                }
            }

            # Extract # ABSTRACT: comment
            if ($src =~ /^\s*#\s*ABSTRACT:\s*(.+)$/m) {
                $abstract = $1;
            }

            # Safely eval the fondation_meta sub in a temp package
            if ($src =~ /(sub\s+fondation_meta\s*\{)/) {
                my $pos  = $-[0] + length($1);
                my $depth = 1;
                my $end   = $pos;
                while ($depth > 0 && $end < length($src)) {
                    my $c = substr($src, $end, 1);
                    $depth++ if $c eq '{';
                    $depth-- if $c eq '}';
                    $end++;
                }
                my $body = substr($src, $-[0], $end - $-[0]);
                my $meta = eval qq{package _FondationDevMeta; $body; _FondationDevMeta::fondation_meta();};
                if ($meta && !$@ && ref $meta eq 'HASH') {
                    $deps = $meta->{dependencies} // [];
                    $abstract = $meta->{setup}{description} // '' unless $abstract;
                }
            }

            # Convert short dep names to full class names
            $deps = [ map { /^Mojolicious::Plugin::/ ? $_ : "Mojolicious::Plugin::$_" } @$deps ];
        }
        my $installed = 1;

        push @plugins, {
            distribution      => $dist,
            version           => $version,
            abstract          => $abstract,
            author            => '',
            date              => '',
            module_class      => $module_class,
            installed         => $installed,
            installed_version => $version,
            upgrade_available => 0,
            dependencies      => $deps,
            is_dev            => 1,
        };
    }
    return \@plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::Controller::Setup - Setup wizard controller — plugin selection, workflow wizard, and .conf generation

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    # Routes are registered automatically by Fondation::Setup:
    #   GET  /setup          → wizard()
    #   GET  /setup/plugins  → plugins()
    #   GET  /setup/discover → discover()
    #   POST /setup/start    → start()
    #   POST /setup/execute  → execute()
    #   GET  /setup/reset    → reset()

=head1 DESCRIPTION

This controller implements the Fondation setup wizard — a step-by-step
interface for discovering, selecting, and configuring Fondation plugins.
It fetches available plugins from MetaCPAN, lets the user pick which ones
to install, walks them through configuration parameters via a Workflow
state machine, and generates the application's C<.conf> file.

The wizard is designed to be the first thing a user sees after installing
a Fondation-based application. It can also be re-run later to add or
upgrade plugins.

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::Controller::Setup - Setup wizard controller — plugin selection, workflow wizard, and .conf generation

=head1 ACTIONS

=head2 plugins

    GET /setup/plugins

Renders the plugin selection page. Reads the existing C<.conf> file to
pre-select plugins that are already configured, fetches the full list of
Fondation plugins from MetaCPAN (async), and passes both to the
C<setup/plugins> template.

Stash keys:

=over 4

=item * C<plugins> — arrayref of plugin metadata from MetaCPAN

=item * C<already_selected> — hashref of fully-qualified class names
already present in the config

=back

=head2 discover

    GET /setup/discover

Async JSON endpoint that returns the full list of Fondation plugins
discovered on MetaCPAN. Used by the plugin selection UI to populate
the list dynamically.

Response: C<{ plugins => [...] }> on success, C<{ error => "..." }>
with status 500 on failure.

=head2 start

    POST /setup/start

Builds a Workflow state machine from the selected plugins' configuration
parameters. Expects C<selected_plugins> (array of fully-qualified class
names) in the POST body.

Flow:

=over 4

=item 1. Reads each selected plugin's C<fondation_meta → setup → parameters>

=item 2. Resolves current values from the existing C<.conf> file if present

=item 3. Builds a YAML workflow data structure with one state per plugin

=item 4. Registers the workflow with C<Workflow::Factory> (in-memory)

=item 5. Checks which selected plugins are not yet installed

=item 6. Stores the workflow ID in a cookie (C<setup_wizard_id>)

=item 7. Redirects to C</setup> (the wizard)

=back

=head2 wizard

    GET /setup

Renders the setup wizard page. Loads the workflow identified by the
C<setup_wizard_id> cookie. If no workflow exists yet, redirects to
C</setup/plugins>.

Also performs an async MetaCPAN check for upgradable plugins — compares
installed versions against CPAN versions and flags any that are out of
date.

Stash keys:

=over 4

=item * C<wf> — the workflow object

=item * C<context> — workflow context hashref (user-provided values)

=item * C<is_done> — true when state is C<setup_done>

=item * C<is_review> — true when state is C<setup_review>

=item * C<conf_path> — path to the generated C<.conf> file (when done)

=item * C<config_loaded> — true if C<Mojolicious::Plugin::Config> is loaded

=item * C<selected_plugins> — arrayref of selected plugin class names

=item * C<not_installed> — arrayref of plugins not yet installed

=item * C<upgradable> — arrayref of plugins with newer versions on CPAN

=back

=head2 execute

    POST /setup/execute

Processes a workflow action (C<next>, C<back>, C<save>). Reads form
parameters matching the current state's parameter keys and stores them
in the workflow context. On C<save> (transition to C<setup_done>),
generates the C<.conf> file via C<_generate_conf>.

Expects:

=over 4

=item * C<action> — the workflow action name to execute

=item * Parameter values matching the current state's C<parameters> keys

=back

=head2 reset

    GET /setup/reset

Clears the C<setup_wizard_id> cookie and redirects back to the plugin
selection page. Use this to start the wizard over from scratch.

=head1 INTERNAL METHODS

These methods are not exposed as routes but implement the core logic.

=head2 _persister_file_dir

    my $dir = $self->_persister_file_dir;

Returns the directory path for the Workflow::Persister::File storage.
Reads C<persister_file_dir> from C<Fondation::Workflow>'s merged config
in the registry, defaulting to C<data/setup>.

=head2 _resolve_config_value

    my $value = $self->_resolve_config_value($config, $key_path);

Resolves a dotted key path within a config hash. Handles flattened array
notation (e.g. C<backends.main.dsn> where C<backends> is an arrayref of
C<< name => { dsn => '...' } >> pairs). Keys prefixed with C<+> are
stripped before resolution.

=head2 _parse_conf_for_plugins

    my $configs = $self->_parse_conf_for_plugins(@classes);

Parses the existing C<.conf> file and extracts per-plugin configuration
hashes for the given class names. Returns a hashref keyed by
fully-qualified class name.

=head2 _collect_setup_params

    my $params = $self->_collect_setup_params($conf_config, @classes);

Loads each plugin's C<fondation_meta → setup → parameters> and resolves
current values from the config file (if available). Returns an arrayref
of parameter hashes ready for the workflow builder.

Each parameter hash contains: C<plugin_short>, C<plugin_label>,
C<plugin_desc>, C<key>, C<label>, C<type>, C<default>, C<current>,
C<required>, and optionally C<min>, C<max>, C<placeholder>, C<options>.

=head2 _build_workflow_data

    my $yaml_data = $self->_build_workflow_data($params);

Builds a complete Workflow data structure from collected parameters.
Creates one state per plugin group, a C<setup_review> state, and a
terminal C<setup_done> state. Includes C<next>, C<back>, and C<save>
actions with Fondation metadata for UI rendering (labels, colors, icons).

=head2 _plugin_state_name

    my $state = $self->_plugin_state_name($plugin_short);

Derives a workflow state name from a plugin short name — lowercased,
double-colons replaced with underscores, non-alphanumeric chars stripped,
prefixed with C<setup_>. Example: C<Fondation::Model::DBIx::Async>
becomes C<setup_model_dbix_async>.

=head2 _generate_conf

    my $conf_path = $self->_generate_conf($wf);

Generates the application C<.conf> file from all values collected in the
workflow context. Builds a hash with:

=over 4

=item * C<Fondation → dependencies> — array of plugin short names

=item * Root-level keys per plugin with their configured values

=item * Dotted keys expanded into nested hashes; C<+> prefix keys use
flattened array notation

=back

Writes the file using C<Data::Dumper> and returns its path.

=head2 _installed_version_for

    my $version = $self->_installed_version_for($class);

Returns the installed version of a plugin class, or C<undef> if not
installed. Used to compare against MetaCPAN versions for upgrade
detection.

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

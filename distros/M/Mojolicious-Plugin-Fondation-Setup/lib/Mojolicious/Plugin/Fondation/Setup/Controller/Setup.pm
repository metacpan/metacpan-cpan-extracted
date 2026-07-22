package Mojolicious::Plugin::Fondation::Setup::Controller::Setup;
$Mojolicious::Plugin::Fondation::Setup::Controller::Setup::VERSION = '0.11';
# ABSTRACT: Session-based setup wizard — no Workflow, no file persister

use Mojo::Base 'Mojolicious::Controller', -signatures;
use version;

use Mojo::File 'path';
use Mojo::Loader;
use Mojo::Util qw(encode);
use Mojolicious::Plugin::Fondation::Setup::MetaCPAN;

# ══════════════════════════════════════════════════════════════════════
# Session keys used by this controller:
#
#   setup_plugins       => [$class, ...]        selected plugin classes
#   setup_index         => $int                 current wizard step
#   setup_context       => {$key => $val, ...}  accumulated form values
#   setup_states        => [{label, plugin, params}, ...]
#   setup_not_installed => [$class, ...]
#   setup_retry         => [$class, ...]        previous selection for retry
#
# Wizard indexes:
#   0 .. $#states   → form for that plugin
#   @states         → review
#   @states + 1     → done
# ══════════════════════════════════════════════════════════════════════

# ── GET /setup/plugins ──────────────────────────────────────────────

sub plugins ($self) {
    $self->render_later;

    my %preselected = $self->_read_conf_plugins;
    $preselected{$_} = 1 for @{ $self->session('setup_retry') // [] };

    $self->_discover(sub ($plugins) {
        $_->{badges} = $self->_badges_for($_) for @$plugins;
        $self->stash(plugins => $plugins, preselected => \%preselected);
        $self->render(template => 'setup/plugins');
    });
}

# ── GET /setup/discover (JSON API) ───────────────────────────────────

sub discover ($self) {
    $self->render_later;
    $self->_discover(sub ($plugins) {
        $_->{badges} = $self->_badges_for($_) for @$plugins;
        $self->render(json => { plugins => $plugins });
    });
}

# ── POST /setup/start ───────────────────────────────────────────────

sub start ($self) {
    my @selected = @{ $self->every_param('selected_plugins') // [] };
    return $self->reply->not_found unless @selected;

    # Separate installed from not-installed
    my (@installed, @not_installed);
    for my $class (@selected) {
        if ($self->_try_load($class)) {
            push @installed, $class;
        } else {
            push @not_installed, $class;
        }
    }

    # Build one state per installed plugin that has setup parameters
    my @states;
    my %context;
    my $conf_config = $self->_read_conf_for(@selected);

    for my $class (@installed) {
        my $meta = $self->_fondation_meta($class) or next;
        my $setup = $meta->{setup} or next;
        my $params = $setup->{parameters} // [];

        my @fields;
        my $plugin_conf = $conf_config->{$class};

        for my $p (@$params) {
            my $key = $p->{key} or next;
            my $val = $self->_resolve_config($plugin_conf, $key) // $p->{default};
            $context{$key} = $val;

            push @fields, {
                key         => $key,
                label       => $p->{label}       // $key,
                type        => $p->{type}        // 'string',
                default     => $p->{default},
                current     => $val,
                required    => $p->{required}    ? 1 : 0,
                placeholder => $p->{placeholder},
                options     => $p->{options},
                min         => $p->{min},
                max         => $p->{max},
            };
        }

        next unless @fields;

        (my $short = $class) =~ s/^Mojolicious::Plugin:://;
        push @states, {
            label       => $setup->{label}       // $short,
            plugin      => $short,
            description => $setup->{description} // '',
            fields      => \@fields,
        };
    }

    # Store everything in session
    $self->session(
        setup_plugins       => \@selected,
        setup_states        => \@states,
        setup_context       => \%context,
        setup_index         => 0,
        setup_not_installed => \@not_installed,
        setup_retry         => \@selected,
    );

    $self->redirect_to('setup_wizard');
}

# ── GET /setup ──────────────────────────────────────────────────────

sub wizard ($self) {
    $self->render_later;

    my $plugins  = $self->session('setup_plugins');
    my $states   = $self->session('setup_states');
    my $index    = $self->session('setup_index');
    my $context  = $self->session('setup_context');
    my $missing  = $self->session('setup_not_installed');

    return $self->redirect_to('setup_plugins') unless $plugins;

    my $is_review = ($index == @$states);
    my $is_done   = ($index > @$states);
    my $state     = $is_done || $is_review ? undef : $states->[$index];

    $self->stash(
        states          => $states,
        state_index     => $index,
        current_state   => $state,
        is_first        => ($index == 0),
        is_last         => ($index == @$states - 1),
        is_review       => $is_review,
        is_done         => $is_done,
        context         => $context,
        selected_plugins => $plugins,
        not_installed   => $missing,
        conf_path       => $context->{_conf_path},
        config_loaded   => $INC{'Mojolicious/Plugin/Config.pm'} ? 1 : 0,
    );

    # Async: fetch CPAN versions for upgrade/dependency checks
    $self->_discover(sub ($all_plugins) {
        my %cpan_ver;
        my %cpan_deps;
        for my $p (@$all_plugins) {
            $cpan_ver{$p->{module_class}}  = $p->{version};
            $cpan_deps{$p->{module_class}} = $p->{dependencies} // [];
        }

        my (@upgradable, @unresolvable);
        my %selected = map { $_ => 1 } @$plugins;
        my $dev_dir  = $self->_dev_plugins_dir;
        my $mc       = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;

        for my $class (@$plugins) {
            # --- upgradable ---
            if (my $inst = $mc->installed_version($class)) {
                my $cpan = $cpan_ver{$class};
                if ($cpan && version->parse($cpan) > version->parse($inst)) {
                    push @upgradable, { module_class => $class, installed => $inst, cpan => $cpan };
                }
            }

            # --- dependencies ---
            my $deps;
            my $meta = $self->_fondation_meta($class);
            if ($meta && $meta->{dependencies}) {
                $deps = $meta->{dependencies};
            } else {
                $deps = $cpan_deps{$class} // [];
            }

            for my $dep (@$deps) {
                $dep = "Mojolicious::Plugin::$dep" unless $dep =~ /^Mojolicious::/;
                next if $dep eq 'Mojolicious::Plugin::Fondation';
                next if $selected{$dep};
                next if $mc->installed_version($dep);
                next if $cpan_ver{$dep};
                next if $dev_dir && $self->_try_load_dev($dep);
                push @unresolvable, { plugin => $class, dependency => $dep };
            }
        }

        # If anything blocks configuration (not installed, upgradable,
        # or unresolvable deps), skip to review and show only the alerts.
        my $review_entries;
        my $can_configure = 1;
        if (@$missing || @upgradable || @unresolvable) {
            $self->session(setup_index => scalar @$states) if $index <= @$states;
            $self->stash(is_review => 1, is_done => 0, current_state => undef) if $index <= @$states;
            $review_entries = [];
            $can_configure  = 0;
        } else {
            $review_entries = $self->_review_entries($context);
        }

        $self->stash(
            upgradable     => \@upgradable,
            unresolvable   => \@unresolvable,
            install_command => $self->_install_command(\@upgradable, $missing, \%cpan_ver),
            review_entries  => $review_entries,
            can_configure   => $can_configure,
        );

        $self->render(template => 'setup/wizard');
    });
}

# ── POST /setup/execute ─────────────────────────────────────────────

sub execute ($self) {
    my $action  = $self->param('action');
    my $states  = $self->session('setup_states') // [];
    my $index   = $self->session('setup_index');
    my $context = $self->session('setup_context') // {};

    return $self->reply->not_found unless defined $action;

    if ($action eq 'back') {
        $self->session(setup_index => $index - 1);
    }
    elsif ($action eq 'next' || $action eq 'save') {
        # Save form values
        my $state = $states->[$index];
        if ($state && $state->{fields}) {
            for my $f (@{$state->{fields}}) {
                my $val = $self->param($f->{key});
                $context->{$f->{key}} = $val if defined $val;
            }
            $self->session(setup_context => $context);
        }

        if ($action eq 'save') {
            my $path = $self->_generate_conf;
            $context->{_conf_path} = $path;
            $self->session(
                setup_context => $context,
                setup_index   => scalar @$states + 1,
            );
        } else {
            $self->session(setup_index => $index + 1);
        }
    }

    $self->redirect_to('setup_wizard');
}

# ── GET /setup/reset ────────────────────────────────────────────────

sub reset ($self) {
    $self->session(
        setup_plugins       => undef,
        setup_states        => undef,
        setup_context       => undef,
        setup_index         => undef,
        setup_not_installed => undef,
        setup_retry         => undef,
    );
    $self->redirect_to('setup_plugins');
}

# ══════════════════════════════════════════════════════════════════════
# INTERNAL HELPERS
# ══════════════════════════════════════════════════════════════════════

# Shared discovery: MetaCPAN + dev plugins merge.
# Calls $cb with the merged plugin arrayref.
sub _discover ($self, $cb) {
    my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;
    $mc->discover_p($self->app)->then(sub ($plugins) {
        my $dev = $self->_dev_plugins;

        my %dev_by_class = map { $_->{module_class} => $_ } @$dev;
        for my $p (@$plugins) {
            $p->{is_dev} = 0;
            $p->{cpan_version} = $p->{version};
            if (my $d = $dev_by_class{$p->{module_class}}) {
                $p->{is_dev}            = 1;
                $p->{installed}         = 1;
                $p->{installed_version} = $d->{installed_version};
                # Replace MetaCPAN dependencies with dev (dev is the source of truth)
                $p->{dependencies} = $d->{dependencies};
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

        $cb->($plugins);
    })->catch(sub ($err) {
        my $dev = $self->_dev_plugins;
        if (@$dev) {
            $_->{is_dev} = 1 for @$dev;
            $cb->($dev);
        } else {
            $self->stash(error => "MetaCPAN unavailable: $err");
            $cb->([]);
        }
    });
}

# Parse $moniker.conf and return { $full_class => 1 } for already-configured plugins.
sub _read_conf_plugins ($self) {
    my %selected;
    my $conf_path = $self->app->home->child($self->app->moniker . '.conf');
    return %selected unless -f $conf_path;

    my $conf = do($conf_path->to_string);
    return %selected unless $conf && $conf->{Fondation} && $conf->{Fondation}{dependencies};

    for my $dep (@{$conf->{Fondation}{dependencies}}) {
        my $name = ref $dep ? (keys %$dep)[0] : $dep;
        $name = "Mojolicious::Plugin::$name" unless $name =~ /^Mojolicious::/;
        $selected{$name} = 1;
    }
    return %selected;
}

# Parse $moniker.conf and return { $full_class => $config_hash } for selected plugins.
sub _read_conf_for ($self, @classes) {
    my %plugin_config;
    my $conf_path = $self->app->home->child($self->app->moniker . '.conf');
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

# Resolve a dotted key in a config hash. Supports array notation (+prefix).
sub _resolve_config ($self, $config, $key_path) {
    return undef unless $config;
    $key_path =~ s/^\+//;
    my @parts = split /\./, $key_path;
    my $cur   = $config;

    for my $part (@parts) {
        if (ref $cur eq 'HASH') {
            return undef unless exists $cur->{$part};
            $cur = $cur->{$part};
        }
        elsif (ref $cur eq 'ARRAY') {
            my $found = 0;
            for (my $i = 0; $i < @$cur; $i += 2) {
                if ($cur->[$i] eq $part) {
                    $cur   = $cur->[$i + 1];
                    $found = 1;
                    last;
                }
            }
            return undef unless $found;
        }
        else { return undef }
    }
    return $cur unless ref $cur;
    return undef;
}

# Load a class safely. Returns true on success.
sub _try_load ($self, $class) {
    my $pm = $class =~ s{::}{/}gr . '.pm';
    return 1 if $INC{$pm};
    return 1 if eval "require $class; 1";

    # Try dev_plugins_dir
    if ($self->_try_load_dev($class)) {
        return 1 if eval "require $class; 1";
    }
    return 0;
}

# Load a class from dev_plugins_dir by adding its lib/ to @INC.
sub _try_load_dev ($self, $class) {
    my $dev_dir = $self->_dev_plugins_dir or return 0;
    (my $rel = "$class.pm") =~ s{::}{/}g;
    my @found = glob("$dev_dir/Mojolicious-Plugin-Fondation-*/lib/$rel");
    return 0 unless @found && -f $found[0];

    (my $lib_dir = $found[0]) =~ s{/lib/.*}{/lib};
    return 0 unless -d $lib_dir;
    unshift @INC, $lib_dir;
    return 1;
}

# Call fondation_meta() on a class. Returns hashref or undef.
sub _fondation_meta ($self, $class) {
    eval {
        my $err = Mojo::Loader::load_class($class);
        die $err if $err;
        $class->can('fondation_meta') ? $class->fondation_meta : undef;
    } // undef;
}

# Scan dev_plugins_dir for locally-developed Fondation plugins.
#
# Expects directories named Mojolicious-Plugin-Fondation-* under
# $app->manager->config->{dev_plugins_dir}. Each directory contains
# a standard Dist::Zilla layout (lib/, dist.ini).
#
# For each plugin found, this method:
#   1. Derives the module class from the directory name
#      Mojolicious-Plugin-Fondation-Foo-Bar → Mojolicious::Plugin::Fondation::Foo::Bar
#   2. Reads the .pm source file (without executing it — no require)
#   3. Extracts $VERSION (from source, fallback to dist.ini)
#   4. Extracts # ABSTRACT: comment
#
# Returns an arrayref of plugin hashes with the same shape as
# MetaCPAN::discover_p, all marked installed=1, is_dev=1.
sub _dev_plugins ($self) {
    my $dev_dir = $self->_dev_plugins_dir or return [];
    my @plugins;

    # Scan each Mojolicious-Plugin-Fondation-* directory
    for my $dir (glob("$dev_dir/Mojolicious-Plugin-Fondation-*")) {
        next unless -d $dir;

        # Extract distribution name from path (e.g. "Mojolicious-Plugin-Fondation-Asset")
        (my $dist = $dir) =~ s{.*/}{};

        # Derive Perl module class: Foo-Bar → Mojolicious::Plugin::Fondation::Foo::Bar
        (my $module_class = $dist) =~ s/^Mojolicious-Plugin-//;
        $module_class = "Mojolicious::Plugin::$module_class";
        $module_class =~ s/-/::/g;

        my ($abstract, $version) = ('', '');

        # Locate the .pm file (e.g. lib/Mojolicious/Plugin/Fondation/Foo/Bar.pm)
        (my $pm_rel = "$module_class.pm") =~ s{::}{/}g;
        my $pm_path = "$dir/lib/$pm_rel";

        my $deps = [];

        if (-f $pm_path) {
            # Read source WITHOUT requiring it — avoids triggering register()
            open my $fh, '<', $pm_path or next;
            my $src = do { local $/; <$fh> };
            close $fh;

            # Extract $VERSION from source:  $VERSION = '0.02';
            if ($src =~ /\$VERSION\s*=\s*['"]?([^'";]+)/) {
                $version = $1;
            }
            # Fallback: read version from dist.ini
            else {
                my $ini = "$dir/dist.ini";
                if (-f $ini) {
                    open my $fh2, '<', $ini;
                    while (my $line = <$fh2>) {
                        if ($line =~ /^version\s*=\s*(\S+)/) { $version = $1; last }
                    }
                    close $fh2;
                }
            }

            # Extract ABSTRACT comment:  # ABSTRACT: Foo bar
            if ($src =~ /^\s*#\s*ABSTRACT:\s*(.+)$/m) { $abstract = $1 }

            # Extract dependencies from fondation_meta in source
            # (brace-counted eval, safe — no require)
            $deps = [];
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
                my $meta = eval qq{no warnings 'redefine'; package _FondationDevMeta; $body; _FondationDevMeta::fondation_meta();};
                if ($meta && !$@ && ref $meta eq 'HASH' && $meta->{dependencies}) {
                    $deps = $meta->{dependencies};
                    # Normalize to full class names
                    $deps = [ map { /^Mojolicious::Plugin::/ ? $_ : "Mojolicious::Plugin::$_" } @$deps ];
                }
            }
        }

        # Build entry in the same shape as MetaCPAN::discover_p
        push @plugins, {
            distribution      => $dist,
            version           => $version,
            abstract          => $abstract,
            module_class      => $module_class,
            installed         => 1,
            installed_version => $version,
            is_dev            => 1,
            dependencies      => $deps,
        };
    }
    return \@plugins;
}

sub _dev_plugins_dir ($self) {
    my $manager = $self->app->manager;
    return $manager ? ($manager->config->{dev_plugins_dir} // undef) : undef;
}

# ── Display helpers (pre-compute data for templates) ──────────────────

# Build badge list for a plugin entry (used by plugins.html.ep and discover JSON).
sub _badges_for ($self, $p) {
    my @badges;

    if ($p->{is_dev}) {
        push @badges, { text => 'Dev',       class => 'info' };
        push @badges, { text => 'Installed', class => 'success ms-2' };
        push @badges, { text => "v$p->{installed_version}", class => 'light text-dark ms-1' } if $p->{installed_version};
        push @badges, { text => "CPAN v$p->{cpan_version}", class => 'light text-dark ms-1' } if $p->{cpan_version};
        push @badges, { text => 'Update',  class => 'warning text-dark ms-1' } if $p->{upgrade_available};
        push @badges, { text => 'Release', class => 'danger ms-1' }          if $p->{release_pending};
    } else {
        push @badges, { text => 'CPAN', class => 'secondary ms-2' };
        if ($p->{installed}) {
            push @badges, { text => 'Installed', class => 'success ms-2' };
            push @badges, { text => "v$p->{installed_version}", class => 'light text-dark ms-1' } if $p->{installed_version};
            push @badges, { text => "CPAN v$p->{cpan_version}", class => 'light text-dark ms-1' } if $p->{cpan_version};
            push @badges, { text => 'Update',  class => 'warning text-dark ms-1' } if $p->{upgrade_available};
            push @badges, { text => 'Release', class => 'danger ms-1' }          if $p->{release_pending};
        } else {
            push @badges, { text => 'Not installed', class => 'warning text-dark ms-2' };
            push @badges, { text => "v$p->{version}", class => 'light text-dark ms-1' } if $p->{version};
        }
    }

    my $deps = $p->{dependencies} // [];
    if (@$deps) {
        push @badges, { text => scalar(@$deps) . ' dep(s)', class => 'info ms-1', title => join(', ', @$deps) };
    }

    return \@badges;
}

# Build the cpanm command string for upgradable + not-installed plugins.
sub _install_command ($self, $upgradable, $missing, $cpan_ver) {
    my @parts;
    for my $u (@{$upgradable // []}) {
        push @parts, "$u->{module_class}\@$u->{cpan}";
    }
    for my $m (@{$missing // []}) {
        my $v = $cpan_ver->{$m};
        push @parts, $v ? "$m\@$v" : $m;
    }
    return @parts ? join(' ', @parts) : undef;
}

# Build sorted, filtered review entries from context.
sub _review_entries ($self, $context) {
    my @entries;
    for my $key (sort keys %$context) {
        next if $key =~ /^_/;
        my $val = $context->{$key};
        next unless defined $val && $val ne '';
        push @entries, { key => $key, value => $val };
    }
    return \@entries;
}

# ── .conf generation ─────────────────────────────────────────────────

sub _generate_conf ($self) {
    my $plugins = $self->session('setup_plugins') // [];
    my $context = $self->session('setup_context') // {};

    # Build key → plugin mapping from fondation_meta
    my %key_to_plugin;
    for my $class (@$plugins) {
        my $meta = $self->_fondation_meta($class) or next;
        my $params = $meta->{setup}{parameters} // [];
        for my $p (@$params) {
            $key_to_plugin{ $p->{key} } = $class if $p->{key};
        }
    }

    # Collect values per plugin
    my %plugin_config;
    for my $key (sort keys %$context) {
        next unless defined $context->{$key} && $context->{$key} ne '';
        next if $key =~ /^_/;  # skip internal keys
        my $plugin = $key_to_plugin{$key} or next;

        my $is_array = ($key =~ s/^\+//);
        my @parts    = split /\./, $key;
        my $target   = ($plugin_config{$plugin} //= {});

        if ($is_array) {
            $target->{$parts[0]} //= [];
            my $entry;
            for (my $j = 0; $j < @{$target->{$parts[0]}}; $j += 2) {
                if ($target->{$parts[0]}[$j] eq $parts[1]) {
                    $entry = $target->{$parts[0]}[$j + 1];
                    last;
                }
            }
            unless ($entry) {
                $entry = {};
                push @{$target->{$parts[0]}}, $parts[1], $entry;
            }
            $target = $entry;
            for my $i (2 .. $#parts - 1) {
                $target->{$parts[$i]} //= {};
                $target = $target->{$parts[$i]};
            }
            $target->{$parts[-1]} = $context->{"+$key"};
        } else {
            for my $i (0 .. $#parts - 1) {
                $target->{$parts[$i]} //= {};
                $target = $target->{$parts[$i]};
            }
            $target->{$parts[-1]} = $context->{$key};
        }
    }

    # Build conf structure
    my @deps;
    for my $class (@$plugins) {
        (my $short = $class) =~ s/^Mojolicious::Plugin:://;
        push @deps, $short;
    }

    my %conf = ( Fondation => { dependencies => \@deps } );
    for my $class (@$plugins) {
        next unless $plugin_config{$class};
        (my $short = $class) =~ s/^Mojolicious::Plugin:://;
        $conf{$short} = $plugin_config{$class};
    }

    require Data::Dumper;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Quotekeys = 0;

    my $content  = Data::Dumper::Dumper(\%conf);
    my $conf_path = $self->app->home->child($self->app->moniker . '.conf');
    $conf_path->spurt(encode('UTF-8', $content));

    $self->app->log->info("Configuration saved to $conf_path");
    return $conf_path->to_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::Controller::Setup - Session-based setup wizard — no Workflow, no file persister

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  # Routes registered by Fondation::Setup:
  GET  /setup          → wizard()   — main wizard page
  GET  /setup/plugins  → plugins()  — plugin selection with checkboxes
  GET  /setup/discover → discover() — JSON API: plugin list
  POST /setup/start    → start()    — build session state, redirect
  POST /setup/execute  → execute()  — process next/back/save
  GET  /setup/reset    → reset()    — clear session, restart

=head1 DESCRIPTION

This controller implements the Setup wizard using Mojolicious sessions
instead of Workflow.pm. State (selected plugins, current step, form
values) is stored entirely in C<$self-E<gt>session>.

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::Controller::Setup — Session-based setup wizard controller

=head1 SESSION KEYS

=over

=item C<setup_plugins>

Arrayref of selected plugin class names.

=item C<setup_states>

Arrayref of wizard states. Each state is a hashref with C<label>,
C<plugin>, C<description>, and C<fields> (arrayref of form field
definitions).

=item C<setup_index>

Integer index into C<setup_states>. A value equal to the array
size means "review", and beyond means "done".

=item C<setup_context>

Hashref of accumulated form values (C<$key =E<gt> $value>).

=item C<setup_not_installed>

Arrayref of plugin class names that are not yet installed via C<cpanm>.

=item C<setup_retry>

Arrayref of previously selected plugins, used by C<plugins()> to
pre-check them when the user clicks "I have installed the plugins, retry".

=back

=head1 INTERNAL METHODS

=head2 _discover($cb)

Shared async discovery: fetches plugins from MetaCPAN, merges with
C<dev_plugins_dir>, and calls C<$cb> with the merged arrayref.

=head2 _badges_for($plugin)

Returns an arrayref of C<{text, class, title?}> hashes for rendering
Bootstrap badges in the plugin selection template.

=head2 _install_command($upgradable, $missing, $cpan_ver)

Builds the C<cpanm> command string for the install/upgrade alert.
Returns C<undef> if nothing to install.

=head2 _review_entries($context)

Returns sorted, filtered C<{key, value}> pairs from the context
hash (excludes internal C<_>-prefixed keys and empty values).

=head2 _dev_plugins

Scans C<dev_plugins_dir> for locally-developed Fondation plugins.
Returns an arrayref with the same shape as C<MetaCPAN::discover_p>.

=head2 _dev_plugins_dir

Returns the C<dev_plugins_dir> path from C<$app-E<gt>manager-E<gt>config>.

=head2 _generate_conf

Generates the C<$moniker.conf> file from session state using
C<Data::Dumper>.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::Setup>,
L<Mojolicious::Plugin::Fondation::Setup::MetaCPAN>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

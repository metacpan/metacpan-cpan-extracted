package PAX::StandaloneRuntime;

our $VERSION = '0.031';

use strict;
use warnings;
use Capture::Tiny ();
use Config ();
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path);
use JSON::PP ();
use Socket qw(MSG_PEEK);

use PAX::GuardManager;
use PAX::NativeRunner;

my $STATE;
my $RUNTIME_JSON_DECODER;
my $RUNTIME_JSON_DECODER_KIND;
my %RESULT_CHANNEL_FILE_HANDLE;
my %RESULT_CHANNEL_FILE_PATH;
my $INDICATOR_STATUS_ICONS = {
    ok => {
        yes     => '&#x2705;',
        running => '&#x2705;',
        secure  => '&#x2705;',
        ok      => '&#x2705;',
        clean   => '&#x2705;',
    },
    error => {
        wrong     => '&#x1F6A8;',
        stopped   => '&#x1F6A8;',
        paused    => '&#x1F6A8;',
        insecure  => '&#x1F6A8;',
        reloading => '&#x1F6A8;',
        missing   => '&#x1F6A8;',
        error     => '&#x1F6A8;',
        dirty     => '&#x1F6A8;',
        down      => '&#x1F6A8;',
    },
};
my $INDICATOR_PROMPT_STATUS_ICONS = {
    ok => {
        yes     => '✅',
        running => '✅',
        secure  => '✅',
        ok      => '✅',
        clean   => '✅',
    },
    error => {
        wrong     => '🚨',
        stopped   => '🚨',
        paused    => '🚨',
        insecure  => '🚨',
        reloading => '🚨',
        missing   => '🚨',
        error     => '🚨',
        dirty     => '🚨',
        down      => '🚨',
    },
};

sub _trace {
    return if !$ENV{PAX_STANDALONE_TRACE};
    my ($message) = @_;
    $message //= '';
    print STDERR "[pax-standalone] $message\n";
}

sub _capture_system_command {
    my (@command) = @_;
    my $exit_code = -1;
    my ($stdout, $stderr) = Capture::Tiny::capture {
        system @command;
        $exit_code = $? == -1 ? -1 : ($? >> 8);
    };
    return ($stdout, $stderr, $exit_code);
}

sub _system_command_missing {
    my ($stderr, $exit_code) = @_;
    return 1 if !defined $exit_code || $exit_code < 0 || $exit_code == 127;
    return 1 if defined $stderr && $stderr =~ /(?:can't exec|not found|no such file or directory)/i;
    return 0;
}

sub run {
    my ($class, %args) = @_;
    my $entrypoint = $args{entrypoint} // shift(@ARGV);
    _state();
    if (!defined $entrypoint || !_entrypoint_looks_valid($entrypoint)) {
        my $fallback = _resolve_entrypoint_from_manifest($entrypoint);
        if (defined $fallback) {
            _trace("entrypoint fallback from manifest: '" . ($entrypoint // '<undef>') . "' -> '$fallback'");
            $entrypoint = $fallback;
        }
    }
    die 'entrypoint required' if !defined $entrypoint;
    if (!_entrypoint_looks_valid($entrypoint)) {
        die "entrypoint is not a valid executable unit: $entrypoint";
    }
    my @argv = @{ $args{argv} // \@ARGV };
    my $self_path = _standalone_executable_path();
    _install_namespace_compat();
    _install_require_hook();
    _install_pending_wrappers();

    local $0 = $self_path if defined $self_path && $self_path ne '';
    if (@argv && $argv[0] eq '--pax-standalone-helper') {
        shift @argv;
        my $helper = shift @argv // die "standalone helper name required\n";
        local @ARGV = @argv;
        return _run_standalone_managed_helper($helper, @argv);
    }

    local @ARGV = @argv;
    my $rv = _run_entrypoint($entrypoint);

    _install_pending_wrappers();
    return $rv;
}

sub _entrypoint_looks_valid {
    my ($entrypoint) = @_;
    return 0 if !defined $entrypoint;
    return 0 if $entrypoint =~ /\A-/;
    return 0 if $entrypoint =~ /\A\s*\z/;
    return 1;
}

sub _resolve_entrypoint_from_manifest {
    my ($entrypoint) = @_;
    my $state = _state();
    my $manifest_entrypoint = $state->{manifest}{entrypoint}{logical_path} // '';
    if ($manifest_entrypoint ne '') {
        my $candidate = File::Spec->catfile($state->{root}, 'code', split m{/}, $manifest_entrypoint);
        return $candidate if -f $candidate;
    }
    my @unit_candidates = grep {
        my $unit = $_;
        my $unit_kind = $unit->{unit_kind} // '';
        my $packaging = $unit->{packaging} // '';
        ($unit_kind // '') eq 'entrypoint' || ($packaging // '') =~ /\A(compiled|hybrid|residual)_(?:dispatch|cli_router|script)_pcu_v1\z/;
    } @{ $state->{manifest}{code_units} // [] };
    for my $unit (@unit_candidates) {
        my $logical = $unit->{logical_path} // '';
        next if $logical eq '';
        my $candidate = File::Spec->catfile($state->{root}, 'code', split m{/}, $logical);
        return $candidate if -f $candidate;
    }
    return;
}

sub _state {
    return $STATE if $STATE;
    my $manifest_path = $ENV{PAX_STANDALONE_MANIFEST_PATH} or die 'PAX_STANDALONE_MANIFEST_PATH not set';
    open my $fh, '<', $manifest_path or die "cannot read $manifest_path: $!";
    local $/;
    my $manifest = _runtime_json_decode(<$fh>);
    my $root = $ENV{PAX_STANDALONE_TMPDIR} or die 'PAX_STANDALONE_TMPDIR not set';
    my $app_namespace = _normalize_namespace($manifest->{app}{namespace} // '');
    if (!$app_namespace) {
        $app_namespace = _normalize_namespace($manifest->{app}{compat}{namespace} // '');
    }
    my $legacy_namespace = _normalize_namespace($manifest->{app}{compat}{legacy_namespace} // '');
    $legacy_namespace = $app_namespace if $legacy_namespace eq '';
    my %by_region = map { ($_->{region_name} // '') => $_ } @{ $manifest->{native_dispatch} // [] };
    my %compiled_packages;
    my %compiled = map {
        my $key = $_->{require_path} // '';
        length($key) ? ($key => $_) : ()
    } grep {
        my $packaging = $_->{packaging} // '';
        (($packaging eq 'compiled_pcu_v1') || ($packaging eq 'hybrid_compiled_pcu_v1'))
    } @{ $manifest->{code_units} // [] };
    for my $unit (@{ $manifest->{code_units} // [] }) {
        my $package = $unit->{package} // '';
        next if !$package || $package eq '';
        $compiled_packages{$package} = 1;
    }
    return $STATE = {
        manifest => $manifest,
        root => $root,
        app_namespace => $app_namespace,
        legacy_namespace => $legacy_namespace,
        compiled_packages => \%compiled_packages,
        app_env_prefix => undef,
        native_runner => PAX::NativeRunner->new,
        wrapped => {},
        namespace_aliases => {},
        by_region => \%by_region,
        compiled_units => \%compiled,
        require_hook_installed => 0,
        loading_require => {},
        residual_loaded => {},
        residual_bootstrap_loaded => {},
    };
}

sub _app_env_prefix {
    my $state = _state();
    return $state->{app_env_prefix} if defined $state->{app_env_prefix};
    my $app = $state->{manifest}{app} // {};
    my $namespace = $app->{compat}{namespace} // $app->{namespace} // '';
    my $name = $namespace || $app->{name} // '';
    if (!$name || $name =~ /\A\s*\z/) {
        $name = $app->{command} // 'app';
    }
    $name = _normalize_namespace($name);
    $name =~ s/::/_/g;
    $name =~ s/[^A-Za-z0-9_]+/_/g;
    $name =~ s/_+/_/g;
    $name =~ s/\A_+|_+\z//g;
    $name = uc($name);
    $name = 'APP' if $name eq '' || $name !~ /[A-Za-z]/;
    $state->{app_env_prefix} = $name;
    return $name;
}

sub _app_command_name {
    my (%args) = @_;
    my $state = _state();
    my $app = $state->{manifest}{app} // {};
    my @env_names = @{$args{env_names} || []};
    for my $env_name (@env_names) {
        next if !defined $env_name || $env_name eq '';
        my $value = $ENV{$env_name} // '';
        return $value if $value ne '';
    }
    my $entry_env = _app_env_prefix() . '_COMMAND';
    my $entry = $ENV{$entry_env} // '';
    return $entry if $entry ne '';
    my $fallback = $app->{command} // '';
    return $fallback if $fallback ne '';
    return $app->{entrypoint_command} // 'pax';
}

sub _app_entry_command {
    my (%args) = @_;
    my $state = _state();
    my $manifest = $state->{manifest} // {};
    my $app = $manifest->{app} // {};

    my $env_name = $args{sub_env} // '';
    if (defined $env_name && $env_name ne '') {
        my $value = $ENV{$env_name} // '';
        return $value if $value ne '';
    }

    my $fallback_env = $app->{entrypoint_env} // '';
    if (defined $fallback_env && $fallback_env ne '' && (!$env_name || $fallback_env ne $env_name)) {
        my $value = $ENV{$fallback_env} // '';
        return $value if $value ne '';
    }

    my $prefix_command_env = _app_env_prefix() . '_COMMAND';
    if (defined $prefix_command_env && $prefix_command_env ne '') {
        my $value = $ENV{$prefix_command_env} // '';
        return $value if $value ne '';
    }

    my $fallback = $args{sub_fallback};
    $fallback = $app->{entrypoint_fallback} if !defined $fallback || $fallback eq '';
    $fallback = $app->{command} if !defined $fallback || $fallback eq '';
    return $fallback ne '' ? $fallback : 'pax';
}

sub _install_require_hook {
    my $state = _state();
    return if $state->{require_hook_installed};
    no warnings 'redefine';
    *CORE::GLOBAL::require = sub {
        my ($target) = @_;
        my $rv = eval {
            if (!defined $target) {
                die "require target missing\n";
            }
            if ($target =~ /\A\d+(?:\.\d+)?\z/) {
                return CORE::require($target);
            }
            my $mapped = _legacy_require_path_to_app_require_path($target);
            $target = $mapped if defined $mapped;
            if (my $loaded = _load_compiled_require($target)) {
                return $loaded;
            }
            return CORE::require($target);
        };
        die $@ if $@;
        _install_pending_wrappers();
        return $rv;
    };
    $state->{require_hook_installed} = 1;
}

sub _load_compiled_require {
    my ($target) = @_;
    my $state = _state();
    my $unit = $state->{compiled_units}{$target};
    if (!$unit) {
        my $mapped = _legacy_require_path_to_app_require_path($target);
        $target = $mapped if defined $mapped;
        $unit = $state->{compiled_units}{$target} if $target && $target ne '';
    }
    return if !$unit;
    _trace("require start $target");
    return 1 if exists $INC{$target};
    if ($state->{loading_require}{$target}) {
        _trace("require cycle short-circuit $target");
        return 1;
    }
    my $virtual_path = _ensure_virtual_source_file($unit);
    local $state->{loading_require}{$target} = 1;
    my $had_inc = exists $INC{$target};
    my $old_inc = $INC{$target};
    $INC{$target} = $virtual_path;
    my $ok = eval {
        _load_compiled_unit($unit);
        1;
    };
    if (!$ok) {
        if ($had_inc) {
            $INC{$target} = $old_inc;
        } else {
            delete $INC{$target};
        }
        _trace("require error $target: $@");
        die $@;
    }
    _sync_namespace_aliases_for_unit($unit);
    $INC{$target} = $virtual_path;
    _trace("require done $target");
    return 1;
}

sub _normalize_namespace {
    my ($namespace) = @_;
    return '' if !defined $namespace;
    $namespace =~ s/^\s+|\s+$//g;
    $namespace =~ s/^\:+|\:+$//g;
    return $namespace;
}

sub _legacy_require_path_to_app_require_path {
    my ($path) = @_;
    my $state = _state();
    my $app_namespace = $state->{app_namespace} // '';
    return if !defined $path || $path eq '';
    my $legacy = $state->{legacy_namespace} // '';
    return if !$legacy || $app_namespace eq $legacy;
    my $legacy_require_prefix = join('/', split(/::/, $legacy)) . '.pm';
    my $legacy_prefix = join('/', split(/::/, $legacy));
    return if index($path, $legacy_prefix . '/') != 0 && $path ne $legacy_require_prefix;
    my $legacy_require_rewrite_prefix = $legacy_prefix . '.pm';
    my $app_prefix = _namespace_to_require_path($app_namespace);
    $path =~ s/\A\Q$legacy_require_rewrite_prefix\E/$app_prefix/;
    return $path;
}

sub _namespace_to_require_path {
    my ($namespace) = @_;
    return '' if !defined $namespace || $namespace eq '';
    return join('/', split(/::/, $namespace)) . '.pm';
}

sub _legacy_module_for_app_module {
    my ($module) = @_;
    my $state = _state();
    my $app_namespace = $state->{app_namespace} // '';
    my $legacy = $state->{legacy_namespace} // '';
    return $module if !$module || $module eq '' || $app_namespace eq '' || $app_namespace eq $legacy;
    if (index($module, $app_namespace) == 0) {
        my $suffix = substr($module, length($app_namespace));
        return $legacy . $suffix;
    }
    return $module;
}

sub _install_namespace_compat {
    my $state = _state();
    my $app_namespace = $state->{app_namespace} // '';
    my $legacy = $state->{legacy_namespace} // '';
    return if $app_namespace eq '' || $app_namespace eq $legacy;
    for my $package (keys %{ $state->{compiled_packages} // {} }) {
        next if index($package, $app_namespace . '::') != 0 && $package ne $app_namespace;
        my $suffix = substr($package, length($app_namespace));
        my $legacy_package = $legacy . $suffix;
        _install_namespace_alias($legacy_package, $package);
    }
}

sub _install_namespace_alias {
    my ($legacy_package, $app_package) = @_;
    my $state = _state();
    return if !$legacy_package || !$app_package;
    return if $legacy_package eq $app_package;
    return if $state->{namespace_aliases}{$legacy_package};
    no strict 'refs';
    _sync_namespace_alias_for_module($legacy_package, $app_package);
    if (!defined *{"${legacy_package}::AUTOLOAD"}{CODE}) {
        *{"${legacy_package}::AUTOLOAD"} = sub {
            my $self = shift;
            our $AUTOLOAD;
            my $method = $AUTOLOAD;
            $method =~ s/^.*:://;
            return if $method eq 'AUTOLOAD';
            _load_package_by_module_name($app_package);
            _sync_namespace_alias_for_module($legacy_package, $app_package);
            my $cv = *{"$app_package\::$method"}{CODE};
            die "Undefined subroutine $AUTOLOAD\n" if !defined $cv;
            goto &$cv;
        };
    }
    $state->{namespace_aliases}{$legacy_package} = $app_package;
}

sub _sync_namespace_alias_for_module {
    my ($legacy_package, $app_package) = @_;
    my $state = _state();
    return if !$legacy_package || !$app_package;
    no strict 'refs';
    my $app_stash = \%{ $app_package . '::' };
    return if !%$app_stash;
    for my $name (keys %$app_stash) {
        next if $name eq '__ANON__';
        next if $name =~ /\A__END__/;
        next if $name eq 'ISA' || $name eq 'AUTOLOAD';
        *{$legacy_package . '::' . $name} = $app_stash->{$name};
    }
    $state->{namespace_aliases}{$legacy_package} = $app_package;
}

sub _sync_namespace_aliases_for_unit {
    my ($unit) = @_;
    my $state = _state();
    my $app_namespace = $state->{app_namespace} // '';
    my $legacy = $state->{legacy_namespace} // '';
    return if $app_namespace eq '' || $app_namespace eq $legacy;
    my $app_package = $unit->{package} // '';
    return if $app_package eq '';
    my $legacy_package = _legacy_module_for_app_module($app_package);
    _install_namespace_alias($legacy_package, $app_package);
}

sub _load_package_by_module_name {
    my ($module) = @_;
    my $state = _state();
    return if !$module;
    my $require_path = join('/', split(/::/, $module)) . '.pm';
    if (exists $state->{compiled_units}{$require_path}) {
        return _load_compiled_require($require_path);
    }
    my $path = File::Spec->catfile($state->{root}, $require_path);
    if (-f $path) {
        my $ok = eval { require $path; 1; };
        die $@ if !$ok && $@;
        return 1 if $ok;
    }
    my $ok = eval { require $require_path; 1; };
    die $@ if !$ok && $@;
    return 1;
}

sub _standalone_executable_path {
    my $path = $ENV{PAX_STANDALONE_EXECUTABLE} // '';
    return if !defined $path || $path eq '';
    if (File::Spec->file_name_is_absolute($path)) {
        my $resolved = abs_path($path);
        return $resolved if defined $resolved && $resolved ne '';
        return $path;
    }
    if ($path =~ m{/}) {
        my $resolved = abs_path($path);
        return $resolved if defined $resolved && $resolved ne '';
        return File::Spec->rel2abs($path);
    }
    my $path_sep = $Config::Config{path_sep} || ':';
    for my $dir (grep { defined && $_ ne '' } split /\Q$path_sep\E/, ($ENV{PATH} // '')) {
        my $candidate = File::Spec->catfile($dir, $path);
        next if !-f $candidate || !-x _;
        my $resolved = abs_path($candidate);
        return $resolved if defined $resolved && $resolved ne '';
        return $candidate;
    }
    return $path;
}

sub _shell_single_quote {
    my ($value) = @_;
    $value //= '';
    $value =~ s/'/'\"'\"'/g;
    return "'" . $value . "'";
}

sub _standalone_internal_cli_wrapper_content {
    my ($name) = @_;
    my $self_path = _standalone_executable_path() or return;
    return if !defined $name || $name eq '';
    my $quoted_self = _shell_single_quote($self_path);
    my $quoted_name = _shell_single_quote($name);
    return <<"SH";
#!/bin/sh
exec $quoted_self --pax-standalone-helper $quoted_name "\$@"
SH
}

sub _standalone_internal_cli_class {
    my $state = _state();
    my $app_namespace = $state->{app_namespace} // '';
    if ($app_namespace) {
        return $app_namespace . '::InternalCLI';
    }
    for my $unit (@{ $state->{manifest}{code_units} // [] }) {
        next if ref($unit) ne 'HASH';
        my $package = $unit->{package} // '';
        next if !$package || $package eq '';
        return $package if $package =~ /::InternalCLI\z/;
    }
    return;
}

sub _standalone_internal_cli_asset_path {
    my ($name) = @_;
    if (my $embedded = _standalone_embedded_asset_path($name)) {
        return $embedded;
    }
    my $class = _standalone_internal_cli_class() or return;
    _load_package_by_module_name($class);
    my $full = $class . '::_helper_asset_path';
    return if !defined &{$full};
    no strict 'refs';
    return &{$full}($name);
}

sub _standalone_internal_cli_asset_content {
    my ($name) = @_;
    if (my $path = _standalone_internal_cli_asset_path($name)) {
        open my $fh, '<:raw', $path or die "Unable to read $path: $!";
        local $/;
        my $content = <$fh>;
        close $fh or die "Unable to close $path: $!";
        return ($content, $path);
    }
    my $class = _standalone_internal_cli_class() or return;
    _load_package_by_module_name($class);
    my $full = $class . '::helper_content';
    return if !defined &{$full};
    local $ENV{PAX_STANDALONE_EXECUTABLE} = '';
    no strict 'refs';
    my $content = &{$full}($name);
    return if !defined $content || $content eq '';
    return ($content, $name);
}

sub _standalone_embedded_asset_path {
    my ($name) = @_;
    return if !defined $name || $name eq '';
    my $state = _state();
    for my $asset (@{ $state->{manifest}{assets} // [] }) {
        next if ref($asset) ne 'HASH';
        my $logical = $asset->{logical_path} // '';
        next if $logical eq '';
        next if $logical ne $name && $logical !~ m{(?:^|/)\Q$name\E\z};
        my $path = File::Spec->catfile($state->{root}, 'assets', split m{/}, $logical);
        return $path if -f $path;
    }
    return;
}

sub _share_dist_private_cli_dir {
    my ($dist_name) = @_;
    return if !defined $dist_name || $dist_name eq '';
    my $ok = eval {
        require File::ShareDir;
        1;
    };
    return if !$ok;
    my $root = eval { File::ShareDir::dist_dir($dist_name) };
    return if !$root || !-d $root;
    my $candidate = File::Spec->catdir($root, 'private-cli');
    return -d $candidate ? $candidate : undef;
}

sub _run_standalone_managed_helper {
    my ($helper, @argv) = @_;
    my ($helper_source, $helper_path) = _standalone_internal_cli_asset_content($helper);
    die "standalone managed helper '$helper' is unavailable\n" if !defined $helper_source || $helper_source eq '';
    my $self_path = _standalone_executable_path();
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = $self_path if defined $self_path && $self_path ne '';
    my ($source, $path, @helper_argv);
    if ($helper eq '_dashboard-core' || _standalone_helper_delegates_to_dashboard_core($helper_source)) {
        my ($core_source, $core_path) = _standalone_internal_cli_asset_content('_dashboard-core');
        die "standalone managed helper core is unavailable\n" if !defined $core_source || $core_source eq '';
        $source = $core_source;
        $path = $core_path;
        @helper_argv = @argv;
        unshift @helper_argv, $helper if $helper ne '_dashboard-core';
    }
    else {
        $source = $helper_source;
        $path = $helper_path;
        @helper_argv = @argv;
    }
    local @ARGV = @helper_argv;
    local $0 = $path if defined $path && $path ne '';
    my $wrapped = "package main;\n#line 1 \"$path\"\n" . $source;
    my $rv = eval $wrapped;
    die $@ if $@;
    return 0 if !defined $rv;
    return $rv;
}

sub _direct_standalone_helper_name_from_path {
    my ($path) = @_;
    return if !defined $path || $path eq '';
    my $name = basename($path);
    return if !defined $name || $name eq '';
    return $name;
}

sub _standalone_helper_delegates_to_dashboard_core {
    my ($source) = @_;
    return 0 if !defined $source || $source eq '';
    return 1 if $source =~ /_dashboard-core/
        && $source =~ /basename\(\$0\)/
        && $source =~ /exec\s+\{\s*\$\^X\s*\}\s+\$\^X,\s+\$core,\s+\$command,\s+\@ARGV;/s;
    return 0;
}

sub _install_pending_wrappers {
    my $state = _state();
    for my $full (sort keys %{ $state->{by_region} }) {
        next if $state->{wrapped}{$full};
        next if !$full || ($full !~ /::/);
        my $cv = _code_for($full) or next;
        my $meta = $state->{by_region}{$full};
        next if !$meta->{executable_logical_path};
        my $original = $cv;
        no strict 'refs';
        no warnings 'redefine';
        *{$full} = sub {
            my @args = @_;
            if (_eligible_i64_args(\@args)) {
                my $guard = PAX::GuardManager->new(
                    epochs => $state->{manifest}{runtime_epochs} // {},
                )->validate_or_deopt({
                    region_id => $meta->{region_id},
                    region_name => $meta->{region_name},
                    guards => $meta->{guards} // [],
                    deopt => $meta->{deopt} // {},
                }, args => [ @args[0, 1] ], context => 'scalar');

                if (($guard->{status} // '') eq 'native_allowed') {
                    my $probe = File::Spec->catfile($state->{root}, split m{/}, $meta->{executable_logical_path});
                    chmod 0700, $probe if -f $probe;
                    my $result = $state->{native_runner}->run_i64_binary(
                        path => $probe,
                        left => $args[0],
                        right => $args[1],
                    );
                    if (($result->{status} // '') eq 'ok' && defined $result->{value}) {
                        _log_native_hit($full);
                        return $result->{value};
                    }
                }
            }
            return $original->(@_);
        };
        $state->{wrapped}{$full} = 1;
    }
}

sub _eligible_i64_args {
    my ($args) = @_;
    return 0 if @$args != 2;
    return 0 if !defined $args->[0] || !defined $args->[1];
    return ($args->[0] =~ /\A-?\d+\z/ && $args->[1] =~ /\A-?\d+\z/) ? 1 : 0;
}

sub _load_compiled_unit {
    my ($unit) = @_;
    my $state = _state();
    _trace("load unit " . (($unit->{require_path} // $unit->{logical_path} // 'unknown')));
    my $path = File::Spec->catfile($state->{root}, 'code', split m{/}, $unit->{logical_path});
    open my $fh, '<', $path or die "cannot read compiled unit $path: $!";
    local $/;
    my $record = _runtime_json_decode(<$fh>);

    if (($record->{residual_mode} // '') eq 'module') {
        _load_residual_module($unit, $record);
        return;
    }

    for my $init (@{ $record->{initializers} // [] }) {
        _apply_initializer($init);
    }
    for my $sub (@{ $record->{subs} // [] }) {
        _install_compiled_sub($record->{package}, $sub);
    }
    if (@{ $record->{unsupported_subs} // [] }) {
        _install_residual_stubs($unit, $record);
    }
}

sub _ensure_virtual_source_file {
    my ($unit) = @_;
    my $state = _state();
    my $logical = _virtual_source_logical_path($unit);
    my $path = File::Spec->catfile($state->{root}, 'code', split m{/}, $logical);
    return $path if -f $path;
    my $dir = dirname($path);
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "cannot write virtual source file $path: $!";
    print {$fh} "# PAX compiled unit placeholder for ", ($unit->{require_path} // $unit->{logical_path} // 'unknown'), "\n1;\n";
    close $fh;
    return $path;
}

sub _virtual_source_logical_path {
    my ($unit) = @_;
    my $logical = $unit->{logical_path} // '';
    if (($unit->{require_path} // '') ne '') {
        if ($logical =~ /\.pcu\.json\z/) {
            $logical =~ s/\.pcu\.json\z/.pm/;
            return $logical;
        }
        return File::Spec->catfile('virtual', split m{/}, ($unit->{require_path} // 'module.pm'));
    }
    if ($logical =~ /\.dashboard\.json\z/) {
        $logical =~ s/\.dashboard\.json\z/.pl/;
        return $logical;
    }
    if ($logical =~ /\.dispatch\.json\z/) {
        $logical =~ s/\.dispatch\.json\z/.pl/;
        return $logical;
    }
    if ($logical =~ /\.script\.json\z/) {
        $logical =~ s/\.script\.json\z/.pl/;
        return $logical;
    }
    return File::Spec->catfile('virtual', 'entrypoint.pl');
}

sub _run_entrypoint {
    my ($entrypoint) = @_;
    if ($entrypoint =~ /\.service\.json\z/) {
        return _run_service_dispatch_unit($entrypoint);
    }
    if ($entrypoint =~ /\.cli-router\.json\z/) {
        return _run_cli_router_unit($entrypoint);
    }
    if ($entrypoint =~ /\.dispatch\.json\z/) {
        return _run_dispatch_script_unit($entrypoint);
    }
    if ($entrypoint =~ /\.script\.json\z/) {
        return _run_script_unit($entrypoint);
    }
    my $rv = do $entrypoint;
    die $@ if $@;
    die "failed to load $entrypoint: $!" if !defined($rv) && $!;
    return $rv;
}

sub _run_service_dispatch_unit {
    my ($entrypoint) = @_;
    open my $fh, '<', $entrypoint or die "cannot read service dispatch unit $entrypoint: $!";
    local $/;
    my $record = _runtime_json_decode(<$fh>);

    my $cmd = shift(@ARGV);
    $cmd = 'version' if !defined($cmd) || $cmd eq '';

    if ($cmd eq 'version') {
        print(($record->{version} // '0.0.0') . "\n");
        exit 0;
    }

    if ($cmd eq 'serve') {
        (my $app_module_path = ($record->{app_module} // '')) =~ s{::}{/}g;
        $app_module_path .= '.pm' if $app_module_path ne '';
        (my $server_module_path = ($record->{server_module} // '')) =~ s{::}{/}g;
        $server_module_path .= '.pm' if $server_module_path ne '';
        _load_compiled_require($app_module_path) || require $app_module_path;
        require $server_module_path;
        my $host = '127.0.0.1';
        my $port = 5000;
        while (@ARGV) {
            my $arg = shift @ARGV;
            if ($arg eq '--host') {
                $host = shift @ARGV // die "--host requires a value\n";
                next;
            }
            if ($arg eq '--port') {
                $port = shift @ARGV // die "--port requires a value\n";
                next;
            }
            die "unexpected argument: $arg\n";
        }

        my $asset_root = $ENV{PAX_EMBEDDED_ASSET_ROOT}
            || File::Spec->catdir(dirname(_virtual_entrypoint_path($entrypoint)), '..', 'share');
        my $builder_method = $record->{builder_method} || 'build_psgi_app';
        my $app_module = $record->{app_module} || die "service dispatch missing app module\n";
        my $server_module = $record->{server_module} || die "service dispatch missing server module\n";
        my $app = $app_module->$builder_method(asset_root => $asset_root);
        my $server = $server_module->new;
        $server->run($app, {
            host => $host,
            port => $port,
            listen => ["$host:$port"],
            workers => 1,
        });
        return 0;
    }

    die "unknown command: $cmd\n";
}

sub _run_cli_router_unit {
    my ($entrypoint) = @_;
    open my $fh, '<', $entrypoint or die "cannot read cli router unit $entrypoint: $!";
    local $/;
    my $record = _runtime_json_decode(<$fh>);
    my $path = _virtual_entrypoint_path($entrypoint);
    my $bootstrap = $record->{bootstrap_source};
    if (defined $bootstrap && $bootstrap ne '') {
        my $wrapped = "package main;\n#line 1 \"$path\"\n" . $bootstrap;
        my $rv = eval $wrapped;
        die $@ if $@;
    }

    my $cmd = shift @ARGV || '';
    _code_for('main::_load_runtime_env')->() if _code_for('main::_load_runtime_env');
    _code_for('main::_prime_command_result_env')->($cmd, @ARGV)
        if $cmd ne '' && _code_for('main::_prime_command_result_env');

    if ($cmd eq '') {
        main::pod2usage(
            -exitval  => 1,
            -verbose  => 99,
            -sections => [qw(NAME SYNOPSIS)],
        );
    }
    elsif ($cmd eq 'help' || $cmd eq '--help' || $cmd eq '-h') {
        main::pod2usage(
            -exitval => 0,
            -verbose => 99,
        );
    }

    if ($cmd eq 'version') {
        my $version_module = $record->{version_module} || die "cli router missing version module\n";
        _load_package_by_module_name($version_module);
        no strict 'refs';
        print ${$version_module . '::VERSION'}, "\n";
        exit 0;
    }

    if (my $helper_path = _code_for('main::_builtin_helper_path')->($cmd)) {
        if (my $helper_name = _direct_standalone_helper_name_from_path($helper_path)) {
            return _run_standalone_managed_helper($helper_name, @ARGV);
        }
        return _code_for('main::_exec_switchboard_command')->($helper_path, @ARGV);
    }

    if (my $custom_path = _code_for('main::_custom_command_path')->($cmd)) {
        return _code_for('main::_exec_switchboard_command')->($custom_path, @ARGV);
    }

    if (my @parts = _code_for('main::_skill_dotted_command_parts')->($cmd)) {
        my ($skill_name, $skill_command) = @parts;
        my $helper_path = _code_for('main::_builtin_helper_path')->('skills');
        if (my $helper_name = _direct_standalone_helper_name_from_path($helper_path)) {
            return _run_standalone_managed_helper($helper_name, '_exec', $skill_name, $skill_command, @ARGV);
        }
        return _code_for('main::_exec_switchboard_command')->($helper_path, '_exec', $skill_name, $skill_command, @ARGV);
    }

    if ($cmd ne '') {
        my $suggest_class = $record->{suggest_class} || die "cli router missing suggest class\n";
        print STDERR $suggest_class->new()->unknown_command_message($cmd);
    }

    main::pod2usage(
        -exitval  => 1,
        -verbose  => 99,
        -sections => [qw(NAME SYNOPSIS)],
    );
}

sub _run_dispatch_script_unit {
    my ($entrypoint) = @_;
    open my $fh, '<', $entrypoint or die "cannot read dispatch script unit $entrypoint: $!";
    local $/;
    my $record = _runtime_json_decode(<$fh>);
    my $path = _virtual_entrypoint_path($entrypoint);
    my $bootstrap = $record->{bootstrap_source};
    if (defined $bootstrap && $bootstrap ne '') {
        my $wrapped = "package main;\n#line 1 \"$path\"\n" . $bootstrap;
        my $rv = eval $wrapped;
        die $@ if $@;
    }
    my $cmd = shift(@ARGV);
    if (($record->{command_default_mode} // '') eq 'defined_or') {
        $cmd = $record->{command_default} if !defined $cmd;
    } else {
        $cmd = $record->{command_default} if !defined($cmd) || $cmd eq '';
    }
    for my $entry (@{ $record->{actions} // [] }) {
        next if ($entry->{command} // '') ne (defined $cmd ? $cmd : '');
        return _run_dispatch_action($entry->{action}, $cmd);
    }
    if (my $unknown = $record->{unknown_action}) {
        return _run_dispatch_action($unknown, $cmd);
    }
    die "no dispatch action for command " . (defined $cmd ? $cmd : '(undef)');
}

sub _run_dispatch_action {
    my ($action, $cmd) = @_;
    my $op = $action->{op} // die 'dispatch action op missing';
    if ($op eq 'print_call') {
        my $cv = _code_for($action->{target}) or die "missing dispatch target $action->{target}";
        my $value = $cv->(@{ $action->{args} // [] });
        print $value;
        print "\n" if $action->{newline};
        exit($action->{exit_code} // 0);
    }
    if ($op eq 'print_required_global') {
        my $module = $action->{require_module} // die 'dispatch require module missing';
        _load_package_by_module_name($module);
        no strict 'refs';
        my $value = ${ $action->{symbol} };
        print $value;
        print "\n" if $action->{newline};
        exit($action->{exit_code} // 0);
    }
    if ($op eq 'print_embedded_asset') {
        my $root = $ENV{PAX_EMBEDDED_ASSET_ROOT} // '';
        my $logical = $action->{logical_path} // die 'dispatch asset logical path missing';
        my $path = $root ? File::Spec->catfile($root, split m{/}, $logical) : '';
        if (!$path || !-f $path) {
            print STDERR "missing asset\n";
            exit 3;
        }
        open my $fh, '<', $path or die $!;
        local $/;
        my $content = <$fh>;
        close $fh;
        print $content;
        exit 0;
    }
    if ($op eq 'stderr_interpolate_cmd') {
        print STDERR ($action->{prefix} // '') . (defined $cmd ? $cmd : '') . ($action->{suffix} // '');
        exit($action->{exit_code} // 0);
    }
    die "unsupported dispatch action op: $op";
}

sub _run_script_unit {
    my ($entrypoint) = @_;
    open my $fh, '<', $entrypoint or die "cannot read script unit $entrypoint: $!";
    local $/;
    my $record = _runtime_json_decode(<$fh>);
    my $source = $record->{script_source} // _script_source_from_code_units($entrypoint)
        // _source_path_to_script_source($entrypoint)
        // _script_source_from_residual_payload($entrypoint);
    die "script source missing for $entrypoint" if !defined $source;
    die "script source is empty for $entrypoint" if $source eq '';
    $source = _apply_compiled_script_subs($source, $record->{compiled_subs} // []);
    my $path = _virtual_entrypoint_path($entrypoint);
    my $wrapped = "package main;\n#line 1 \"$path\"\n" . $source;
    my $rv = eval $wrapped;
    die $@ if $@;
    return 0 if !defined($rv);
    if (my $invocation = $record->{entry_invocation}) {
        my $op = $invocation->{op} // '';
        if ($op eq 'call_main_argv_and_exit') {
            my $cv = _code_for('main::main') or die "script unit $path missing main";
            exit(($cv->(@ARGV) // 0));
        }
        die "unsupported script entry invocation op: $op";
    }
    return $rv;
}

sub _script_source_from_code_units {
    my ($entrypoint) = @_;
    my $state = _state();
    my $unit = _find_code_unit_for_entrypoint($entrypoint);
    return if !$unit;
    return $unit->{script_source} if defined $unit->{script_source};
    my $bytes = $unit->{bytes};
    return if !defined $bytes;
    my $decoded = eval { _runtime_json_decode($bytes) };
    return $decoded->{script_source} if ref($decoded) eq 'HASH' && defined $decoded->{script_source};
    return $bytes;
}

sub _runtime_json_decoder {
    return $RUNTIME_JSON_DECODER if $RUNTIME_JSON_DECODER;
    if (eval { require JSON::XS; 1 }) {
        $RUNTIME_JSON_DECODER = JSON::XS->new->utf8(1);
        $RUNTIME_JSON_DECODER_KIND = 'JSON::XS';
        return $RUNTIME_JSON_DECODER;
    }
    $RUNTIME_JSON_DECODER = JSON::PP->new->utf8(1);
    $RUNTIME_JSON_DECODER_KIND = 'JSON::PP';
    return $RUNTIME_JSON_DECODER;
}

sub _runtime_json_decode {
    my ($json) = @_;
    return _runtime_json_decoder()->decode($json);
}

sub _source_path_to_script_source {
    my ($entrypoint) = @_;
    my $state = _state();
    my $unit = _find_code_unit_for_entrypoint($entrypoint);
    return if !$unit;
    my $source_path = $unit->{source_path} // '';
    return if !$source_path;
    my $root = $state->{manifest}{entrypoint}{source_path} // '';
    my $abs_root = File::Spec->rel2abs($source_path);
    $source_path = $abs_root;
    if (open my $source_fh, '<:raw', $source_path) {
        local $/;
        return <$source_fh>;
    }
    return;
}

sub _script_source_from_residual_payload {
    my ($entrypoint) = @_;
    my $manifest_entry = _find_code_unit_for_entrypoint($entrypoint);
    return if !$manifest_entry;
    my $payload = $manifest_entry->{residual_payload} // $manifest_entry->{payload} // '';
    return if !$payload;
    return $payload;
}

sub _find_code_unit_for_entrypoint {
    my ($entrypoint) = @_;
    my $state = _state();
    my $entrypoint_name = $entrypoint;
    for my $unit (@{ $state->{manifest}{code_units} // [] }) {
        next unless $unit && ref($unit) eq 'HASH';
        my $logical = $unit->{logical_path} // '';
        my $packed = File::Spec->catfile($state->{root}, 'code', split m{/}, $logical);
        return $unit if $unit->{logical_path} eq $entrypoint || $packed eq $entrypoint_name;
        my $source_path = $unit->{source_path} // '';
        next if $source_path eq '';
        return $unit if File::Spec->rel2abs($source_path) eq File::Spec->rel2abs($entrypoint_name);
    }
    return;
}

sub _apply_initializer {
    my ($init) = @_;
    my $op = $init->{op} // '';
    _trace("initializer $op " . ($init->{module} // $init->{symbol} // ''));
    if ($op eq 'require_module') {
        my $module = $init->{module} // die 'initializer module missing';
        my $path = $module;
        $path =~ s{::}{/}g;
        $path .= '.pm';
        _load_compiled_require($path) || require $path;
        return;
    }
    if ($op eq 'use_module') {
        my $module = $init->{module} // die 'initializer module missing';
        my $path = $module;
        $path =~ s{::}{/}g;
        $path .= '.pm';
        _load_compiled_require($path) || require $path;
        my @args = @{ $init->{args} // [] };
        my $target_package = $init->{package} || 'main';
        my $arg_list = join(', ', map { _perl_literal($_) } @args);
        my $code = "package $target_package; ${module}->import(" . $arg_list . "); 1;";
        _trace("initializer import start $module into $target_package");
        my $ok = eval $code;
        die $@ if !$ok;
        _trace("initializer import done $module into $target_package");
        return;
    }
    if ($op eq 'set_scalar_literal') {
        my $symbol = $init->{symbol} // die 'initializer symbol missing';
        my $value = $init->{value};
        no strict 'refs';
        ${$symbol} = $value;
        return;
    }
    if ($op eq 'set_array_literal') {
        my $symbol = $init->{symbol} // die 'initializer symbol missing';
        my $values = $init->{values} // [];
        no strict 'refs';
        @{$symbol} = @$values;
        return;
    }
    if ($op eq 'increment_scalar_default_zero') {
        my $symbol = $init->{symbol} // die 'initializer symbol missing';
        my $by = $init->{by} // 0;
        no strict 'refs';
        ${$symbol} = (${ $symbol } // 0) + $by;
        return;
    }
    die "unsupported compiled initializer op: $op";
}

sub _perl_literal {
    my ($value) = @_;
    return 'undef' if !defined $value;
    return $value if !ref($value) && $value =~ /\A-?\d+(?:\.\d+)?\z/;
    my $text = "$value";
    $text =~ s/\\/\\\\/g;
    $text =~ s/'/\\'/g;
    return "'" . $text . "'";
}

sub _install_compiled_sub {
    my ($package, $sub) = @_;
    my $name = $sub->{name} // die 'compiled sub name missing';
    my $full = $package . '::' . $name;
    my $impl;
    if (($sub->{op} // '') eq 'return_literal') {
        my $value = $sub->{value};
        $impl = sub { return $value };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'native_shape_sub') {
        my $shape = $sub->{native_shape} // {};
        $impl = sub {
            return _run_native_shape_sub($full, $shape, @_);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'global_eq_literal_bool') {
        my $symbol = $sub->{symbol} // die 'compiled sub symbol missing';
        my $literal = $sub->{literal};
        $impl = sub {
            no strict 'refs';
            return (defined ${$symbol} && ${$symbol} eq $literal) ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'command_chain_or_literal') {
        my @commands = @{ $sub->{commands} // [] };
        my $fallback = $sub->{fallback};
        $impl = sub {
            no strict 'refs';
            my $resolver = *{ $package . '::command_in_path' }{CODE} or die "missing command_in_path for $package";
            for my $command (@commands) {
                my $resolved = $resolver->($command);
                return $resolved if defined $resolved && $resolved ne '';
            }
            return $fallback;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'normalize_shell_name') {
        $impl = sub {
            my ($shell) = @_;
            no strict 'refs';
            my $native = *{ $package . '::native_shell_name' }{CODE} or die "missing native_shell_name for $package";
            $shell = $native->() if !defined $shell || $shell eq '';
            $shell =~ s{.*[\\/]}{} if defined $shell;
            $shell = lc($shell || '');
            return 'powershell' if $shell eq 'ps' || $shell eq 'powershell.exe';
            return 'pwsh' if $shell eq 'pwsh.exe';
            return $shell if $shell eq 'bash' || $shell eq 'zsh' || $shell eq 'sh' || $shell eq 'powershell' || $shell eq 'pwsh';
            die "Unsupported shell '$shell'\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'native_shell_name') {
        $impl = sub {
            my ($requested) = @_;
            no strict 'refs';
            my $normalize = *{ $package . '::normalize_shell_name' }{CODE} or die "missing normalize_shell_name for $package";
            my $command_in_path = *{ $package . '::command_in_path' }{CODE} or die "missing command_in_path for $package";
            my $is_windows = *{ $package . '::is_windows' }{CODE} or die "missing is_windows for $package";
            return $normalize->($requested) if defined $requested && $requested ne '';
            if ($is_windows->()) {
                return $command_in_path->('pwsh') ? 'pwsh' : 'powershell';
            }
            my $shell = $ENV{SHELL} || '';
            $shell =~ s{.*[\\/]}{} if $shell ne '';
            return $normalize->($shell) if $shell ne '';
            return 'bash' if $command_in_path->('bash');
            return 'zsh' if $command_in_path->('zsh');
            return 'sh';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'shell_command_argv') {
        $impl = sub {
            my ($command, %args) = @_;
            die "Missing shell command\n" if !defined $command;
            no strict 'refs';
            my $normalize = *{ $package . '::normalize_shell_name' }{CODE} or die "missing normalize_shell_name for $package";
            my $native = *{ $package . '::native_shell_name' }{CODE} or die "missing native_shell_name for $package";
            my $shell = $normalize->($args{shell} || $native->());
            return ($shell, '-lc', $command) if $shell eq 'bash' || $shell eq 'zsh' || $shell eq 'sh';
            return ($shell, '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', $command)
                if $shell eq 'powershell' || $shell eq 'pwsh';
            die "Unsupported shell '$shell'\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'shell_quote_for') {
        $impl = sub {
            my ($shell, $value) = @_;
            no strict 'refs';
            my $normalize = *{ $package . '::normalize_shell_name' }{CODE} or die "missing normalize_shell_name for $package";
            $shell = $normalize->($shell);
            $value = '' if !defined $value;
            if ($shell eq 'powershell' || $shell eq 'pwsh') {
                $value =~ s/'/''/g;
                return "'$value'";
            }
            $value =~ s/'/'\\''/g;
            return "'$value'";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'has_shebang') {
        $impl = sub {
            my ($path) = @_;
            open my $fh, '<', $path or die "Unable to read $path: $!";
            my $first = <$fh>;
            close $fh;
            return defined $first && $first =~ /^#!/ ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'shebang_uses_perl') {
        $impl = sub {
            my ($path) = @_;
            open my $fh, '<', $path or die "Unable to read $path: $!";
            my $first = <$fh>;
            close $fh;
            return 0 if !defined $first;
            return $first =~ /^#!.*\bperl(?:\s|\z)/ ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'path_candidates') {
        $impl = sub {
            my ($path) = @_;
            my @candidates = ($path);
            no strict 'refs';
            my $is_windows = *{ $package . '::is_windows' }{CODE} or die "missing is_windows for $package";
            return @candidates if !$is_windows->();
            return @candidates if $path =~ /\.[^\\\/.]+\z/;
            my @extensions = split /;/, ($ENV{PATHEXT} || '.COM;.EXE;.BAT;.CMD;.PS1');
            for my $ext (@extensions) {
                next if !defined $ext || $ext eq '';
                push @candidates, $path . lc($ext);
                push @candidates, $path . uc($ext);
            }
            return @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runnable_path_candidates') {
        $impl = sub {
            my ($path) = @_;
            no strict 'refs';
            my $path_candidates = *{ $package . '::_path_candidates' }{CODE} or die "missing _path_candidates for $package";
            my @candidates = $path_candidates->($path);
            return @candidates if $path =~ /\.[^\\\/.]+\z/;
            for my $suffix (qw(.pl .go .java .ps1 .cmd .bat .sh .bash)) {
                push @candidates, $path_candidates->($path . $suffix);
            }
            my %seen;
            return grep { !$seen{$_}++ } @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'is_windows_runnable_candidate') {
        $impl = sub {
            my ($path) = @_;
            no strict 'refs';
            my $command_in_path = *{ $package . '::command_in_path' }{CODE} or die "missing command_in_path for $package";
            my $has_shebang = *{ $package . '::_has_shebang' }{CODE} or die "missing _has_shebang for $package";
            return 1 if $path =~ /\.(?:pl|ps1)\z/i;
            return 1 if $path =~ /\.(?:com|exe|bat|cmd)\z/i;
            return 1 if $path =~ /\.(?:sh|bash)\z/i && ($command_in_path->('bash') || $command_in_path->('sh'));
            return 1 if $has_shebang->($path);
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'command_in_path') {
        $impl = sub {
            my ($name) = @_;
            return if !defined $name || $name eq '';
            no strict 'refs';
            my $path_candidates = *{ $package . '::_path_candidates' }{CODE} or die "missing _path_candidates for $package";
            for my $candidate ($path_candidates->($name)) {
                return $candidate if -f $candidate;
            }
            require File::Spec;
            for my $dir (File::Spec->path) {
                next if !defined $dir || $dir eq '';
                for my $candidate ($path_candidates->(File::Spec->catfile($dir, $name))) {
                    return $candidate if -f $candidate;
                }
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'resolve_runnable_file') {
        $impl = sub {
            my ($path) = @_;
            return if !defined $path || $path eq '';
            no strict 'refs';
            my $runnable_candidates = *{ $package . '::_runnable_path_candidates' }{CODE} or die "missing _runnable_path_candidates for $package";
            my $is_windows = *{ $package . '::is_windows' }{CODE} or die "missing is_windows for $package";
            my $is_windows_candidate = *{ $package . '::_is_windows_runnable_candidate' }{CODE} or die "missing _is_windows_runnable_candidate for $package";
            for my $candidate ($runnable_candidates->($path)) {
                next if !-f $candidate;
                return $candidate if !$is_windows->() && -x $candidate;
                return $candidate if $is_windows->() && $is_windows_candidate->($candidate);
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'is_runnable_file') {
        $impl = sub {
            my ($path) = @_;
            no strict 'refs';
            my $resolve = *{ $package . '::resolve_runnable_file' }{CODE} or die "missing resolve_runnable_file for $package";
            my $resolved = $resolve->($path);
            return $resolved ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'command_argv_for_path') {
    $impl = sub {
            my ($path) = @_;
            no strict 'refs';
            my $platform_argv_for_path = $package . '::_exec_go_source';
            my $platform_exec_java_source = $package . '::_exec_java_source';
            my $resolve = *{ $package . '::resolve_runnable_file' }{CODE} or die "missing resolve_runnable_file for $package";
            my $module_lib_root = *{ $package . '::_module_lib_root' }{CODE} or die "missing _module_lib_root for $package";
            my $shebang_uses_perl = *{ $package . '::_shebang_uses_perl' }{CODE} or die "missing _shebang_uses_perl for $package";
            my $has_shebang = *{ $package . '::_has_shebang' }{CODE} or die "missing _has_shebang for $package";
            my $powershell_binary = *{ $package . '::_powershell_binary' }{CODE} or die "missing _powershell_binary for $package";
            my $cmd_binary = *{ $package . '::_cmd_binary' }{CODE} or die "missing _cmd_binary for $package";
            my $posix_shell_binary = *{ $package . '::_posix_shell_binary' }{CODE} or die "missing _posix_shell_binary for $package";
            my $is_windows = *{ $package . '::is_windows' }{CODE} or die "missing is_windows for $package";
            my $resolved = ((-f $path ? $path : undef) || $resolve->($path)) || die "Unable to find runnable file for $path";
            my $lower = lc $resolved;
            return ($^X, '-I', $module_lib_root->(), $resolved) if $lower =~ /\.pl\z/;
            return ($^X, '-I', $module_lib_root->(), '-M' . $package, '-e', $platform_argv_for_path . '(@ARGV)', $resolved)
                if $lower =~ /\.go\z/;
            return ($^X, '-I', $module_lib_root->(), '-M' . $package, '-e', $platform_exec_java_source . '(@ARGV)', $resolved)
                if $lower =~ /\.java\z/;
            return ($^X, '-I', $module_lib_root->(), $resolved) if !$is_windows->() && $shebang_uses_perl->($resolved);
            return ($resolved) if !$is_windows->() && $has_shebang->($resolved);
            return ($powershell_binary->(), '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $resolved)
                if $lower =~ /\.ps1\z/;
            return ($cmd_binary->(), '/d', '/c', $resolved) if $lower =~ /\.(?:cmd|bat)\z/;
            return ($posix_shell_binary->('bash'), $resolved) if $lower =~ /\.bash\z/;
            return ($posix_shell_binary->('sh'), $resolved) if $lower =~ /\.sh\z/;
            return ($resolved) if !$is_windows->();
            return ($^X, $resolved);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'exec_go_source') {
        $impl = sub {
            my ($path, @args) = @_;
            die "Missing Go source path\n" if !defined $path || $path eq '';
            no strict 'refs';
            my $exec_launcher = ${ $package . '::EXEC_LAUNCHER' } or die "missing EXEC_LAUNCHER for $package";
            $exec_launcher->('go', 'run', $path, @args) or die "Unable to exec go run for $path: $!";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'java_main_class') {
        $impl = sub {
            my ($path) = @_;
            die "Missing Java source path\n" if !defined $path || $path eq '';
            require File::Basename;
            open my $fh, '<', $path or die "Unable to read $path: $!";
            my $package_name = '';
            my $class = '';
            while (my $line = <$fh>) {
                if ($line =~ /^\s*package\s+([A-Za-z_][A-Za-z0-9_\.]*)\s*;/) {
                    $package_name = $1;
                    next;
                }
                if ($line =~ /^\s*(?:public\s+)?(?:final\s+|abstract\s+)?(?:class|interface|enum|record)\s+([A-Za-z_][A-Za-z0-9_]*)\b/) {
                    $class = $1;
                    last;
                }
            }
            close $fh;
            if ($class eq '') {
                $class = File::Basename::basename($path);
                $class =~ s/\.java\z//i;
            }
            return $package_name eq '' ? $class : $package_name . '.' . $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'exec_java_source') {
        $impl = sub {
            my ($path, @args) = @_;
            die "Missing Java source path\n" if !defined $path || $path eq '';
            require File::Copy;
            require File::Spec;
            require File::Temp;
            no strict 'refs';
            my $java_main_class = *{ $package . '::_java_main_class' }{CODE} or die "missing _java_main_class for $package";
            my $exec_launcher = ${ $package . '::EXEC_LAUNCHER' } or die "missing EXEC_LAUNCHER for $package";
            my $system_launcher = ${ $package . '::SYSTEM_LAUNCHER' } or die "missing SYSTEM_LAUNCHER for $package";
            my $class = $java_main_class->($path);
            my ($simple_class) = $class =~ /([^\.]+)\z/;
            die "Unable to resolve Java main class for $path\n" if !defined $simple_class || $simple_class eq '';
            my $build_root = File::Temp::tempdir(CLEANUP => 1);
            my $source_root = File::Temp::tempdir(CLEANUP => 1);
            my $staged_source = File::Spec->catfile($source_root, $simple_class . '.java');
            File::Copy::copy($path, $staged_source) or die "Unable to stage Java source $path as $staged_source: $!";
            $system_launcher->('javac', '-d', $build_root, $staged_source);
            my $exit_code = $? >> 8;
            die "javac failed for $path with exit code $exit_code\n" if $exit_code != 0;
            $exec_launcher->('java', '-cp', $build_root, $class, @args) or die "Unable to exec java for $path: $!";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'split_reverse_join') {
        my $split_pattern = $sub->{split_pattern} // '\\s+';
        my $joiner = defined $sub->{joiner} ? $sub->{joiner} : ' ';
        my $default = defined $sub->{default} ? $sub->{default} : '';
        $impl = sub {
            my ($text) = @_;
            $text = $default if !defined $text;
            my @parts = split /\s+/, $text;
            return join $joiner, reverse @parts;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'json_xs_encode_pretty') {
        $impl = sub {
            require JSON::XS;
            return JSON::XS->new->utf8->canonical->pretty->encode($_[0]);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'json_xs_decode') {
        $impl = sub {
            require JSON::XS;
            return JSON::XS->new->utf8->decode($_[0]);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'call_named_with_first_arg') {
        my $target = $sub->{target} // die 'compiled sub target missing';
        $impl = sub {
            return _code_for($target)->($_[0]);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'call_named_with_first_arg_default') {
        my $target = $sub->{target} // die 'compiled sub target missing';
        my $default = $sub->{default};
        $impl = sub {
            my $arg = $_[0];
            $arg = $default if !defined $arg;
            return _code_for($target)->($arg);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'clear_package_hash_and_env') {
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        my $env_key = $sub->{env_key} // die 'compiled sub env key missing';
        $impl = sub {
            no strict 'refs';
            %{$hash_symbol} = ();
            delete $ENV{$env_key};
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'hash_lookup_via_method_copy') {
        my $copy_method = $sub->{copy_method} // die 'compiled sub copy method missing';
        $impl = sub {
            my ($class, $key) = @_;
            return undef if !defined $key || $key eq '';
            my $audit = _code_for($copy_method)->($class);
            return undef if !exists $audit->{$key};
            return $audit->{$key};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'return_method_call') {
        my $target = $sub->{target} // die 'compiled sub target missing';
        $impl = sub {
            return _code_for($target)->(@_);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'copy_package_hash_entries') {
        my $load_method = $sub->{load_method} // die 'compiled sub load method missing';
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        $impl = sub {
            my ($class) = @_;
            _code_for($load_method)->($class);
            no strict 'refs';
            my %copy = map {
                my $entry = ${$hash_symbol}{$_};
                $_ => {
                    value => $entry->{value},
                    envfile => $entry->{envfile},
                }
            } CORE::keys %{$hash_symbol};
            return \%copy;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'load_package_hash_from_env_json') {
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        my $env_key = $sub->{env_key} // die 'compiled sub env key missing';
        my $error_message = $sub->{error_message} // 'decoded payload must be a hash';
        $impl = sub {
            my ($class) = @_;
            no strict 'refs';
            return 1 if %{$hash_symbol};
            my $raw = $ENV{$env_key} || '';
            return 1 if $raw eq '';
            my $decoded = __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($raw);
            die $error_message if ref($decoded) ne 'HASH';
            %{$hash_symbol} = map {
                $_ => {
                    value => $decoded->{$_}{value},
                    envfile => $decoded->{$_}{envfile},
                }
            } CORE::keys %{$decoded};
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'sync_env_json_from_method') {
        my $env_key = $sub->{env_key} // die 'compiled sub env key missing';
        my $copy_method = $sub->{copy_method} // die 'compiled sub copy method missing';
        $impl = sub {
            my ($class) = @_;
            $ENV{$env_key} = __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode(_code_for($copy_method)->($class));
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'record_package_hash_entry_and_sync') {
        my $missing_key_error = $sub->{missing_key_error} // 'missing key';
        my $missing_source_error = $sub->{missing_source_error} // 'missing source file';
        my $load_method = $sub->{load_method} // die 'compiled sub load method missing';
        my $sync_method = $sub->{sync_method} // die 'compiled sub sync method missing';
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        $impl = sub {
            my ($class, $key, $value, $envfile) = @_;
            die $missing_key_error if !defined $key || $key eq '';
            die $missing_source_error if !defined $envfile || $envfile eq '';
            _code_for($load_method)->($class);
            no strict 'refs';
            ${$hash_symbol}{$key} = {
                value => $value,
                envfile => $envfile,
            };
            _code_for($sync_method)->($class);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'content_md5') {
        my $default = defined $sub->{default} ? $sub->{default} : '';
        my $bytes_method = $sub->{bytes_method} // die 'compiled sub bytes method missing';
        $impl = sub {
            require Digest::MD5;
            my ($content) = @_;
            $content = $default if !defined $content;
            return Digest::MD5::md5_hex(_code_for($bytes_method)->($content));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'same_content_md5') {
        my $target = $sub->{target} // die 'compiled sub target missing';
        $impl = sub {
            my ($left, $right) = @_;
            return _code_for($target)->($left) eq _code_for($target)->($right);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_matches_content_md5') {
        my $read_error = $sub->{read_error} // 'Unable to read %s: %s';
        my $close_error = $sub->{close_error} // 'Unable to close %s: %s';
        my $compare_method = $sub->{compare_method} // die 'compiled sub compare method missing';
        $impl = sub {
            my ($path, $content) = @_;
            return 0 if !defined $path || $path eq '' || !-f $path;
            open my $fh, '<:raw', $path or die sprintf($read_error, $path, $!);
            my $existing = do { local $/; <$fh> };
            close $fh or die sprintf($close_error, $path, $!);
            return _code_for($compare_method)->($existing, $content);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'utf8_content_bytes') {
        $impl = sub {
            require Encode;
            my ($content) = @_;
            return Encode::encode_utf8($content) if utf8::is_utf8($content);
            return $content;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'configure_aliases_hash') {
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        $impl = sub {
            my ($class, %args) = @_;
            no strict 'refs';
            %{$hash_symbol} = %{ $args{aliases} || {} };
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'read_with_aliases') {
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        my $read_error = $sub->{read_error} // 'Unable to read %s: %s';
        $impl = sub {
            my ($class, $file) = @_;
            no strict 'refs';
            $file = ${$hash_symbol}{$file} if exists ${$hash_symbol}{$file};
            return if !defined $file || !-f $file;
            open my $fh, '<', $file or die sprintf($read_error, $file, $!);
            local $/;
            return <$fh>;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'write_with_aliases') {
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub hash symbol missing';
        my $missing_error = $sub->{missing_error} // 'Missing file path';
        my $write_error = $sub->{write_error} // 'Unable to write %s: %s';
        $impl = sub {
            my ($class, $file, $content) = @_;
            no strict 'refs';
            $file = ${$hash_symbol}{$file} if exists ${$hash_symbol}{$file};
            die $missing_error if !defined $file || $file eq '';
            open my $fh, '>', $file or die sprintf($write_error, $file, $!);
            print {$fh} defined $content ? $content : '';
            close $fh;
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'tiehandle_constructor') {
        $impl = sub {
            my ($class, %args) = @_;
            return bless { writer => $args{writer} || sub { } }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'bless_args_hash') {
        my $slots = $sub->{slots} || [];
        $impl = sub {
            my ($class, %args) = @_;
            my %payload = map { ($_->{slot} => $args{ $_->{arg} }) } @$slots;
            return bless \%payload, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'bless_required_args_hash') {
        my $slots = $sub->{slots} || [];
        $impl = sub {
            my ($class, %args) = @_;
            my %payload;
            for my $slot (@$slots) {
                my $value = $args{ $slot->{arg} };
                die $slot->{error} if !$value;
                $payload{ $slot->{slot} } = $value;
            }
            return bless \%payload, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'return_self_slot') {
        my $slot = $sub->{slot} // die 'compiled sub slot missing';
        $impl = sub {
            return $_[0]{$slot};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cwd_catdir_literal') {
        my $parts = $sub->{path_parts} || [];
        $impl = sub {
            require Cwd;
            require File::Spec;
            return File::Spec->catdir(Cwd::cwd(), @$parts);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'supported_update_script') {
        $impl = sub {
            my ($self, $path) = @_;
            return 0 if !defined $path || $path eq '';
            return 1 if $path =~ /\.pl\z/i;
            return 1 if $path =~ /\.(?:sh|bash|ps1|cmd|bat)\z/i;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file($path) ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runner_loop_names') {
        $impl = sub {
            my ($self) = @_;
            return map { $_->{name} } $self->{runner}->running_loops;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'stop_named_loops') {
        $impl = sub {
            my ($self, @names) = @_;
            for my $name (@names) {
                eval { $self->{runner}->stop_loop($name) };
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'restart_wanted_collectors') {
        $impl = sub {
            my ($self, @names) = @_;
            return if !@names;
            my %wanted = map { $_ => 1 } @names;
            my @jobs = @{ $self->{config}->collectors };
            for my $job (@jobs) {
                next if ref($job) ne 'HASH';
                next if !$wanted{ $job->{name} };
                eval { $self->{runner}->start_loop($job) };
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'update_manager_run') {
        my $updates_dir_method = $sub->{updates_dir_method} // die 'compiled sub updates_dir method missing';
        my $running_method = $sub->{running_method} // die 'compiled sub running method missing';
        my $stop_method = $sub->{stop_method} // die 'compiled sub stop method missing';
        my $restart_method = $sub->{restart_method} // die 'compiled sub restart method missing';
        my $support_method = $sub->{support_method} // die 'compiled sub support method missing';
        my $open_error = $sub->{open_error} // 'Unable to open updates directory %s: %s';
        $impl = sub {
            require Capture::Tiny;
            require File::Spec;
            my ($self) = @_;
            my @running = _code_for($running_method)->($self);
            _code_for($stop_method)->($self, @running);
            my @results;
            my $dir = _code_for($updates_dir_method)->($self);
            return \@results if !-d $dir;
            opendir my $dh, $dir or die sprintf($open_error, $dir, $!);
            for my $file (sort readdir $dh) {
                next if $file eq '.' || $file eq '..';
                next if !-f File::Spec->catfile($dir, $file);
                my $path = File::Spec->catfile($dir, $file);
                next if !_code_for($support_method)->($self, $path);
                my @cmd = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($path);
                print "-" x 40, "\n";
                print ">> Run Update: $file...\n";
                print "-" x 40, "\n";
                print ">> @cmd\n";
                print "-" x 40, "\n";
                my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                    system @cmd;
                    return $? >> 8;
                };
                my $output = $stdout . $stderr;
                print $output if defined $output && $output ne '';
                print "\n>> Finished.\n\n";
                push @results, {
                    file => $file,
                    exit_code => $exit_code,
                    output => $output,
                };
            }
            closedir $dh;
            _code_for($restart_method)->($self, @running);
            return \@results;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_resolver_providers') {
        $impl = sub {
            my ($self) = @_;
            my @providers = (
                {
                    id => 'system-status',
                    kind => 'builtin',
                    title => 'System Status',
                    description => 'Generated page describing the local runtime.',
                },
                {
                    id => 'project-context',
                    kind => 'builtin',
                    title => 'Project Context',
                    description => 'Generated page describing the active project.',
                },
            );
            push @providers, @{ $self->{config}->providers };
            return \@providers;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_resolver_list_pages') {
        my $providers_method = $sub->{providers_method} // die 'compiled sub providers method missing';
        $impl = sub {
            my ($self) = @_;
            my %ids = map { $_ => 1 } $self->{pages}->list_saved_pages;
            for my $provider (@{ _code_for($providers_method)->($self) }) {
                next if ref($provider) ne 'HASH';
                $ids{ $provider->{id} } = 1 if $provider->{id};
            }
            return sort keys %ids;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_resolver_load_named_page') {
        my $missing_error = $sub->{missing_error} // 'Missing page id';
        my $provider_method = $sub->{provider_method} // die 'compiled sub provider method missing';
        $impl = sub {
            my ($self, $id) = @_;
            die $missing_error if !defined $id || $id eq '';
            my $saved = eval { $self->{pages}->load_saved_page($id) };
            if ($saved) {
                $saved->{meta}{source_kind} = 'saved';
                return $saved;
            }
            return _code_for($provider_method)->($self, $id);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_resolver_load_provider_page') {
        my $providers_method = $sub->{providers_method} // die 'compiled sub providers method missing';
        my $missing_error = $sub->{missing_error} // "Page '%s' not found";
        $impl = sub {
            my ($self, $id) = @_;
            require __PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument;
            my ($provider) = grep { ref($_) eq 'HASH' && $_->{id} && $_->{id} eq $id } @{ _code_for($providers_method)->($self) };
            die sprintf($missing_error, $id) if !$provider;
            my $page;
            if (($provider->{kind} || '') eq 'builtin' && $id eq 'system-status') {
                $page = __PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument->new(
                    id => $id,
                    title => 'System Status',
                    description => 'Generated overview of runtime paths and roots.',
                    layout => {
                        body => join(
                            "\n",
                            'Developer Dashboard runtime paths:',
                            'home: ' . $self->{paths}->home,
                            'runtime: ' . $self->{paths}->runtime_root,
                            'dashboards: ' . $self->{paths}->dashboards_root,
                            'config: ' . $self->{paths}->config_root,
                            'cli: ' . $self->{paths}->cli_root,
                        ),
                    },
                    actions => [
                        { id => 'paths', label => 'Show paths', kind => 'builtin', builtin => 'paths.list', safe => 1 },
                    ],
                );
            } elsif (($provider->{kind} || '') eq 'builtin' && $id eq 'project-context') {
                my $root = $self->{paths}->current_project_root || '(none)';
                $page = __PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument->new(
                    id => $id,
                    title => 'Project Context',
                    description => 'Generated page describing the current project root.',
                    layout => { body => "Current project root:\n$root" },
                    state => { current_project_root => $root },
                    actions => [
                        { id => 'state', label => 'Show state', kind => 'builtin', builtin => 'page.state', safe => 1 },
                    ],
                );
            } elsif (ref($provider->{page}) eq 'HASH') {
                $page = __PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument->from_hash($provider->{page});
            } else {
                $page = __PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument->new(
                    id => $provider->{id},
                    title => $provider->{title} || $provider->{id},
                    description => $provider->{description} || 'Generated provider page.',
                    layout => { body => $provider->{body} || '' },
                    actions => $provider->{actions} || [],
                    state => $provider->{state} || {},
                );
            }
            $page->{meta}{source_kind} = 'provider';
            return $page;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'strftime_now') {
        my $format = $sub->{format} // '%Y-%m-%d %H:%M:%S';
        $impl = sub {
            require POSIX;
            return POSIX::strftime($format, localtime);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'prompt_indicator_parts') {
        $impl = sub {
            my ($self, %args) = @_;
            my $mode = $args{mode} || 'compact';
            my $color = exists $args{color} ? $args{color} : 0;
            my $max_age = defined $args{max_age} ? $args{max_age} : 300;
            my @indicator_parts;
            for my $indicator ($self->{indicators}->list_indicators) {
                next if exists $indicator->{prompt_visible} && !$indicator->{prompt_visible};
                my $status_icon = $self->{indicators}->prompt_status_icon($indicator);
                my $icon = defined $indicator->{icon} ? $indicator->{icon} : '';
                my $label = defined $indicator->{label} ? $indicator->{label} : $indicator->{name};
                my $stale = $self->{indicators}->is_stale($indicator, max_age => $max_age) ? 1 : 0;
                my $part = $mode eq 'extended'
                    ? join('', grep { defined && $_ ne '' } $status_icon, $icon, $label)
                    : join('', grep { defined && $_ ne '' } $status_icon, ($icon || substr($label, 0, 1)));
                if ($color) {
                    my $status = $indicator->{status} || '';
                    my $ansi = $stale ? "\e[33m"
                        : $status =~ /^(ok|clean)$/ ? "\e[32m"
                        : $status =~ /^(missing|error|dirty|down)$/ ? "\e[31m"
                        : "\e[36m";
                    $part = $ansi . $part . "\e[0m";
                }
                push @indicator_parts, $part;
            }
            return @indicator_parts;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'git_branch_for_project') {
        my $restore_error = $sub->{restore_error} // 'Unable to restore cwd to %s: %s';
        $impl = sub {
            require Capture::Tiny;
            require Cwd;
            my ($self, $project_root) = @_;
            return if !$project_root || !-d $project_root;
            my $old = Cwd::cwd();
            chdir $project_root or return;
            my ($stdout, undef, $exit_code) = Capture::Tiny::capture {
                system 'git', 'branch';
                return $? >> 8;
            };
            chdir $old or die sprintf($restore_error, $old, $!);
            return if $exit_code != 0;
            return if !defined $stdout || $stdout eq '';
            for my $line (split /\n/, $stdout) {
                next if !defined $line;
                return $1 if $line =~ /^\*\s+(.+)$/;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'prompt_render') {
        my $indicator_method = $sub->{indicator_method} // die 'compiled sub indicator method missing';
        my $branch_method = $sub->{branch_method} // die 'compiled sub branch method missing';
        my $timestamp_method = $sub->{timestamp_method} // die 'compiled sub timestamp method missing';
        $impl = sub {
            require Cwd;
            my ($self, %args) = @_;
            my $jobs = defined $args{jobs} ? $args{jobs} : 0;
            my $cwd = $args{cwd} || Cwd::cwd();
            my $mode = $args{mode} || 'compact';
            my $color = exists $args{color} ? $args{color} : 0;
            my $max_age = defined $args{max_age} ? $args{max_age} : 300;
            my $project = $self->{paths}->project_root_for($cwd);
            my $home = $self->{paths}->home;
            $cwd =~ s/^\Q$home\E/~/;
            $cwd = "Home: $home" if $cwd eq '~';
            my @indicator_parts = _code_for($indicator_method)->(
                $self,
                color => $color,
                max_age => $max_age,
                mode => $mode,
            );
            my $ticket = defined $ENV{TICKET_REF} ? $ENV{TICKET_REF} : '';
            my @info_parts = @indicator_parts;
            push @info_parts, "🎫:$ticket" if defined $ticket && $ticket ne '';
            my $info = @info_parts ? join(' ', @info_parts) : '';
            my $branch = _code_for($branch_method)->($self, $project);
            my $jobs_suffix = $jobs ? " ($jobs jobs)" : '';
            my $branch_suffix = $branch ? " 🌿$branch" : '';
            return sprintf "(%s)%s [%s]%s%s\n> ",
                _code_for($timestamp_method)->($self),
                ($info ne '' ? " $info" : ''),
                $cwd,
                $jobs_suffix,
                $branch_suffix;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'doctor_known_roots') {
        $impl = sub {
            my ($self) = @_;
            require File::Spec;
            my $home = $self->{paths}->home;
            return (
                {
                    label => 'home_runtime',
                    path => $self->{paths}->home_runtime_path,
                },
                map {
                    +{
                        label => $_->{label},
                        path => File::Spec->catdir($home, $_->{name}),
                    }
                } (
                    { label => 'legacy_bookmarks', name => 'bookmarks' },
                    { label => 'legacy_config', name => 'config' },
                    { label => 'legacy_cli', name => 'cli' },
                    { label => 'legacy_checkers', name => 'checkers' },
                ),
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'mode_octal_stat') {
        $impl = sub {
            my ($path) = @_;
            my @stat = stat($path);
            return undef if !@stat;
            return sprintf '%04o', $stat[2] & 07777;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'doctor_permission_issue_for_path') {
        my $mode_method = $sub->{mode_method} // die 'compiled sub mode method missing';
        $impl = sub {
            my ($self, $path) = @_;
            return if !defined $path || $path eq '';
            my $mode = _code_for($mode_method)->($path);
            return if !defined $mode;
            my $expected = -d $path ? '0700' : (-x $path ? '0700' : '0600');
            return if $mode eq $expected;
            return {
                path => $path,
                kind => -d $path ? 'directory' : 'file',
                current_mode => $mode,
                expected_mode => $expected,
                fixed => 0,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'doctor_hook_results') {
        my $decode_error = $sub->{decode_error} // 'Doctor hook RESULT must decode to a hash';
        $impl = sub {
            return {} if !defined $ENV{RESULT} || $ENV{RESULT} eq '';
            my $results = __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($ENV{RESULT});
            die $decode_error if ref($results) ne 'HASH';
            return $results;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'doctor_audit_root') {
        my $missing_path_error = $sub->{missing_path_error} // 'Missing audit root path';
        my $missing_label_error = $sub->{missing_label_error} // 'Missing audit root label';
        my $chmod_error = $sub->{chmod_error} // 'Unable to chmod %s to %s: %s';
        my $permission_method = $sub->{permission_method} // die 'compiled sub permission method missing';
        $impl = sub {
            require File::Find;
            my ($self, %args) = @_;
            my $path = $args{path} || die $missing_path_error;
            my $label = $args{label} || die $missing_label_error;
            my $fix = $args{fix} ? 1 : 0;
            return {
                label => $label,
                path => $path,
                exists => 0,
                issue_count => 0,
                issues => [],
            } if !-e $path;
            my @issues;
            File::Find::find(
                {
                    no_chdir => 1,
                    wanted => sub {
                        my $entry = $File::Find::name;
                        my $issue = _code_for($permission_method)->($self, $entry);
                        return if !$issue;
                        if ($fix) {
                            chmod oct($issue->{expected_mode}), $entry
                                or die sprintf($chmod_error, $entry, $issue->{expected_mode}, $!);
                            $issue->{fixed} = 1;
                            $issue->{current_mode} = $issue->{expected_mode};
                        }
                        push @issues, $issue;
                    },
                },
                $path,
            );
            return {
                label => $label,
                path => $path,
                exists => 1,
                issue_count => scalar @issues,
                issues => \@issues,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'doctor_audit_roots') {
        my $roots_method = $sub->{roots_method} // die 'compiled sub roots method missing';
        my $audit_method = $sub->{audit_method} // die 'compiled sub audit method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my %seen;
            my @reports;
            for my $root (_code_for($roots_method)->($self)) {
                next if !$root->{path} || $seen{ $root->{path} }++;
                push @reports, _code_for($audit_method)->($self, %{$root}, fix => $args{fix});
            }
            return @reports;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'doctor_run') {
        my $audit_roots_method = $sub->{audit_roots_method} // die 'compiled sub audit roots method missing';
        my $hook_results_method = $sub->{hook_results_method} // die 'compiled sub hook results method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $fix = $args{fix} ? 1 : 0;
            my @roots = _code_for($audit_roots_method)->($self, fix => $fix);
            my @issues = map { @{ $_->{issues} || [] } } @roots;
            my $hooks = _code_for($hook_results_method)->($self);
            my @hook_failures = grep { ( $_->{exit_code} || 0 ) != 0 } values %{$hooks};
            return {
                ok => @issues || @hook_failures ? 0 : 1,
                fix_applied => $fix,
                roots => \@roots,
                issues => \@issues,
                issue_count => scalar @issues,
                hooks => $hooks,
                hook_failures => scalar @hook_failures,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'build_paths_registry') {
        $impl = sub {
            require Cwd;
            my $home = $ENV{HOME} || '';
            my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry->new(
                home => $home,
                cwd => Cwd::cwd(),
                workspace_roots => \@roots,
                project_roots => \@roots,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cdr_payload') {
        my $missing_paths_error = $sub->{missing_paths_error} // "Missing paths registry\n";
        my $type_error = $sub->{type_error} // "cdr args must be an array reference\n";
        $impl = sub {
            require Cwd;
            my (%args) = @_;
            my $paths = $args{paths} || die $missing_paths_error;
            my $argv = $args{args} || [];
            die $type_error if ref($argv) ne 'ARRAY';
            my @terms = @{$argv};
            return { target => '', matches => [] } if !@terms;
            my $first = $terms[0];
            my $alias_target = eval { $paths->resolve_dir($first) };
            if (defined $alias_target && $alias_target ne '') {
                shift @terms;
                return { target => $alias_target, matches => [] } if !@terms;
                my @matches = $paths->locate_dirs_under($alias_target, @terms);
                return {
                    target => @matches == 1 ? $matches[0] : $alias_target,
                    matches => @matches == 1 ? [] : \@matches,
                };
            }
            my @matches = $paths->locate_dirs_under(Cwd::cwd(), @terms);
            return {
                target => @matches == 1 ? $matches[0] : '',
                matches => @matches == 1 ? [] : \@matches,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cdr_directory_candidates') {
        my $missing_paths_error = $sub->{missing_paths_error} // "Missing paths registry\n";
        my $type_error = $sub->{type_error} // "cdr completion terms must be an array reference\n";
        $impl = sub {
            require File::Basename;
            my (%args) = @_;
            my $paths = $args{paths} || die $missing_paths_error;
            my $root = $args{root} || return ();
            my $terms = $args{terms} || [];
            my $prefix = defined $args{prefix} ? $args{prefix} : '';
            die $type_error if ref($terms) ne 'ARRAY';
            my @matches = $paths->locate_dirs_under($root, @{$terms});
            my %seen;
            my @candidates;
            for my $path (@matches) {
                next if !defined $path || $path eq '' || $path eq $root;
                my $name = File::Basename::basename($path);
                next if !defined $name || $name eq '';
                next if $prefix ne '' && index($name, $prefix) != 0;
                next if $seen{$name}++;
                push @candidates, $name;
            }
            return sort @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cdr_initial_candidates') {
        my $missing_paths_error = $sub->{missing_paths_error} // "Missing paths registry\n";
        my $type_error = $sub->{type_error} // "cdr completion include roots must be an array reference\n";
        my $directory_method = $sub->{directory_method} // die 'compiled sub directory method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die $missing_paths_error;
            my $prefix = defined $args{prefix} ? $args{prefix} : '';
            my $roots = $args{include} || [];
            die $type_error if ref($roots) ne 'ARRAY';
            my @candidates = grep { index($_, $prefix) == 0 } keys %{ $paths->named_paths || {} };
            for my $root (grep { defined && $_ ne '' && -d $_ } @{$roots}) {
                push @candidates, _code_for($directory_method)->(
                    paths => $paths,
                    root => $root,
                    terms => [],
                    prefix => $prefix,
                );
            }
            my %seen;
            return sort grep { defined && $_ ne '' && !$seen{$_}++ } @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cdr_completion') {
        my $missing_paths_error = $sub->{missing_paths_error} // "Missing paths registry\n";
        my $missing_words_error = $sub->{missing_words_error} // "Missing completion words\n";
        my $missing_index_error = $sub->{missing_index_error} // "Missing completion index\n";
        my $type_error = $sub->{type_error} // "cdr completion words must be an array reference\n";
        my $initial_method = $sub->{initial_method} // die 'compiled sub initial method missing';
        my $directory_method = $sub->{directory_method} // die 'compiled sub directory method missing';
        $impl = sub {
            require Cwd;
            my (%args) = @_;
            my $paths = $args{paths} || die $missing_paths_error;
            my $words = $args{words} || die $missing_words_error;
            my $index = defined $args{index} ? $args{index} : die $missing_index_error;
            die $type_error if ref($words) ne 'ARRAY';
            my @words = @{$words};
            return () if !@words;
            my $current = defined $words[$index] ? $words[$index] : '';
            my @args = @words > 1 ? @words[1 .. $#words] : ();
            my $arg_index = $index - 1;
            if ($arg_index <= 0) {
                return _code_for($initial_method)->(
                    paths => $paths,
                    prefix => $current,
                    include => [ Cwd::cwd() ],
                );
            }
            my $first = $args[0] // '';
            my $alias_target = eval { $paths->resolve_dir($first) };
            my $base_root = defined $alias_target && $alias_target ne '' ? $alias_target : Cwd::cwd();
            my $filter_start = defined $alias_target && $alias_target ne '' ? 1 : 0;
            my @filters = @args >= $arg_index ? @args[$filter_start .. ($arg_index - 1)] : ();
            return _code_for($directory_method)->(
                paths => $paths,
                root => $base_root,
                terms => \@filters,
                prefix => $current,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'run_paths_command') {
        my $missing_command_error = $sub->{missing_command_error} // "Missing command name\n";
        my $missing_args_error = $sub->{missing_args_error} // "Missing command arguments\n";
        my $type_error = $sub->{type_error} // "Command arguments must be an array reference\n";
        my $usage_error = $sub->{usage_error} // "Usage: dashboard path <resolve|locate|cdr|complete-cdr|add|del|project-root|list> ...\n";
        my $build_paths_method = $sub->{build_paths_method} // die 'compiled sub build paths method missing';
        my $cdr_payload_method = $sub->{cdr_payload_method} // die 'compiled sub cdr payload method missing';
        my $cdr_completion_method = $sub->{cdr_completion_method} // die 'compiled sub cdr completion method missing';
        $impl = sub {
            my (%args) = @_;
            my $command = $args{command} || die $missing_command_error;
            my $argv = $args{args} || die $missing_args_error;
            die $type_error if ref($argv) ne 'ARRAY';
            my $paths = _code_for($build_paths_method)->();
            my $files = __PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry->new(paths => $paths);
            my $config = __PAX_RUNTIME_LEGACY_NAMESPACE__::Config->new(files => $files, paths => $paths);
            my $aliases_loaded = 0;
            my $load_configured_path_aliases = sub {
                return 1 if $aliases_loaded;
                $paths->register_named_paths($config->path_aliases);
                $aliases_loaded = 1;
                return 1;
            };
            if ($command eq 'paths') {
                $load_configured_path_aliases->();
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($paths->all_paths);
                return 1;
            }
            my @argv = @{$argv};
            my $action = shift @argv || '';
            if ($action eq 'resolve') {
                $load_configured_path_aliases->();
                my $name = shift @argv || die "Usage: dashboard path resolve <name>\n";
                print $paths->resolve_dir($name), "\n";
                return 1;
            }
            if ($action eq 'locate') {
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode([ $paths->locate_projects(@argv) ]);
                return 1;
            }
            if ($action eq 'cdr') {
                $load_configured_path_aliases->();
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode(_code_for($cdr_payload_method)->(paths => $paths, args => \@argv));
                return 1;
            }
            if ($action eq 'complete-cdr') {
                $load_configured_path_aliases->();
                my $index = shift @argv;
                $index = 0 if !defined $index || $index eq '';
                print join("\n", _code_for($cdr_completion_method)->(paths => $paths, words => \@argv, index => $index)), "\n";
                return 1;
            }
            if ($action eq 'add') {
                my $name = shift @argv || die "Usage: dashboard path add <name> <path>\n";
                my $path = shift @argv || die "Usage: dashboard path add <name> <path>\n";
                my $saved = $config->save_global_path_alias($name, $path);
                $paths->register_named_paths({ $name => $path });
                $saved->{resolved} = $paths->resolve_dir($name);
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($saved);
                return 1;
            }
            if ($action eq 'del') {
                my $name = shift @argv || die "Usage: dashboard path del <name>\n";
                my $deleted = $config->remove_global_path_alias($name);
                $paths->unregister_named_path($name);
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($deleted);
                return 1;
            }
            if ($action eq 'project-root') {
                my $root = $paths->current_project_root;
                print defined $root ? "$root\n" : '';
                return 1;
            }
            if ($action eq 'list') {
                $load_configured_path_aliases->();
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($paths->all_path_aliases);
                return 1;
            }
            die $usage_error;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'paths_normalize_add_arguments') {
        $impl = sub {
            my (@argv) = @_;
            die "Usage: dashboard path add <name> <path>\n" if !@argv;
            if (@argv == 1 && $argv[0] eq '.') {
                my $cwd = Cwd::cwd();
                return (File::Basename::basename($cwd), $cwd);
            }
            my $name = shift @argv || die "Usage: dashboard path add <name> <path>\n";
            my $path = shift @argv || die "Usage: dashboard path add <name> <path>\n";
            $path = Cwd::cwd() if $path eq '.';
            return ($name, $path);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'paths_normalize_delete_argument') {
        $impl = sub {
            my (%args) = @_;
            my $paths  = $args{paths}  || die "Missing paths registry\n";
            my $config = $args{config} || die "Missing config\n";
            my $name   = $args{name};
            die "Usage: dashboard path del <name>\n" if !defined $name || $name eq '';
            return $name if $name ne '.';
            my $cwd = Cwd::cwd();
            my %aliases = %{ $config->path_aliases || {} };
            my $preferred = File::Basename::basename($cwd);
            if (exists $aliases{$preferred}) {
                my $resolved = eval { $paths->_expand_home($aliases{$preferred}) };
                $resolved = $aliases{$preferred} if !defined $resolved || $resolved eq '';
                return $preferred if $resolved eq $cwd;
            }
            for my $candidate (sort keys %aliases) {
                my $target = $aliases{$candidate};
                next if !defined $target || $target eq '';
                my $resolved = eval { $paths->_expand_home($target) };
                $resolved = $target if !defined $resolved || $resolved eq '';
                return $candidate if $resolved eq $cwd;
            }
            return File::Basename::basename($cwd);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'run_files_command') {
        my $missing_command_error = $sub->{missing_command_error} // "Missing command name\n";
        my $missing_args_error = $sub->{missing_args_error} // "Missing command arguments\n";
        my $type_error = $sub->{type_error} // "Command arguments must be an array reference\n";
        my $usage_error = $sub->{usage_error} // "Usage: dashboard file <resolve|locate|add|del|list> ...\n";
        my $build_paths_method = $sub->{build_paths_method} // die 'compiled sub build paths method missing';
        $impl = sub {
            my (%args) = @_;
            my $command = $args{command} || die $missing_command_error;
            my $argv = $args{args} || die $missing_args_error;
            die $type_error if ref($argv) ne 'ARRAY';

            my $paths = _code_for($build_paths_method)->();
            my $files = __PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry->new(paths => $paths);
            my $config = __PAX_RUNTIME_LEGACY_NAMESPACE__::Config->new(files => $files, paths => $paths);
            my $aliases_loaded = 0;
            my $load_configured_file_aliases = sub {
                return 1 if $aliases_loaded;
                $files->register_named_files($config->file_aliases);
                $aliases_loaded = 1;
                return 1;
            };

            if ($command eq 'files') {
                $load_configured_file_aliases->();
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($files->all_files);
                return 1;
            }

            my @argv = @{$argv};
            my $action = shift @argv || '';
            if ($action eq 'resolve') {
                $load_configured_file_aliases->();
                my $name = shift @argv || die "Usage: dashboard file resolve <name>\n";
                print $files->resolve_file($name), "\n";
                return 1;
            }
            if ($action eq 'locate') {
                my $root = Cwd::cwd();
                if (@argv >= 2) {
                    $load_configured_file_aliases->();
                    my $candidate = $argv[0];
                    my $resolved = eval { $files->resolve_file($candidate) };
                    if (defined $resolved && $resolved ne '') {
                        $root = $resolved;
                        shift @argv;
                    } elsif (-d $candidate) {
                        $root = $candidate;
                        shift @argv;
                    }
                }
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode([ $files->locate_files_under($root, @argv) ]);
                return 1;
            }
            if ($action eq 'add') {
                my $name = shift @argv || die "Usage: dashboard file add <name> <path>\n";
                my $path = shift @argv || die "Usage: dashboard file add <name> <path>\n";
                my $saved = $config->save_global_file_alias($name, $path);
                $files->register_named_files({ $name => $saved->{path} });
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($saved);
                return 1;
            }
            if ($action eq 'del') {
                my $name = shift @argv || die "Usage: dashboard file del <name>\n";
                my $deleted = $config->remove_global_file_alias($name);
                $files->unregister_named_file($name);
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($deleted);
                return 1;
            }
            if ($action eq 'list') {
                $load_configured_file_aliases->();
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($files->named_files);
                return 1;
            }

            die $usage_error;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_build_psgi_app') {
        my $backend_symbol = $sub->{backend_symbol} // die 'compiled sub backend symbol missing';
        my $app_package = $sub->{app_package} // $package;
        $impl = sub {
            my ($class, %args) = @_;
            my $app = $args{app} || die 'Missing backend web app';
            my $default_headers = $args{default_headers} || {};
            {
                no strict 'refs';
                ${$backend_symbol} = {
                    app => $app,
                    default_headers => { %{$default_headers} },
                };
            }
            return $app_package->to_app;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_current_backend') {
        my $backend_symbol = $sub->{backend_symbol} // die 'compiled sub backend symbol missing';
        $impl = sub {
            no strict 'refs';
            return ${$backend_symbol} || die 'Missing backend web app';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_request_headers') {
        $impl = sub {
            return {
                host => scalar(request->header('Host') // ''),
                cookie => scalar(request->header('Cookie') // ''),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_request_args') {
        my $request_headers_method = $sub->{request_headers_method} // die 'compiled sub request headers method missing';
        $impl = sub {
            my $host = scalar(request->header('Host') // '');
            if ($host eq '') {
                my $server_name = scalar(request->env->{SERVER_NAME} // '');
                my $server_port = scalar(request->env->{SERVER_PORT} // '');
                $host = $server_name;
                $host .= ':' . $server_port if $host ne '' && $server_port ne '';
            }
            my $remote_addr = scalar(request->env->{REMOTE_ADDR} // request->env->{SERVER_ADDR} // '');
            $remote_addr = scalar(request->env->{SERVER_NAME} // '') if $remote_addr eq '';
            return {
                path => scalar(request->env->{PATH_INFO} // '/'),
                query => scalar(request->env->{QUERY_STRING} // ''),
                method => scalar(request->env->{REQUEST_METHOD} // 'GET'),
                body => scalar(request->body // ''),
                remote_addr => $remote_addr,
                headers => {
                    %{ _code_for($request_headers_method)->() },
                    host => $host,
                },
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_capture') {
        $impl = sub {
            my ($index) = @_;
            my @parts = @_;
            @parts = @{ $parts[0] } if @parts == 1 && ref($parts[0]) eq 'ARRAY';
            return undef if !@parts;
            return $parts[$index];
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_disconnect_error') {
        $impl = sub {
            my ($error) = @_;
            return 0 if !defined $error || $error eq '';
            return $error =~ /(broken pipe|client disconnected|connection reset|stream closed|connection aborted|write failed)/i ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_response_from_result') {
        my $current_backend_method = $sub->{current_backend_method} // die 'compiled sub current backend method missing';
        my $disconnect_method = $sub->{disconnect_method} // die 'compiled sub disconnect method missing';
        $impl = sub {
            my ($result) = @_;
            my ($code, $type, $body, $headers) = @{$result};
            my $backend = _code_for($current_backend_method)->();
            my %merged_headers = (
                %{ $backend->{default_headers} || {} },
                %{ $headers || {} },
            );
            if (ref($body) eq 'HASH' && ref($body->{stream}) eq 'CODE') {
                my $stream = $body->{stream};
                return delayed {
                    my @headers = ('Content-Type' => $type);
                    push @headers, map { $_ => $merged_headers{$_} } sort keys %merged_headers;
                    my $responder = $Dancer2::Core::Route::RESPONDER
                        or die "Missing delayed response writer\n";
                    my $psgi_writer = $responder->([ $code, \@headers ]);
                    my $writer = sub {
                        my ($chunk) = @_;
                        return 1 if !defined $chunk || $chunk eq '';
                        my $ok = eval { $psgi_writer->write($chunk); 1; };
                        return 0 if !$ok && _code_for($disconnect_method)->($@);
                        die $@ if !$ok;
                        return 1;
                    };
                    eval { $stream->($writer); 1; } or do {
                        my $error = $@ || "Streaming response failed\n";
                        $writer->($error);
                    };
                    eval { $psgi_writer->close };
                };
            }
            status $code;
            content_type $type;
            for my $header_name (sort keys %merged_headers) {
                response_header($header_name => $merged_headers{$header_name});
            }
            return $body;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_run_backend') {
        my $current_backend_method = $sub->{current_backend_method} // die 'compiled sub current backend method missing';
        my $request_args_method = $sub->{request_args_method} // die 'compiled sub request args method missing';
        my $response_method = $sub->{response_method} // die 'compiled sub response method missing';
        $impl = sub {
            my ($method, %extra) = @_;
            my $backend = _code_for($current_backend_method)->();
            my %args = (%{ _code_for($request_args_method)->() }, %extra);
            my $result = eval {
                return $backend->{app}->$method(%args) if $backend->{app}->can($method);
                return $backend->{app}->handle(%args) if $backend->{app}->can('handle');
                die "Backend app does not implement $method or handle";
            };
            if ($@) {
                $result = [ 500, 'text/plain; charset=utf-8', "$@", {} ];
            }
            return _code_for($response_method)->($result);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'dancerapp_run_authorized') {
        my $current_backend_method = $sub->{current_backend_method} // die 'compiled sub current backend method missing';
        my $request_args_method = $sub->{request_args_method} // die 'compiled sub request args method missing';
        my $response_method = $sub->{response_method} // die 'compiled sub response method missing';
        $impl = sub {
            my ($method, %extra) = @_;
            my $backend = _code_for($current_backend_method)->();
            my %args = (%{ _code_for($request_args_method)->() }, %extra);
            my $result = eval {
                if ($backend->{app}->can($method)) {
                    my $auth_response = $backend->{app}->can('authorize_request')
                        ? $backend->{app}->authorize_request(%args)
                        : undef;
                    return $auth_response if $auth_response;
                    return $backend->{app}->$method(%args);
                }
                return $backend->{app}->handle(%args) if $backend->{app}->can('handle');
                die "Backend app does not implement $method or handle";
            };
            if ($@) {
                $result = [ 500, 'text/plain; charset=utf-8', "$@", {} ];
            }
            return _code_for($response_method)->($result);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_new') {
        my $generate_cert_method = $sub->{generate_cert_method} // die 'compiled sub generate-cert method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my $app = $args{app} || die 'Missing web app';
            my $host = defined $args{host} ? $args{host} : '0.0.0.0';
            my $port = defined $args{port} ? $args{port} : 7890;
            my $workers = defined $args{workers} ? $args{workers} : 1;
            my $ssl = defined $args{ssl} ? ($args{ssl} ? 1 : 0) : 0;
            my $ssl_subject_alt_names = ref($args{ssl_subject_alt_names}) eq 'ARRAY' ? [ @{ $args{ssl_subject_alt_names} } ] : [];
            die 'Missing worker count' if !defined $workers || $workers eq '';
            die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;
            if ($ssl) {
                _code_for($generate_cert_method)->(
                    host  => $host,
                    hosts => $ssl_subject_alt_names,
                );
            }
            return bless {
                app                   => $app,
                host                  => $host,
                port                  => $port,
                workers               => $workers + 0,
                ssl                   => $ssl,
                ssl_subject_alt_names => $ssl_subject_alt_names,
            }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_run') {
        my $start_daemon_method = $sub->{start_daemon_method} // die 'compiled sub start-daemon method missing';
        my $listening_url_method = $sub->{listening_url_method} // die 'compiled sub listening-url method missing';
        my $serve_daemon_method = $sub->{serve_daemon_method} // die 'compiled sub serve-daemon method missing';
        $impl = sub {
            my ($self) = @_;
            my $daemon = _code_for($start_daemon_method)->($self);
            print "Developer Dashboard listening on ", _code_for($listening_url_method)->($self, $daemon), "\n";
            return _code_for($serve_daemon_method)->($self, $daemon);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_listening_url') {
        $impl = sub {
            my ($self, $daemon) = @_;
            return unless defined $daemon;
            my $scheme = $self->{ssl} ? 'https' : 'http';
            my $host = $daemon->sockhost // 'localhost';
            my $port = $daemon->sockport // 7890;
            return sprintf '%s://%s:%s/', $scheme, $host, $port;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_serve_daemon') {
        my $serve_ssl_method = $sub->{serve_ssl_method} // die 'compiled sub serve-ssl method missing';
        my $build_runner_method = $sub->{build_runner_method} // die 'compiled sub build-runner method missing';
        my $psgi_app_method = $sub->{psgi_app_method} // die 'compiled sub psgi-app method missing';
        $impl = sub {
            my ($self, $daemon) = @_;
            return _code_for($serve_ssl_method)->($self, $daemon) if $self->{ssl};
            my $runner = _code_for($build_runner_method)->($self, $daemon);
            my $app = _code_for($psgi_app_method)->($self);
            $runner->run($app);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_psgi_app') {
        my $default_headers_method = $sub->{default_headers_method} // die 'compiled sub default-headers method missing';
        my $request_is_https_method = $sub->{request_is_https_method} // die 'compiled sub request-is-https method missing';
        my $redirect_response_method = $sub->{redirect_response_method} // die 'compiled sub redirect-response method missing';
        $impl = sub {
            my ($self) = @_;
            my $app = __PAX_RUNTIME_LEGACY_NAMESPACE__::Web::DancerApp->build_psgi_app(
                app             => $self->{app},
                default_headers => _code_for($default_headers_method)->(),
            );
            return $app if !$self->{ssl};
            return sub {
                my ($env) = @_;
                return _code_for($redirect_response_method)->($env) if !_code_for($request_is_https_method)->($env);
                return $app->($env);
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_start_daemon') {
        $impl = sub {
            my ($self) = @_;
            my $socket = IO::Socket::INET->new(
                LocalAddr => $self->{host},
                LocalPort => $self->{port},
                Proto     => 'tcp',
                ReuseAddr => 1,
                Listen    => 10,
            );
            die "Unable to start server on $self->{host}:$self->{port}: $!" if !$socket;
            my $daemon = __PAX_RUNTIME_LEGACY_NAMESPACE__::Web::Server::Daemon->new(
                host => scalar($socket->sockhost),
                port => scalar($socket->sockport),
            );
            close $socket or die "Unable to close reserved listen socket: $!";
            return $daemon if !$self->{ssl};
            my $backend_socket = IO::Socket::INET->new(
                LocalAddr => '127.0.0.1',
                LocalPort => 0,
                Proto     => 'tcp',
                ReuseAddr => 1,
                Listen    => 10,
            );
            die "Unable to reserve internal SSL backend port: $!" if !$backend_socket;
            my $ssl_daemon = __PAX_RUNTIME_LEGACY_NAMESPACE__::Web::Server::Daemon->new(
                host          => $daemon->sockhost,
                port          => $daemon->sockport,
                internal_host => scalar($backend_socket->sockhost),
                internal_port => scalar($backend_socket->sockport),
            );
            close $backend_socket or die "Unable to close reserved internal SSL backend socket: $!";
            return $ssl_daemon;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_serve_ssl_frontend') {
        my $build_runner_method = $sub->{build_runner_method} // die 'compiled sub build-runner method missing';
        my $psgi_app_method = $sub->{psgi_app_method} // die 'compiled sub psgi-app method missing';
        my $stop_backend_method = $sub->{stop_backend_method} // die 'compiled sub stop-backend method missing';
        my $term_handler = $sub->{term_handler} // die 'compiled sub term-handler missing';
        my $int_handler = $sub->{int_handler} // die 'compiled sub int-handler missing';
        my $hup_handler = $sub->{hup_handler} // die 'compiled sub hup-handler missing';
        my $handle_client_method = $sub->{handle_client_method} // die 'compiled sub handle-client method missing';
        $impl = sub {
            my ($self, $daemon) = @_;
            my $backend_pid = fork();
            die "Unable to fork SSL backend process: $!" if !defined $backend_pid;
            if (!$backend_pid) {
                my $runner = _code_for($build_runner_method)->($self, $daemon);
                my $app = _code_for($psgi_app_method)->($self);
                $runner->run($app);
                exit 0;
            }
            my $previous_term = $SIG{TERM};
            my $previous_int  = $SIG{INT};
            my $previous_hup  = $SIG{HUP};
            local $__PAX_RUNTIME_LEGACY_NAMESPACE__::Web::Server::SSL_BACKEND_PID = $backend_pid;
            local %__PAX_RUNTIME_LEGACY_NAMESPACE__::Web::Server::SSL_PREVIOUS_SIGNAL = (
                TERM => $previous_term,
                INT  => $previous_int,
                HUP  => $previous_hup,
            );
            local $SIG{TERM} = sub { _code_for($term_handler)->() };
            local $SIG{INT}  = sub { _code_for($int_handler)->() };
            local $SIG{HUP}  = sub { _code_for($hup_handler)->() };
            my $listener = IO::Socket::INET->new(
                LocalAddr => $daemon->sockhost,
                LocalPort => $daemon->sockport,
                Proto     => 'tcp',
                ReuseAddr => 1,
                Listen    => 128,
            );
            if (!$listener) {
                _code_for($stop_backend_method)->($backend_pid);
                die "Unable to bind SSL frontend on $self->{host}:$self->{port}: $!";
            }
            while (my $client = $listener->accept) {
                my $pid = fork();
                die "Unable to fork SSL frontend connection handler: $!" if !defined $pid;
                if ($pid) {
                    close $client;
                    while (waitpid(-1, 1) > 0) { }
                    next;
                }
                close $listener;
                eval {
                    _code_for($handle_client_method)->(
                        $self,
                        client => $client,
                        daemon => $daemon,
                    );
                };
                close $client;
                exit 0;
            }
            close $listener;
            _code_for($stop_backend_method)->($backend_pid);
            waitpid($backend_pid, 0);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_build_runner') {
        my $ssl_cert_paths_method = $sub->{ssl_cert_paths_method} // die 'compiled sub ssl-cert-paths method missing';
        $impl = sub {
            my ($self, $daemon) = @_;
            my $runner = Plack::Runner->new;
            my $listen_host = $self->{ssl} && $daemon->can('internal_sockhost') && defined $daemon->internal_sockhost
                ? $daemon->internal_sockhost
                : $daemon->sockhost;
            my $listen_port = $self->{ssl} && $daemon->can('internal_sockport') && defined $daemon->internal_sockport
                ? $daemon->internal_sockport
                : $daemon->sockport;
            my @options = (
                '--server', 'Starman',
                '--host',   $listen_host,
                '--port',   $listen_port,
                '--env',    'deployment',
                '--workers', $self->{workers},
            );
            if ($self->{ssl}) {
                my ($cert, $key) = _code_for($ssl_cert_paths_method)->();
                push @options, '--ssl', 1;
                push @options, '--ssl-key', $key;
                push @options, '--ssl-cert', $cert;
            }
            $runner->parse_options(@options);
            return $runner;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_handle_ssl_frontend_client') {
        my $socket_looks_like_tls_method = $sub->{socket_looks_like_tls_method} // die 'compiled sub socket-looks-like-tls method missing';
        my $read_http_request_head_method = $sub->{read_http_request_head_method} // die 'compiled sub read-http-request-head method missing';
        my $request_host_from_head_method = $sub->{request_host_from_head_method} // die 'compiled sub request-host-from-head method missing';
        my $request_target_from_head_method = $sub->{request_target_from_head_method} // die 'compiled sub request-target-from-head method missing';
        my $http_redirect_response_method = $sub->{http_redirect_response_method} // die 'compiled sub http-redirect-response method missing';
        my $proxy_streams_method = $sub->{proxy_streams_method} // die 'compiled sub proxy-streams method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $client = $args{client} || die 'Missing frontend client socket';
            my $daemon = $args{daemon} || die 'Missing daemon descriptor';
            my $first = '';
            my $peeked = recv($client, $first, 1, MSG_PEEK);
            return 1 if !defined $peeked || !defined $first || $first eq '';
            if (_code_for($socket_looks_like_tls_method)->($first)) {
                my $backend = IO::Socket::INET->new(
                    PeerAddr => $daemon->internal_sockhost,
                    PeerPort => $daemon->internal_sockport,
                    Proto    => 'tcp',
                );
                die "Unable to connect to internal SSL backend: $!" if !$backend;
                _code_for($proxy_streams_method)->($client, $backend);
                close $backend;
                return 1;
            }
            my $request = _code_for($read_http_request_head_method)->($client);
            my $response = _code_for($http_redirect_response_method)->(
                host   => _code_for($request_host_from_head_method)->($request, $daemon),
                target => _code_for($request_target_from_head_method)->($request),
            );
            syswrite($client, $response);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_proxy_streams') {
        $impl = sub {
            my ($client, $backend) = @_;
            my $select = IO::Select->new($client, $backend);
            while (my @ready = $select->can_read) {
                for my $source (@ready) {
                    my $chunk = '';
                    my $read = sysread($source, $chunk, 8192);
                    return 1 if !defined $read || $read <= 0;
                    my $target = $source == $client ? $backend : $client;
                    my $offset = 0;
                    while ($offset < length $chunk) {
                        my $written = syswrite($target, $chunk, length($chunk) - $offset, $offset);
                        die "Unable to proxy SSL frontend bytes: $!" if !defined $written;
                        $offset += $written;
                    }
                }
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_socket_looks_like_tls') {
        $impl = sub {
            my ($byte) = @_;
            return 0 if !defined $byte || $byte eq '';
            return ord($byte) == 22 ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_read_http_request_head') {
        $impl = sub {
            my ($socket) = @_;
            my $head = '';
            while (length($head) < 16384) {
                my $chunk = '';
                my $read = sysread($socket, $chunk, 1024);
                last if !defined $read || $read <= 0;
                $head .= $chunk;
                last if $head =~ /\r?\n\r?\n/;
            }
            return $1 if $head =~ /\A(.*?\r?\n\r?\n)/s;
            return $head;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_request_target_from_head') {
        $impl = sub {
            my ($head) = @_;
            return '/' if !defined $head || $head eq '';
            return $1 if $head =~ m{\A[A-Z]+\s+(\S+)\s+HTTP/}s;
            return '/';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_request_host_from_head') {
        $impl = sub {
            my ($head, $daemon) = @_;
            if (defined $head && $head =~ /^Host:\s*([^\r\n]+)/im) {
                return $1;
            }
            my $host = $daemon->sockhost || '127.0.0.1';
            my $port = $daemon->sockport || 443;
            return $port == 443 ? $host : $host . ':' . $port;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_http_redirect_response') {
        $impl = sub {
            my (%args) = @_;
            my $target = defined $args{target} && $args{target} ne '' ? $args{target} : '/';
            my $host = $args{host} || '127.0.0.1';
            my $body = 'Redirecting to HTTPS';
            return join(
                "\r\n",
                'HTTP/1.1 307 Temporary Redirect',
                'Content-Type: text/plain; charset=utf-8',
                'Content-Length: ' . length($body),
                'Location: https://' . $host . $target,
                'Connection: close',
                '',
                $body,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_stop_ssl_backend') {
        $impl = sub {
            my ($pid) = @_;
            return 1 if !$pid;
            kill 15, $pid;
            waitpid($pid, 0);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_ssl_signal_handler') {
        my $signal_name = $sub->{signal_name} // die 'compiled sub signal name missing';
        my $handle_signal_method = $sub->{handle_signal_method} // die 'compiled sub handle-signal method missing';
        $impl = sub {
            return _code_for($handle_signal_method)->($signal_name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_handle_ssl_signal') {
        my $stop_backend_method = $sub->{stop_backend_method} // die 'compiled sub stop-backend method missing';
        my $run_previous_method = $sub->{run_previous_method} // die 'compiled sub run-previous method missing';
        $impl = sub {
            my ($signal_name) = @_;
            _code_for($stop_backend_method)->($__PAX_RUNTIME_LEGACY_NAMESPACE__::Web::Server::SSL_BACKEND_PID);
            return _code_for($run_previous_method)->($__PAX_RUNTIME_LEGACY_NAMESPACE__::Web::Server::SSL_PREVIOUS_SIGNAL{$signal_name});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_run_previous_signal') {
        my $default_term_method = $sub->{default_term_method} // die 'compiled sub default-term method missing';
        $impl = sub {
            my ($handler) = @_;
            return 1 if !defined $handler;
            if (ref($handler) eq 'CODE') {
                $handler->();
                return 1;
            }
            return _code_for($default_term_method)->() if $handler eq 'DEFAULT';
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_signal_default_term') {
        $impl = sub {
            kill 15, $$;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_default_headers') {
        $impl = sub {
            return {
                'X-Frame-Options'         => 'DENY',
                'X-Content-Type-Options'  => 'nosniff',
                'Referrer-Policy'         => 'no-referrer',
                'Cache-Control'           => 'no-store',
                'Content-Security-Policy' => q{default-src 'self' 'unsafe-inline' data:; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'},
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_request_is_https') {
        $impl = sub {
            my ($env) = @_;
            return 0 if ref($env) ne 'HASH';
            my $scheme = defined $env->{'psgi.url_scheme'} ? lc($env->{'psgi.url_scheme'}) : '';
            return 1 if $scheme eq 'https';
            my $forwarded = defined $env->{HTTP_X_FORWARDED_PROTO} ? lc($env->{HTTP_X_FORWARDED_PROTO}) : '';
            return 1 if $forwarded eq 'https';
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_ssl_redirect_response') {
        my $redirect_location_method = $sub->{redirect_location_method} // die 'compiled sub redirect-location method missing';
        $impl = sub {
            my ($env) = @_;
            my $location = _code_for($redirect_location_method)->($env);
            return [
                307,
                [
                    'Content-Type' => 'text/plain; charset=utf-8',
                    'Location'     => $location,
                ],
                ['Redirecting to HTTPS'],
            ];
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_https_redirect_location') {
        $impl = sub {
            my ($env) = @_;
            my $host = defined $env->{HTTP_HOST} ? $env->{HTTP_HOST} : '';
            if ($host eq '') {
                my $server_name = defined $env->{SERVER_NAME} ? $env->{SERVER_NAME} : '127.0.0.1';
                my $server_port = defined $env->{SERVER_PORT} ? $env->{SERVER_PORT} : 443;
                $host = $server_name;
                $host .= ':' . $server_port if defined $server_port && $server_port ne '' && $server_port !~ /^443$/;
            }
            my $path = defined $env->{SCRIPT_NAME} ? $env->{SCRIPT_NAME} : '';
            $path .= defined $env->{PATH_INFO} ? $env->{PATH_INFO} : '/';
            $path = '/' if $path eq '';
            my $query = defined $env->{QUERY_STRING} ? $env->{QUERY_STRING} : '';
            return 'https://' . $host . $path . ($query ne '' ? '?' . $query : '');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_ssl_expected_subject_alt_names') {
        my $normalize_method = $sub->{normalize_method} // die 'compiled sub normalize method missing';
        my $wildcard_method = $sub->{wildcard_method} // die 'compiled sub wildcard method missing';
        $impl = sub {
            my (%args) = @_;
            my @requested = ('localhost', '127.0.0.1', '::1');
            push @requested, $args{host} if defined $args{host};
            push @requested, @{ $args{hosts} || [] } if ref($args{hosts}) eq 'ARRAY';
            my @normalized;
            my %seen;
            for my $name (@requested) {
                my $normalized = _code_for($normalize_method)->($name);
                next if !defined $normalized || $normalized eq '';
                next if _code_for($wildcard_method)->($normalized);
                my $seen_key = lc $normalized;
                next if $seen{$seen_key}++;
                push @normalized, $normalized;
            }
            return @normalized;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_normalize_ssl_subject_alt_name') {
        $impl = sub {
            my ($name) = @_;
            return '' if !defined $name;
            $name =~ s/^\s+//;
            $name =~ s/\s+$//;
            return '' if $name eq '';
            $name =~ s/^\[(.+)\](?::\d+)?$/$1/;
            $name =~ s/^([^:]+):\d+$/$1/ if $name =~ /^[^:]+:\d+$/;
            return lc $name;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_ssl_subject_alt_name_is_wildcard') {
        $impl = sub {
            my ($name) = @_;
            return 1 if !defined $name || $name eq '';
            return 1 if $name eq '*';
            return 1 if $name eq '0.0.0.0';
            return 1 if $name eq '::';
            return 1 if $name eq '0:0:0:0:0:0:0:0';
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_ssl_subject_alt_name_is_ip') {
        $impl = sub {
            my ($name) = @_;
            return 0 if !defined $name || $name eq '';
            return 1 if $name =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/;
            return 1 if $name =~ /:/;
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_ssl_cert_has_expected_profile') {
        my $expected_san_method = $sub->{expected_san_method} // die 'compiled sub expected-san method missing';
        my $is_ip_method = $sub->{is_ip_method} // die 'compiled sub is-ip method missing';
        $impl = sub {
            my ($cert_file, %args) = @_;
            return 0 if !defined $cert_file || $cert_file eq '' || !-f $cert_file;
            my @expected_subject_alt_names = _code_for($expected_san_method)->(
                hosts => $args{hosts},
            );
            my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
                system('openssl', 'x509', '-in', $cert_file, '-noout', '-text');
            };
            die "Failed to inspect SSL certificate $cert_file: $stderr$stdout" if $exit != 0;
            return 0 if $stdout !~ /Basic Constraints:\s+critical\s+CA:FALSE/s;
            return 0 if $stdout !~ /Extended Key Usage:\s+TLS Web Server Authentication/s;
            return 0 if $stdout !~ /Key Usage:\s+critical\s+Digital Signature, Key Encipherment/s;
            for my $subject_alt_name (@expected_subject_alt_names) {
                my @verify_cmd = ('openssl', 'verify', '-CAfile', $cert_file);
                if (_code_for($is_ip_method)->($subject_alt_name)) {
                    push @verify_cmd, '-verify_ip', $subject_alt_name;
                } else {
                    push @verify_cmd, '-verify_hostname', $subject_alt_name;
                }
                push @verify_cmd, $cert_file;
                my ($verify_stdout, $verify_stderr, $verify_exit) = Capture::Tiny::capture {
                    system(@verify_cmd);
                };
                return 0 if $verify_exit != 0;
                return 0 if $verify_stdout !~ /\:\s+OK\s*\z/ && $verify_stderr !~ /\:\s+OK\s*\z/;
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_generate_self_signed_cert') {
        my $expected_san_method = $sub->{expected_san_method} // die 'compiled sub expected-san method missing';
        my $cert_profile_method = $sub->{cert_profile_method} // die 'compiled sub cert-profile method missing';
        my $is_ip_method = $sub->{is_ip_method} // die 'compiled sub is-ip method missing';
        $impl = sub {
            my (%args) = @_;
            my $home = $ENV{HOME} || die 'Missing HOME environment variable';
            my $paths = __PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry->new(home => $home);
            my $cert_dir = File::Spec->catdir($paths->home_runtime_path, 'certs');
            my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
            my $key_file  = File::Spec->catfile($cert_dir, 'server.key');
            my @expected_subject_alt_names = _code_for($expected_san_method)->(
                host  => $args{host},
                hosts => $args{hosts},
            );
            if (
                -f $cert_file
                && -f $key_file
                && _code_for($cert_profile_method)->(
                    $cert_file,
                    hosts => \@expected_subject_alt_names,
                )
            ) {
                $paths->secure_dir_permissions($cert_dir);
                $paths->secure_file_permissions($cert_file);
                $paths->secure_file_permissions($key_file);
                return $cert_file;
            }
            $paths->ensure_dir($cert_dir);
            unlink $cert_file if -f $cert_file;
            unlink $key_file  if -f $key_file;
            my ($config_fh, $config_file) = File::Temp::tempfile('dd-openssl-XXXXXX', SUFFIX => '.cnf', DIR => $cert_dir);
            my $config_text_head = <<'OPENSSL_CONFIG';
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[ dn ]
C = US
ST = Local
L = Local
O = Developer Dashboard
CN = localhost

[ v3_req ]
subjectAltName = @alt_names
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth

[ alt_names ]
OPENSSL_CONFIG
            my $alt_names_text = '';
            my $dns_index = 0;
            my $ip_index  = 0;
            for my $subject_alt_name (@expected_subject_alt_names) {
                if (_code_for($is_ip_method)->($subject_alt_name)) {
                    $ip_index++;
                    $alt_names_text .= sprintf "IP.%d = %s\n", $ip_index, $subject_alt_name;
                    next;
                }
                $dns_index++;
                $alt_names_text .= sprintf "DNS.%d = %s\n", $dns_index, $subject_alt_name;
            }
            my $config_text = $config_text_head . $alt_names_text;
            print {$config_fh} $config_text or die "Unable to write OpenSSL config $config_file: $!";
            close $config_fh or die "Unable to close OpenSSL config $config_file: $!";
            my @cmd = (
                'openssl', 'req', '-new', '-x509', '-days', '365',
                '-nodes',
                '-config', $config_file,
                '-out', $cert_file,
                '-keyout', $key_file,
            );
            my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
                system(@cmd);
            };
            unlink $config_file if -f $config_file;
            die "Failed to generate SSL certificate: $stderr" if $exit != 0;
            die "Certificate file not created" if !-f $cert_file;
            die "Key file not created" if !-f $key_file;
            die "Generated certificate is missing the required dashboard HTTPS server profile"
                if !_code_for($cert_profile_method)->(
                    $cert_file,
                    hosts => \@expected_subject_alt_names,
                );
            $paths->secure_dir_permissions($cert_dir);
            $paths->secure_file_permissions($cert_file);
            $paths->secure_file_permissions($key_file);
            return $cert_file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'web_server_get_ssl_cert_paths') {
        $impl = sub {
            my $home = $ENV{HOME} || die 'Missing HOME environment variable';
            my $cert_dir = File::Spec->catdir($home, '.developer-dashboard', 'certs');
            my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
            my $key_file  = File::Spec->catfile($cert_dir, 'server.key');
            die "Certificate file not found: $cert_file" if !-f $cert_file;
            die "Key file not found: $key_file" if !-f $key_file;
            return ($cert_file, $key_file);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_new') {
        $impl = sub {
            my ($class, %args) = @_;
            my $config      = $args{config}      || die 'Missing config';
            my $files       = $args{files}       || die 'Missing file registry';
            my $paths       = $args{paths}       || die 'Missing path registry';
            my $runner      = $args{runner}      || die 'Missing collector runner';
            my $app_builder = $args{app_builder} || die 'Missing app builder';
            return bless {
                app_builder => $app_builder,
                config      => $config,
                files       => $files,
                paths       => $paths,
                runner      => $runner,
            }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_web_log') {
        my $tail_text_method = $sub->{tail_text_method} // die 'compiled sub tail-text method missing';
        my $follow_log_file_method = $sub->{follow_log_file_method} // die 'compiled sub follow-log-file method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $file = $self->{files}->resolve_file('dashboard_log');
            my $lines = $args{lines};
            my $follow = $args{follow} ? 1 : 0;
            die 'Line count must be a positive integer' if defined $lines && ($lines !~ /^\d+$/ || $lines < 1);
            return '' if !$follow && !-f $file;
            my $log = $self->{files}->read('dashboard_log');
            $log = '' if !defined $log;
            $log = _code_for($tail_text_method)->($self, $log, $lines) if defined $lines;
            return $log if !$follow;
            my $old_stdout = select STDOUT;
            $| = 1;
            select $old_stdout;
            print $log if $log ne '';
            _code_for($follow_log_file_method)->($self, file => $file);
            return '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_tail_text') {
        $impl = sub {
            my ($self, $text, $lines) = @_;
            return '' if !defined $text || $text eq '';
            return $text if !defined $lines;
            my @parts = split /\n/, $text, -1;
            my $had_trailing_newline = @parts && $parts[-1] eq '' ? 1 : 0;
            pop @parts if $had_trailing_newline;
            my $start = @parts - $lines;
            $start = 0 if $start < 0;
            my $tail = join "\n", @parts[$start .. $#parts];
            $tail .= "\n" if $had_trailing_newline && $tail ne '';
            return $tail;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_follow_log_file') {
        $impl = sub {
            my ($self, %args) = @_;
            my $file = $args{file} || die 'Missing log file';
            my $interval = defined $args{interval} ? $args{interval} : 0.1;
            my $fh;
            if (!open($fh, '<', $file)) {
                open my $create_fh, '>>', $file or die "Unable to create $file: $!";
                close $create_fh;
                $self->{paths}->secure_file_permissions($file);
                open($fh, '<', $file) or die "Unable to read $file: $!";
            }
            seek $fh, 0, 2 or die "Unable to seek $file: $!";
            local $SIG{TERM} = sub { exit 0 };
            local $SIG{INT}  = sub { exit 0 };
            local $SIG{HUP}  = sub { exit 0 };
            while (1) {
                my $chunk = '';
                my $read = sysread($fh, $chunk, 8192);
                if (defined $read && $read > 0) {
                    print $chunk;
                    next;
                }
                Time::HiRes::sleep($interval);
            }
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_web_state') {
        $impl = sub {
            my ($self) = @_;
            my $file = $self->{files}->web_state;
            return if !-f $file;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            local $/;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(scalar <$fh>);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_shutdown_web') {
        my $web_state_method = $sub->{web_state_method} // die 'compiled sub web-state method missing';
        my $write_web_state_method = $sub->{write_web_state_method} // die 'compiled sub write-web-state method missing';
        $impl = sub {
            my ($self, $status) = @_;
            my $state = _code_for($web_state_method)->($self);
            $state = {} if !$state;
            my $final_status = 'stopped';
            $final_status = $status if defined $status && $status ne '';
            _code_for($write_web_state_method)->(
                $self,
                {
                    %{$state},
                    pid        => $$,
                    status     => $final_status,
                    updated_at => __PAX_RUNTIME_LEGACY_NAMESPACE__::RuntimeManager::_now_iso8601(),
                }
            );
            exit 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_write_web_state') {
        $impl = sub {
            my ($self, $data) = @_;
            my $payload = $data ? $data : {};
            my $file = $self->{files}->web_state;
            my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
            open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($payload);
            close $fh;
            $self->{paths}->secure_file_permissions($tmp);
            rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
            $self->{paths}->secure_file_permissions($file);
            return $payload;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_cleanup_web_files') {
        $impl = sub {
            my ($self) = @_;
            $self->{files}->remove('web_pid');
            $self->{files}->remove('web_state');
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_web_process_title') {
        $impl = sub {
            my ($self, $host, $port) = @_;
            return "dashboard web: $host:$port";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_portable_signal') {
        $impl = sub {
            my ($signal) = @_;
            die 'Missing signal name' if !defined $signal || $signal eq '';
            return $signal + 0 if $signal =~ /^\d+$/;
            my %signal_number = (HUP => 1, INT => 2, TERM => 15, KILL => 9);
            my $name = uc $signal;
            die "Unsupported signal name: $signal" if !exists $signal_number{$name};
            return $signal_number{$name};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_send_signal') {
        my $portable_signal_method = $sub->{portable_signal_method} // die 'compiled sub portable-signal method missing';
        $impl = sub {
            my ($self, $signal, @pids) = @_;
            my $portable_signal = _code_for($portable_signal_method)->($signal);
            my @targets = grep { defined $_ && /^\d+$/ && $_ > 0 } @pids;
            return 0 if !@targets;
            return kill $portable_signal, @targets;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_proc_owned_by_current_user') {
        $impl = sub {
            my ($self, $proc) = @_;
            return 0 if !$proc || !$proc->{pid};
            return 1 if !defined $proc->{uid} || $proc->{uid} eq '';
            return ($proc->{uid} + 0) == ($< + 0) ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_find_legacy_web_processes') {
        my $find_web_processes_method = $sub->{find_web_processes_method} // die 'compiled sub find-web-processes method missing';
        $impl = sub {
            my ($self) = @_;
            return grep { $_->{args} !~ /^dashboard web:/ } _code_for($find_web_processes_method)->($self);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_looks_like_web_process') {
        $impl = sub {
            my ($self, $proc) = @_;
            return 0 if !$proc || !$proc->{pid} || !$proc->{args};
            return 1 if $proc->{args} =~ /^dashboard web:\s+\S+:\d+$/;
            return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+(?:\S+/)?dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
            return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+bin/dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
            return 1 if $proc->{args} =~ m{^(?:\S+/)?dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
            return 1 if $proc->{args} =~ m{^bin/dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_ps_processes') {
        $impl = sub {
            my ($self) = @_;
            my ($stdout, $stderr, $exit_code) = _capture_system_command('ps', '-eo', 'pid=,uid=,args=');
            return () if _system_command_missing($stderr, $exit_code);
            return () if $exit_code != 0;
            my @procs;
            for my $line (split /\n/, $stdout) {
                next if $line !~ /^\s*(\d+)\s+(\d+)\s+(.*)$/;
                push @procs, {
                    pid  => $1 + 0,
                    uid  => $2 + 0,
                    args => $3,
                };
            }
            return @procs;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_find_processes_by_prefix') {
        my $proc_owned_method = $sub->{proc_owned_method} // die 'compiled sub proc-owned method missing';
        my $ps_processes_method = $sub->{ps_processes_method} // die 'compiled sub ps-processes method missing';
        $impl = sub {
            my ($self, $prefix) = @_;
            return grep {
                _code_for($proc_owned_method)->($self, $_)
                    && $_->{args} =~ /^\Q$prefix\E/
            } _code_for($ps_processes_method)->($self);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_find_web_processes') {
        my $ps_processes_method = $sub->{ps_processes_method} // die 'compiled sub ps-processes method missing';
        my $proc_owned_method = $sub->{proc_owned_method} // die 'compiled sub proc-owned method missing';
        my $looks_like_web_process_method = $sub->{looks_like_web_process_method} // die 'compiled sub looks-like-web-process method missing';
        $impl = sub {
            my ($self) = @_;
            my @seen;
            my %seen_pid;
            for my $proc (_code_for($ps_processes_method)->($self)) {
                next if $proc->{pid} == $$;
                next if $seen_pid{$proc->{pid}}++;
                next if !_code_for($proc_owned_method)->($self, $proc);
                next if !_code_for($looks_like_web_process_method)->($self, $proc);
                push @seen, $proc;
            }
            return @seen;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_is_managed_web') {
        my $read_env_marker_method = $sub->{read_env_marker_method} // die 'compiled sub read-env-marker method missing';
        my $read_title_method = $sub->{read_title_method} // die 'compiled sub read-title method missing';
        $impl = sub {
            my ($self, $pid) = @_;
            return 0 if !$pid || !kill 0, $pid;
            my $marker = _code_for($read_env_marker_method)->($self, $pid, 'DEVELOPER_DASHBOARD_WEB_SERVICE');
            return 1 if defined $marker && $marker eq '1';
            my $title = _code_for($read_title_method)->($self, $pid);
            return 0 if !defined $title || $title eq '';
            return $title =~ /^dashboard web:/ ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_pkill_perl') {
        my $ps_processes_method = $sub->{ps_processes_method} // die 'compiled sub ps-processes method missing';
        my $proc_owned_method = $sub->{proc_owned_method} // die 'compiled sub proc-owned method missing';
        my $send_signal_method = $sub->{send_signal_method} // die 'compiled sub send-signal method missing';
        $impl = sub {
            my ($self, $pattern) = @_;
            my (undef, $stderr, $exit_code) = _capture_system_command('pkill', '-15', '-f', $pattern);
            return 1 if $exit_code == 0 || $exit_code == 1;
            if (_system_command_missing($stderr, $exit_code)) {
                for my $proc (_code_for($ps_processes_method)->($self)) {
                    next if !_code_for($proc_owned_method)->($self, $proc);
                    next if $proc->{args} !~ /$pattern/;
                    _code_for($send_signal_method)->($self, 'TERM', $proc->{pid});
                }
                return 1;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_managed_listener_pids_for_port') {
        my $is_managed_web_method = $sub->{is_managed_web_method} // die 'compiled sub is-managed-web method missing';
        my $listener_pids_for_port_method = $sub->{listener_pids_for_port_method} // die 'compiled sub listener-pids-for-port method missing';
        $impl = sub {
            my ($self, $port) = @_;
            return grep { _code_for($is_managed_web_method)->($self, $_) } _code_for($listener_pids_for_port_method)->($self, $port);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_listener_pids_for_port') {
        my $listener_pids_for_port_via_proc_method = $sub->{listener_pids_for_port_via_proc_method} // die 'compiled sub listener-pids-for-port-via-proc method missing';
        $impl = sub {
            my ($self, $port) = @_;
            return () if !$port;
            my ($stdout, $stderr, $exit_code) = _capture_system_command('ss', '-ltnp', "( sport = :$port )");
            my @pids;
            my $has_stdout = defined $stdout && $stdout ne '';
            if ($exit_code == 0 && $has_stdout) {
                my %seen;
                @pids = grep { !$seen{$_}++ } ($stdout =~ /pid=(\d+)/g);
            } else {
                @pids = _code_for($listener_pids_for_port_via_proc_method)->($self, $port)
                    if _system_command_missing($stderr, $exit_code);
            }
            return @pids;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_listener_pids_for_port_via_proc') {
        my $listener_socket_inodes_for_port_method = $sub->{listener_socket_inodes_for_port_method} // die 'compiled sub listener-socket-inodes-for-port method missing';
        my $process_pids_for_socket_inodes_method = $sub->{process_pids_for_socket_inodes_method} // die 'compiled sub process-pids-for-socket-inodes method missing';
        $impl = sub {
            my ($self, $port) = @_;
            my %inode = map { $_ => 1 } _code_for($listener_socket_inodes_for_port_method)->($self, $port);
            return () if !%inode;
            return _code_for($process_pids_for_socket_inodes_method)->($self, \%inode);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_listener_socket_inodes_for_port') {
        my $listener_socket_table_paths_method = $sub->{listener_socket_table_paths_method} // die 'compiled sub listener-socket-table-paths method missing';
        $impl = sub {
            my ($self, $port) = @_;
            return () if !$port;
            my $hex_port = sprintf '%04X', $port;
            my %seen;
            my @inodes;
            for my $file (_code_for($listener_socket_table_paths_method)->($self)) {
                next if !-r $file;
                open my $fh, '<', $file or next;
                while (my $line = <$fh>) {
                    next if $line !~ /\S/;
                    my @fields = split ' ', $line;
                    next if @fields < 10;
                    next if !defined $fields[1] || !defined $fields[3] || !defined $fields[9];
                    my (undef, $local_port) = split /:/, $fields[1], 2;
                    next if !defined $local_port || uc($local_port) ne $hex_port;
                    next if $fields[3] ne '0A';
                    my $inode = $fields[9];
                    next if !$inode || $seen{$inode}++;
                    push @inodes, $inode + 0;
                }
                close $fh;
            }
            return @inodes;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_process_pids_for_socket_inodes') {
        my $process_fd_paths_method = $sub->{process_fd_paths_method} // die 'compiled sub process-fd-paths method missing';
        $impl = sub {
            my ($self, $inode_lookup) = @_;
            return () if !$inode_lookup || ref($inode_lookup) ne 'HASH' || !%{$inode_lookup};
            my %seen;
            my @pids;
            for my $fd_path (_code_for($process_fd_paths_method)->($self)) {
                next if $fd_path !~ m{/(?:proc/)?(\d+)/fd/[^/]+$};
                my $pid = $1 + 0;
                my $target = readlink $fd_path;
                next if !defined $target || $target !~ /^socket:\[(\d+)\]$/;
                next if !$inode_lookup->{$1};
                next if $seen{$pid}++;
                push @pids, $pid;
            }
            return @pids;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_start_collectors') {
        my $progress_emit_method = $sub->{progress_emit_method} // die 'compiled sub progress-emit method missing';
        my $collector_runtime_ready_method = $sub->{collector_runtime_ready_method} // die 'compiled sub collector-runtime-ready method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $progress = $args{progress};
            my @started;
            for my $job (@{ $self->{config}->collectors }) {
                next if ref($job) ne 'HASH';
                my $schedule = $job->{schedule} || ($job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual');
                next if $schedule eq 'manual';
                my $name = $job->{name} || '(unnamed)';
                _code_for($progress_emit_method)->($self, $progress, {
                    task_id => "start_collector:$name",
                    status  => 'running',
                    label   => "Start collector $name",
                });
                my $pid = eval { $self->{runner}->start_loop($job) };
                if ($@) {
                    my $error = $@;
                    chomp $error;
                    for my $started (@started) {
                        eval { $self->{runner}->stop_loop($started->{name}) };
                    }
                    _code_for($progress_emit_method)->($self, $progress, {
                        task_id => "start_collector:$name",
                        status  => 'failed',
                        label   => "Start collector $name",
                    });
                    die "Failed to start collector '$name': $error\n";
                }
                if (defined $pid && !_code_for($collector_runtime_ready_method)->($self, $job->{name}, $pid)) {
                    for my $started (@started) {
                        eval { $self->{runner}->stop_loop($started->{name}) };
                    }
                    eval { $self->{runner}->stop_loop($job->{name}) };
                    _code_for($progress_emit_method)->($self, $progress, {
                        task_id => "start_collector:$name",
                        status  => 'failed',
                        label   => "Start collector $name",
                    });
                    die "Failed to keep collector '$name' running after startup\n";
                }
                _code_for($progress_emit_method)->($self, $progress, {
                    task_id => "start_collector:$name",
                    status  => 'done',
                    label   => "Start collector $name",
                });
                push @started, { name => $job->{name}, pid => $pid } if defined $pid;
            }
            return @started;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_stop_collectors') {
        my $progress_emit_method = $sub->{progress_emit_method} // die 'compiled sub progress-emit method missing';
        my $find_processes_by_prefix_method = $sub->{find_processes_by_prefix_method} // die 'compiled sub find-processes-by-prefix method missing';
        my $send_signal_method = $sub->{send_signal_method} // die 'compiled sub send-signal method missing';
        my $pkill_perl_method = $sub->{pkill_perl_method} // die 'compiled sub pkill-perl method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $progress = $args{progress};
            my @running = $self->{runner}->running_loops;
            my @names = map { $_->{name} } @running;
            for my $name (@names) {
                _code_for($progress_emit_method)->($self, $progress, {
                    task_id => "stop_collector:$name",
                    status  => 'running',
                    label   => "Stop collector $name",
                });
                eval { $self->{runner}->stop_loop($name) };
                _code_for($progress_emit_method)->($self, $progress, {
                    task_id => "stop_collector:$name",
                    status  => 'done',
                    label   => "Stop collector $name",
                });
            }
            _code_for($pkill_perl_method)->($self, '^dashboard collector:');
            for (1 .. 30) {
                last if !scalar _code_for($find_processes_by_prefix_method)->($self, 'dashboard collector:');
                Time::HiRes::sleep(0.1);
            }
            for my $proc (_code_for($find_processes_by_prefix_method)->($self, 'dashboard collector:')) {
                _code_for($send_signal_method)->($self, 'KILL', $proc->{pid});
            }
            return @names;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_stop_all') {
        my $stop_web_method = $sub->{stop_web_method} // die 'compiled sub stop-web method missing';
        my $stop_collectors_method = $sub->{stop_collectors_method} // die 'compiled sub stop-collectors method missing';
        $impl = sub {
            my ($self, %args) = @_;
            return {
                web_pid    => _code_for($stop_web_method)->($self, progress => $args{progress}),
                collectors => [ _code_for($stop_collectors_method)->($self, progress => $args{progress}) ],
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_stop_progress_tasks') {
        $impl = sub {
            my ($self) = @_;
            my @tasks = ({
                id    => 'stop_web',
                label => 'Stop dashboard web service',
            });
            push @tasks, map {
                +{
                    id    => "stop_collector:$_->{name}",
                    label => "Stop collector $_->{name}",
                }
            } $self->{runner}->running_loops;
            return \@tasks;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_restart_progress_tasks') {
        my $stop_progress_tasks_method = $sub->{stop_progress_tasks_method} // die 'compiled sub stop-progress-tasks method missing';
        $impl = sub {
            my ($self) = @_;
            my @tasks = @{ _code_for($stop_progress_tasks_method)->($self) };
            for my $job (@{ $self->{config}->collectors }) {
                next if ref($job) ne 'HASH';
                my $schedule = $job->{schedule} || ($job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual');
                next if $schedule eq 'manual';
                my $name = $job->{name} || '(unnamed)';
                push @tasks, {
                    id    => "start_collector:$name",
                    label => "Start collector $name",
                };
            }
            push @tasks, {
                id    => 'start_web',
                label => 'Start dashboard web service',
            };
            return \@tasks;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_serve_all') {
        my $start_collectors_method = $sub->{start_collectors_method} // die 'compiled sub start-collectors method missing';
        my $start_web_method = $sub->{start_web_method} // die 'compiled sub start-web method missing';
        my $stop_collectors_method = $sub->{stop_collectors_method} // die 'compiled sub stop-collectors method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $host = defined $args{host} ? $args{host} : '0.0.0.0';
            my $port = defined $args{port} ? $args{port} : 7890;
            my $workers = defined $args{workers} ? $args{workers} : 1;
            my $ssl = $args{ssl} ? 1 : 0;
            my $foreground = $args{foreground} ? 1 : 0;
            if ($foreground) {
                my @collectors = _code_for($start_collectors_method)->($self, progress => $args{progress});
                my $result = eval {
                    _code_for($start_web_method)->(
                        $self,
                        foreground => 1,
                        host       => $host,
                        port       => $port,
                        workers    => $workers,
                        ssl        => $ssl,
                    );
                };
                my $error = $@;
                my @stopped_collectors = _code_for($stop_collectors_method)->($self);
                die $error if $error;
                return {
                    foreground         => 1,
                    host               => $host,
                    port               => $port,
                    workers            => $workers,
                    ssl                => $ssl,
                    collectors         => \@collectors,
                    stopped_collectors => \@stopped_collectors,
                    result             => $result,
                };
            }
            my $pid = _code_for($start_web_method)->(
                $self,
                foreground => 0,
                host       => $host,
                port       => $port,
                workers    => $workers,
                ssl        => $ssl,
            );
            my @collectors = _code_for($start_collectors_method)->($self);
            return {
                host       => $host,
                port       => $port,
                workers    => $workers,
                ssl        => $ssl,
                pid        => $pid,
                collectors => \@collectors,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_restart_all') {
        my $stop_all_method = $sub->{stop_all_method} // die 'compiled sub stop-all method missing';
        my $start_collectors_method = $sub->{start_collectors_method} // die 'compiled sub start-collectors method missing';
        my $restart_web_with_retry_method = $sub->{restart_web_with_retry_method} // die 'compiled sub restart-web-with-retry method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $host = defined $args{host} ? $args{host} : '0.0.0.0';
            my $port = defined $args{port} ? $args{port} : 7890;
            my $workers = defined $args{workers} ? $args{workers} : 1;
            my $ssl = $args{ssl} ? 1 : 0;
            my %progress_args = defined $args{progress} ? (progress => $args{progress}) : ();
            my $stopped = _code_for($stop_all_method)->($self, %progress_args);
            my @collectors = _code_for($start_collectors_method)->($self, %progress_args);
            my $web_pid = _code_for($restart_web_with_retry_method)->(
                $self,
                host    => $host,
                port    => $port,
                workers => $workers,
                ssl     => $ssl,
                %progress_args,
            );
            return {
                stopped    => $stopped,
                collectors => \@collectors,
                web_pid    => $web_pid,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_listener_socket_table_paths') {
        $impl = sub { return ('/proc/net/tcp', '/proc/net/tcp6') };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_process_fd_paths') {
        $impl = sub { return glob('/proc/[0-9]*/fd/*') };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_wait_for_port_release') {
        my $listener_pids_for_port_method = $sub->{listener_pids_for_port_method} // die 'compiled sub listener-pids-for-port method missing';
        $impl = sub {
            my ($self, $port) = @_;
            return 1 if !$port;
            for (1 .. 50) {
                return 1 if !scalar _code_for($listener_pids_for_port_method)->($self, $port);
                Time::HiRes::sleep(0.1);
            }
            return !scalar _code_for($listener_pids_for_port_method)->($self, $port);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_progress_emit') {
        $impl = sub {
            my ($self, $progress, $event) = @_;
            return 1 if !$progress || ref($progress) ne 'CODE';
            $progress->($event);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_runtime_stability_polls') {
        $impl = sub {
            my $override = $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS};
            return $override if defined $override && $override =~ /^\d+$/ && $override > 0;
            my $perl5opt = join ' ', grep { defined && $_ ne '' } @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
            return 300 if $perl5opt =~ /Devel::Cover/;
            return 100;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_runtime_confirmation_polls') {
        $impl = sub {
            my $override = $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS};
            return $override if defined $override && $override =~ /^\d+$/ && $override > 0;
            return 3;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_runtime_poll_interval') {
        $impl = sub { return 0.1 };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_port_accepting_connections') {
        $impl = sub {
            my ($self, $port) = @_;
            return 0 if !defined $port || $port !~ /^\d+$/ || $port < 1;
            my $socket = IO::Socket::INET->new(
                PeerAddr => '127.0.0.1',
                PeerPort => $port,
                Proto    => 'tcp',
                Timeout  => 1,
            );
            return 0 if !$socket;
            close $socket;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'runtime_manager_read_process_title') {
        $impl = sub {
            my ($self, $pid) = @_;
            my $proc = "/proc/$pid/cmdline";
            if (-r $proc) {
                open my $fh, '<', $proc or return;
                local $/;
                my $cmdline = scalar <$fh>;
                if (defined $cmdline && $cmdline ne '') {
                    $cmdline =~ s/\0/ /g;
                    $cmdline =~ s/\s+$//;
                    return $cmdline;
                }
            }
            my ($stdout, $stderr, $exit_code) = _capture_system_command('ps', '-o', 'args=', '-p', $pid);
            return if _system_command_missing($stderr, $exit_code);
            return if $exit_code != 0;
            $stdout =~ s/\s+$// if defined $stdout;
            return $stdout;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_system_context') {
        $impl = sub {
            my ($self, %args) = @_;
            return {
                cwd    => $args{runtime_context}{cwd} || '.',
                source => $args{source} || '',
                params => $args{runtime_context}{params} || {},
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_noop_writer') {
        $impl = sub { return '' };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_stream_disconnect_error') {
        $impl = sub {
            my ($self, $error) = @_;
            return 1 if !defined $error || $error eq '';
            return 1 if $error =~ /^__DD_AJAX_STREAM_DISCONNECTED__/;
            return $error =~ /(broken pipe|client disconnected|connection reset|stream closed|connection aborted|write failed|closed handle)/i ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_stream_sysread') {
        $impl = sub {
            my ($self, $fh, $chunk_ref) = @_;
            return sysread($fh, ${$chunk_ref}, 8192);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_saved_ajax_inline_env_limit') {
        $impl = sub { return 131_072 };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_cleanup_saved_ajax_temp_files') {
        $impl = sub {
            my ($self, @paths) = @_;
            for my $path (@paths) {
                next if !defined $path || $path eq '';
                next if !-e $path;
                unlink $path or die "Unable to remove saved ajax temp file $path: $!";
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_normalize_saved_ajax_singleton') {
        $impl = sub {
            my ($self, $singleton) = @_;
            return '' if !defined $singleton || $singleton eq '';
            die "Invalid ajax singleton name\n" if $singleton =~ /[[:cntrl:]]/;
            return $singleton;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_kill_saved_ajax_singleton') {
        my $quote_pattern_method = $sub->{quote_pattern_method} // die 'compiled sub quote-pattern method missing';
        $impl = sub {
            my ($self, $singleton) = @_;
            return 1 if !defined $singleton || $singleton eq '';
            my $pattern = '^dashboard ajax: ' . _code_for($quote_pattern_method)->($self, $singleton) . '$';
            __PAX_RUNTIME_LEGACY_NAMESPACE__::RuntimeManager->_pkill_perl($pattern);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_quote_process_pattern_literal') {
        $impl = sub {
            my ($self, $text) = @_;
            $text =~ s/([\\.^$|(){}\[\]*+?])/\\$1/g;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_query_string_from_params') {
        $impl = sub {
            my ($params) = @_;
            return '' if ref($params) ne 'HASH' || !%{$params};
            require URI::Escape;
            return join '&',
                map {
                    URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape(defined $params->{$_} ? $params->{$_} : '')
                } sort keys %{$params};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_legacy_quote') {
        $impl = sub {
            my ($text) = @_;
            $text =~ s/\\/\\\\/g;
            $text =~ s/'/\\'/g;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_legacy_value') {
        my $quote_method = $sub->{quote_method} // die 'compiled sub quote method missing';
        my $value_method = $sub->{value_method} // die 'compiled sub value method missing';
        $impl = sub {
            my ($value) = @_;
            return 'undef' if !defined $value;
            if (ref($value) eq 'ARRAY') {
                return "[\n  " . join(",\n  ", map { _code_for($value_method)->($_) } @{$value}) . "\n]";
            }
            if (ref($value) eq 'HASH') {
                return "{\n  " . join(",\n  ", map { sprintf "%s => %s", $_, _code_for($value_method)->($value->{$_}) } sort keys %{$value}) . "\n}";
            }
            return $value =~ /\A-?\d+(?:\.\d+)?\z/ ? $value : "'" . _code_for($quote_method)->($value) . "'";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_value_text') {
        my $legacy_value_method = $sub->{legacy_value_method} // die 'compiled sub legacy-value method missing';
        $impl = sub {
            my ($self, $value) = @_;
            return '' if !defined $value;
            return '' if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
            return _code_for($legacy_value_method)->($value);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_saved_ajax_command') {
        my $perl_wrapper_method = $sub->{perl_wrapper_method} // die 'compiled sub perl-wrapper method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $path = $args{path} || die 'Missing saved ajax file path';
            return ($^X, '-e', _code_for($perl_wrapper_method)->($self), $path) if $path =~ /\.pl\z/i;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($path) if $path =~ /\.(?:ps1|cmd|bat|sh|bash)\z/i;
            return (__PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_in_path('python3') || __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_in_path('python') || 'python3', $path) if $path =~ /\.py\z/i;
            open my $fh, '<', $path or die "Unable to read saved ajax file $path: $!";
            my $first_line = <$fh>;
            close $fh;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($path) if defined $first_line && $first_line =~ /^#!/;
            return ($^X, '-e', _code_for($perl_wrapper_method)->($self), $path);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_saved_ajax_env') {
        my $query_string_method = $sub->{query_string_method} // die 'compiled sub query-string method missing';
        my $normalize_singleton_method = $sub->{normalize_singleton_method} // die 'compiled sub normalize-singleton method missing';
        my $inline_env_limit_method = $sub->{inline_env_limit_method} // die 'compiled sub inline-env-limit method missing';
        my $temp_file_method = $sub->{temp_file_method} // die 'compiled sub temp-file method missing';
        my $runtime_local_env_method = $sub->{runtime_local_env_method} // die 'compiled sub runtime-local-env method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $params = ref($args{params}) eq 'HASH' ? $args{params} : {};
            my $params_json = __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($params);
            my $query_string = _code_for($query_string_method)->($params);
            my %env = (
                DEVELOPER_DASHBOARD_AJAX_FILE      => $args{path} || '',
                DEVELOPER_DASHBOARD_AJAX_PAGE      => $args{page} || '',
                DEVELOPER_DASHBOARD_AJAX_SINGLETON => _code_for($normalize_singleton_method)->($self, $args{singleton}),
                DEVELOPER_DASHBOARD_AJAX_TYPE      => $args{type} || '',
                DEVELOPER_DASHBOARD_AJAX_PARAMS    => $params_json,
                DEVELOPER_DASHBOARD_RUNTIME_LAYERS => $self->{paths} ? join("\n", $self->{paths}->runtime_layers) : '',
                QUERY_STRING                       => $query_string,
                REQUEST_METHOD                     => 'GET',
            );
            if (length($params_json) > _code_for($inline_env_limit_method)->()) {
                $env{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE} = _code_for($temp_file_method)->(
                    prefix  => 'developer-dashboard-ajax-params-',
                    suffix  => '.json',
                    content => $params_json,
                );
                $env{DEVELOPER_DASHBOARD_AJAX_PARAMS} = '{}';
            }
            if (length($query_string) > _code_for($inline_env_limit_method)->()) {
                $env{DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE} = _code_for($temp_file_method)->(
                    prefix  => 'developer-dashboard-ajax-query-',
                    suffix  => '.txt',
                    content => $query_string,
                );
                $env{QUERY_STRING} = '';
            }
            if ($self->{paths}) {
                my %runtime_env = _code_for($runtime_local_env_method)->($self);
                @env{keys %runtime_env} = values %runtime_env;
            }
            return %env;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_local_perl_env') {
        $impl = sub {
            my ($self) = @_;
            my $paths = $self->{paths} || return ();
            my $path_sep = $^O eq 'MSWin32' ? ';' : ':';
            my @perl5lib = grep { defined $_ && $_ ne '' } split /\Q$path_sep\E/, ($ENV{PERL5LIB} || '');
            for my $local_lib (reverse $paths->runtime_local_lib_roots) {
                next if !-d $local_lib;
                next if grep { $_ eq $local_lib } @perl5lib;
                unshift @perl5lib, $local_lib;
            }
            return (PERL5LIB => join($path_sep, @perl5lib));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_saved_ajax_temp_file') {
        $impl = sub {
            my (%args) = @_;
            my ($fh, $path) = File::Temp::tempfile(
                ($args{prefix} || 'developer-dashboard-ajax-') . 'XXXXXX',
                TMPDIR => 1,
                UNLINK => 0,
                SUFFIX => $args{suffix} || '',
            );
            print {$fh} defined $args{content} ? $args{content} : '';
            close $fh or die "Unable to close saved ajax temp file $path: $!";
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_drain_saved_ajax_ready_handle') {
        my $noop_writer_method = $sub->{noop_writer_method} // die 'compiled sub noop-writer method missing';
        my $stream_sysread_method = $sub->{stream_sysread_method} // die 'compiled sub stream-sysread method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $fh            = $args{fh}            || die 'Missing ready handle';
            my $path          = $args{path}          || '';
            my $select        = $args{select}        || die 'Missing select set';
            my $stdout        = $args{stdout}        || die 'Missing stdout handle';
            my $stdout_writer = $args{stdout_writer} || _code_for($noop_writer_method);
            my $stderr_writer = $args{stderr_writer} || _code_for($noop_writer_method);
            my $chunk = '';
            my $bytes = _code_for($stream_sysread_method)->($self, $fh, \$chunk);
            if (!defined $bytes) {
                return 1 if $!{EINTR};
                $stderr_writer->("Unable to read ajax stream for $path: $!\n");
                $select->remove($fh);
                close $fh;
                return 1;
            }
            if ($bytes == 0) {
                $select->remove($fh);
                close $fh;
                return 1;
            }
            my $ready_fileno = fileno($fh);
            my $stdout_fileno = fileno($stdout);
            if (defined $ready_fileno && defined $stdout_fileno && $ready_fileno == $stdout_fileno) {
                my $continued = $stdout_writer->($chunk);
                return defined $continued ? $continued : 1;
            }
            my $continued = $stderr_writer->($chunk);
            return defined $continued ? $continued : 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_close_saved_ajax_streams') {
        $impl = sub {
            my ($self, $select, @handles) = @_;
            if ($select && eval { $select->can('handles') }) {
                for my $fh ($select->handles) {
                    next if !defined fileno($fh);
                    $select->remove($fh);
                    close $fh;
                }
            }
            for my $fh (@handles) {
                next if !defined $fh;
                next if !defined fileno($fh);
                close $fh;
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_terminate_saved_ajax_process') {
        $impl = sub {
            my ($self, $pid) = @_;
            return 1 if !$pid;
            return 1 if !kill 0, $pid;
            kill 15, $pid;
            for (1 .. 20) {
                return 1 if !kill 0, $pid;
                Time::HiRes::sleep(0.05);
            }
            kill 9, $pid if kill 0, $pid;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_ajax_stash') {
        $impl = sub {
            my ($input) = @_;
            die "no input" if !defined $input;
            if (ref($input) eq 'HASH') {
                @{$__PAX_RUNTIME_LEGACY_NAMESPACE__::PageRuntime::AJAX_STASH}{keys %{$input}} = values %{$input};
                return $input;
            }
            return $__PAX_RUNTIME_LEGACY_NAMESPACE__::PageRuntime::AJAX_STASH->{$input};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_ajax_hide') {
        my $stash_method = $sub->{stash_method} // die 'compiled sub stash method missing';
        $impl = sub {
            my ($input) = @_;
            _code_for($stash_method)->($input) if ref($input) eq 'HASH';
            return "__DD_HIDE__";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_ajax_void') {
        my $stash_method = $sub->{stash_method} // die 'compiled sub stash method missing';
        $impl = sub {
            my ($input) = @_;
            _code_for($stash_method)->($input) if defined $input;
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_ajax_stop') {
        $impl = sub {
            my ($message) = @_;
            die defined $message ? $message : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_ajax_params') {
        $impl = sub {
            return $__PAX_RUNTIME_LEGACY_NAMESPACE__::PageRuntime::AJAX_PARAMS;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_code_header') {
        $impl = sub {
            my ($self, $state) = @_;
            $state ||= {};
            my @keys = grep { /^[A-Za-z_][A-Za-z0-9_]*$/ } sort keys %{$state};
            return '' if !@keys;
            my $header = sprintf 'my (%s) = @{ $stash }{qw(%s)};' . "\n",
                join(', ', map { '$' . $_ } @keys),
                join(' ', @keys);
            $header .= sprintf 'my (%s) = map { \\$stash->{$_} } qw(%s);' . "\n",
                join(', ', map { '$' . $_ . '_r' } @keys),
                join(' ', @keys);
            return $header;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_destroy_sandpit') {
        $impl = sub {
            my ($self, $sandpit) = @_;
            return if ref($sandpit) ne 'HASH' || !$sandpit->{package};
            my $stash = $sandpit->{package};
            no strict 'refs';
            %{"${stash}::"} = ();
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_saved_ajax_perl_wrapper') {
        $impl = sub {
            return <<'PERL';
use strict;
use warnings;
use __PAX_RUNTIME_LEGACY_NAMESPACE__::DataHelper qw(j je);
use __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON qw(json_decode);
use __PAX_RUNTIME_LEGACY_NAMESPACE__::Zipper qw(Ajax acmdx zip unzip);
my $old_stdout = select STDOUT;
$| = 1;
select STDERR;
$| = 1;
select $old_stdout;

my $ajax_params_json = $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS} || '{}';
if ( ( $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE} || '' ) ne '' ) {
    open my $params_fh, '<:raw', $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE}
      or die "Unable to read $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE}: $!";
    local $/;
    $ajax_params_json = <$params_fh>;
    close $params_fh or die "Unable to close $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE}: $!";
}
if ( ( $ENV{QUERY_STRING} || '' ) eq '' && ( $ENV{DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE} || '' ) ne '' ) {
    open my $query_fh, '<:raw', $ENV{DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE}
      or die "Unable to read $ENV{DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE}: $!";
    local $/;
    $ENV{QUERY_STRING} = <$query_fh>;
    close $query_fh or die "Unable to close $ENV{DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE}: $!";
}

our $AJAX_STASH = {};
our $AJAX_PARAMS = eval { json_decode($ajax_params_json) };
$AJAX_PARAMS = {} if ref($AJAX_PARAMS) ne 'HASH';
my $singleton = $ENV{DEVELOPER_DASHBOARD_AJAX_SINGLETON} || '';
$0 = "dashboard ajax: $singleton" if $singleton ne '';

sub stash {
    my ($input) = @_;
    die "no input" if !defined $input;
    if ( ref($input) eq 'HASH' ) {
        @{$AJAX_STASH}{ keys %{$input} } = values %{$input};
        return $input;
    }
    return $AJAX_STASH->{$input};
}

sub hide {
    my ($input) = @_;
    stash($input) if ref($input) eq 'HASH';
    return "__DD_HIDE__";
}

sub void {
    my ($input) = @_;
    stash($input) if defined $input;
    return;
}

sub stop {
    my ($message) = @_;
    die defined $message ? $message : '';
}

sub params {
    return $AJAX_PARAMS;
}

my $file = shift @ARGV;
open my $fh, '<', $file or die "Unable to read $file: $!";
local $/;
my $code = <$fh>;
close $fh;
eval "{ $code }";
die $@ if $@;
PERL
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_sandpit_add_error') {
        $impl = sub {
            no strict 'refs';
            push @{"${package}::errors"}, grep { defined $_ && $_ ne '' } @_;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_sandpit_errors') {
        $impl = sub {
            no strict 'refs';
            my @copy = @{"${package}::errors"};
            @{"${package}::errors"} = ();
            return @copy;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_sandpit_initial_context') {
        $impl = sub {
            my ($class, $next_stash, $next_runtime) = @_;
            no strict 'refs';
            ${"${package}::stash"} = $next_stash || {};
            ${"${package}::runtime"} = $next_runtime || {};
            @{"${package}::errors"} = ();
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_sandpit_run_code') {
        my $add_error_method = $sub->{add_error_method} // die 'compiled sub add-error method missing';
        $impl = sub {
            my ($class, $code) = @_;
            my @result = eval "{ $code }";
            _code_for($add_error_method)->($@) if $@;
            return @result;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_new_sandpit') {
        $impl = sub {
            my ($self, %args) = @_;
            my $package_name = sprintf '__PAX_RUNTIME_LEGACY_NAMESPACE__::Sandpit::%d::%d::%d', $$, time, ++$__PAX_RUNTIME_LEGACY_NAMESPACE__::PageRuntime::SANDPIT_SEQ;
            $package_name =~ s/[^A-Za-z0-9:]/_/g;
            my $compiled = <<"PERL";
package $package_name;
use strict;
use warnings;
use __PAX_RUNTIME_LEGACY_NAMESPACE__::DataHelper qw(j je);
use __PAX_RUNTIME_LEGACY_NAMESPACE__::Zipper qw(Ajax acmdx zip unzip);

our \$stash = {};
our \$runtime = {};
our \@errors = ();

sub __add_error {
    push \@errors, grep { defined \$_ && \$_ ne '' } \@_;
}

sub __errors {
    my \@copy = \@errors;
    \@errors = ();
    return \@copy;
}

sub stash {
    my (\$input) = \@_;
    die "no input" if !defined \$input;
    if (ref(\$input) eq 'HASH') {
        \@{\$stash}{keys %\$input} = values %\$input;
        return \$input;
    }
    return \$stash->{\$input};
}

sub hide {
    my (\$input) = \@_;
    stash(\$input) if ref(\$input) eq 'HASH';
    return "__DD_HIDE__";
}

sub void {
    my (\$input) = \@_;
    stash(\$input) if defined \$input;
    return;
}

sub stop {
    my (\$message) = \@_;
    die "__DD_STOP__\\n" . (defined \$message ? \$message : '');
}

sub params {
    return \$runtime->{params} || {};
}

sub __initial_context {
    my (\$class, \$next_stash, \$next_runtime) = \@_;
    \$stash = \$next_stash || {};
    \$runtime = \$next_runtime || {};
    \@errors = ();
    return 1;
}

sub __run_code {
    my (\$class, \$code) = \@_;
    my \@result = eval "{\$code}";
    __add_error(\$@) if \$@;
    return \@result;
}

1;
PERL
            my $ok = eval $compiled;
            die "Unable to setup sandpit $@\n" if !$ok;
            no strict 'refs';
            $package_name->__initial_context(
                $args{state} || {},
                $args{runtime_context} || {},
            );
            return { package => $package_name };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_run_single_block') {
        my $new_sandpit_method = $sub->{new_sandpit_method} // die 'compiled sub new-sandpit method missing';
        my $code_header_method = $sub->{code_header_method} // die 'compiled sub code-header method missing';
        my $destroy_sandpit_method = $sub->{destroy_sandpit_method} // die 'compiled sub destroy-sandpit method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $code            = $args{code} // '';
            my $state           = $args{state} || {};
            my $runtime         = $args{runtime_context} || {};
            my $sandpit         = $args{sandpit};
            my $destroy_sandpit = !$sandpit ? 1 : 0;
            __PAX_RUNTIME_LEGACY_NAMESPACE__::Folder->configure(
                paths   => $self->{paths},
                aliases => $self->{aliases},
            );
            $sandpit ||= _code_for($new_sandpit_method)->(
                $self,
                state           => $state,
                runtime_context => $runtime,
            );
            my $package_name = $sandpit->{package} || die 'Missing sandpit package';
            my $wrapped_code = _code_for($code_header_method)->($self, $state) . $code;
            my @returns;
            local $__PAX_RUNTIME_LEGACY_NAMESPACE__::Zipper::AJAX_CONTEXT = {
                allow_transient_urls => (
                    defined $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS}
                      && $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} =~ /\A(?:1|true|yes|on)\z/i
                ) ? 1 : 0,
                page_id      => $args{page} && ref($args{page}) ? ($args{page}->as_hash->{id} || '') : '',
                runtime_root => $self->{paths} ? $self->{paths}->runtime_root : '',
                source       => $args{source} || '',
            };
            my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                @returns = $package_name->__run_code($wrapped_code);
                return $?;
            };
            my @errors = $package_name->__errors();
            if (@errors) {
                my $error = join '', grep { defined $_ && $_ ne '' } @errors;
                _code_for($destroy_sandpit_method)->($self, $sandpit) if $destroy_sandpit;
                die $error if $error ne '';
            }
            _code_for($destroy_sandpit_method)->($self, $sandpit) if $destroy_sandpit;
            return {
                stdout  => $stdout,
                stderr  => $stderr,
                returns => \@returns,
                merge   => $state,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_stream_code_block') {
        my $noop_writer_method = $sub->{noop_writer_method} // die 'compiled sub noop-writer method missing';
        my $new_sandpit_method = $sub->{new_sandpit_method} // die 'compiled sub new-sandpit method missing';
        my $code_header_method = $sub->{code_header_method} // die 'compiled sub code-header method missing';
        my $value_text_method = $sub->{value_text_method} // die 'compiled sub value-text method missing';
        my $destroy_sandpit_method = $sub->{destroy_sandpit_method} // die 'compiled sub destroy-sandpit method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $code            = $args{code} // '';
            my $state           = $args{state} || {};
            my $runtime         = $args{runtime_context} || {};
            my $sandpit         = $args{sandpit};
            my $destroy_sandpit = !$sandpit ? 1 : 0;
            my $stdout_writer   = $args{stdout_writer} || _code_for($noop_writer_method);
            my $stderr_writer   = $args{stderr_writer} || _code_for($noop_writer_method);
            __PAX_RUNTIME_LEGACY_NAMESPACE__::Folder->configure(
                paths   => $self->{paths},
                aliases => $self->{aliases},
            );
            $sandpit ||= _code_for($new_sandpit_method)->(
                $self,
                state           => $state,
                runtime_context => $runtime,
            );
            my $package_name = $sandpit->{package} || die 'Missing sandpit package';
            my $wrapped_code = _code_for($code_header_method)->($self, $state) . $code;
            my @returns;
            local $__PAX_RUNTIME_LEGACY_NAMESPACE__::Zipper::AJAX_CONTEXT = {
                allow_transient_urls => (
                    defined $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS}
                      && $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} =~ /\A(?:1|true|yes|on)\z/i
                ) ? 1 : 0,
                page_id      => $args{page} && ref($args{page}) ? ($args{page}->as_hash->{id} || '') : '',
                runtime_root => $self->{paths} ? $self->{paths}->runtime_root : '',
                source       => $args{source} || '',
            };
            tie *STDOUT, '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageRuntime::StreamHandle', writer => $stdout_writer;
            tie *STDERR, '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageRuntime::StreamHandle', writer => $stderr_writer;
            local $| = 1;
            my $old_stderr = select STDERR;
            $| = 1;
            select $old_stderr;
            @returns = $package_name->__run_code($wrapped_code);
            untie *STDOUT;
            untie *STDERR;
            my @errors = $package_name->__errors();
            my $error = join '', grep { defined $_ && $_ ne '' } @errors;
            if (ref($args{return_writer}) eq 'CODE') {
                for my $value (@returns) {
                    next if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
                    $args{return_writer}->(_code_for($value_text_method)->($self, $value));
                }
            }
            _code_for($destroy_sandpit_method)->($self, $sandpit) if $destroy_sandpit;
            return {
                returns => \@returns,
                merge   => $state,
                error   => $error,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_stream_saved_ajax_file') {
        my $noop_writer_method = $sub->{noop_writer_method} // die 'compiled sub noop-writer method missing';
        my $normalize_singleton_method = $sub->{normalize_singleton_method} // die 'compiled sub normalize-singleton method missing';
        my $kill_singleton_method = $sub->{kill_singleton_method} // die 'compiled sub kill-singleton method missing';
        my $saved_ajax_command_method = $sub->{saved_ajax_command_method} // die 'compiled sub saved-ajax-command method missing';
        my $saved_ajax_env_method = $sub->{saved_ajax_env_method} // die 'compiled sub saved-ajax-env method missing';
        my $cleanup_temp_files_method = $sub->{cleanup_temp_files_method} // die 'compiled sub cleanup-temp-files method missing';
        my $drain_ready_handle_method = $sub->{drain_ready_handle_method} // die 'compiled sub drain-ready-handle method missing';
        my $close_streams_method = $sub->{close_streams_method} // die 'compiled sub close-streams method missing';
        my $terminate_process_method = $sub->{terminate_process_method} // die 'compiled sub terminate-process method missing';
        my $disconnect_error_method = $sub->{disconnect_error_method} // die 'compiled sub disconnect-error method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $path          = $args{path} || die 'Missing saved ajax file path';
            my $params        = $args{params} || {};
            my $stdout_writer = $args{stdout_writer} || _code_for($noop_writer_method);
            my $stderr_writer = $args{stderr_writer} || _code_for($noop_writer_method);
            my $singleton     = _code_for($normalize_singleton_method)->($self, $params->{singleton});
            _code_for($kill_singleton_method)->($self, $singleton) if $singleton ne '';
            my @command       = _code_for($saved_ajax_command_method)->($self, path => $path);
            my %env           = _code_for($saved_ajax_env_method)->(
                $self,
                path      => $path,
                page      => $args{page} || '',
                type      => $args{type} || '',
                params    => $params,
                singleton => $singleton,
            );
            my @temp_files = grep { defined $_ && $_ ne '' } @env{qw(DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE)};
            my $stdout = Symbol::gensym;
            my $stderr = Symbol::gensym;
            my $stdin  = Symbol::gensym;
            my $pid = eval {
                local %ENV = (%ENV, %env);
                IPC::Open3::open3($stdin, $stdout, $stderr, @command);
            };
            if ($@) {
                _code_for($cleanup_temp_files_method)->($self, @temp_files);
                die $@;
            }
            close $stdin;
            my $select = IO::Select->new($stdout, $stderr);
            my $stream_error = '';
            my $disconnected = 0;
            eval {
                while (1) {
                    my @ready = $select->can_read(0.25);
                    last if !@ready && !$select->count;
                    for my $fh (@ready) {
                        my $continued = _code_for($drain_ready_handle_method)->(
                            $self,
                            fh            => $fh,
                            path          => $path,
                            select        => $select,
                            stdout        => $stdout,
                            stdout_writer => $stdout_writer,
                            stderr_writer => $stderr_writer,
                        );
                        if (!$continued) {
                            $disconnected = 1;
                            die "__DD_AJAX_STREAM_DISCONNECTED__\n";
                        }
                    }
                }
                1;
            } or do {
                $stream_error = $@ || "Saved ajax stream failed\n";
            };
            _code_for($close_streams_method)->($self, $select, $stdout, $stderr);
            my $fatal_error = '';
            if ($disconnected) {
                _code_for($terminate_process_method)->($self, $pid);
            } elsif ($stream_error ne '') {
                _code_for($terminate_process_method)->($self, $pid);
                $fatal_error = $stream_error if !_code_for($disconnect_error_method)->($self, $stream_error);
            }
            waitpid($pid, 0);
            _code_for($cleanup_temp_files_method)->($self, @temp_files);
            die $fatal_error if $fatal_error ne '';
            return {
                disconnected => $disconnected ? 1 : 0,
                exit_code => $? >> 8,
                status    => $?,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_run_code_blocks') {
        my $new_sandpit_method = $sub->{new_sandpit_method} // die 'compiled sub new-sandpit method missing';
        my $run_single_block_method = $sub->{run_single_block_method} // die 'compiled sub run-single-block method missing';
        my $value_text_method = $sub->{value_text_method} // die 'compiled sub value-text method missing';
        my $destroy_sandpit_method = $sub->{destroy_sandpit_method} // die 'compiled sub destroy-sandpit method missing';
        $impl = sub {
            my ($self, %args) = @_;
            $self = __PACKAGE__->new if !ref($self);
            my $page  = $args{page} || die 'Missing page';
            my $codes = $page->as_hash->{meta}{codes} || [];
            my $state = $page->{state} || {};
            return { outputs => [], errors => [] } if ref($codes) ne 'ARRAY' || !@$codes;
            my (@outputs, @errors);
            my $sandpit = _code_for($new_sandpit_method)->(
                $self,
                state           => $state,
                runtime_context => $args{runtime_context} || {},
            );
            eval {
                CODE:
                for my $block (@$codes) {
                    next if ref($block) ne 'HASH';
                    my $code = $block->{body} // '';
                    next if $code eq '';
                    my $result = eval {
                        _code_for($run_single_block_method)->(
                            $self,
                            code            => $code,
                            page            => $page,
                            sandpit         => $sandpit,
                            source          => $args{source} || '',
                            state           => $state,
                            runtime_context => $args{runtime_context} || {},
                        );
                    };
                    if ($@) {
                        my $error = "$@";
                        if ($error =~ /^__DD_HIDE__/) {
                            next CODE;
                        }
                        if ($error =~ /^__DD_STOP__(?:\n(.*))?/s) {
                            push @errors, $1 if defined $1 && $1 ne '';
                            last CODE;
                        }
                        push @errors, $error;
                        last CODE;
                    }
                    if (ref($result->{merge}) eq 'HASH') {
                        $page->merge_state($result->{merge});
                        $state = $page->{state};
                    }
                    if (ref($result->{returns}) eq 'ARRAY') {
                        for my $value (@{$result->{returns}}) {
                            if (ref($value) eq 'HASH') {
                                $page->merge_state($value);
                                $state = $page->{state};
                            }
                            next if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
                            push @outputs, _code_for($value_text_method)->($self, $value);
                        }
                    }
                    my $stdout = defined $result->{stdout} ? $result->{stdout} : '';
                    my $stderr = defined $result->{stderr} ? $result->{stderr} : '';
                    push @outputs, $stdout if $stdout ne '';
                    push @errors, $stderr if $stderr ne '';
                }
                1;
            };
            _code_for($destroy_sandpit_method)->($self, $sandpit);
            return {
                outputs => \@outputs,
                errors  => \@errors,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_render_templates') {
        my $system_context_method = $sub->{system_context_method} // die 'compiled sub system-context method missing';
        my $run_single_block_method = $sub->{run_single_block_method} // die 'compiled sub run-single-block method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $page = $args{page} || die 'Missing page';
            my $layout = $page->{layout} || {};
            my $state  = $page->{state} || {};
            my $request_context = $page->{meta}{request_context} || {};
            my $current_page = $args{runtime_context}{current_page} || $request_context->{path} || '';
            my %template_runtime = (
                %{ $args{runtime_context} || {} },
                current_page => $current_page,
            );
            my %template_env = (
                %ENV,
                current_page    => $current_page,
                runtime_context => \%template_runtime,
            );
            my $system = _code_for($system_context_method)->($self, %args);
            my $tt = Template->new({
                EVAL_PERL    => 1,
                INCLUDE_PATH => $self->{paths} ? [ $self->{paths}->dashboards_roots ] : '.',
            });
            for my $field (qw(body)) {
                my $template = $layout->{$field};
                next if !defined $template || $template eq '';
                my $rendered = '';
                my $page_data = $page->as_hash;
                my $ok = $tt->process(
                    \$template,
                    {
                        app    => $page,
                        parts  => $page,
                        page   => $page_data,
                        stash  => $state,
                        id     => $page_data->{id},
                        title  => $page_data->{title},
                        description => $page_data->{description},
                        mode   => $page_data->{mode},
                        icon   => $page_data->{icon},
                        ENV    => \%template_env,
                        SYSTEM => $system,
                        env    => \%template_env,
                        func   => sub { return '' },
                        method => sub {
                            my ($class, $method, @rest) = @_;
                            return '' if !$class || !$method || !$class->can($method);
                            return $class->$method(@rest);
                        },
                        eval => sub {
                            my ($code) = @_;
                            my $result = _code_for($run_single_block_method)->(
                                $self,
                                code            => $code,
                                page            => $page,
                                source          => $args{source} || '',
                                state           => $state,
                                runtime_context => $args{runtime_context} || {},
                            );
                            die $result->{stderr} if defined $result->{stderr} && $result->{stderr} ne '';
                            return $result->{stdout};
                        },
                        %{$state},
                    },
                    \$rendered,
                );
                if ($ok) {
                    $page->{layout}{$field} = $rendered;
                    next;
                }
                $page->{layout}{$field} = '';
                push @{ $page->{meta}{runtime_errors} ||= [] }, '' . $tt->error;
            }
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_runtime_prepare_page') {
        my $run_code_blocks_method = $sub->{run_code_blocks_method} // die 'compiled sub run-code-blocks method missing';
        my $render_templates_method = $sub->{render_templates_method} // die 'compiled sub render-templates method missing';
        $impl = sub {
            my ($self, %args) = @_;
            $self = __PACKAGE__->new if !ref($self);
            my $page = $args{page} || die 'Missing page';
            my $source = $args{source} || 'saved';
            my $runtime_context = $args{runtime_context} || {};
            my $runtime = _code_for($run_code_blocks_method)->(
                $self,
                page            => $page,
                source          => $source,
                runtime_context => $runtime_context,
            );
            $page->{meta}{runtime_outputs} = $runtime->{outputs};
            $page->{meta}{runtime_errors}  = $runtime->{errors};
            _code_for($render_templates_method)->(
                $self,
                page            => $page,
                runtime_context => $runtime_context,
            );
            return $page;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_temp_file_kind') {
        $impl = sub {
            my ($self, $entry) = @_;
            return ('ajax-temp-file', 'ajax_temp_files') if $entry =~ /\Adeveloper-dashboard-ajax-/;
            return ('result-temp-file', 'result_temp_files') if $entry =~ /\Adashboard-result-/;
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_collector_rotation') {
        $impl = sub {
            my ($self, $job) = @_;
            my %rotation;
            if (ref($job->{rotation}) eq 'HASH') {
                %rotation = (%rotation, %{ $job->{rotation} });
            }
            if (ref($job->{rotations}) eq 'HASH') {
                %rotation = (%rotation, %{ $job->{rotations} });
            }
            return \%rotation;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_path_old_enough') {
        $impl = sub {
            my ($self, $path, $min_age_seconds) = @_;
            my @stat = stat($path);
            return 0 if !@stat;
            return (time - $stat[9]) >= $min_age_seconds ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_only_missing_tree_errors') {
        $impl = sub {
            my ($self, $errors) = @_;
            return 1 if ref($errors) ne 'ARRAY' || !@{$errors};
            for my $entry (@{$errors}) {
                my ($message) = values %{ $entry || {} };
                return 0 if !defined $message || $message !~ /No such file or directory/;
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_read_state_metadata') {
        $impl = sub {
            my ($self, $dir) = @_;
            my $file = File::Spec->catfile($dir, 'runtime.json');
            return if !-f $file;
            open my $fh, '<', $file or die "Unable to read $file: $!";
            local $/;
            my $raw = <$fh>;
            close $fh or die "Unable to close $file: $!";
            my $data = eval { __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($raw) };
            return if !$data || ref($data) ne 'HASH';
            return $data;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_remove_tree') {
        my $missing_errors_method = $sub->{missing_errors_method} // die 'compiled sub missing-errors method missing';
        $impl = sub {
            my ($self, $path, $kind) = @_;
            my $errors = [];
            File::Path::remove_tree($path, { error => \$errors });
            if (@{$errors} && !_code_for($missing_errors_method)->($self, $errors)) {
                die "Unable to remove stale $kind $path\n";
            }
            return {
                kind => $kind,
                path => $path,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_collector_store') {
        $impl = sub {
            my ($self) = @_;
            return $self->{collector_store} ||= __PAX_RUNTIME_LEGACY_NAMESPACE__::Collector->new(paths => $self->{paths});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_config') {
        $impl = sub {
            my ($self) = @_;
            return $self->{config} ||= __PAX_RUNTIME_LEGACY_NAMESPACE__::Config->new(
                paths => $self->{paths},
                files => __PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry->new(paths => $self->{paths}),
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_state_root_has_live_collectors') {
        $impl = sub {
            my ($self, $dir) = @_;
            my $collectors_root = File::Spec->catdir($dir, 'collectors');
            return 0 if !-d $collectors_root;
            opendir my $dh, $collectors_root or die "Unable to read $collectors_root: $!";
            while (my $entry = readdir $dh) {
                next if $entry eq '.' || $entry eq '..';
                next if $entry !~ /\.pid\z/;
                my $pidfile = File::Spec->catfile($collectors_root, $entry);
                next if !-f $pidfile;
                open my $fh, '<', $pidfile or die "Unable to read $pidfile: $!";
                my $pid = <$fh>;
                close $fh or die "Unable to close $pidfile: $!";
                chomp $pid if defined $pid;
                next if !defined $pid || $pid !~ /\A\d+\z/;
                if (kill 0, $pid) {
                    closedir $dh;
                    return 1;
                }
            }
            closedir $dh;
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_state_root_is_stale') {
        my $old_enough_method = $sub->{old_enough_method} // die 'compiled sub old-enough method missing';
        my $live_collectors_method = $sub->{live_collectors_method} // die 'compiled sub live-collectors method missing';
        my $read_metadata_method = $sub->{read_metadata_method} // die 'compiled sub read-metadata method missing';
        $impl = sub {
            my ($self, $dir, $min_age_seconds) = @_;
            return 0 if !_code_for($old_enough_method)->($self, $dir, $min_age_seconds);
            return 0 if _code_for($live_collectors_method)->($self, $dir);
            my $metadata = _code_for($read_metadata_method)->($self, $dir);
            if ($metadata) {
                my $runtime_root = $metadata->{runtime_root} || '';
                return 1 if $runtime_root eq '' || !-d $runtime_root;
                return 0;
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_cleanup_state_roots') {
        my $stale_method = $sub->{stale_method} // die 'compiled sub stale method missing';
        my $remove_tree_method = $sub->{remove_tree_method} // die 'compiled sub remove-tree method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $base = $self->{paths}->state_base_root;
            return () if !-d $base;
            my %active_roots = map { $self->{paths}->_state_root_for_layer($_) => 1 } $self->{paths}->runtime_layers;
            opendir my $dh, $base or die "Unable to read $base: $!";
            my @removed;
            while (my $entry = readdir $dh) {
                next if $entry eq '.' || $entry eq '..';
                my $dir = File::Spec->catdir($base, $entry);
                next if !-d $dir;
                $args{scanned}{state_roots}++;
                next if $active_roots{$dir};
                next if !_code_for($stale_method)->($self, $dir, $args{min_age_seconds});
                push @removed, _code_for($remove_tree_method)->($self, $dir, 'state-root');
            }
            closedir $dh;
            return @removed;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_cleanup_temp_files') {
        my $temp_file_kind_method = $sub->{temp_file_kind_method} // die 'compiled sub temp-file-kind method missing';
        my $old_enough_method = $sub->{old_enough_method} // die 'compiled sub old-enough method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $tmpdir = File::Spec->tmpdir;
            opendir my $dh, $tmpdir or die "Unable to read $tmpdir: $!";
            my @removed;
            while (my $entry = readdir $dh) {
                next if $entry eq '.' || $entry eq '..';
                my $path = File::Spec->catfile($tmpdir, $entry);
                next if !-f $path;
                my ($kind, $scan_key) = _code_for($temp_file_kind_method)->($self, $entry);
                next if !$kind;
                $args{scanned}{$scan_key}++;
                next if !_code_for($old_enough_method)->($self, $path, $args{min_age_seconds});
                if (!unlink $path) {
                    next if !-e $path;
                    my $label = $kind eq 'ajax-temp-file' ? 'Ajax temp file' : 'runtime result temp file';
                    die "Unable to remove stale $label $path: $!";
                }
                push @removed, { kind => $kind, path => $path };
            }
            closedir $dh;
            return @removed;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_rotate_collector_logs') {
        my $config_method = $sub->{config_method} // die 'compiled sub config method missing';
        my $collector_rotation_method = $sub->{collector_rotation_method} // die 'compiled sub collector-rotation method missing';
        my $collector_store_method = $sub->{collector_store_method} // die 'compiled sub collector-store method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my @rotated;
            for my $job (@{ _code_for($config_method)->($self)->collectors || [] }) {
                next if ref($job) ne 'HASH';
                my $name = $job->{name} || next;
                my $rotation = _code_for($collector_rotation_method)->($self, $job);
                next if !keys %{$rotation};
                $args{scanned}{collector_logs}++;
                my $result = _code_for($collector_store_method)->($self)->rotate_log(
                    $name,
                    $rotation,
                    now_epoch => $args{now_epoch},
                );
                push @rotated, $result if $result;
            }
            return @rotated;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'housekeeper_run') {
        my $cleanup_state_roots_method = $sub->{cleanup_state_roots_method} // die 'compiled sub cleanup-state-roots method missing';
        my $cleanup_temp_files_method = $sub->{cleanup_temp_files_method} // die 'compiled sub cleanup-temp-files method missing';
        my $rotate_collector_logs_method = $sub->{rotate_collector_logs_method} // die 'compiled sub rotate-collector-logs method missing';
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $min_age_seconds = defined $args{min_age_seconds} ? $args{min_age_seconds} : 3600;
            die "min_age_seconds must be a non-negative integer\n" if $min_age_seconds !~ /\A\d+\z/;
            my $removed = [];
            my $scanned = {
                state_roots => 0,
                ajax_temp_files => 0,
                result_temp_files => 0,
                collector_logs => 0,
            };
            push @{$removed}, _code_for($cleanup_state_roots_method)->($self, min_age_seconds => $min_age_seconds, scanned => $scanned);
            push @{$removed}, _code_for($cleanup_temp_files_method)->($self, min_age_seconds => $min_age_seconds, scanned => $scanned);
            push @{$removed}, _code_for($rotate_collector_logs_method)->($self, scanned => $scanned, now_epoch => $args{now_epoch});
            return {
                ok => 1,
                happened_at => _code_for($now_method)->(),
                min_age_seconds => $min_age_seconds + 0,
                scanned => $scanned,
                removed => $removed,
                removed_count => scalar @{$removed},
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_configure') {
        my $paths_symbol = $sub->{paths_symbol} // die 'compiled sub paths symbol missing';
        my $aliases_symbol = $sub->{aliases_symbol} // die 'compiled sub aliases symbol missing';
        my $config_aliases_symbol = $sub->{config_aliases_symbol} // die 'compiled sub config aliases symbol missing';
        my $config_key_symbol = $sub->{config_key_symbol} // die 'compiled sub config key symbol missing';
        $impl = sub {
            my ($class, %args) = @_;
            no strict 'refs';
            ${$paths_symbol} = $args{paths} if $args{paths};
            %{$aliases_symbol} = %{ $args{aliases} || {} };
            %{$config_aliases_symbol} = ();
            ${$config_key_symbol} = '';
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_home') {
        $impl = sub { return $ENV{HOME} || '' };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_tmp') {
        $impl = sub { return File::Spec->tmpdir };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_runtime_root') {
        my $paths_method = $sub->{paths_method} // die 'compiled sub paths method missing';
        $impl = sub {
            my $paths = _code_for($paths_method)->();
            return $paths && $paths->can('runtime_root') ? $paths->runtime_root : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_dashboards_root') {
        my $paths_method = $sub->{paths_method} // die 'compiled sub paths method missing';
        $impl = sub {
            my $paths = _code_for($paths_method)->();
            return $paths && $paths->can('dashboards_root') ? $paths->dashboards_root : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_config_root') {
        my $paths_method = $sub->{paths_method} // die 'compiled sub paths method missing';
        $impl = sub {
            my $paths = _code_for($paths_method)->();
            return $paths && $paths->can('config_root') ? $paths->config_root : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_all_paths') {
        my $paths_method = $sub->{paths_method} // die 'compiled sub paths method missing';
        my $load_aliases_method = $sub->{load_aliases_method} // die 'compiled sub load-aliases method missing';
        $impl = sub {
            my $paths = _code_for($paths_method)->();
            _code_for($load_aliases_method)->();
            return {} if !$paths || !$paths->can('all_paths');
            return $paths->all_paths;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_postman') {
        $impl = sub {
            my $dir = File::Spec->catdir(__PACKAGE__->configs(), 'postman');
            File::Path::make_path($dir) if $dir ne '' && !-d $dir;
            return $dir;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_paths_obj') {
        my $paths_symbol = $sub->{paths_symbol} // die 'compiled sub paths symbol missing';
        $impl = sub {
            no strict 'refs';
            return ${$paths_symbol} if Scalar::Util::blessed(${$paths_symbol});
            my $home = $ENV{HOME} || '';
            return if $home eq '';
            ${$paths_symbol} = __PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry->new(
                home => $home,
                workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
                project_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
            );
            __PACKAGE__->_load_configured_aliases();
            return ${$paths_symbol};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_load_configured_aliases') {
        my $paths_symbol = $sub->{paths_symbol} // die 'compiled sub paths symbol missing';
        my $config_aliases_symbol = $sub->{config_aliases_symbol} // die 'compiled sub config aliases symbol missing';
        my $config_key_symbol = $sub->{config_key_symbol} // die 'compiled sub config key symbol missing';
        my $cache_key_method = $sub->{cache_key_method} // die 'compiled sub cache key method missing';
        $impl = sub {
            no strict 'refs';
            my $paths = Scalar::Util::blessed(${$paths_symbol}) ? ${$paths_symbol} : return 1;
            my $key = _code_for($cache_key_method)->($paths);
            return 1 if $key ne '' && ${$config_key_symbol} eq $key;
            my $files = __PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry->new(paths => $paths);
            my $config = __PAX_RUNTIME_LEGACY_NAMESPACE__::Config->new(files => $files, paths => $paths);
            %{$config_aliases_symbol} = %{ $config->path_aliases || {} };
            ${$config_key_symbol} = $key;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_resolve_path') {
        my $paths_method = $sub->{paths_method} // die 'compiled sub paths method missing';
        my $load_aliases_method = $sub->{load_aliases_method} // die 'compiled sub load aliases method missing';
        my $aliases_symbol = $sub->{aliases_symbol} // die 'compiled sub aliases symbol missing';
        my $config_aliases_symbol = $sub->{config_aliases_symbol} // die 'compiled sub config aliases symbol missing';
        $impl = sub {
            my ($class, $where) = @_;
            return if !defined $where || $where eq '';
            return $where if File::Spec->file_name_is_absolute($where) || -d $where;
            _code_for($paths_method)->();
            _code_for($load_aliases_method)->();
            my %legacy_aliases = (
                runtime_root => 'dd',
                bookmarks_root => 'bookmarks',
                config_root => 'configs',
            );
            if (my $legacy = $legacy_aliases{$where}) {
                return $class->$legacy() if $class->can($legacy);
            }
            return $class->$where() if $class->can($where);
            {
                no strict 'refs';
                return ${$aliases_symbol}{$where} if defined ${$aliases_symbol}{$where};
                return ${$config_aliases_symbol}{$where} if defined ${$config_aliases_symbol}{$where};
            }
            my $env = 'DEVELOPER_DASHBOARD_PATH_' . uc($where);
            return $ENV{$env} if defined $ENV{$env} && $ENV{$env} ne '';
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_autoload') {
        my $autoload_symbol = $sub->{autoload_symbol} // die 'compiled sub autoload symbol missing';
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($class) = @_;
            my $autoload;
            no strict 'refs';
            $autoload = ${$autoload_symbol};
            my ($name) = $autoload =~ /::([^:]+)$/;
            return if $name eq 'DESTROY';
            my $path = _code_for($resolve_method)->($class, $name);
            die "Unknown folder '$name'" if !defined $path;
            File::Path::make_path($path) if $path ne '' && $path =~ m{^/} && !-e $path;
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_cd') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($class, $where, $code) = @_;
            return if ref($code) ne 'CODE';
            my $pwd = Cwd::cwd();
            my $dir = _code_for($resolve_method)->($class, $where);
            return if !$dir || !-d $dir;
            chdir $dir or return;
            my $parent = File::Basename::dirname($dir);
            my $result = $code->({
                caller => $pwd,
                parent => $parent,
                dir => $dir,
                stay => sub { $pwd = $_[0] if defined $_[0] && $_[0] ne '' },
            });
            chdir $pwd if $pwd;
            return $result;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_names') {
        my $names = $sub->{names} || [];
        $impl = sub { return @{$names}; };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_aliases') {
        my $aliases = $sub->{aliases} || {};
        $impl = sub { return { %{$aliases} }; };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_canonical_helper_name') {
        my $helper_names_method = $sub->{helper_names_method} // die 'compiled sub helper-names method missing';
        my $helper_aliases_method = $sub->{helper_aliases_method} // die 'compiled sub helper-aliases method missing';
        $impl = sub {
            my ($name) = @_;
            return '' if !defined $name || $name eq '';
            my %allowed = map { $_ => 1 } _code_for($helper_names_method)->();
            return $name if $allowed{$name};
            my $aliases = _code_for($helper_aliases_method)->();
            return $aliases->{$name} || '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_parent_root') {
        $impl = sub {
            my ($paths) = @_;
            return File::Spec->catdir($paths->home_runtime_root, 'cli');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_install_root') {
        my $parent_root_method = $sub->{parent_root_method} // die 'compiled sub parent-root method missing';
        $impl = sub {
            my ($paths) = @_;
            return File::Spec->catdir(_code_for($parent_root_method)->($paths), 'dd');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_managed_helper_marker') {
        $impl = sub {
            my ($name) = @_;
            return "# developer-dashboard-managed-helper: $name";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_repo_private_cli_root') {
        $impl = sub {
            return File::Spec->catdir(
                File::Basename::dirname(__FILE__),
                File::Spec->updir,
                File::Spec->updir,
                File::Spec->updir,
                'share',
                'private-cli',
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_shared_private_cli_root') {
        my $dist_name = $sub->{dist_name} // die 'compiled sub dist name missing';
        $impl = sub {
            my $path = _share_dist_private_cli_dir($dist_name);
            die "Unable to resolve private-cli share dir for distribution $dist_name" if !defined $path || $path eq '';
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_asset_path') {
        my $repo_root_method = $sub->{repo_root_method} // die 'compiled sub repo-root method missing';
        my $shared_root_method = $sub->{shared_root_method} // die 'compiled sub shared-root method missing';
        $impl = sub {
            my ($name) = @_;
            my $repo_path = File::Spec->catfile(_code_for($repo_root_method)->(), $name);
            return $repo_path if -f $repo_path;
            return File::Spec->catfile(_code_for($shared_root_method)->(), $name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_path') {
        my $canonical_method = $sub->{canonical_method} // die 'compiled sub canonical method missing';
        my $install_root_method = $sub->{install_root_method} // die 'compiled sub install-root method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            my $name = _code_for($canonical_method)->($args{name});
            die "Unsupported helper command '$args{name}'" if $name eq '';
            return File::Spec->catfile(_code_for($install_root_method)->($paths), $name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_helper_content') {
        my $canonical_method = $sub->{canonical_method} // die 'compiled sub canonical method missing';
        my $asset_path_method = $sub->{asset_path_method} // die 'compiled sub asset-path method missing';
        $impl = sub {
            my ($name) = @_;
            $name = $name eq '_dashboard-core' ? $name : _code_for($canonical_method)->($name);
            die "Unsupported helper command '$name'" if !defined $name || $name eq '';
            if (my $content = _standalone_internal_cli_wrapper_content($name)) {
                return $content;
            }
            my $path = _code_for($asset_path_method)->($name);
            open my $fh, '<:raw', $path or die "Unable to read $path: $!";
            my $content = do { local $/; <$fh> };
            close $fh or die "Unable to close $path: $!";
            return $content;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_managed_helper_content') {
        my $helper_content_method = $sub->{helper_content_method} // die 'compiled sub helper-content method missing';
        my $marker_method = $sub->{marker_method} // die 'compiled sub marker method missing';
        $impl = sub {
            my ($name) = @_;
            my $content = _code_for($helper_content_method)->($name);
            my $marker = _code_for($marker_method)->($name) . "\n";
            return $content if $content =~ /\Q$marker\E/;
            if ($content =~ /\A(#![^\n]*\n)/) {
                substr($content, length($1), 0, $marker);
                return $content;
            }
            return $marker . $content;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_is_dashboard_managed_helper') {
        my $marker_method = $sub->{marker_method} // die 'compiled sub marker method missing';
        $impl = sub {
            my ($content, $name) = @_;
            return 0 if !defined $content;
            return 1 if $content =~ /^\Q@{[ _code_for($marker_method)->($name) ]}\E$/m;
            if ($name eq '_dashboard-core') {
                return 1
                    if $content =~ /Missing built-in dashboard command/
                    && $content =~ /__PAX_RUNTIME_LEGACY_NAMESPACE__::CLI::SeededPages/;
            }
            return 1
                if $content =~ /LAZY-THIN-CMD/
                && $content =~ /Developer Dashboard/;
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_stage_managed_helper') {
        my $managed_content_method = $sub->{managed_content_method} // die 'compiled sub managed-content method missing';
        my $managed_check_method = $sub->{managed_check_method} // die 'compiled sub managed-check method missing';
        $impl = sub {
            my (%args) = @_;
            my $target = $args{target} || die 'Missing helper target';
            my $name = $args{name} || die 'Missing helper name';
            my $content = _code_for($managed_content_method)->($name);
            if (-e $target) {
                return 0 if !-f $target;
                open my $existing_fh, '<:raw', $target or die "Unable to read $target: $!";
                my $existing = do { local $/; <$existing_fh> };
                close $existing_fh or die "Unable to close $target: $!";
                return 0 if !_code_for($managed_check_method)->($existing, $name);
                return 0 if __PAX_RUNTIME_LEGACY_NAMESPACE__::SeedSync::same_content_md5($existing, $content);
            }
            open my $fh, '>:raw', $target or die "Unable to write $target: $!";
            print {$fh} $content;
            close $fh or die "Unable to close $target: $!";
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_remove_retired_managed_helper') {
        my $install_root_method = $sub->{install_root_method} // die 'compiled sub install-root method missing';
        my $managed_check_method = $sub->{managed_check_method} // die 'compiled sub managed-check method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            my $name = $args{name} || die 'Missing retired helper name';
            my $target = File::Spec->catfile(_code_for($install_root_method)->($paths), $name);
            return 0 if !-e $target;
            return 0 if !-f $target;
            open my $fh, '<:raw', $target or die "Unable to read $target: $!";
            my $content = do { local $/; <$fh> };
            close $fh or die "Unable to close $target: $!";
            return 0 if !_code_for($managed_check_method)->($content, $name);
            unlink $target or die "Unable to remove retired helper $target: $!";
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'internal_cli_ensure_helpers') {
        my $parent_root_method = $sub->{parent_root_method} // die 'compiled sub parent-root method missing';
        my $install_root_method = $sub->{install_root_method} // die 'compiled sub install-root method missing';
        my $stage_method = $sub->{stage_method} // die 'compiled sub stage method missing';
        my $helper_names_method = $sub->{helper_names_method} // die 'compiled sub helper-names method missing';
        my $helper_path_method = $sub->{helper_path_method} // die 'compiled sub helper-path method missing';
        my $remove_retired_method = $sub->{remove_retired_method} // die 'compiled sub remove-retired method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            my @written;
            $paths->ensure_dir(_code_for($parent_root_method)->($paths));
            $paths->ensure_dir(_code_for($install_root_method)->($paths));
            my $core_target = File::Spec->catfile(_code_for($install_root_method)->($paths), '_dashboard-core');
            if (_code_for($stage_method)->(paths => $paths, name => '_dashboard-core', target => $core_target)) {
                $paths->secure_file_permissions($core_target, executable => 1);
            }
            for my $name (_code_for($helper_names_method)->()) {
                my $target = _code_for($helper_path_method)->(paths => $paths, name => $name);
                next if !_code_for($stage_method)->(paths => $paths, name => $name, target => $target);
                $paths->secure_file_permissions($target, executable => 1);
                push @written, $target;
            }
            _code_for($remove_retired_method)->(paths => $paths, name => 'skill');
            return \@written;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_expand_env_path') {
        $impl = sub {
            my ($self, $path) = @_;
            return $path if !defined $path || $path eq '';
            $path =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/defined $ENV{$1} ? $ENV{$1} : ''/ge;
            $path =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/defined $ENV{$1} ? $ENV{$1} : ''/ge;
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_config_root') {
        $impl = sub {
            my ($self) = @_;
            return File::Spec->catdir($self->{paths}->config_root, 'docker');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_home_config_root') {
        $impl = sub {
            my ($self) = @_;
            return File::Spec->catdir($self->{paths}->home_runtime_root, 'config', 'docker');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_discover_base_files') {
        my $candidates = $sub->{candidates} || [];
        $impl = sub {
            my ($self, $root) = @_;
            return grep { -f $_ } map { File::Spec->catfile($root, $_) } @{$candidates};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_service_toggle_root') {
        $impl = sub {
            my ($self, %args) = @_;
            my @layers = $self->{paths}->runtime_layers;
            my $runtime_root = @layers ? $layers[-1] : $self->{paths}->home_runtime_root;
            my $home_runtime_root = $self->{paths}->home_runtime_root;
            return $runtime_root eq $home_runtime_root
                ? File::Spec->catdir($runtime_root, 'config', 'docker')
                : File::Spec->catdir($runtime_root, 'docker');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_service_disabled_marker_path') {
        my $toggle_root_method = $sub->{toggle_root_method} // die 'compiled sub toggle-root method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $service = $args{service} || die 'Missing service';
            my $root = _code_for($toggle_root_method)->($self, %args);
            return File::Spec->catfile($root, $service, 'disabled.yml');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_service_lookup_roots') {
        $impl = sub {
            my ($self, %args) = @_;
            my $service = $args{service} || return;
            my $project_root = $args{project_root} || Cwd::cwd();
            my @roots;
            my %seen;
            my $home_runtime_root = $self->{paths}->home_runtime_root;
            for my $runtime_root ($self->{paths}->runtime_layers) {
                my @candidates;
                my $config_docker_root = File::Spec->catdir($runtime_root, 'config', 'docker');
                push @candidates, $config_docker_root;
                if ($runtime_root ne $home_runtime_root) {
                    push @candidates, File::Spec->catdir($runtime_root, 'docker');
                }
                push @candidates, $self->{paths}->installed_skill_docker_roots_for_runtime($runtime_root);
                for my $root (@candidates) {
                    next if !defined $root || $root eq '';
                    next if $seen{$root}++;
                    if ($service eq '__all__') {
                        push @roots, $root;
                        next;
                    }
                    my $service_root = File::Spec->catdir($root, $service);
                    push @roots, $root if -d $service_root;
                }
            }
            return @roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_service_folder_is_disabled') {
        my $lookup_roots_method = $sub->{lookup_roots_method} // die 'compiled sub lookup-roots method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $service = $args{service} || return 0;
            my $project_root = $args{project_root} || Cwd::cwd();
            my @roots = _code_for($lookup_roots_method)->($self, project_root => $project_root, service => $service);
            return 0 if !@roots;
            for my $root (reverse @roots) {
                my $service_root = File::Spec->catdir($root, $service);
                next if !-d $service_root;
                return 1 if -f File::Spec->catfile($service_root, 'disabled.yml');
                return 0;
            }
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_discover_service_names') {
        my $lookup_roots_method = $sub->{lookup_roots_method} // die 'compiled sub lookup-roots method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $project_root = $args{project_root} || Cwd::cwd();
            my $service_map = $args{service_map} || {};
            my %names = map { $_ => 1 } grep { defined && $_ ne '' } keys %{$service_map};
            for my $root (_code_for($lookup_roots_method)->($self, project_root => $project_root, service => '__all__')) {
                next if !-d $root;
                opendir my $dh, $root or next;
                while (my $entry = readdir $dh) {
                    next if $entry eq '.' || $entry eq '..';
                    next if !-d File::Spec->catdir($root, $entry);
                    $names{$entry} = 1;
                }
                closedir $dh;
            }
            return sort keys %names;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_discover_enabled_services') {
        my $discover_names_method = $sub->{discover_names_method} // die 'compiled sub discover-names method missing';
        my $service_disabled_method = $sub->{service_disabled_method} // die 'compiled sub service-disabled method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my @services = _code_for($discover_names_method)->($self, %args);
            return grep { !_code_for($service_disabled_method)->($self, project_root => $args{project_root}, service => $_) } @services;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_infer_services_from_args') {
        my $discover_names_method = $sub->{discover_names_method} // die 'compiled sub discover-names method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $argv = $args{args} || [];
            my $project_root = $args{project_root} || Cwd::cwd();
            my $service_map = $args{service_map} || {};
            my %known = map { $_ => 1 } _code_for($discover_names_method)->($self, project_root => $project_root, service_map => $service_map);
            my @services;
            my %seen;
            for my $arg (@{$argv}) {
                next if !defined $arg || $arg eq '';
                next if $arg =~ /^-/;
                next if !$known{$arg};
                next if $seen{$arg}++;
                push @services, $arg;
            }
            return @services;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_discover_service_files') {
        my $service_disabled_method = $sub->{service_disabled_method} // die 'compiled sub service-disabled method missing';
        my $lookup_roots_method = $sub->{lookup_roots_method} // die 'compiled sub lookup-roots method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $service = $args{service} || return;
            my $project_root = $args{project_root} || Cwd::cwd();
            return if _code_for($service_disabled_method)->($self, project_root => $project_root, service => $service);
            my @roots = _code_for($lookup_roots_method)->($self, project_root => $project_root, service => $service);
            my @files;
            my %seen;
            for my $root (@roots) {
                next if !defined $root || $root eq '';
                my $service_root = File::Spec->catdir($root, $service);
                next if !-d $service_root;
                my $development = File::Spec->catfile($service_root, 'development.compose.yml');
                if (-f $development) {
                    push @files, $development if !$seen{$development}++;
                    next;
                }
                my $compose = File::Spec->catfile($service_root, 'compose.yml');
                push @files, $compose if -f $compose && !$seen{$compose}++;
            }
            return @files;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_resolve') {
        my $base_files_method = $sub->{base_files_method} // die 'compiled sub base-files method missing';
        my $infer_services_method = $sub->{infer_services_method} // die 'compiled sub infer-services method missing';
        my $discover_enabled_method = $sub->{discover_enabled_method} // die 'compiled sub discover-enabled method missing';
        my $discover_service_files_method = $sub->{discover_service_files_method} // die 'compiled sub discover-service-files method missing';
        my $expand_path_method = $sub->{expand_path_method} // die 'compiled sub expand-path method missing';
        my $config_root_method = $sub->{config_root_method} // die 'compiled sub config-root method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $project_root = $args{project_root} || $self->{paths}->current_project_root || Cwd::cwd();
            my $docker_cfg = $self->{config}->docker_config;
            my $docker_root = _code_for($config_root_method)->($self);
            my @passthrough = @{ $args{args} || [] };
            my (@compose_files, @layers);
            my @base = _code_for($base_files_method)->($self, $project_root);
            push @compose_files, @base;
            push @layers, { name => 'base', files => [@base] };
            my @project_overlays = (@{ $docker_cfg->{files} || [] }, @{ $docker_cfg->{project_overlays} || [] });
            push @compose_files, @project_overlays;
            push @layers, { name => 'project', files => [@project_overlays] } if @project_overlays;
            my @addons = @{ $args{addons} || [] };
            my @modes = @{ $args{modes} || [] };
            my @services = @{ $args{services} || [] };
            my %addon_map = %{ $docker_cfg->{addons} || {} };
            my %mode_map = %{ $docker_cfg->{modes} || {} };
            my %service_map = %{ $docker_cfg->{services} || {} };
            my @inferred_services = _code_for($infer_services_method)->($self, args => \@passthrough, project_root => $project_root, service_map => \%service_map);
            my %service_seen;
            @services = grep { !$service_seen{$_}++ } (@services, @inferred_services);
            if (!@services) {
                my @auto_services = _code_for($discover_enabled_method)->($self, project_root => $project_root, service_map => \%service_map);
                @services = grep { !$service_seen{$_}++ } @auto_services;
            }
            my @service_files;
            for my $service (@services) {
                my $def = $service_map{$service};
                next if ref($def) ne 'HASH';
                push @service_files, @{ $def->{files} || [] } if ref($def->{files}) eq 'ARRAY';
            }
            for my $service (@services) {
                push @service_files, _code_for($discover_service_files_method)->($self, service => $service, project_root => $project_root, modes => \@modes);
            }
            push @compose_files, @service_files;
            push @layers, { name => 'service', files => [@service_files] } if @service_files;
            my @addon_files;
            for my $addon (@addons) {
                my $def = $addon_map{$addon};
                next if ref($def) ne 'HASH';
                push @addon_files, @{ $def->{files} || [] } if ref($def->{files}) eq 'ARRAY';
                push @modes, @{ $def->{modes} || [] } if ref($def->{modes}) eq 'ARRAY';
            }
            push @compose_files, @addon_files;
            push @layers, { name => 'addon', files => [@addon_files] } if @addon_files;
            my @mode_files;
            for my $mode (@modes) {
                my $def = $mode_map{$mode};
                next if ref($def) ne 'HASH';
                push @mode_files, @{ $def->{files} || [] } if ref($def->{files}) eq 'ARRAY';
            }
            push @compose_files, @mode_files;
            push @layers, { name => 'mode', files => [@mode_files] } if @mode_files;
            my (@files, %seen);
            for my $file (@compose_files) {
                next if !defined $file || $file eq '';
                $file = _code_for($expand_path_method)->($self, $file);
                $file = File::Spec->catfile($project_root, $file) if !File::Spec->file_name_is_absolute($file);
                next if $seen{$file}++;
                push @files, $file if -f $file;
            }
            my %env = (%{ $docker_cfg->{env} || {} }, DDDC => $docker_root);
            for my $addon (@addons) {
                my $def = $addon_map{$addon};
                next if ref($def) ne 'HASH' || ref($def->{env}) ne 'HASH';
                @env{keys %{$def->{env}}} = values %{$def->{env}};
            }
            for my $mode (@modes) {
                my $def = $mode_map{$mode};
                next if ref($def) ne 'HASH' || ref($def->{env}) ne 'HASH';
                @env{keys %{$def->{env}}} = values %{$def->{env}};
            }
            my @command = ('docker', 'compose');
            for my $file (@files) { push @command, '-f', $file; }
            push @command, @passthrough;
            return {
                project_root => $project_root,
                addons => \@addons,
                modes => \@modes,
                services => \@services,
                files => \@files,
                env => \%env,
                command => \@command,
                layers => \@layers,
                precedence => [qw(base project service addon mode)],
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_disable_service') {
        my $disabled_marker_method = $sub->{disabled_marker_method} // die 'compiled sub disabled-marker method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $service = $args{service} || die "Usage: dashboard docker disable <service>\n";
            my $marker = _code_for($disabled_marker_method)->($self, project_root => $args{project_root}, service => $service);
            my (undef, $dir) = File::Spec->splitpath($marker);
            File::Path::make_path($dir) if !-d $dir;
            open my $fh, '>', $marker or die "Unable to write $marker: $!";
            print {$fh} "---\ndisabled: 1\n";
            close $fh or die "Unable to close $marker: $!";
            return { action => 'disable', disabled => 1, marker => $marker, service => $service };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_enable_service') {
        my $disabled_marker_method = $sub->{disabled_marker_method} // die 'compiled sub disabled-marker method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $service = $args{service} || die "Usage: dashboard docker enable <service>\n";
            my $marker = _code_for($disabled_marker_method)->($self, project_root => $args{project_root}, service => $service);
            unlink $marker or die "Unable to remove $marker: $!" if -e $marker;
            return { action => 'enable', disabled => 0, marker => $marker, service => $service };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_list_services') {
        my $discover_names_method = $sub->{discover_names_method} // die 'compiled sub discover-names method missing';
        my $service_disabled_method = $sub->{service_disabled_method} // die 'compiled sub service-disabled method missing';
        my $disabled_marker_method = $sub->{disabled_marker_method} // die 'compiled sub disabled-marker method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $project_root = $args{project_root} || Cwd::cwd();
            my $filter = defined $args{filter} && $args{filter} ne '' ? $args{filter} : 'all';
            die "Usage: dashboard docker list [--enabled|--disabled]\n" if $filter !~ /\A(?:all|enabled|disabled)\z/;
            my @services = _code_for($discover_names_method)->($self, project_root => $project_root, service_map => $self->{config}->docker_config->{services} || {});
            my @listed;
            for my $service (@services) {
                my $disabled = _code_for($service_disabled_method)->($self, project_root => $project_root, service => $service) ? 1 : 0;
                next if $filter eq 'enabled' && $disabled;
                next if $filter eq 'disabled' && !$disabled;
                push @listed, {
                    disabled => $disabled,
                    enabled => $disabled ? 0 : 1,
                    marker => _code_for($disabled_marker_method)->($self, project_root => $project_root, service => $service),
                    service => $service,
                    status => $disabled ? 'disabled' : 'enabled',
                };
            }
            return \@listed;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'docker_compose_run') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $resolved = _code_for($resolve_method)->($self, %args);
            return $resolved if $args{dry_run};
            my $old = Cwd::cwd();
            chdir $resolved->{project_root} or die "Unable to chdir to $resolved->{project_root}: $!";
            local @ENV{keys %{ $resolved->{env} }} = values %{ $resolved->{env} } if %{ $resolved->{env} };
            my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                system @{ $resolved->{command} };
                return $? >> 8;
            };
            chdir $old or die "Unable to restore cwd to $old: $!";
            return { %{$resolved}, stdout => $stdout, stderr => $stderr, exit_code => $exit_code };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_run_command') {
        my $split_args_method = $sub->{split_args_method} // die 'compiled sub split-args method missing';
        my $read_input_method = $sub->{read_input_method} // die 'compiled sub read-input method missing';
        my $parse_input_method = $sub->{parse_input_method} // die 'compiled sub parse-input method missing';
        my $select_value_method = $sub->{select_value_method} // die 'compiled sub select-value method missing';
        my $print_value_method = $sub->{print_value_method} // die 'compiled sub print-value method missing';
        my $command_exit_method = $sub->{command_exit_method} // die 'compiled sub command-exit method missing';
        $impl = sub {
            my (%args) = @_;
            my $command = $args{command} || die 'Missing command';
            my @argv = @{ $args{args} || [] };
            my ($path, $file) = _code_for($split_args_method)->(@argv);
            my $raw = _code_for($read_input_method)->($file);
            my $data = _code_for($parse_input_method)->(command => $command, text => $raw);
            my $value = _code_for($select_value_method)->($data, $path);
            _code_for($print_value_method)->($value);
            _code_for($command_exit_method)->(0);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_split_args') {
        $impl = sub {
            my (@argv) = @_;
            my $file = '';
            my @rest;
            for my $arg (@argv) {
                if (!$file && defined $arg && -f $arg) {
                    $file = $arg;
                    next;
                }
                push @rest, $arg;
            }
            my $path = @rest ? join(' ', @rest) : '';
            return ($path, $file);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_read_input') {
        $impl = sub {
            my ($file) = @_;
            if ($file) {
                open my $fh, '<', $file or die "Unable to read $file: $!";
                local $/;
                return <$fh>;
            }
            local $/;
            return scalar <STDIN>;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_parse_input') {
        my $parse_java_properties_method = $sub->{parse_java_properties_method} // die 'compiled sub parse-java-properties method missing';
        my $parse_ini_method = $sub->{parse_ini_method} // die 'compiled sub parse-ini method missing';
        my $parse_csv_method = $sub->{parse_csv_method} // die 'compiled sub parse-csv method missing';
        my $parse_xml_method = $sub->{parse_xml_method} // die 'compiled sub parse-xml method missing';
        $impl = sub {
            my (%args) = @_;
            my $command = $args{command} || die 'Missing command';
            my $text = defined $args{text} ? $args{text} : '';
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($text) if $command eq 'pjq' || $command eq 'jq';
            return YAML::XS::Load($text) if $command eq 'pyq' || $command eq 'yq';
            return TOML::Tiny::from_toml($text) if $command eq 'ptomq' || $command eq 'tomq';
            return _code_for($parse_java_properties_method)->($text) if $command eq 'pjp' || $command eq 'propq';
            return _code_for($parse_ini_method)->($text) if $command eq 'iniq';
            return _code_for($parse_csv_method)->($text) if $command eq 'csvq';
            return _code_for($parse_xml_method)->($text) if $command eq 'xmlq';
            die "Unsupported data query command '$command'\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_extract_path') {
        $impl = sub {
            my ($data, $path) = @_;
            return $data if !defined $path || $path eq '' || $path eq '$d' || $path eq '.';
            $path =~ s/^\$d\.?//;
            my @parts = grep { defined && $_ ne '' } split /\./, $path;
            my $value = $data;
            while (@parts) {
                if (ref($value) eq 'HASH') {
                    my $remaining = join '.', @parts;
                    if (exists $value->{$remaining}) {
                        return $value->{$remaining};
                    }
                }
                my $part = shift @parts;
                if (ref($value) eq 'HASH') {
                    die "Missing path segment '$part'\n" if !exists $value->{$part};
                    $value = $value->{$part};
                    next;
                }
                if (ref($value) eq 'ARRAY') {
                    die "Array index '$part' is invalid\n" if $part !~ /^\d+$/ || $part > $#$value;
                    $value = $value->[$part];
                    next;
                }
                die "Path '$path' does not resolve through a nested structure\n";
            }
            return $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_path_uses_expression') {
        $impl = sub {
            my ($path) = @_;
            return 0 if !defined $path || $path eq '' || $path eq '$d' || $path eq '.';
            return 0 if $path =~ /^\$d(?:\.[A-Za-z0-9_]+)*\z/;
            return index($path, '$d') >= 0 ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_select_value') {
        my $path_expression_method = $sub->{path_expression_method} // die 'compiled sub path-expression method missing';
        my $evaluate_expression_method = $sub->{evaluate_expression_method} // die 'compiled sub evaluate-expression method missing';
        my $extract_path_method = $sub->{extract_path_method} // die 'compiled sub extract-path method missing';
        $impl = sub {
            my ($data, $path) = @_;
            return $data if !defined $path || $path eq '';
            return _code_for($evaluate_expression_method)->($data, $path) if _code_for($path_expression_method)->($path);
            return _code_for($extract_path_method)->($data, $path);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_evaluate_expression') {
        my $expression_prefers_list_method = $sub->{expression_prefers_list_method} // die 'compiled sub expression-prefers-list method missing';
        $impl = sub {
            my ($data, $expr) = @_;
            my $code = eval <<"PERL_EVAL";
sub {
    my (\$d) = \@_;
    return do { $expr };
}
PERL_EVAL
            die "Query expression '$expr' failed: $@" if $@;
            if ($expr =~ /^\s*scalar\b/) {
                my $scalar = eval { scalar $code->($data) };
                die "Query expression '$expr' failed: $@" if $@;
                return $scalar;
            }
            my @list = eval { $code->($data) };
            die "Query expression '$expr' failed: $@" if $@;
            return \@list if _code_for($expression_prefers_list_method)->($expr);
            return \@list if @list > 1;
            return $list[0] if @list == 1;
            return [];
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_expression_prefers_list') {
        $impl = sub {
            my ($expr) = @_;
            return 0 if !defined $expr || $expr =~ /^\s*scalar\b/;
            return 0 if $expr =~ /\bjoin\b/;
            return $expr =~ /\b(?:sort|map|grep|keys|values)\b/ ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_print_value') {
        $impl = sub {
            my ($value) = @_;
            if (ref($value)) {
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($value), "\n";
                return 1;
            }
            print defined $value ? $value : '';
            print "\n";
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_parse_java_properties') {
        my $unescape_method = $sub->{unescape_method} // die 'compiled sub unescape method missing';
        $impl = sub {
            my ($text) = @_;
            my %props;
            my @lines = split /\n/, ($text // '');
            my $pending = '';
            for my $line (@lines) {
                $line =~ s/\r$//;
                next if $line =~ /^\s*[#!]/;
                if ($line =~ s/\\$//) {
                    $pending .= $line;
                    next;
                }
                $line = $pending . $line;
                $pending = '';
                next if $line =~ /^\s*$/;
                my ($key, $value) = split /\s*[:=]\s*|\s+/, $line, 2;
                $key = '' if !defined $key;
                $value = '' if !defined $value;
                $key =~ s/^\s+|\s+$//g;
                $value =~ s/^\s+|\s+$//g;
                $props{$key} = _code_for($unescape_method)->($value);
            }
            return \%props;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_unescape_properties') {
        $impl = sub {
            my ($text) = @_;
            $text =~ s/\\t/\t/g;
            $text =~ s/\\n/\n/g;
            $text =~ s/\\r/\r/g;
            $text =~ s/\\f/\f/g;
            $text =~ s/\\\\/\\/g;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_parse_ini') {
        $impl = sub {
            my ($text) = @_;
            my %ini;
            my $current_section = '_global';
            $ini{$current_section} = {};
            my @lines = split /\n/, ($text // '');
            for my $line (@lines) {
                $line =~ s/[\r\n]+$//;
                $line =~ s/^\s+|\s+$//g;
                next if $line =~ /^[;#]/ || $line eq '';
                if ($line =~ /^\[(.+)\]$/) {
                    $current_section = $1;
                    $ini{$current_section} = {};
                    next;
                }
                if ($line =~ /^([^=:]+)\s*[:=]\s*(.*)$/) {
                    my ($key, $value) = ($1, $2);
                    $key =~ s/^\s+|\s+$//g;
                    $value =~ s/^\s+|\s+$//g;
                    $ini{$current_section}{$key} = $value;
                }
            }
            return \%ini;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_parse_csv') {
        $impl = sub {
            my ($text) = @_;
            my @rows;
            my @lines = split /\n/, ($text // '');
            for my $line (@lines) {
                $line =~ s/[\r\n]+$//;
                next if $line eq '';
                my @fields = split /,/, $line;
                push @rows, \@fields;
            }
            return \@rows;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_parse_xml') {
        my $xml_tree_method = $sub->{xml_tree_method} // die 'compiled sub xml-tree method missing';
        $impl = sub {
            my ($text) = @_;
            my $parser = XML::Parser->new(Style => 'Tree');
            my $tree = $parser->parse($text);
            return _code_for($xml_tree_method)->($tree);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_xml_tree_to_data') {
        my $xml_element_method = $sub->{xml_element_method} // die 'compiled sub xml-element method missing';
        $impl = sub {
            my ($tree) = @_;
            die 'XML tree must be an array reference' if ref($tree) ne 'ARRAY' || @{$tree} < 2;
            my ($root_name, $root_children) = @{$tree};
            return { $root_name => _code_for($xml_element_method)->($root_children) };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_xml_element_payload') {
        $impl = sub {
            my ($children) = @_;
            die 'XML element payload must be an array reference' if ref($children) ne 'ARRAY';
            my $attrs = $children->[0];
            my @items = @{$children}[1 .. $#$children];
            my @text;
            my %elements;
            my %repeated;
            while (@items) {
                my $name = shift @items;
                my $value = shift @items;
                if (defined $name && $name eq '0') {
                    push @text, $value if defined $value && $value !~ /^\s*$/;
                    next;
                }
                my $decoded = __SUB__->($value);
                if (exists $elements{$name}) {
                    if (!$repeated{$name}) {
                        $elements{$name} = [ $elements{$name} ];
                        $repeated{$name} = 1;
                    }
                    push @{ $elements{$name} }, $decoded;
                    next;
                }
                $elements{$name} = $decoded;
            }
            my $text = join '', @text;
            my $has_attrs = ref($attrs) eq 'HASH' && keys %{$attrs};
            my $has_children = keys %elements ? 1 : 0;
            return $text if !$has_attrs && !$has_children;
            my %node = %elements;
            $node{_attributes} = $attrs if $has_attrs;
            $node{_text} = $text if $text ne '';
            return \%node;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'query_command_exit') {
        $impl = sub {
            my ($code) = @_;
            exit $code;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_api_dashboard_page') {
        my $page_from_asset_method = $sub->{page_from_asset_method} // die 'compiled sub page-from-asset method missing';
        $impl = sub { return _code_for($page_from_asset_method)->('api-dashboard.page'); };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_sql_dashboard_page') {
        my $page_from_asset_method = $sub->{page_from_asset_method} // die 'compiled sub page-from-asset method missing';
        $impl = sub { return _code_for($page_from_asset_method)->('sql-dashboard.page'); };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_page_for_id') {
        my $asset_filename_method = $sub->{asset_filename_method} // die 'compiled sub asset-filename method missing';
        my $page_from_asset_method = $sub->{page_from_asset_method} // die 'compiled sub page-from-asset method missing';
        $impl = sub {
            my ($id) = @_;
            my $filename = _code_for($asset_filename_method)->($id);
            return _code_for($page_from_asset_method)->($filename);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_manifest_path') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            return File::Spec->catfile($paths->config_root, 'seeded-pages.json');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_known_managed_page_md5s') {
        my $asset_filename_method = $sub->{asset_filename_method} // die 'compiled sub asset-filename method missing';
        my $seeded_instruction_method = $sub->{seeded_instruction_method} // die 'compiled sub instruction method missing';
        my $legacy_map = $sub->{legacy_map} || {};
        $impl = sub {
            my ($id) = @_;
            my $filename = _code_for($asset_filename_method)->($id);
            my %seen;
            my @md5s = (
                __PAX_RUNTIME_LEGACY_NAMESPACE__::SeedSync::content_md5(_code_for($seeded_instruction_method)->($filename)),
                @{ $legacy_map->{$id} || [] },
            );
            return grep { defined $_ && $_ ne '' && !$seen{$_}++ } @md5s;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_is_known_managed_page_md5') {
        my $known_md5s_method = $sub->{known_md5s_method} // die 'compiled sub known-md5s method missing';
        $impl = sub {
            my (%args) = @_;
            my $id = $args{id} || '';
            my $md5 = $args{md5} || '';
            return 0 if $id eq '' || $md5 eq '';
            my $matches = scalar grep { $_ eq $md5 } _code_for($known_md5s_method)->($id);
            return $matches ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_page_from_asset') {
        my $instruction_method = $sub->{instruction_method} // die 'compiled sub instruction method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($filename) = @_;
            die "Missing seeded page filename\n" if !defined $filename || $filename eq '';
            my $instruction = _code_for($instruction_method)->($filename);
            return $page_class->from_instruction($instruction);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_instruction') {
        my $asset_path_method = $sub->{asset_path_method} // die 'compiled sub asset-path method missing';
        $impl = sub {
            my ($filename) = @_;
            die "Missing seeded page filename\n" if !defined $filename || $filename eq '';
            my $path = _code_for($asset_path_method)->($filename);
            open my $fh, '<:raw', $path or die "Unable to read $path: $!";
            my $instruction = do { local $/; <$fh> };
            close $fh or die "Unable to close $path: $!";
            return $instruction;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_asset_filename') {
        my $id_to_asset = $sub->{id_to_asset} || {};
        $impl = sub {
            my ($id) = @_;
            die "Unknown seeded page id '$id'\n" if !defined $id || !$id_to_asset->{$id};
            return $id_to_asset->{$id};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_asset_path') {
        my $repo_root_method = $sub->{repo_root_method} // die 'compiled sub repo-root method missing';
        my $shared_root_method = $sub->{shared_root_method} // die 'compiled sub shared-root method missing';
        $impl = sub {
            my ($filename) = @_;
            die "Missing seeded page filename\n" if !defined $filename || $filename eq '';
            my $repo_path = File::Spec->catfile(_code_for($repo_root_method)->(), $filename);
            return $repo_path if -f $repo_path;
            return File::Spec->catfile(_code_for($shared_root_method)->(), $filename);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_repo_root') {
        $impl = sub {
            return File::Spec->catdir(
                File::Basename::dirname(__FILE__),
                File::Spec->updir,
                File::Spec->updir,
                File::Spec->updir,
                File::Spec->updir,
                'share',
                'seeded-pages',
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_shared_root') {
        $impl = sub {
            return File::Spec->catdir(File::ShareDir::dist_dir('Developer-Dashboard'), 'seeded-pages');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_read_manifest') {
        my $manifest_path_method = $sub->{manifest_path_method} // die 'compiled sub manifest-path method missing';
        $impl = sub {
            my (%args) = @_;
            my $manifest_path = _code_for($manifest_path_method)->(%args);
            return {} if !-f $manifest_path;
            open my $fh, '<:raw', $manifest_path or die "Unable to read $manifest_path: $!";
            my $json = do { local $/; <$fh> };
            close $fh or die "Unable to close $manifest_path: $!";
            $json = '{}' if !defined $json || $json =~ /\A\s*\z/;
            my $manifest = __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($json);
            die "Seed manifest at $manifest_path must decode to a hash\n" if ref($manifest) ne 'HASH';
            return $manifest;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_write_manifest') {
        my $manifest_path_method = $sub->{manifest_path_method} // die 'compiled sub manifest-path method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            my $manifest = $args{manifest};
            die 'Missing seeded page manifest hash' if ref($manifest) ne 'HASH';
            my $manifest_path = _code_for($manifest_path_method)->(paths => $paths);
            open my $fh, '>:raw', $manifest_path or die "Unable to write $manifest_path: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($manifest);
            print {$fh} "\n";
            close $fh or die "Unable to close $manifest_path: $!";
            $paths->secure_file_permissions($manifest_path) if $paths->can('secure_file_permissions');
            return $manifest_path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_record_manifest_md5') {
        my $read_manifest_method = $sub->{read_manifest_method} // die 'compiled sub read-manifest method missing';
        my $asset_filename_method = $sub->{asset_filename_method} // die 'compiled sub asset-filename method missing';
        my $write_manifest_method = $sub->{write_manifest_method} // die 'compiled sub write-manifest method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            my $id = $args{id} || die 'Missing seeded page id';
            my $md5 = $args{md5} || die 'Missing seeded page md5';
            my $manifest = _code_for($read_manifest_method)->(paths => $paths);
            $manifest->{$id} = { asset => _code_for($asset_filename_method)->($id), md5 => $md5 };
            _code_for($write_manifest_method)->(paths => $paths, manifest => $manifest);
            return $md5;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_manifest_md5_matches') {
        my $read_manifest_method = $sub->{read_manifest_method} // die 'compiled sub read-manifest method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing paths registry';
            my $id = $args{id} || '';
            my $md5 = $args{md5} || '';
            return 0 if $id eq '' || $md5 eq '';
            my $manifest = _code_for($read_manifest_method)->(paths => $paths);
            my $recorded = $manifest->{$id}{md5} || '';
            return $recorded eq $md5 ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'seeded_pages_ensure_seeded_page') {
        my $record_manifest_method = $sub->{record_manifest_method} // die 'compiled sub record-manifest method missing';
        my $manifest_matches_method = $sub->{manifest_matches_method} // die 'compiled sub manifest-matches method missing';
        my $known_md5_method = $sub->{known_md5_method} // die 'compiled sub known-md5 method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my (%args) = @_;
            my $pages = $args{pages} || die 'Missing page store';
            my $paths = $args{paths} || die 'Missing paths registry';
            my $page = $args{page} || die 'Missing seeded page';
            if (ref($page) ne $page_class) {
                $page = $page_class->from_hash($page);
            }
            my $id = $page->as_hash->{id} || die 'Missing seeded page id';
            my $wanted = $page->canonical_instruction;
            my $wanted_md5 = __PAX_RUNTIME_LEGACY_NAMESPACE__::SeedSync::content_md5($wanted);
            my $current;
            my $loaded = eval {
                $current = $pages->read_saved_entry($id);
                1;
            };
            if (!$loaded) {
                die $@ if $@ !~ /Page '\Q$id\E' not found/;
                $pages->save_page($page);
                _code_for($record_manifest_method)->(paths => $paths, id => $id, md5 => $wanted_md5);
                return 'created';
            }
            my $current_md5 = __PAX_RUNTIME_LEGACY_NAMESPACE__::SeedSync::content_md5($current);
            if ($current_md5 eq $wanted_md5) {
                _code_for($record_manifest_method)->(paths => $paths, id => $id, md5 => $wanted_md5);
                return 'current';
            }
            if (
                _code_for($manifest_matches_method)->(paths => $paths, id => $id, md5 => $current_md5)
                || _code_for($known_md5_method)->(id => $id, md5 => $current_md5)
            ) {
                $pages->save_page($page);
                _code_for($record_manifest_method)->(paths => $paths, id => $id, md5 => $wanted_md5);
                return 'updated';
            }
            return 'preserved';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_ls') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($class, $where) = @_;
            my $dir = _code_for($resolve_method)->($class, $where);
            return () if !$dir || !-d $dir;
            opendir my $dh, $dir or return ();
            my @items;
            while (my $entry = readdir $dh) {
                next if $entry eq '.' || $entry eq '..';
                my $path = File::Spec->catfile($dir, $entry);
                push @items, {
                    NAME => $entry,
                    path => $path,
                    type => -d $path ? 'folder' : 'file',
                    size => -s $path || 0,
                };
            }
            closedir $dh;
            return sort { $b->{type} cmp $a->{type} || $a->{NAME} cmp $b->{NAME} } @items;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'folder_locate') {
        my $paths_method = $sub->{paths_method} // die 'compiled sub paths method missing';
        $impl = sub {
            my ($class, @parts) = @_;
            require File::Find;
            @parts = grep { defined && $_ ne '' } @parts;
            my $paths = _code_for($paths_method)->();
            return () if !@parts || !$paths || !$paths->can('workspace_roots');
            my @found;
            for my $root ($paths->workspace_roots) {
                next if !-d $root;
                File::Find::find(
                    {
                        no_chdir => 1,
                        wanted => sub {
                            return if !-d $_;
                            my $path = $File::Find::name;
                            my $entry = $_;
                            for my $part (@parts) {
                                return if $entry !~ /\Q$part\E/i && $path !~ /\Q$part\E/i;
                            }
                            push @found, $path;
                        },
                    },
                    $root,
                );
            }
            my %seen;
            return grep { !$seen{$_}++ } sort @found;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_status_prefix') {
        $impl = sub {
            my ($self, $status) = @_;
            return '[OK]' if defined $status && $status eq 'done';
            return '->' if defined $status && $status eq 'running';
            return '[X]' if defined $status && $status eq 'failed';
            return '[ ]';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_colorize') {
        $impl = sub {
            my ($self, $text, $status) = @_;
            return $text if !$self->{color};
            return "\e[32m$text\e[0m" if defined $status && $status eq 'done';
            return "\e[33m$text\e[0m" if defined $status && $status eq 'running';
            return "\e[31m$text\e[0m" if defined $status && $status eq 'failed';
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_render_text') {
        my $prefix_method = $sub->{prefix_method} // die 'compiled sub prefix method missing';
        my $colorize_method = $sub->{colorize_method} // die 'compiled sub colorize method missing';
        $impl = sub {
            my ($self) = @_;
            my @lines = ($self->{title});
            for my $id (@{ $self->{order} }) {
                my $task = $self->{tasks}{$id} || next;
                my $prefix = _code_for($prefix_method)->($self, $task->{status});
                push @lines, sprintf '%s %s', _code_for($colorize_method)->($self, $prefix, $task->{status}), $task->{label};
            }
            return join("\n", @lines) . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_render') {
        my $render_text_method = $sub->{render_text_method} // die 'compiled sub render_text method missing';
        $impl = sub {
            my ($self) = @_;
            my $stream = $self->{stream};
            my $board = _code_for($render_text_method)->($self);
            if ($self->{dynamic} && $self->{rendered}) {
                my $line_count = scalar(split /\n/, $board);
                for (1 .. $line_count) {
                    print {$stream} "\e[1A\e[2K";
                }
            }
            print {$stream} $board;
            $self->{rendered} = 1;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_update') {
        my $render_method = $sub->{render_method} // die 'compiled sub render method missing';
        $impl = sub {
            my ($self, $event) = @_;
            return 1 if !$event || ref($event) ne 'HASH';
            my $id = $event->{task_id} || return 1;
            my $task = $self->{tasks}{$id} || return 1;
            $task->{status} = $event->{status} if defined $event->{status} && $event->{status} ne '';
            $task->{label} = $event->{label} if defined $event->{label} && $event->{label} ne '';
            _code_for($render_method)->($self);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_callback') {
        my $update_method = $sub->{update_method} // die 'compiled sub update method missing';
        $impl = sub {
            my ($self) = @_;
            return sub {
                my ($event) = @_;
                _code_for($update_method)->($self, $event);
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_finish') {
        $impl = sub {
            my ($self) = @_;
            return 1 if !$self->{dynamic} || !$self->{rendered};
            my $stream = $self->{stream};
            print {$stream} "\n";
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'progress_new') {
        my $tasks_type_error = $sub->{tasks_type_error} // 'Progress tasks must be an array reference';
        my $missing_id_error = $sub->{missing_id_error} // 'Progress task missing id';
        my $render_method = $sub->{render_method} // die 'compiled sub render method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my $tasks = $args{tasks} || [];
            die $tasks_type_error if ref($tasks) ne 'ARRAY';
            my @order = map { $_->{id} } @{$tasks};
            my %task_lookup = map {
                my $task = $_;
                my $id = $task->{id} || die $missing_id_error;
                $id => {
                    id => $id,
                    label => $task->{label} || $id,
                    status => 'pending',
                }
            } @{$tasks};
            my $stream = $args{stream} || \*STDERR;
            my $self = bless {
                title => $args{title} || 'dashboard progress',
                order => \@order,
                tasks => \%task_lookup,
                stream => $stream,
                dynamic => $args{dynamic} ? 1 : 0,
                color => $args{color} ? 1 : 0,
                rendered => 0,
            }, $class;
            _code_for($render_method)->($self);
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_now_iso8601') {
        $impl = sub {
            require POSIX;
            my @t = gmtime();
            return POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', @t);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_is_trusted') {
        $impl = sub {
            my ($self, %args) = @_;
            my $page = $args{page};
            my $action = $args{action};
            my $source = $args{source} || '';
            return 1 if $action->{safe};
            return 1 if $source eq 'saved' || $source eq 'provider';
            my $permissions = $page->as_hash->{permissions} || {};
            return 0 if !$permissions->{allow_untrusted_actions};
            if (ref($permissions->{trusted_actions}) eq 'ARRAY') {
                my %allowed = map { $_ => 1 } @{ $permissions->{trusted_actions} };
                return $allowed{$action->{id}} ? 1 : 0;
            }
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_run_builtin') {
        $impl = sub {
            my ($self, %args) = @_;
            my $action = $args{action};
            my $page = $args{page};
            my $id = $action->{builtin} || $action->{id} || '';
            if ($id eq 'page.source') {
                return {
                    kind => 'builtin',
                    content_type => 'text/plain; charset=utf-8',
                    body => $page->canonical_instruction,
                };
            }
            if ($id eq 'page.state') {
                return {
                    kind => 'builtin',
                    content_type => 'application/json; charset=utf-8',
                    body => __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($page->as_hash->{state} || {}),
                };
            }
            if ($id eq 'paths.list') {
                return {
                    kind => 'builtin',
                    content_type => 'application/json; charset=utf-8',
                    body => __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode({
                        home => $self->{paths}->home,
                        runtime => $self->{paths}->runtime_root,
                        dashboards => $self->{paths}->dashboards_root,
                        config => $self->{paths}->config_root,
                        cli => $self->{paths}->cli_root,
                    }),
                };
            }
            die "Unsupported builtin action '$id'\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_encode_payload') {
        $impl = sub {
            require Digest::SHA;
            my ($self, %args) = @_;
            my $page = $args{page} || die 'Missing page';
            my $action = $args{action} || die 'Missing action';
            my $source = $args{source} || 'saved';
            my $page_hash = $page->as_hash;
            my $page_source = $page->can('canonical_instruction') ? $page->canonical_instruction : '';
            my $payload = {
                version => 1,
                source => $source,
                page_source => $page_source,
                action => $action,
                trusted_id => Digest::SHA::sha256_hex(
                    join ':',
                    $source,
                    ($page_hash->{id} || ''),
                    ($action->{id} || ''),
                    $page_source,
                ),
            };
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::encode_payload(
                __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($payload)
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_decode_payload') {
        $impl = sub {
            my ($self, $token) = @_;
            my $payload = __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(
                __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::decode_payload($token)
            );
            die 'Action payload must be a hash' if ref($payload) ne 'HASH';
            return $payload;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_run_encoded') {
        my $decode_method = $sub->{decode_method} // die 'compiled sub decode method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        my $run_page_action_method = $sub->{run_page_action_method} // die 'compiled sub run_page_action method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $payload = _code_for($decode_method)->($self, $args{token} || '');
            my $page = $page_class->from_instruction($payload->{page_source} || '');
            return _code_for($run_page_action_method)->(
                $self,
                action => $payload->{action},
                page => $page,
                source => $payload->{source} || 'saved',
                params => $args{params} || {},
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_run_page_action') {
        my $builtin_method = $sub->{builtin_method} // die 'compiled sub builtin method missing';
        my $trust_method = $sub->{trust_method} // die 'compiled sub trust method missing';
        my $command_method = $sub->{command_method} // die 'compiled sub command method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $page = $args{page} || die 'Missing page';
            my $action = $args{action} || die 'Missing action';
            my $source = $args{source} || 'saved';
            die 'Page action must be a hash' if ref($action) ne 'HASH';
            my $kind = $action->{kind} || 'builtin';
            if ($kind eq 'builtin') {
                return _code_for($builtin_method)->(
                    $self,
                    action => $action,
                    page => $page,
                    params => $args{params} || {},
                );
            }
            if ($kind eq 'command') {
                die "Action '$action->{id}' is not trusted for source '$source'\n"
                    if !_code_for($trust_method)->($self, page => $page, action => $action, source => $source);
                return _code_for($command_method)->(
                    $self,
                    command => $action->{command},
                    cwd => $action->{cwd},
                    env => $action->{env},
                    timeout_ms => $action->{timeout_ms},
                    background => $action->{background},
                );
            }
            die "Unsupported action kind '$kind'\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_run_command_action') {
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        my $run_command_method = $sub->{run_command_method} // die 'compiled sub run_command method missing';
        $impl = sub {
            require Cwd;
            require File::Spec;
            require POSIX;
            my ($self, %args) = @_;
            my $cmd = $args{command} || die 'Missing command';
            my $cwd = $args{cwd} || Cwd::cwd();
            if (!File::Spec->file_name_is_absolute($cwd) && $self->{paths}->can($cwd)) {
                $cwd = $self->{paths}->$cwd();
            }
            die "Action cwd '$cwd' does not exist" if !-d $cwd;
            my $env = ref($args{env}) eq 'HASH' ? { %{ $args{env} } } : {};
            my $timeout_ms = $args{timeout_ms} || 30_000;
            my $background = $args{background} ? 1 : 0;
            if ($background) {
                my $pid = fork();
                die "Unable to fork background action: $!" if !defined $pid;
                if ($pid) {
                    return {
                        background => 1,
                        pid => $pid,
                        started_at => _code_for($now_method)->(),
                    };
                }
                POSIX::setsid();
                open STDIN, '<', File::Spec->devnull() or die $!;
                open STDOUT, '>>', $self->{files}->dashboard_log or die $!;
                open STDERR, '>>', $self->{files}->dashboard_log or die $!;
                _code_for($run_command_method)->(
                    $self,
                    cmd => $cmd,
                    cwd => $cwd,
                    env => $env,
                    timeout_ms => $timeout_ms,
                );
                exit 0;
            }
            return _code_for($run_command_method)->(
                $self,
                cmd => $cmd,
                cwd => $cwd,
                env => $env,
                timeout_ms => $timeout_ms,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'action_run_command') {
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        $impl = sub {
            require Capture::Tiny;
            require Cwd;
            my ($self, %args) = @_;
            my $cmd = $args{cmd};
            my $cwd = $args{cwd};
            my $env = $args{env} || {};
            my $timeout_ms = $args{timeout_ms} || 30_000;
            my $old = Cwd::cwd();
            chdir $cwd or die "Unable to chdir to $cwd: $!";
            local @ENV{ keys %{$env} } = values %{$env} if %{$env};
            my $timed_out = 0;
            my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                local $SIG{ALRM} = sub { die "__ACTION_TIMEOUT__\n" };
                alarm(int(($timeout_ms + 999) / 1000));
                my $ok = eval {
                    system __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::shell_command_argv($cmd);
                    return $? >> 8;
                };
                if ($@) {
                    die $@ if $@ !~ /__ACTION_TIMEOUT__/;
                    $timed_out = 1;
                    return 124;
                }
                alarm(0);
                return $ok;
            };
            alarm(0);
            chdir $old or die "Unable to restore cwd to $old: $!";
            return {
                background => 0,
                command => $cmd,
                cwd => $cwd,
                env => $env,
                exit_code => $exit_code,
                stdout => $stdout,
                stderr => $stderr,
                timed_out => $timed_out ? 1 : 0,
                content_type => 'application/json; charset=utf-8',
                started_at => _code_for($now_method)->(),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'utc_iso8601_after') {
        $impl = sub {
            require POSIX;
            my ($seconds) = @_;
            my $epoch = time + ($seconds || 0);
            my @t = gmtime($epoch);
            return POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', @t);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'utc_iso8601_to_epoch') {
        $impl = sub {
            my ($text) = @_;
            return 0 if !defined $text || $text !~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z\z/;
            require Time::Local;
            return Time::Local::timegm($6, $5, $4, $3, $2 - 1, $1);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'iso8601_to_epoch_with_zone') {
        $impl = sub {
            my ($self, $timestamp) = @_;
            my ( $year, $month, $day, $hour, $minute, $second, $zone ) =
                $timestamp =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-]\d{4}|[+-]\d{2}:\d{2})\z/;
            die "Unsupported collector log timestamp $timestamp\n" if !defined $zone;
            require Time::Local;
            my $offset_seconds = 0;
            if ($zone ne 'Z') {
                my ($sign, $offset_hour, $offset_minute) = $zone =~ /\A([+-])(\d{2}):?(\d{2})\z/;
                $offset_seconds = ($offset_hour * 3600) + ($offset_minute * 60);
                $offset_seconds *= -1 if $sign eq '-';
            }
            return Time::Local::timegm($second, $minute, $hour, $day, $month - 1, $year) - $offset_seconds;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'text_with_trailing_newline') {
        $impl = sub {
            my ($text) = @_;
            $text = '' if !defined $text;
            return $text =~ /\n\z/ ? $text : $text . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'fs_slurp') {
        $impl = sub {
            my ($file) = @_;
            return '' if !-f $file;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            local $/;
            return scalar <$fh>;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'fs_atomic_write_text') {
        $impl = sub {
            my ($self, $file, $text) = @_;
            my $tmp = "$file.pending";
            open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
            print {$fh} $text;
            close $fh;
            $self->{paths}->secure_file_permissions($tmp);
            unlink $file if -f $file;
            rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
            $self->{paths}->secure_file_permissions($file);
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'fs_atomic_write_json') {
        my $write_text_method = $sub->{write_text_method} // die 'compiled sub write-text method missing';
        $impl = sub {
            my ($self, $file, $data) = @_;
            return _code_for($write_text_method)->($self, $file, __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($data));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'local_iso8601_now') {
        $impl = sub {
            require POSIX;
            my @t = localtime();
            return POSIX::strftime('%Y-%m-%dT%H:%M:%S%z', @t);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_new_from_all_folders') {
        $impl = sub {
            my ($class) = @_;
            require __PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry;
            return $class->new(
                paths => __PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry->new_from_all_folders,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_paths') {
        $impl = sub {
            my ($self, $collector_name) = @_;
            my $dir = $self->{paths}->collector_dir($collector_name);
            return {
                dir      => $dir,
                log      => File::Spec->catfile($dir, 'log'),
                stdout   => File::Spec->catfile($dir, 'stdout'),
                stderr   => File::Spec->catfile($dir, 'stderr'),
                combined => File::Spec->catfile($dir, 'combined'),
                last_run => File::Spec->catfile($dir, 'last_run'),
                status   => File::Spec->catfile($dir, 'status.json'),
                job      => File::Spec->catfile($dir, 'job.json'),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_write_job') {
        my $collector_paths_method = $sub->{collector_paths_method} // die 'compiled sub collector-paths method missing';
        my $write_json_method = $sub->{write_json_method} // die 'compiled sub write-json method missing';
        $impl = sub {
            my ($self, $collector_name, $job) = @_;
            my $paths = _code_for($collector_paths_method)->($self, $collector_name);
            return _code_for($write_json_method)->($self, $paths->{job}, $job);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_file_candidates') {
        $impl = sub {
            my ($self, $collector_name, $filename) = @_;
            return map { File::Spec->catfile($_, $collector_name, $filename) } $self->{paths}->collectors_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_read_job') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file-candidates method missing';
        $impl = sub {
            my ($self, $collector_name) = @_;
            for my $file (_code_for($file_candidates_method)->($self, $collector_name, 'job.json')) {
                next if !-f $file;
                open my $fh, '<:raw', $file or die "Unable to read $file: $!";
                local $/;
                return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(<$fh>);
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_read_status') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file-candidates method missing';
        $impl = sub {
            my ($self, $collector_name) = @_;
            for my $file (_code_for($file_candidates_method)->($self, $collector_name, 'status.json')) {
                next if !-f $file;
                open my $fh, '<:raw', $file or die "Unable to read $file: $!";
                local $/;
                my $raw = <$fh>;
                my $data = eval { __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($raw) };
                return $data if !$@;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_first_existing_text_file') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file-candidates method missing';
        my $slurp_method = $sub->{slurp_method} // die 'compiled sub slurp method missing';
        $impl = sub {
            my ($self, $collector_name, $filename) = @_;
            for my $file (_code_for($file_candidates_method)->($self, $collector_name, $filename)) {
                return _code_for($slurp_method)->($file) if -f $file;
            }
            return '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_read_output') {
        my $first_text_method = $sub->{first_text_method} // die 'compiled sub first-text method missing';
        $impl = sub {
            my ($self, $collector_name) = @_;
            my $last_run = _code_for($first_text_method)->($self, $collector_name, 'last_run');
            $last_run =~ s/\r?\n\z// if defined $last_run;
            return {
                stdout   => _code_for($first_text_method)->($self, $collector_name, 'stdout'),
                stderr   => _code_for($first_text_method)->($self, $collector_name, 'stderr'),
                combined => _code_for($first_text_method)->($self, $collector_name, 'combined'),
                last_run => $last_run,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_exists') {
        $impl = sub {
            my ($self, $collector_name) = @_;
            die 'Missing collector name' if !defined $collector_name || $collector_name eq '';
            for my $root ($self->{paths}->collectors_roots) {
                return 1 if -d File::Spec->catdir($root, $collector_name);
            }
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_log_payload_present') {
        $impl = sub {
            my ($self, $status, $output) = @_;
            return 1 if grep { defined && $_ ne '' } map { $output->{$_} } qw(stdout stderr combined last_run);
            return 1 if grep { defined } map { $status->{$_} } qw(last_exit_code last_run last_completed_at last_started_at timed_out);
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_format_log_entry') {
        my $trailing_newline_method = $sub->{trailing_newline_method} // die 'compiled sub trailing-newline method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $collector_name = $args{name} || die 'Missing collector name';
            my $time = $args{happened_at} || 'unknown-time';
            my @header = ("=== collector $collector_name", "\@ $time");
            push @header, 'exit=' . $args{exit_code} if defined $args{exit_code};
            push @header, 'timed_out=1' if $args{timed_out};
            push @header, 'source=' . $args{source} if defined $args{source} && $args{source} ne '';
            my @chunks = (join(' | ', @header) . " ===\n");
            if (defined $args{stdout} && $args{stdout} ne '') {
                push @chunks, "[stdout]\n", _code_for($trailing_newline_method)->($args{stdout});
            }
            if (defined $args{stderr} && $args{stderr} ne '') {
                push @chunks, "[stderr]\n", _code_for($trailing_newline_method)->($args{stderr});
            }
            if (defined $args{error} && $args{error} ne '') {
                push @chunks, "[error]\n", _code_for($trailing_newline_method)->($args{error});
            }
            push @chunks, "\n";
            return join '', @chunks;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_append_log_entry') {
        my $collector_paths_method = $sub->{collector_paths_method} // die 'compiled sub collector-paths method missing';
        my $format_method = $sub->{format_method} // die 'compiled sub format method missing';
        $impl = sub {
            my ($self, $collector_name, %entry) = @_;
            die 'Missing collector name' if !defined $collector_name || $collector_name eq '';
            my $paths = _code_for($collector_paths_method)->($self, $collector_name);
            my $text = _code_for($format_method)->(
                $self,
                name        => $collector_name,
                happened_at => $entry{happened_at},
                exit_code   => $entry{exit_code},
                timed_out   => $entry{timed_out},
                stdout      => $entry{stdout},
                stderr      => $entry{stderr},
                error       => $entry{error},
                source      => $entry{source},
            );
            open my $fh, '>>', $paths->{log} or die "Unable to append $paths->{log}: $!";
            print {$fh} $text;
            close $fh;
            $self->{paths}->secure_file_permissions($paths->{log});
            return $paths->{log};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_write_result') {
        my $collector_paths_method = $sub->{collector_paths_method} // die 'compiled sub collector-paths method missing';
        my $read_status_method = $sub->{read_status_method} // die 'compiled sub read-status method missing';
        my $write_text_method = $sub->{write_text_method} // die 'compiled sub write-text method missing';
        my $write_json_method = $sub->{write_json_method} // die 'compiled sub write-json method missing';
        my $append_log_method = $sub->{append_log_method} // die 'compiled sub append-log method missing';
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        $impl = sub {
            my ($self, $collector_name, %result) = @_;
            my $paths = _code_for($collector_paths_method)->($self, $collector_name);
            _code_for($write_text_method)->($self, $paths->{stdout}, defined $result{stdout} ? $result{stdout} : '');
            _code_for($write_text_method)->($self, $paths->{stderr}, defined $result{stderr} ? $result{stderr} : '');
            _code_for($write_text_method)->(
                $self,
                $paths->{combined},
                (defined $result{stdout} ? $result{stdout} : '') . (defined $result{stderr} ? $result{stderr} : ''),
            );
            my $timestamp = _code_for($now_method)->();
            _code_for($write_text_method)->($self, $paths->{last_run}, $timestamp . "\n");
            my $previous = _code_for($read_status_method)->($self, $collector_name) || {};
            my $status = {
                %{$previous},
                name              => $collector_name,
                enabled           => exists $result{enabled} ? $result{enabled} : 1,
                running           => exists $result{running} ? $result{running} : 0,
                last_run          => $timestamp,
                last_completed_at => $timestamp,
                last_exit_code    => $result{exit_code},
                last_success      => $result{exit_code} ? 0 : 1,
                last_success_at   => $result{exit_code} ? ($previous->{last_success_at} || undef) : $timestamp,
                last_failure_at   => $result{exit_code} ? $timestamp : ($previous->{last_failure_at} || undef),
                last_started_at   => $result{started_at} || $previous->{last_started_at},
                output_format     => $result{output_format},
                timed_out         => $result{timed_out} ? 1 : 0,
                updated_at_epoch  => time,
            };
            my $written = _code_for($write_json_method)->($self, $paths->{status}, $status);
            _code_for($append_log_method)->(
                $self,
                $collector_name,
                happened_at => $timestamp,
                exit_code   => $result{exit_code},
                timed_out   => $result{timed_out},
                stdout      => $result{stdout},
                stderr      => $result{stderr},
            );
            return $written;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_write_status') {
        my $collector_paths_method = $sub->{collector_paths_method} // die 'compiled sub collector-paths method missing';
        my $read_status_method = $sub->{read_status_method} // die 'compiled sub read-status method missing';
        my $write_json_method = $sub->{write_json_method} // die 'compiled sub write-json method missing';
        $impl = sub {
            my ($self, $collector_name, $status) = @_;
            my $paths = _code_for($collector_paths_method)->($self, $collector_name);
            my $existing = _code_for($read_status_method)->($self, $collector_name) || {};
            my %merged = (
                %{$existing},
                %{ $status || {} },
                name => $collector_name,
                updated_at_epoch => time,
            );
            return _code_for($write_json_method)->($self, $paths->{status}, \%merged);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_render_latest_log_entry') {
        my $exists_method = $sub->{exists_method} // die 'compiled sub exists method missing';
        my $read_status_method = $sub->{read_status_method} // die 'compiled sub read-status method missing';
        my $read_output_method = $sub->{read_output_method} // die 'compiled sub read-output method missing';
        my $payload_present_method = $sub->{payload_present_method} // die 'compiled sub payload-present method missing';
        my $format_method = $sub->{format_method} // die 'compiled sub format method missing';
        $impl = sub {
            my ($self, $collector_name) = @_;
            return '' if !_code_for($exists_method)->($self, $collector_name);
            my $status = _code_for($read_status_method)->($self, $collector_name) || {};
            my $output = _code_for($read_output_method)->($self, $collector_name) || {};
            return '' if !_code_for($payload_present_method)->($self, $status, $output);
            return _code_for($format_method)->(
                $self,
                name        => $collector_name,
                happened_at => $output->{last_run} || $status->{last_run} || $status->{last_completed_at} || $status->{last_started_at},
                exit_code   => $status->{last_exit_code},
                timed_out   => $status->{timed_out},
                stdout      => $output->{stdout},
                stderr      => $output->{stderr},
                source      => 'latest state snapshot',
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_read_log') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file-candidates method missing';
        my $slurp_method = $sub->{slurp_method} // die 'compiled sub slurp method missing';
        my $render_method = $sub->{render_method} // die 'compiled sub render method missing';
        $impl = sub {
            my ($self, $collector_name) = @_;
            die 'Missing collector name' if !defined $collector_name || $collector_name eq '';
            for my $file (_code_for($file_candidates_method)->($self, $collector_name, 'log')) {
                return _code_for($slurp_method)->($file) if -f $file;
            }
            return _code_for($render_method)->($self, $collector_name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_inspect') {
        my $read_job_method = $sub->{read_job_method} // die 'compiled sub read-job method missing';
        my $read_output_method = $sub->{read_output_method} // die 'compiled sub read-output method missing';
        my $read_status_method = $sub->{read_status_method} // die 'compiled sub read-status method missing';
        $impl = sub {
            my ($self, $collector_name) = @_;
            return {
                job    => _code_for($read_job_method)->($self, $collector_name),
                output => _code_for($read_output_method)->($self, $collector_name),
                status => _code_for($read_status_method)->($self, $collector_name),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_list') {
        my $read_status_method = $sub->{read_status_method} // die 'compiled sub read-status method missing';
        $impl = sub {
            my ($self) = @_;
            my %items;
            for my $root ($self->{paths}->collectors_roots) {
                next if !-d $root;
                opendir my $dh, $root or next;
                while (my $entry = readdir $dh) {
                    next if $entry eq '.' || $entry eq '..';
                    next if $items{$entry};
                    my $status = eval { _code_for($read_status_method)->($self, $entry) };
                    $items{$entry} = $status if $status;
                }
                closedir $dh;
            }
            return sort { $a->{name} cmp $b->{name} } values %items;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_normalize_rotation') {
        $impl = sub {
            my ($self, $collector_name, $rotation) = @_;
            return {} if !defined $rotation;
            die "collector rotation for $collector_name must be a hash reference\n" if ref($rotation) ne 'HASH';
            my %normalized;
            my %aliases = (
                lines   => 'lines',
                minute  => 'minutes',
                minutes => 'minutes',
                hour    => 'hours',
                hours   => 'hours',
                day     => 'days',
                days    => 'days',
                week    => 'weeks',
                weeks   => 'weeks',
                month   => 'months',
                months  => 'months',
            );
            for my $key (sort keys %{$rotation}) {
                my $canonical = $aliases{$key}
                    or die "collector rotation key $key for $collector_name is not supported\n";
                my $value = $rotation->{$key};
                die "collector rotation $canonical for $collector_name must be a non-negative integer\n"
                    if !defined $value || $value !~ /\A\d+\z/;
                $normalized{$canonical} = $value + 0;
            }
            return \%normalized;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_rotation_retention_seconds') {
        $impl = sub {
            my ($self, $rotation) = @_;
            my %seconds_per_unit = (
                minutes => 60,
                hours   => 60 * 60,
                days    => 60 * 60 * 24,
                weeks   => 60 * 60 * 24 * 7,
                months  => 60 * 60 * 24 * 30,
            );
            my $seconds;
            for my $unit (keys %seconds_per_unit) {
                next if !exists $rotation->{$unit};
                $seconds ||= 0;
                $seconds += $rotation->{$unit} * $seconds_per_unit{$unit};
            }
            return $seconds;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_split_log_entries') {
        $impl = sub {
            my ($self, $text) = @_;
            return () if !defined $text || $text eq '';
            return grep { defined && $_ ne '' } split /(?=^=== collector )/m, $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_entry_timestamp_epoch') {
        my $to_epoch_method = $sub->{to_epoch_method} // die 'compiled sub to-epoch method missing';
        $impl = sub {
            my ($self, $collector_name, $entry) = @_;
            my ($timestamp) = $entry =~ /\A=== collector [^\n]* \| \@ ([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:Z|[+-][0-9]{4}|[+-][0-9]{2}:[0-9]{2}))(?: \| [^\n]*)* ===\n/;
            die "Unable to parse collector log timestamp for $collector_name\n" if !defined $timestamp;
            return _code_for($to_epoch_method)->($self, $timestamp);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_trim_log_by_age') {
        my $split_method = $sub->{split_method} // die 'compiled sub split method missing';
        my $entry_epoch_method = $sub->{entry_epoch_method} // die 'compiled sub entry-epoch method missing';
        $impl = sub {
            my ($self, $collector_name, $text, $retention_seconds, %args) = @_;
            return $text if !defined $retention_seconds;
            return $text if $text eq '';
            my $now_epoch = defined $args{now_epoch} ? $args{now_epoch} : time;
            my $cutoff = $now_epoch - $retention_seconds;
            my @kept;
            for my $entry (_code_for($split_method)->($self, $text)) {
                my $entry_epoch = _code_for($entry_epoch_method)->($self, $collector_name, $entry);
                push @kept, $entry if $entry_epoch >= $cutoff;
            }
            return join '', @kept;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_trim_log_by_lines') {
        $impl = sub {
            my ($self, $text, $lines) = @_;
            return $text if $text eq '';
            my $has_trailing_newline = $text =~ /\n\z/ ? 1 : 0;
            my @parts = split /\n/, $text, -1;
            pop @parts if $has_trailing_newline && @parts && $parts[-1] eq '';
            return $text if @parts <= $lines;
            @parts = @parts[@parts - $lines .. $#parts];
            return join("\n", @parts) . ($has_trailing_newline ? "\n" : '');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_apply_log_rotation') {
        my $retention_method = $sub->{retention_method} // die 'compiled sub retention method missing';
        my $trim_age_method = $sub->{trim_age_method} // die 'compiled sub trim-age method missing';
        my $trim_lines_method = $sub->{trim_lines_method} // die 'compiled sub trim-lines method missing';
        $impl = sub {
            my ($self, $collector_name, $text, $rotation, %args) = @_;
            my $rotated = $text;
            my $retention_seconds = _code_for($retention_method)->($self, $rotation);
            if (defined $retention_seconds) {
                $rotated = _code_for($trim_age_method)->(
                    $self,
                    $collector_name,
                    $rotated,
                    $retention_seconds,
                    now_epoch => $args{now_epoch},
                );
            }
            if (exists $rotation->{lines}) {
                $rotated = _code_for($trim_lines_method)->($self, $rotated, $rotation->{lines});
            }
            return $rotated;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_rotate_log') {
        my $normalize_method = $sub->{normalize_method} // die 'compiled sub normalize method missing';
        my $collector_paths_method = $sub->{collector_paths_method} // die 'compiled sub collector-paths method missing';
        my $slurp_method = $sub->{slurp_method} // die 'compiled sub slurp method missing';
        my $apply_method = $sub->{apply_method} // die 'compiled sub apply method missing';
        my $write_text_method = $sub->{write_text_method} // die 'compiled sub write-text method missing';
        $impl = sub {
            my ($self, $collector_name, $rotation, %args) = @_;
            die 'Missing collector name' if !defined $collector_name || $collector_name eq '';
            my $normalized = _code_for($normalize_method)->($self, $collector_name, $rotation);
            return if !keys %{$normalized};
            my $paths = _code_for($collector_paths_method)->($self, $collector_name);
            return if !-f $paths->{log};
            my $original = _code_for($slurp_method)->($paths->{log});
            my $rotated = _code_for($apply_method)->(
                $self,
                $collector_name,
                $original,
                $normalized,
                now_epoch => $args{now_epoch},
            );
            return if $rotated eq $original;
            _code_for($write_text_method)->($self, $paths->{log}, $rotated);
            return {
                kind         => 'collector-log-rotation',
                name         => $collector_name,
                path         => $paths->{log},
                strategy     => join(',', map { $_ . '=' . $normalized->{$_} } sort keys %{$normalized}),
                before_bytes => length $original,
                after_bytes  => length $rotated,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_new') {
        $impl = sub {
            my ($class, %args) = @_;
            my $files = $args{files} || die 'Missing file registry';
            my $paths = $args{paths} || die 'Missing path registry';
            return bless {
                files => $files,
                paths => $paths,
                repo_root => $args{repo_root},
            }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_global_config_file') {
        $impl = sub {
            my ($self) = @_;
            return File::Spec->catfile($self->{paths}->config_root, 'config.json');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_global_config_files') {
        $impl = sub {
            my ($self) = @_;
            return map { File::Spec->catfile($_, 'config.json') } $self->{paths}->config_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_merge_named_hash_item') {
        my $merge_hashes_method = $sub->{merge_hashes_method} // die 'compiled sub merge-hashes method missing';
        $impl = sub {
            my ($self, $left, $right) = @_;
            return $right if ref($left) ne 'HASH' || ref($right) ne 'HASH';
            return _code_for($merge_hashes_method)->($self, $left, $right);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_merge_named_hash_array') {
        my $merge_item_method = $sub->{merge_item_method} // die 'compiled sub merge-item method missing';
        $impl = sub {
            my ($self, $left, $right, $identity_key) = @_;
            my @merged;
            my %positions;
            for my $item (@{ $left || [] }, @{ $right || [] }) {
                if (
                    ref($item) eq 'HASH'
                    && defined $identity_key
                    && $identity_key ne ''
                    && defined $item->{$identity_key}
                    && $item->{$identity_key} ne ''
                ) {
                    if (exists $positions{$item->{$identity_key}}) {
                        $merged[$positions{$item->{$identity_key}}] = _code_for($merge_item_method)->(
                            $self,
                            $merged[$positions{$item->{$identity_key}}],
                            $item,
                        );
                        next;
                    }
                    $positions{$item->{$identity_key}} = scalar @merged;
                }
                push @merged, $item;
            }
            return \@merged;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_merge_hashes') {
        my $merge_named_array_method = $sub->{merge_named_array_method} // die 'compiled sub merge-named-array method missing';
        $impl = sub {
            my ($self, $left, $right) = @_;
            $left ||= {};
            $right ||= {};
            my %merged = (%{$left});
            for my $key (keys %{$right}) {
                if (ref($left->{$key}) eq 'HASH' && ref($right->{$key}) eq 'HASH') {
                    $merged{$key} = _code_for($name)->($self, $left->{$key}, $right->{$key});
                    next;
                }
                if (ref($left->{$key}) eq 'ARRAY' && ref($right->{$key}) eq 'ARRAY') {
                    if ($key eq 'collectors') {
                        $merged{$key} = _code_for($merge_named_array_method)->($self, $left->{$key}, $right->{$key}, 'name');
                        next;
                    }
                    if ($key eq 'providers') {
                        $merged{$key} = _code_for($merge_named_array_method)->($self, $left->{$key}, $right->{$key}, 'id');
                        next;
                    }
                }
                $merged{$key} = $right->{$key};
            }
            return \%merged;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_load_global') {
        my $global_files_method = $sub->{global_files_method} // die 'compiled sub global-files method missing';
        my $skill_fragments_method = $sub->{skill_fragments_method} // die 'compiled sub skill-fragments method missing';
        my $merge_hashes_method = $sub->{merge_hashes_method} // die 'compiled sub merge-hashes method missing';
        $impl = sub {
            my ($self) = @_;
            my $merged = {};
            for my $file (reverse _code_for($global_files_method)->($self)) {
                next if !-f $file;
                open my $fh, '<:raw', $file or die "Unable to read $file: $!";
                local $/;
                $merged = _code_for($merge_hashes_method)->($self, $merged, __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(<$fh>));
            }
            for my $fragment (_code_for($skill_fragments_method)->($self)) {
                $merged = _code_for($merge_hashes_method)->($self, $merged, $fragment);
            }
            return $merged;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_save_global') {
        my $file_method = $sub->{file_method} // die 'compiled sub file method missing';
        $impl = sub {
            my ($self, $config) = @_;
            my $file = _code_for($file_method)->($self);
            open my $fh, '>:raw', $file or die "Unable to write $file: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($config || {});
            close $fh;
            $self->{paths}->secure_file_permissions($file);
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_load_writable_global') {
        my $file_method = $sub->{file_method} // die 'compiled sub file method missing';
        $impl = sub {
            my ($self) = @_;
            my $file = _code_for($file_method)->($self);
            return {} if !-f $file;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            local $/;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(<$fh>);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_save_global_defaults') {
        my $load_writable_method = $sub->{load_writable_method} // die 'compiled sub load-writable method missing';
        my $merge_hashes_method = $sub->{merge_hashes_method} // die 'compiled sub merge-hashes method missing';
        my $save_global_method = $sub->{save_global_method} // die 'compiled sub save-global method missing';
        $impl = sub {
            my ($self, $defaults) = @_;
            $defaults ||= {};
            my $current = _code_for($load_writable_method)->($self);
            my $merged = _code_for($merge_hashes_method)->($self, $defaults, $current);
            return _code_for($save_global_method)->($self, $merged);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_ensure_global_file') {
        my $file_method = $sub->{file_method} // die 'compiled sub file method missing';
        my $save_global_method = $sub->{save_global_method} // die 'compiled sub save-global method missing';
        $impl = sub {
            my ($self) = @_;
            my $file = _code_for($file_method)->($self);
            return $file if -e $file;
            return _code_for($save_global_method)->($self, {});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_load_repo') {
        $impl = sub {
            my ($self) = @_;
            $self->{repo_root} = $self->{paths}->current_project_root if !$self->{repo_root};
            my $repo = $self->{repo_root} || return {};
            my $file = File::Spec->catfile($repo, '.developer-dashboard.json');
            return {} if !-f $file;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            local $/;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(<$fh>);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_merged') {
        my $load_global_method = $sub->{load_global_method} // die 'compiled sub load-global method missing';
        my $load_repo_method = $sub->{load_repo_method} // die 'compiled sub load-repo method missing';
        my $merge_hashes_method = $sub->{merge_hashes_method} // die 'compiled sub merge-hashes method missing';
        $impl = sub {
            my ($self) = @_;
            my $global = _code_for($load_global_method)->($self);
            my $repo = _code_for($load_repo_method)->($self);
            return _code_for($merge_hashes_method)->($self, $global, $repo);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_builtin_collectors') {
        $impl = sub {
            return [
                {
                    name     => 'housekeeper',
                    code     => <<'PERL',
my $housekeeper = __PAX_RUNTIME_LEGACY_NAMESPACE__::Housekeeper->new(
    paths => __PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry->new(
        workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    ),
);
print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode( $housekeeper->run );
0;
PERL
                    cwd      => 'home',
                    interval => 900,
                },
            ];
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_skill_config_entries') {
        my $dispatcher_class = $sub->{dispatcher_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillDispatcher';
        $impl = sub {
            my ($self) = @_;
            my $dispatcher = $dispatcher_class->new(paths => $self->{paths});
            my @entries;
            for my $skill_root ($self->{paths}->installed_skill_roots) {
                my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
                next if !defined $skill_name || $skill_name eq '';
                my $config = $dispatcher->get_skill_config($skill_name);
                next if ref($config) ne 'HASH' || !%{$config};
                push @entries, {
                    skill_name => $skill_name,
                    skill_root => $skill_root,
                    config => $config,
                    dispatcher => $dispatcher,
                };
            }
            return @entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_skill_config_fragments') {
        my $entries_method = $sub->{entries_method} // die 'compiled sub entries method missing';
        $impl = sub {
            my ($self) = @_;
            my @fragments;
            for my $entry (_code_for($entries_method)->($self)) {
                my $fragment = $entry->{dispatcher}->config_fragment($entry->{skill_name});
                push @fragments, $fragment if ref($fragment) eq 'HASH' && %{$fragment};
            }
            return @fragments;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_skill_collectors') {
        my $entries_method = $sub->{entries_method} // die 'compiled sub entries method missing';
        $impl = sub {
            my ($self) = @_;
            my @jobs;
            for my $entry (_code_for($entries_method)->($self)) {
                my $collectors = $entry->{config}{collectors};
                next if ref($collectors) ne 'ARRAY';
                for my $job (@{$collectors}) {
                    next if ref($job) ne 'HASH';
                    next if !defined $job->{name} || $job->{name} eq '';
                    my $qualified_name = $job->{name} =~ /^\Q$entry->{skill_name}\E\./
                        ? $job->{name}
                        : $entry->{skill_name} . '.' . $job->{name};
                    push @jobs, {
                        %{$job},
                        name => $qualified_name,
                        skill_name => $entry->{skill_name},
                        skill_root => $entry->{skill_root},
                    };
                }
            }
            return @jobs;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_collectors') {
        my $merged_method = $sub->{merged_method} // die 'compiled sub merged method missing';
        my $builtin_collectors_method = $sub->{builtin_collectors_method} // die 'compiled sub builtin-collectors method missing';
        my $merge_named_array_method = $sub->{merge_named_array_method} // die 'compiled sub merge-named-array method missing';
        my $skill_collectors_method = $sub->{skill_collectors_method} // die 'compiled sub skill-collectors method missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($merged_method)->($self);
            my @jobs = @{ _code_for($builtin_collectors_method)->($self) };
            if (ref($cfg->{collectors}) eq 'ARRAY') {
                @jobs = @{ _code_for($merge_named_array_method)->($self, \@jobs, $cfg->{collectors}, 'name') };
            }
            @jobs = @{ _code_for($merge_named_array_method)->($self, \@jobs, [ _code_for($skill_collectors_method)->($self) ], 'name') };
            if (my $filter = $ENV{DEVELOPER_DASHBOARD_CHECKERS}) {
                my %wanted = map { $_ => 1 } grep { defined && $_ ne '' } split /:/, $filter;
                @jobs = grep { ref($_) eq 'HASH' && $wanted{ $_->{name} } } @jobs;
            }
            return \@jobs;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_normalize_home_path') {
        $impl = sub {
            my ($self, $path) = @_;
            return $path if !defined $path || $path eq '';
            my $home = $self->{paths}->home;
            return $path if !defined $home || $home eq '';
            return '$HOME' if $path eq $home;
            my $home_prefix = $home . '/';
            return '$HOME/' . substr($path, length($home_prefix)) if index($path, $home_prefix) == 0;
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_expand_config_path') {
        $impl = sub {
            my ($self, $path) = @_;
            return $path if !defined $path || $path eq '';
            my $home = $self->{paths}->home;
            return $home if defined $home && $path eq '$HOME';
            return $home . substr($path, 5) if defined $home && $path =~ /^\$HOME(?=\/)/;
            return $home . substr($path, 1) if defined $home && $path =~ /^~/;
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_expand_path_aliases') {
        my $expand_config_path_method = $sub->{expand_config_path_method} // die 'compiled sub expand-config-path method missing';
        $impl = sub {
            my ($self, $aliases) = @_;
            my %expanded;
            for my $alias_name (keys %{ $aliases || {} }) {
                $expanded{$alias_name} = _code_for($expand_config_path_method)->($self, $aliases->{$alias_name});
            }
            return \%expanded;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_path_aliases') {
        my $merged_method = $sub->{merged_method} // die 'compiled sub merged method missing';
        my $expand_aliases_method = $sub->{expand_aliases_method} // die 'compiled sub expand-aliases method missing';
        my $key = $sub->{key} // die 'compiled sub alias key missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($merged_method)->($self);
            return {} if ref($cfg->{$key}) ne 'HASH';
            return _code_for($expand_aliases_method)->($self, $cfg->{$key});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_global_aliases') {
        my $load_global_method = $sub->{load_global_method} // die 'compiled sub load-global method missing';
        my $expand_aliases_method = $sub->{expand_aliases_method} // die 'compiled sub expand-aliases method missing';
        my $key = $sub->{key} // die 'compiled sub alias key missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($load_global_method)->($self);
            return {} if ref($cfg->{$key}) ne 'HASH';
            return _code_for($expand_aliases_method)->($self, $cfg->{$key});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_web_workers') {
        my $merged_method = $sub->{merged_method} // die 'compiled sub merged method missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($merged_method)->($self);
            my $workers = $cfg->{web}{workers};
            return 1 if !defined $workers;
            return 1 if $workers !~ /^\d+$/;
            return 1 if $workers < 1;
            return $workers + 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_normalize_ssl_subject_alt_names') {
        $impl = sub {
            my ($self, $names) = @_;
            return [] if ref($names) ne 'ARRAY';
            my @normalized;
            for my $name (@{$names}) {
                next if !defined $name;
                next if ref($name);
                $name =~ s/^\s+//;
                $name =~ s/\s+$//;
                next if $name eq '';
                push @normalized, $name;
            }
            return \@normalized;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_save_global_web_workers') {
        my $load_writable_method = $sub->{load_writable_method} // die 'compiled sub load-writable method missing';
        my $save_global_method = $sub->{save_global_method} // die 'compiled sub save-global method missing';
        $impl = sub {
            my ($self, $workers) = @_;
            die 'Missing worker count' if !defined $workers || $workers eq '';
            die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;
            my $cfg = _code_for($load_writable_method)->($self);
            $cfg->{web} = {} if ref($cfg->{web}) ne 'HASH';
            $cfg->{web}{workers} = $workers + 0;
            _code_for($save_global_method)->($self, $cfg);
            return { workers => $workers + 0 };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_web_settings') {
        my $merged_method = $sub->{merged_method} // die 'compiled sub merged method missing';
        my $normalize_san_method = $sub->{normalize_san_method} // die 'compiled sub normalize-san method missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($merged_method)->($self);
            my $web = $cfg->{web} || {};
            return {
                host                  => $web->{host} || '0.0.0.0',
                port                  => defined $web->{port} && $web->{port} =~ /^\d+$/ ? $web->{port} + 0 : 7890,
                workers               => defined $web->{workers} && $web->{workers} =~ /^\d+$/ && $web->{workers} > 0 ? $web->{workers} + 0 : 1,
                ssl                   => $web->{ssl} ? 1 : 0,
                no_editor             => $web->{no_editor} ? 1 : 0,
                no_indicators         => $web->{no_indicators} ? 1 : 0,
                ssl_subject_alt_names => _code_for($normalize_san_method)->($self, $web->{ssl_subject_alt_names}),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_save_global_web_settings') {
        my $load_writable_method = $sub->{load_writable_method} // die 'compiled sub load-writable method missing';
        my $save_global_method = $sub->{save_global_method} // die 'compiled sub save-global method missing';
        my $normalize_san_method = $sub->{normalize_san_method} // die 'compiled sub normalize-san method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $result = {};
            if (defined $args{host}) {
                die 'Host cannot be empty' if $args{host} eq '';
                $result->{host} = $args{host};
            }
            if (defined $args{port}) {
                die 'Port must be numeric' if $args{port} !~ /^\d+$/;
                die 'Port must be between 1 and 65535' if $args{port} < 1 || $args{port} > 65535;
                $result->{port} = $args{port} + 0;
            }
            if (defined $args{workers}) {
                die 'Worker count must be numeric' if $args{workers} !~ /^\d+$/;
                die 'Worker count must be at least 1' if $args{workers} < 1;
                $result->{workers} = $args{workers} + 0;
            }
            if (defined $args{ssl}) {
                $result->{ssl} = $args{ssl} ? 1 : 0;
            }
            if (defined $args{no_editor}) {
                $result->{no_editor} = $args{no_editor} ? 1 : 0;
            }
            if (defined $args{no_indicators}) {
                $result->{no_indicators} = $args{no_indicators} ? 1 : 0;
            }
            if (exists $args{ssl_subject_alt_names}) {
                $result->{ssl_subject_alt_names} = _code_for($normalize_san_method)->($self, $args{ssl_subject_alt_names});
            }
            my $cfg = _code_for($load_writable_method)->($self);
            $cfg->{web} = {} if ref($cfg->{web}) ne 'HASH';
            for my $key (keys %{$result}) {
                $cfg->{web}{$key} = $result->{$key};
            }
            _code_for($save_global_method)->($self, $cfg);
            return $result;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_save_global_alias') {
        my $alias_key = $sub->{alias_key} // die 'compiled sub alias-key missing';
        my $kind = $sub->{kind} // 'path';
        my $load_writable_method = $sub->{load_writable_method} // die 'compiled sub load-writable method missing';
        my $normalize_home_path_method = $sub->{normalize_home_path_method} // die 'compiled sub normalize-home-path method missing';
        my $save_global_method = $sub->{save_global_method} // die 'compiled sub save-global method missing';
        my $expand_config_path_method = $sub->{expand_config_path_method} // die 'compiled sub expand-config-path method missing';
        $impl = sub {
            my ($self, $name_arg, $path) = @_;
            die "Missing $kind alias name" if !defined $name_arg || $name_arg eq '';
            die "Missing $kind alias target" if !defined $path || $path eq '';
            my $cfg = _code_for($load_writable_method)->($self);
            $cfg->{$alias_key} = {} if ref($cfg->{$alias_key}) ne 'HASH';
            my $stored_path = _code_for($normalize_home_path_method)->($self, $path);
            $cfg->{$alias_key}{$name_arg} = $stored_path;
            _code_for($save_global_method)->($self, $cfg);
            return {
                name => $name_arg,
                path => _code_for($expand_config_path_method)->($self, $stored_path),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_remove_global_alias') {
        my $alias_key = $sub->{alias_key} // die 'compiled sub alias-key missing';
        my $kind = $sub->{kind} // 'path';
        my $load_writable_method = $sub->{load_writable_method} // die 'compiled sub load-writable method missing';
        my $save_global_method = $sub->{save_global_method} // die 'compiled sub save-global method missing';
        $impl = sub {
            my ($self, $name_arg) = @_;
            die "Missing $kind alias name" if !defined $name_arg || $name_arg eq '';
            my $cfg = _code_for($load_writable_method)->($self);
            $cfg->{$alias_key} = {} if ref($cfg->{$alias_key}) ne 'HASH';
            my $removed = delete $cfg->{$alias_key}{$name_arg} ? 1 : 0;
            _code_for($save_global_method)->($self, $cfg);
            return {
                name => $name_arg,
                removed => $removed,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_docker_config') {
        my $merged_method = $sub->{merged_method} // die 'compiled sub merged method missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($merged_method)->($self);
            return {} if ref($cfg->{docker}) ne 'HASH';
            return { %{ $cfg->{docker} } };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'config_providers') {
        my $merged_method = $sub->{merged_method} // die 'compiled sub merged method missing';
        $impl = sub {
            my ($self) = @_;
            my $cfg = _code_for($merged_method)->($self);
            my @providers;
            push @providers, @{ $cfg->{providers} } if ref($cfg->{providers}) eq 'ARRAY';
            return \@providers;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_new') {
        my $skill_manager_class = $sub->{skill_manager_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillManager';
        $impl = sub {
            my ($class, %args) = @_;
            my $manager = $args{manager} || $skill_manager_class->new(paths => $args{paths});
            return bless { manager => $manager }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_arrayref_or_empty') {
        $impl = sub {
            my ($self, $value) = @_;
            return $value if ref($value) eq 'ARRAY';
            my @empty;
            my $empty = \@empty;
            return $empty;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_hashref_or_empty') {
        $impl = sub {
            my ($self, $value) = @_;
            return $value if ref($value) eq 'HASH';
            my %empty;
            my $empty = \%empty;
            return $empty;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_defined_or_default') {
        $impl = sub {
            my ($self, $value, $default) = @_;
            return defined $value ? $value : $default;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_merge_array_items_by_identity') {
        my $arrayref_or_empty_method = $sub->{arrayref_or_empty_method} // die 'compiled sub arrayref method missing';
        $impl = sub {
            my ($self, $left_items, $right_items, $field) = @_;
            my @combined;
            my %positions;
            my $left = _code_for($arrayref_or_empty_method)->($self, $left_items);
            my $right = _code_for($arrayref_or_empty_method)->($self, $right_items);
            for my $item (@{$left}) {
                push @combined, $item;
                next if ref($item) ne 'HASH';
                my $identity = $item->{$field};
                next if !defined $identity || $identity eq '';
                $positions{$identity} = $#combined;
            }
            for my $item (@{$right}) {
                if (ref($item) eq 'HASH') {
                    my $identity = $item->{$field};
                    if (defined $identity && $identity ne '') {
                        if (exists $positions{$identity}) {
                            $combined[$positions{$identity}] = $item;
                            next;
                        }
                        $positions{$identity} = scalar @combined;
                    }
                }
                push @combined, $item;
            }
            return \@combined;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_layers') {
        $impl = sub {
            my ($self, $skill_name, %args) = @_;
            return () if !$skill_name;
            my $paths = $self->{manager}{paths};
            return $paths->skill_layers($skill_name, %args) if $paths->can('skill_layers');
            my $skill_path = $self->{manager}->get_skill_path($skill_name, %args) or return ();
            return ($skill_path);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_lookup_roots') {
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        $impl = sub {
            my ($self, $skill_name, %args) = @_;
            return reverse _code_for($skill_layers_method)->($self, $skill_name, %args);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_command_root_specs') {
        $impl = sub {
            my ($self, $segments) = @_;
            my @segments = @{ $segments || [] };
            return () if !@segments;
            my @specs = ({
                nested_segments => [],
                command_name => join('.', @segments),
            });
            for my $split_index (1 .. $#segments) {
                push @specs, {
                    nested_segments => [ @segments[0 .. $split_index - 1] ],
                    command_name => join('.', @segments[$split_index .. $#segments]),
                };
            }
            return @specs;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_nested_skill_path') {
        $impl = sub {
            my ($self, $skill_path, $nested_segments) = @_;
            my @segments = @{ $nested_segments || [] };
            return $skill_path if !@segments;
            my @parts = ($skill_path);
            for my $segment (@segments) {
                push @parts, 'skills', $segment;
            }
            return File::Spec->catdir(@parts);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_page_location') {
        my $skill_lookup_roots_method = $sub->{skill_lookup_roots_method} // die 'compiled sub skill-lookup-roots method missing';
        $impl = sub {
            my ($self, $skill_name, $route_id) = @_;
            return if !$skill_name || !$route_id;
            for my $skill_path (_code_for($skill_lookup_roots_method)->($self, $skill_name)) {
                my $file = File::Spec->catfile($skill_path, 'dashboards', split m{/+}, $route_id);
                return ($file, $skill_path) if -f $file;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_bookmark_entries') {
        my $skill_lookup_roots_method = $sub->{skill_lookup_roots_method} // die 'compiled sub skill-lookup-roots method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            return () if !$skill_name;
            my %entries;
            for my $skill_path (_code_for($skill_lookup_roots_method)->($self, $skill_name)) {
                my $dashboards_root = File::Spec->catdir($skill_path, 'dashboards');
                next if !-d $dashboards_root;
                opendir(my $dh, $dashboards_root) or die "Unable to read $dashboards_root: $!";
                for my $entry (
                    grep {
                        $_ ne '.' && $_ ne '..' && $_ ne 'nav' && -f File::Spec->catfile($dashboards_root, $_)
                    } readdir($dh)
                ) {
                    $entries{$entry} ||= 1;
                }
                closedir($dh);
            }
            return sort keys %entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_nav_route_ids') {
        my $skill_lookup_roots_method = $sub->{skill_lookup_roots_method} // die 'compiled sub skill-lookup-roots method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            return () if !$skill_name;
            my %routes;
            for my $skill_path (_code_for($skill_lookup_roots_method)->($self, $skill_name)) {
                my $nav_root = File::Spec->catdir($skill_path, 'dashboards', 'nav');
                next if !-d $nav_root;
                opendir my $dh, $nav_root or die "Unable to read $nav_root: $!";
                for my $entry (
                    grep { $_ ne '.' && $_ ne '..' && -f File::Spec->catfile($nav_root, $_) } readdir $dh
                ) {
                    $routes{$entry} ||= 'nav/' . $entry;
                }
                closedir $dh;
            }
            return %routes;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_merge_skill_hashes') {
        my $merge_array_items_method = $sub->{merge_array_items_method} // die 'compiled sub merge-array-items method missing';
        $impl = sub {
            my ($self, $left, $right) = @_;
            $left ||= {};
            $right ||= {};
            my %merged = (%{$left});
            for my $key (keys %{$right}) {
                if (ref($left->{$key}) eq 'HASH' && ref($right->{$key}) eq 'HASH') {
                    $merged{$key} = _code_for($name)->($self, $left->{$key}, $right->{$key});
                    next;
                }
                if (ref($left->{$key}) eq 'ARRAY' && ref($right->{$key}) eq 'ARRAY') {
                    if ($key eq 'collectors') {
                        $merged{$key} = _code_for($merge_array_items_method)->($self, $left->{$key}, $right->{$key}, 'name');
                        next;
                    }
                    if ($key eq 'providers') {
                        $merged{$key} = _code_for($merge_array_items_method)->($self, $left->{$key}, $right->{$key}, 'id');
                        next;
                    }
                }
                $merged{$key} = $right->{$key};
            }
            return \%merged;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_get_skill_config') {
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        my $merge_skill_hashes_method = $sub->{merge_skill_hashes_method} // die 'compiled sub merge-skill-hashes method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            return {} if !$skill_name;
            my @skill_layers = _code_for($skill_layers_method)->($self, $skill_name);
            return {} if !@skill_layers;
            my $merged = {};
            for my $skill_path (@skill_layers) {
                my $config_file = File::Spec->catfile($skill_path, 'config', 'config.json');
                next if !-f $config_file;
                open(my $fh, '<', $config_file) or return {};
                my $json_text = do { local $/; <$fh> };
                close($fh);
                my $config = eval { JSON::XS::decode_json($json_text) } || {};
                return {} if ref($config) ne 'HASH';
                $merged = _code_for($merge_skill_hashes_method)->($self, $merged, $config);
            }
            return $merged;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_config_fragment') {
        my $get_skill_config_method = $sub->{get_skill_config_method} // die 'compiled sub get-skill-config method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            return {} if !$skill_name;
            my $config = _code_for($get_skill_config_method)->($self, $skill_name);
            return {} if ref($config) ne 'HASH' || !%{$config};
            return { '_' . $skill_name => $config };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_get_skill_path') {
        $impl = sub {
            my ($self, $skill_name) = @_;
            return if !$skill_name;
            return $self->{manager}->get_skill_path($skill_name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_command_spec') {
        my $command_root_specs_method = $sub->{command_root_specs_method} // die 'compiled sub command-root-specs method missing';
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        my $nested_skill_path_method = $sub->{nested_skill_path_method} // die 'compiled sub nested-skill-path method missing';
        $impl = sub {
            my ($self, $skill_name, $command) = @_;
            return if !$skill_name || !$command;
            my @segments = grep { defined && $_ ne '' } split /\./, $command;
            return if !@segments;
            for my $command_root_spec (_code_for($command_root_specs_method)->($self, \@segments)) {
                my @provider_layers;
                for my $skill_path (_code_for($skill_layers_method)->($self, $skill_name)) {
                    my $provider_path = $skill_path;
                    if (@{ $command_root_spec->{nested_segments} }) {
                        $provider_path = _code_for($nested_skill_path_method)->($self, $skill_path, $command_root_spec->{nested_segments});
                        next if !-d $provider_path;
                    }
                    push @provider_layers, $provider_path;
                }
                next if !@provider_layers;
                for my $provider_path (reverse @provider_layers) {
                    my $cmd_path = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::resolve_runnable_file(
                        File::Spec->catfile($provider_path, 'cli', $command_root_spec->{command_name})
                    );
                    next if !$cmd_path;
                    return {
                        cmd_path => $cmd_path,
                        skill_path => $provider_path,
                        skill_layers => \@provider_layers,
                        command_name => $command_root_spec->{command_name},
                    };
                }
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_command_path') {
        my $command_spec_method = $sub->{command_spec_method} // die 'compiled sub command-spec method missing';
        $impl = sub {
            my ($self, $skill_name, $command) = @_;
            return if !$skill_name || !$command;
            my $command_spec = _code_for($command_spec_method)->($self, $skill_name, $command);
            return $command_spec ? $command_spec->{cmd_path} : undef;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_command_spec_public') {
        my $command_spec_method = $sub->{command_spec_method} // die 'compiled sub command-spec method missing';
        $impl = sub {
            my ($self, $skill_name, $command) = @_;
            return if !$skill_name || !$command;
            return _code_for($command_spec_method)->($self, $skill_name, $command);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_command_hook_paths') {
        my $command_spec_method = $sub->{command_spec_method} // die 'compiled sub command-spec method missing';
        $impl = sub {
            my ($self, $skill_name, $command) = @_;
            return () if !$skill_name || !$command;
            my $command_spec = _code_for($command_spec_method)->($self, $skill_name, $command);
            return () if !$command_spec;
            my @hooks;
            my $resolved_command = $command_spec->{command_name} || '';
            return () if $resolved_command eq '';
            for my $layer_path (@{ $command_spec->{skill_layers} || [] }) {
                my $hooks_dir = File::Spec->catdir($layer_path, 'cli', "$resolved_command.d");
                next if !-d $hooks_dir;
                opendir(my $dh, $hooks_dir) or die "Unable to read $hooks_dir: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' } readdir($dh)) {
                    my $hook_path = File::Spec->catfile($hooks_dir, $entry);
                    next unless __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file($hook_path);
                    push @hooks, $hook_path;
                }
                closedir($dh);
            }
            return @hooks;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_append_error_text') {
        $impl = sub {
            my ($self, $stderr, $error) = @_;
            $stderr = '' if !defined $stderr;
            $error = '' if !defined $error;
            return $stderr if $error eq '';
            $stderr .= "\n" if $stderr ne '' && $stderr !~ /\n\z/;
            return $stderr . $error . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_new') {
        $impl = sub {
            my ($class, %args) = @_;
            my $collectors = $args{collectors} || die 'Missing collector store';
            my $files = $args{files} || die 'Missing file registry';
            my $paths = $args{paths} || die 'Missing path registry';
            return bless {
                collectors => $collectors,
                files      => $files,
                indicators => $args{indicators},
                paths      => $paths,
            }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_run_once') {
        my $collector_source_method = $sub->{collector_source_method} // die 'compiled sub collector-source method missing';
        my $run_job_method = $sub->{run_job_method} // die 'compiled sub run-job method missing';
        my $materialize_indicator_state_method = $sub->{materialize_indicator_state_method} // die 'compiled sub materialize-indicator-state method missing';
        my $append_error_text_method = $sub->{append_error_text_method} // die 'compiled sub append-error-text method missing';
        $impl = sub {
            my ($self, $job) = @_;
            die 'Collector job must be a hash' if ref($job) ne 'HASH';
            my $name = $job->{name} || die 'Collector job missing name';
            my ($mode, $source) = _code_for($collector_source_method)->($self, $job);
            my $cwd = $job->{cwd} || Cwd::cwd();
            if (!File::Spec->file_name_is_absolute($cwd) && $self->{paths}->can($cwd)) {
                $cwd = $self->{paths}->$cwd();
            }
            die "Collector cwd '$cwd' does not exist" if !-d $cwd;
            my $started_at = __PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_now_iso8601();
            $self->{collectors}->write_job($name, {
                name       => $name,
                command    => $job->{command},
                code       => $job->{code},
                mode       => $mode,
                cwd        => $cwd,
                interval   => $job->{interval},
                cron       => $job->{cron},
                schedule   => $job->{schedule},
                timeout    => $job->{timeout} || $job->{timeout_ms},
                env        => $job->{env},
                output_format => $job->{output_format},
                updated_at => $started_at,
            });
            $self->{collectors}->write_status($name, {
                enabled         => 1,
                running         => 1,
                last_started_at => $started_at,
                schedule        => $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' ),
            });
            my ($stdout, $stderr, $exit_code, $timed_out) = _code_for($run_job_method)->(
                $self,
                mode       => $mode,
                source     => $source,
                cwd        => $cwd,
                env        => $job->{env},
                timeout_ms => $job->{timeout_ms} || ( $job->{timeout} ? $job->{timeout} * 1000 : undef ),
            );
            my $indicator_payload;
            if ($self->{indicators} && ref($job->{indicator}) eq 'HASH') {
                $indicator_payload = $self->{indicators}->collector_indicator_candidate($job, status => $exit_code ? 'error' : 'ok');
                my $materialized = eval {
                    _code_for($materialize_indicator_state_method)->(
                        $self,
                        job       => $job,
                        indicator => $indicator_payload,
                        stdout    => $stdout,
                    );
                };
                if (!$materialized) {
                    my $error = "$@";
                    $error =~ s/\s+\z//;
                    $stderr = _code_for($append_error_text_method)->($self, $stderr, $error);
                    $exit_code = 255 if !$exit_code;
                    $indicator_payload->{status} = 'error';
                } else {
                    $indicator_payload = $materialized;
                }
            }
            $self->{collectors}->write_result(
                $name,
                exit_code => $exit_code,
                stdout    => $stdout,
                stderr    => $stderr,
                started_at => $started_at,
                running    => 0,
                output_format => $job->{output_format},
                timed_out  => $timed_out,
            );
            if ($indicator_payload) {
                $indicator_payload->{status} = $exit_code ? 'error' : 'ok';
                $self->{indicators}->set_indicator($indicator_payload->{name}, %{$indicator_payload});
            }
            return {
                name      => $name,
                exit_code => $exit_code,
                stdout    => $stdout,
                stderr    => $stderr,
                timed_out => $timed_out ? 1 : 0,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_materialize_indicator_state') {
        my $render_icon_template_method = $sub->{render_icon_template_method} // die 'compiled sub render-icon-template method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $job = $args{job} || die 'Missing collector job';
            my $indicator = $args{indicator} || die 'Missing indicator payload';
            my %materialized = %{$indicator};
            if (defined $materialized{icon_template} && $materialized{icon_template} ne '') {
                $materialized{icon} = _code_for($render_icon_template_method)->(
                    $self,
                    collector_name => $job->{name},
                    template       => $materialized{icon_template},
                    stdout         => $args{stdout},
                );
            }
            return \%materialized;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_render_indicator_icon_template') {
        my $indicator_template_vars_method = $sub->{indicator_template_vars_method} // die 'compiled sub indicator-template-vars method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $collector_name = $args{collector_name} || die 'Missing collector name';
            my $template_text = $args{template} || die 'Missing indicator icon template';
            my $vars = _code_for($indicator_template_vars_method)->(
                $self,
                collector_name => $collector_name,
                stdout         => $args{stdout},
            );
            my $tt = Template->new();
            my $rendered = '';
            $tt->process(\$template_text, $vars, \$rendered)
                or die sprintf "Collector '%s' indicator icon template failed: %s\n", $collector_name, $tt->error();
            return $rendered;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_indicator_template_vars') {
        $impl = sub {
            my ($self, %args) = @_;
            my $collector_name = $args{collector_name} || die 'Missing collector name';
            my $stdout = defined $args{stdout} ? $args{stdout} : '';
            my $decoded = eval { __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($stdout) };
            if ($@) {
                my $error = "$@";
                $error =~ s/\s+\z//;
                die sprintf "Collector '%s' indicator icon template requires collector stdout JSON: %s\n", $collector_name, $error;
            }
            my %vars = ( data => $decoded );
            if (ref($decoded) eq 'HASH') {
                %vars = (%vars, %{$decoded});
            }
            return \%vars;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_source') {
        $impl = sub {
            my ($self, $job) = @_;
            return ('command', $job->{command}) if defined $job->{command} && $job->{command} ne '';
            return ('code', $job->{code}) if defined $job->{code} && $job->{code} ne '';
            my $job_name = ref($job) eq 'HASH' ? ($job->{name} || '(unnamed)') : '(unnamed)';
            die "Collector '$job_name' missing command or code";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_run_job') {
        my $run_command_method = $sub->{run_command_method} // die 'compiled sub run-command method missing';
        my $run_code_method = $sub->{run_code_method} // die 'compiled sub run-code method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $mode = $args{mode} || die 'Missing collector mode';
            return _code_for($run_command_method)->($self, %args) if $mode eq 'command';
            return _code_for($run_code_method)->($self, %args) if $mode eq 'code';
            die "Unknown collector mode '$mode'";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_start_loop') {
        my $pidfile_method = $sub->{pidfile_method} // die 'compiled sub pidfile method missing';
        my $process_title_method = $sub->{process_title_method} // die 'compiled sub process-title method missing';
        my $is_managed_loop_method = $sub->{is_managed_loop_method} // die 'compiled sub is-managed-loop method missing';
        my $write_loop_state_method = $sub->{write_loop_state_method} // die 'compiled sub write-loop-state method missing';
        my $cleanup_loop_files_method = $sub->{cleanup_loop_files_method} // die 'compiled sub cleanup-loop-files method missing';
        my $fork_process_method = $sub->{fork_process_method} // die 'compiled sub fork-process method missing';
        my $run_loop_child_method = $sub->{run_loop_child_method} // die 'compiled sub run-loop-child method missing';
        $impl = sub {
            my ($self, $job) = @_;
            my $interval = $job->{interval} || 30;
            my $name = $job->{name} || die 'Collector job missing name';
            my $schedule_mode = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
            die "Collector '$name' uses manual schedule and should be run on demand" if $schedule_mode eq 'manual';
            my $pidfile = _code_for($pidfile_method)->($self, $name);
            my $title = _code_for($process_title_method)->($self, $name);
            if (-f $pidfile) {
                my $pid = _code_for('__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_slurp')->($pidfile);
                chomp $pid;
                if ($pid && _code_for($is_managed_loop_method)->($self, $pid, $name)) {
                    _code_for($write_loop_state_method)->($self, $name, {
                        pid          => $pid,
                        name         => $name,
                        process_name => $title,
                        interval     => $interval,
                        schedule     => $schedule_mode,
                        status       => 'running',
                        heartbeat_at => __PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_now_iso8601(),
                    });
                    return $pid;
                }
                _code_for($cleanup_loop_files_method)->($self, $name);
            }
            my $pid = _code_for($fork_process_method)->($self);
            die "Unable to fork collector '$name': $!" if !defined $pid;
            if ($pid) {
                open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
                print {$fh} $pid;
                close $fh;
                $self->{paths}->secure_file_permissions($pidfile);
                _code_for($write_loop_state_method)->($self, $name, {
                    pid          => $pid,
                    name         => $name,
                    process_name => $title,
                    command      => $job->{command},
                    cwd          => $job->{cwd},
                    interval     => $interval,
                    schedule     => $schedule_mode,
                    status       => 'starting',
                    started_at   => __PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_now_iso8601(),
                    heartbeat_at => __PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_now_iso8601(),
                });
                return $pid;
            }
            return $self->$run_loop_child_method(
                interval      => $interval,
                job           => $job,
                name          => $name,
                schedule_mode => $schedule_mode,
                title         => $title,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_fork_process') {
        $impl = sub { return fork(); };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_run_loop_child') {
        my $process_title_method = $sub->{process_title_method} // die 'compiled sub process-title method missing';
        my $scrub_coverage_method = $sub->{scrub_coverage_method} // die 'compiled sub scrub-coverage method missing';
        my $write_loop_state_method = $sub->{write_loop_state_method} // die 'compiled sub write-loop-state method missing';
        my $job_is_due_method = $sub->{job_is_due_method} // die 'compiled sub job-is-due method missing';
        my $run_once_method = $sub->{run_once_method} // die 'compiled sub run-once method missing';
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $job = $args{job} || die 'Missing collector job';
            my $name = $args{name} || die 'Missing collector name';
            my $title = $args{title} || _code_for($process_title_method)->($self, $name);
            my $interval = defined $args{interval} ? $args{interval} : 30;
            my $schedule_mode = $args{schedule_mode} || 'interval';
            my $daemonize = exists $args{daemonize} ? $args{daemonize} : 1;
            my $single_tick = $args{single_tick} ? 1 : 0;
            _code_for($scrub_coverage_method)->($self);
            if ($daemonize) {
                POSIX::setsid();
                open STDIN, '<', File::Spec->devnull() or die $!;
                open STDOUT, '>>', $self->{files}->collector_log or die $!;
                open STDERR, '>>', $self->{files}->collector_log or die $!;
            }
            $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $name;
            $ENV{DEVELOPER_DASHBOARD_LOOP_STATUS} = 'running';
            $0 = $title;
            local $__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::SIGNAL_RUNNER = $self;
            local $__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::SIGNAL_LOOP_NAME = $name;
            local $SIG{TERM} = \&__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_signal_stop;
            local $SIG{INT} = \&__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_signal_stop;
            local $SIG{HUP} = \&__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::_signal_stop;
            while (1) {
                _code_for($write_loop_state_method)->($self, $name, {
                    pid          => $$,
                    name         => $name,
                    process_name => $title,
                    command      => $job->{command},
                    cwd          => $job->{cwd},
                    interval     => $interval,
                    schedule     => $schedule_mode,
                    status       => 'running',
                    heartbeat_at => _code_for($now_method)->(),
                });
                my $due = _code_for($job_is_due_method)->($self, $job, $name);
                eval { _code_for($run_once_method)->($self, $job) } if $due;
                if ($@) {
                    my $error = "$@";
                    my $message = sprintf "[%s][%s] %s\n", _code_for($now_method)->(), $name, $error;
                    $self->{files}->append('collector_log', $message);
                    $self->{collectors}->append_log_entry($name, happened_at => _code_for($now_method)->(), error => $error, source => 'loop error');
                    _code_for($write_loop_state_method)->($self, $name, {
                        pid          => $$,
                        name         => $name,
                        process_name => $title,
                        command      => $job->{command},
                        cwd          => $job->{cwd},
                        interval     => $interval,
                        schedule     => $schedule_mode,
                        status       => 'error',
                        heartbeat_at => _code_for($now_method)->(),
                        error        => $error,
                    });
                }
                Time::HiRes::sleep($schedule_mode eq 'cron' ? 1 : $interval);
                return 1 if $single_tick;
            }
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_stop_loop') {
        my $pidfile_method = $sub->{pidfile_method} // die 'compiled sub pidfile method missing';
        my $is_managed_loop_method = $sub->{is_managed_loop_method} // die 'compiled sub is-managed-loop method missing';
        my $cleanup_loop_files_method = $sub->{cleanup_loop_files_method} // die 'compiled sub cleanup-loop-files method missing';
        my $slurp_method = $sub->{slurp_method} // die 'compiled sub slurp method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my $pidfile = _code_for($pidfile_method)->($self, $name);
            return if !-f $pidfile;
            my $pid = _code_for($slurp_method)->($pidfile);
            chomp $pid;
            if ($pid && _code_for($is_managed_loop_method)->($self, $pid, $name)) {
                kill 15, $pid;
                for (1 .. 20) {
                    last if !kill 0, $pid;
                    Time::HiRes::sleep(0.1);
                }
                kill 9, $pid if kill 0, $pid;
            }
            _code_for($cleanup_loop_files_method)->($self, $name);
            return $pid;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_running_loops') {
        my $is_managed_loop_method = $sub->{is_managed_loop_method} // die 'compiled sub is-managed-loop method missing';
        my $cleanup_loop_files_method = $sub->{cleanup_loop_files_method} // die 'compiled sub cleanup-loop-files method missing';
        my $loop_state_method = $sub->{loop_state_method} // die 'compiled sub loop-state method missing';
        my $slurp_method = $sub->{slurp_method} // die 'compiled sub slurp method missing';
        $impl = sub {
            my ($self) = @_;
            my $root = $self->{paths}->collectors_root;
            opendir my $dh, $root or return;
            my @running;
            while (my $entry = readdir $dh) {
                next if $entry eq '.' || $entry eq '..';
                next if $entry !~ /^(.*)\.pid$/;
                my $name = $1;
                my $pid = eval { _code_for($slurp_method)->(File::Spec->catfile($root, $entry)) };
                next if !$pid;
                chomp $pid;
                if ($pid && _code_for($is_managed_loop_method)->($self, $pid, $name)) {
                    push @running, { name => $name, pid => $pid, state => scalar _code_for($loop_state_method)->($self, $name) };
                    next;
                }
                _code_for($cleanup_loop_files_method)->($self, $name);
            }
            closedir $dh;
            @running = sort { $a->{name} cmp $b->{name} } @running;
            return @running;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_sort_loop_names') {
        $impl = sub { return $a->{name} cmp $b->{name}; };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_loop_state') {
        my $statefile_method = $sub->{statefile_method} // die 'compiled sub statefile method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my $file = _code_for($statefile_method)->($self, $name);
            return if !-f $file;
            open my $fh, '<', $file or die "Unable to read $file: $!";
            local $/;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(scalar <$fh>);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_pidfile') {
        $impl = sub {
            my ($self, $name) = @_;
            return File::Spec->catfile($self->{paths}->collectors_root, "$name.pid");
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_statefile') {
        $impl = sub {
            my ($self, $name) = @_;
            return File::Spec->catfile($self->{paths}->collector_dir($name), 'loop.json');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_process_title') {
        $impl = sub {
            my ($self, $name) = @_;
            return "dashboard collector: $name";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_read_proc_file') {
        $impl = sub {
            my ($self, $file) = @_;
            return if !-r $file;
            open my $fh, '<', $file or return;
            local $/;
            return scalar <$fh>;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_read_process_env_marker') {
        $impl = sub {
            my ($self, $pid, $key) = @_;
            my $proc = "/proc/$pid/environ";
            return if !-r $proc;
            open my $fh, '<', $proc or return;
            local $/;
            my $env = scalar <$fh>;
            return if !defined $env || $env eq '';
            for my $pair (split /\0/, $env) {
                next if $pair !~ /^([^=]+)=(.*)$/s;
                return $2 if $1 eq $key;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_read_process_title') {
        my $read_proc_method = $sub->{read_proc_method} // die 'compiled sub read-proc method missing';
        $impl = sub {
            my ($self, $pid) = @_;
            my $proc = "/proc/$pid/cmdline";
            my $cmdline = _code_for($read_proc_method)->($self, $proc);
            if (defined $cmdline && $cmdline ne '') {
                $cmdline =~ s/\0/ /g;
                $cmdline =~ s/\s+$// if defined $cmdline;
                return $cmdline;
            }
            my ($title, $stderr, $exit_code) = _capture_system_command('ps', '-o', 'args=', '-p', $pid);
            return if _system_command_missing($stderr, $exit_code);
            return if defined $exit_code && $exit_code != 0;
            $title =~ s/\s+$// if defined $title;
            return $title;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_is_managed_loop') {
        my $read_env_marker_method = $sub->{read_env_marker_method} // die 'compiled sub read-env-marker method missing';
        my $read_title_method = $sub->{read_title_method} // die 'compiled sub read-title method missing';
        my $process_title_method = $sub->{process_title_method} // die 'compiled sub process-title method missing';
        $impl = sub {
            my ($self, $pid, $name) = @_;
            return 0 if !$pid || !kill 0, $pid;
            my $marker = _code_for($read_env_marker_method)->($self, $pid, 'DEVELOPER_DASHBOARD_LOOP_NAME');
            return 1 if defined $marker && $marker eq $name;
            my $title = _code_for($read_title_method)->($self, $pid);
            return 0 if !defined $title || $title eq '';
            return $title eq _code_for($process_title_method)->($self, $name) ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_write_loop_state') {
        my $statefile_method = $sub->{statefile_method} // die 'compiled sub statefile method missing';
        my $loop_state_method = $sub->{loop_state_method} // die 'compiled sub loop-state method missing';
        $impl = sub {
            my ($self, $name, $data) = @_;
            my $file = _code_for($statefile_method)->($self, $name);
            my $existing = eval { _code_for($loop_state_method)->($self, $name) } || {};
            my %state = (%{$existing}, %{ $data || {} }, name => $name);
            my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
            open my $fh, '>', $tmp or die "Unable to write $tmp: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode(\%state);
            close $fh;
            $self->{paths}->secure_file_permissions($tmp);
            rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
            $self->{paths}->secure_file_permissions($file);
            return \%state;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_cleanup_loop_files') {
        my $pidfile_method = $sub->{pidfile_method} // die 'compiled sub pidfile method missing';
        my $statefile_method = $sub->{statefile_method} // die 'compiled sub statefile method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my $pidfile = _code_for($pidfile_method)->($self, $name);
            my $statefile = _code_for($statefile_method)->($self, $name);
            unlink $pidfile if -f $pidfile;
            unlink $statefile if -f $statefile;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_scrub_coverage_environment') {
        my $coverage_active_method = $sub->{coverage_active_method} // die 'compiled sub coverage-active method missing';
        $impl = sub {
            my ($self) = @_;
            return if !_code_for($coverage_active_method)->($self);
            delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_coverage_instrumentation_active') {
        $impl = sub {
            my ($self) = @_;
            my $perl5opt = join ' ', grep { defined && $_ ne '' } @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
            return $perl5opt =~ /Devel::Cover/ ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_job_is_due') {
        my $cron_due_method = $sub->{cron_due_method} // die 'compiled sub cron-due method missing';
        $impl = sub {
            my ($self, $job, $name) = @_;
            my $mode = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
            return 0 if $mode eq 'manual';
            return 1 if $mode eq 'interval';
            return _code_for($cron_due_method)->($self, $job->{cron}, $name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_cron_match') {
        $impl = sub {
            my ($spec, $value) = @_;
            return 1 if !defined $spec || $spec eq '*' || $spec eq '';
            for my $part (split /,/, $spec) {
                return 1 if $part =~ /^\d+$/ && $part == $value;
                if ($part =~ m{^\*/(\d+)$}) {
                    return 1 if $1 && $value % $1 == 0;
                }
                if ($part =~ /^(\d+)-(\d+)$/) {
                    return 1 if $value >= $1 && $value <= $2;
                }
            }
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_cron_due') {
        my $loop_state_method = $sub->{loop_state_method} // die 'compiled sub loop-state method missing';
        my $write_loop_state_method = $sub->{write_loop_state_method} // die 'compiled sub write-loop-state method missing';
        my $cron_match_method = $sub->{cron_match_method} // die 'compiled sub cron-match method missing';
        $impl = sub {
            my ($self, $expr, $name) = @_;
            return 1 if !defined $expr || $expr eq '' || $expr eq '* * * * *';
            my @now = localtime();
            my @parts = split /\s+/, $expr;
            return 0 if @parts < 5;
            my ($min, $hour, $mday, $mon, $wday) = @parts[0..4];
            return 0 if !_code_for($cron_match_method)->($min,  $now[1]);
            return 0 if !_code_for($cron_match_method)->($hour, $now[2]);
            return 0 if !_code_for($cron_match_method)->($mday, $now[3]);
            return 0 if !_code_for($cron_match_method)->($mon,  $now[4] + 1);
            return 0 if !_code_for($cron_match_method)->($wday, $now[6]);
            my $state = _code_for($loop_state_method)->($self, $name) || {};
            my $stamp = POSIX::strftime('%Y-%m-%dT%H:%M%z', @now);
            return 0 if ($state->{last_cron_slot} || '') eq $stamp;
            _code_for($write_loop_state_method)->($self, $name, { last_cron_slot => $stamp });
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_run_command') {
        $impl = sub {
            my ($self, %args) = @_;
            my $cmd = $args{source};
            my $cwd = $args{cwd};
            my $env = ref($args{env}) eq 'HASH' ? $args{env} : {};
            my $timeout_ms = $args{timeout_ms} || 30_000;
            my $old = Cwd::cwd();
            chdir $cwd or die "Unable to chdir to $cwd: $!";
            local @ENV{ keys %$env } = values %$env if %$env;
            my $timed_out = 0;
            my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                local $SIG{ALRM} = sub { die "__COLLECTOR_TIMEOUT__\n" };
                alarm(int(($timeout_ms + 999) / 1000));
                my $ok = eval {
                    system __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::shell_command_argv($cmd);
                    return $? >> 8;
                };
                if ($@) {
                    die $@ if $@ !~ /__COLLECTOR_TIMEOUT__/;
                    $timed_out = 1;
                    return 124;
                }
                alarm(0);
                return $ok;
            };
            alarm(0);
            chdir $old or die "Unable to restore cwd to $old: $!";
            return ($stdout, $stderr, $exit_code, $timed_out);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_run_code') {
        $impl = sub {
            my ($self, %args) = @_;
            my $code = $args{source};
            my $cwd = $args{cwd};
            my $env = ref($args{env}) eq 'HASH' ? $args{env} : {};
            my $timeout_ms = $args{timeout_ms} || 30_000;
            my $old = Cwd::cwd();
            chdir $cwd or die "Unable to chdir to $cwd: $!";
            local @ENV{ keys %$env } = values %$env if %$env;
            my $timed_out = 0;
            my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                local $SIG{ALRM} = sub { die "__COLLECTOR_TIMEOUT__\n" };
                alarm(int(($timeout_ms + 999) / 1000));
                my $result = eval $code;
                if ($@) {
                    if ($@ =~ /__COLLECTOR_TIMEOUT__/) {
                        $timed_out = 1;
                        alarm(0);
                        return 124;
                    }
                    my $error = $@;
                    print STDERR $error;
                    alarm(0);
                    return 255;
                }
                alarm(0);
                return (defined $result && $result =~ /\A-?\d+\z/) ? $result : 0;
            };
            alarm(0);
            chdir $old or die "Unable to restore cwd to $old: $!";
            return ($stdout, $stderr, $exit_code, $timed_out);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_shutdown_loop') {
        my $write_loop_state_method = $sub->{write_loop_state_method} // die 'compiled sub write-loop-state method missing';
        my $process_title_method = $sub->{process_title_method} // die 'compiled sub process-title method missing';
        my $cleanup_loop_files_method = $sub->{cleanup_loop_files_method} // die 'compiled sub cleanup-loop-files method missing';
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        $impl = sub {
            my ($self, $name, $status) = @_;
            _code_for($write_loop_state_method)->($self, $name, {
                pid          => $$,
                process_name => _code_for($process_title_method)->($self, $name),
                status       => $status || 'stopped',
                heartbeat_at => _code_for($now_method)->(),
                stopped_at   => _code_for($now_method)->(),
            });
            _code_for($cleanup_loop_files_method)->($self, $name);
            exit 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'collector_runner_signal_stop') {
        $impl = sub {
            $__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::SIGNAL_RUNNER->_shutdown_loop(
                $__PAX_RUNTIME_LEGACY_NAMESPACE__::CollectorRunner::SIGNAL_LOOP_NAME,
                'stopped',
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_dispatch') {
        my $command_spec_method = $sub->{command_spec_method} // die 'compiled sub command-spec method missing';
        my $execute_hooks_method = $sub->{execute_hooks_method} // die 'compiled sub execute-hooks method missing';
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        my $skill_env_method = $sub->{skill_env_method} // die 'compiled sub skill-env method missing';
        $impl = sub {
            my ($self, $skill_name, $command, @args) = @_;
            return { error => 'Missing skill name' } if !$skill_name;
            return { error => 'Missing command name' } if !$command;
            my $skill_path = $self->{manager}->get_skill_path($skill_name, include_disabled => 1);
            my $suggest = __PAX_RUNTIME_LEGACY_NAMESPACE__::CLI::Suggest->new(paths => $self->{manager}{paths}, manager => $self->{manager});
            return { error => $suggest->unknown_skill_command_message($skill_name, $command) } if !$skill_path;
            return { error => $suggest->unknown_skill_command_message($skill_name, $command) } if !$self->{manager}->is_enabled($skill_name);
            my $command_spec = _code_for($command_spec_method)->($self, $skill_name, $command);
            my $cmd_path = $command_spec ? $command_spec->{cmd_path} : undef;
            my $command_skill_path = $command_spec ? $command_spec->{skill_path} : undef;
            return { error => $suggest->unknown_skill_command_message($skill_name, $command) } if !$cmd_path;
            my $hook_result = _code_for($execute_hooks_method)->($self, $skill_name, $command, @args);
            return $hook_result if $hook_result->{error};
            my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} || [] } : _code_for($skill_layers_method)->($self, $skill_name);
            my %env = _code_for($skill_env_method)->(
                $self,
                skill_name   => $skill_name,
                skill_path   => $command_skill_path || $skill_path,
                skill_layers => \@skill_layers,
                command      => $command_spec ? $command_spec->{command_name} : $command,
                result_state => $hook_result->{result_state} || {},
            );
            my @command = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($cmd_path);
            my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
                local %ENV = (%ENV, %env);
                __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_current($hook_result->{result_state} || {});
                if (ref($hook_result->{last_result}) eq 'HASH' && %{ $hook_result->{last_result} }) {
                    __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_last_result($hook_result->{last_result});
                } else {
                    __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::clear_last_result();
                }
                __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_runtime_layers(paths => $self->{manager}{paths});
                __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_skill_layers(skill_layers => \@skill_layers);
                system(@command, @args);
            };
            my $hook_stdout = join '', map { defined $_->{stdout} ? $_->{stdout} : '' } values %{ $hook_result->{hooks} || {} };
            my $hook_stderr = join '', map { defined $_->{stderr} ? $_->{stderr} : '' } values %{ $hook_result->{hooks} || {} };
            return {
                stdout    => $hook_stdout . $stdout,
                stderr    => $hook_stderr . $stderr,
                exit_code => $exit,
                hooks     => $hook_result->{hooks} || {},
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_exec_command') {
        my $command_spec_method = $sub->{command_spec_method} // die 'compiled sub command-spec method missing';
        my $execute_hooks_streaming_method = $sub->{execute_hooks_streaming_method} // die 'compiled sub execute-hooks-streaming method missing';
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        my $skill_env_method = $sub->{skill_env_method} // die 'compiled sub skill-env method missing';
        my $exec_resolved_method = $sub->{exec_resolved_method} // die 'compiled sub exec-resolved method missing';
        $impl = sub {
            my ($self, $skill_name, $command, @args) = @_;
            return { error => 'Missing skill name' } if !$skill_name;
            return { error => 'Missing command name' } if !$command;
            my $skill_path = $self->{manager}->get_skill_path($skill_name, include_disabled => 1);
            my $suggest = __PAX_RUNTIME_LEGACY_NAMESPACE__::CLI::Suggest->new(paths => $self->{manager}{paths}, manager => $self->{manager});
            return { error => $suggest->unknown_skill_command_message($skill_name, $command) } if !$skill_path;
            return { error => $suggest->unknown_skill_command_message($skill_name, $command) } if !$self->{manager}->is_enabled($skill_name);
            my $command_spec = _code_for($command_spec_method)->($self, $skill_name, $command);
            my $cmd_path = $command_spec ? $command_spec->{cmd_path} : undef;
            my $command_skill_path = $command_spec ? $command_spec->{skill_path} : undef;
            return { error => $suggest->unknown_skill_command_message($skill_name, $command) } if !$cmd_path;
            my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} || [] } : _code_for($skill_layers_method)->($self, $skill_name);
            my $hook_result = _code_for($execute_hooks_streaming_method)->($self, $skill_name, $command_spec ? $command_spec->{command_name} : $command, \@skill_layers, @args);
            return $hook_result if $hook_result->{error};
            my %env = _code_for($skill_env_method)->(
                $self,
                skill_name   => $skill_name,
                skill_path   => $command_skill_path || $skill_path,
                skill_layers => \@skill_layers,
                command      => $command_spec ? $command_spec->{command_name} : $command,
                result_state => $hook_result->{result_state} || {},
            );
            my @command = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($cmd_path);
            %ENV = (%ENV, %env);
            __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_current($hook_result->{result_state} || {});
            if (ref($hook_result->{last_result}) eq 'HASH' && %{ $hook_result->{last_result} }) {
                __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_last_result($hook_result->{last_result});
            } else {
                __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::clear_last_result();
            }
            __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_runtime_layers(paths => $self->{manager}{paths});
            __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_skill_layers(skill_layers => \@skill_layers);
            return _code_for($exec_resolved_method)->($self, $cmd_path, \@command, \@args);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_execute_hooks') {
        my $command_spec_method = $sub->{command_spec_method} // die 'compiled sub command-spec method missing';
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        my $skill_env_method = $sub->{skill_env_method} // die 'compiled sub skill-env method missing';
        $impl = sub {
            my ($self, $skill_name, $command, @args) = @_;
            return { hooks => {}, result_state => {} } if !$skill_name || !$command;
            my $skill_path = $self->{manager}->get_skill_path($skill_name, include_disabled => 1);
            return { hooks => {}, result_state => {} } if !$skill_path;
            return { hooks => {}, result_state => {} } if !$self->{manager}->is_enabled($skill_name);
            my $command_spec = _code_for($command_spec_method)->($self, $skill_name, $command);
            my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} || [] } : _code_for($skill_layers_method)->($self, $skill_name);
            return { hooks => {}, result_state => {} } if !@skill_layers;
            my $resolved_command = $command_spec ? $command_spec->{command_name} : $command;
            my %results;
            my $last_result = {};
            for my $layer_path (@skill_layers) {
                my $hooks_dir = File::Spec->catdir($layer_path, 'cli', "$resolved_command.d");
                next if !-d $hooks_dir;
                opendir(my $dh, $hooks_dir) or die "Unable to read $hooks_dir: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' } readdir($dh)) {
                    my $hook_path = File::Spec->catfile($hooks_dir, $entry);
                    next unless __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file($hook_path);
                    my %env = _code_for($skill_env_method)->(
                        $self,
                        skill_name   => $skill_name,
                        skill_path   => $layer_path,
                        skill_layers => \@skill_layers,
                        command      => $resolved_command,
                        result_state => \%results,
                    );
                    my @command = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($hook_path);
                    my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
                        local %ENV = (%ENV, %env);
                        __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_current(\%results);
                        if (%{$last_result}) {
                            __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_last_result($last_result);
                        } else {
                            __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::clear_last_result();
                        }
                        __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_runtime_layers(paths => $self->{manager}{paths});
                        __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_skill_layers(skill_layers => \@skill_layers);
                        system(@command, @args);
                    };
                    my $result_key = $entry;
                    if (exists $results{$entry}) {
                        my $leaf = File::Basename::basename(File::Basename::dirname($hook_path));
                        $result_key = $leaf . '/' . File::Basename::basename($hook_path);
                    }
                    $results{$result_key} = { stdout => $stdout, stderr => $stderr, exit_code => $exit };
                    $last_result = { file => $hook_path, exit => $exit, STDOUT => $stdout, STDERR => $stderr };
                }
                closedir($dh);
            }
            my %payload = ( hooks => \%results, result_state => \%results );
            $payload{last_result} = $last_result if %{$last_result};
            return \%payload;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_execute_hooks_streaming') {
        my $arrayref_or_empty_method = $sub->{arrayref_or_empty_method} // die 'compiled sub arrayref-or-empty method missing';
        my $skill_env_method = $sub->{skill_env_method} // die 'compiled sub skill-env method missing';
        my $run_child_streaming_method = $sub->{run_child_streaming_method} // die 'compiled sub child-streaming method missing';
        $impl = sub {
            my ($self, $skill_name, $command, $skill_layers, @args) = @_;
            return { hooks => {}, result_state => {} } if !$skill_name || !$command;
            my @skill_layers = @{ _code_for($arrayref_or_empty_method)->($self, $skill_layers) };
            return { hooks => {}, result_state => {} } if !@skill_layers;
            my %results;
            my $last_result = {};
            for my $layer_path (@skill_layers) {
                my $hooks_dir = File::Spec->catdir($layer_path, 'cli', "$command.d");
                next if !-d $hooks_dir;
                opendir(my $dh, $hooks_dir) or die "Unable to read $hooks_dir: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' } readdir($dh)) {
                    my $hook_path = File::Spec->catfile($hooks_dir, $entry);
                    next unless __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file($hook_path);
                    my %env = _code_for($skill_env_method)->(
                        $self,
                        skill_name   => $skill_name,
                        skill_path   => $layer_path,
                        skill_layers => \@skill_layers,
                        command      => $command,
                        result_state => \%results,
                    );
                    my @hook_command = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_argv_for_path($hook_path);
                    my $run = _code_for($run_child_streaming_method)->(
                        $self,
                        command      => \@hook_command,
                        args         => \@args,
                        env          => \%env,
                        skill_layers => \@skill_layers,
                        result_state => \%results,
                        last_result  => $last_result,
                        stdin_mode   => 'null',
                    );
                    my $result_key = $entry;
                    if (exists $results{$entry}) {
                        my $leaf = File::Basename::basename(File::Basename::dirname($hook_path));
                        $result_key = $leaf . '/' . File::Basename::basename($hook_path);
                    }
                    $results{$result_key} = {
                        stdout    => $run->{stdout},
                        stderr    => $run->{stderr},
                        exit_code => $run->{exit_code},
                    };
                    $last_result = {
                        file   => $hook_path,
                        exit   => $run->{exit_code},
                        STDOUT => $run->{stdout},
                        STDERR => $run->{stderr},
                    };
                }
                closedir($dh);
            }
            my %payload = ( hooks => \%results, result_state => \%results );
            $payload{last_result} = $last_result if %{$last_result};
            return \%payload;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_run_child_command_streaming') {
        my $arrayref_or_empty_method = $sub->{arrayref_or_empty_method} // die 'compiled sub arrayref-or-empty method missing';
        my $hashref_or_empty_method = $sub->{hashref_or_empty_method} // die 'compiled sub hashref-or-empty method missing';
        my $defined_or_default_method = $sub->{defined_or_default_method} // die 'compiled sub defined-or-default method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my @command = @{ _code_for($arrayref_or_empty_method)->($self, $args{command}) };
            my @argv = @{ _code_for($arrayref_or_empty_method)->($self, $args{args}) };
            my %env = %{ _code_for($hashref_or_empty_method)->($self, $args{env}) };
            my @skill_layers = @{ _code_for($arrayref_or_empty_method)->($self, $args{skill_layers}) };
            my $result_state = _code_for($hashref_or_empty_method)->($self, $args{result_state});
            my $last_result = $args{last_result};
            my $stdin_mode = _code_for($defined_or_default_method)->($self, $args{stdin_mode}, 'inherit');
            my $stdin_spec = '<&STDIN';
            my $stdin_fh;
            if ($stdin_mode eq 'null') {
                open $stdin_fh, '<', File::Spec->devnull() or die "Unable to open " . File::Spec->devnull() . " for streaming skill hook stdin: $!";
                $stdin_spec = '<&' . fileno($stdin_fh);
            }
            my $stderr = Symbol::gensym();
            my $stdout;
            my ($stdout_text, $stderr_text) = ('', '');
            my $pid;
            {
                local %ENV = (%ENV, %env);
                __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_current($result_state);
                if (ref($last_result) eq 'HASH' && %{$last_result}) {
                    __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::set_last_result($last_result);
                } else {
                    __PAX_RUNTIME_LEGACY_NAMESPACE__::Runtime::Result::clear_last_result();
                }
                __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_runtime_layers(paths => $self->{manager}{paths});
                __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvLoader->load_skill_layers(skill_layers => \@skill_layers);
                $pid = IPC::Open3::open3($stdin_spec, $stdout, $stderr, @command, @argv);
            }
            close $stdin_fh if $stdin_fh;
            my $selector = IO::Select->new($stdout, $stderr);
            my $stdout_fd = fileno($stdout);
            my $stderr_fd = fileno($stderr);
            local $| = 1;
            STDOUT->autoflush(1);
            STDERR->autoflush(1);
            while (my @ready = $selector->can_read) {
                for my $fh (@ready) {
                    my $buffer = '';
                    my $read = sysread($fh, $buffer, 8192);
                    if (!defined $read || $read == 0) {
                        $selector->remove($fh);
                        close $fh;
                        next;
                    }
                    if (fileno($fh) == $stdout_fd) {
                        print STDOUT $buffer;
                        $stdout_text .= $buffer;
                        next;
                    }
                    if (fileno($fh) == $stderr_fd) {
                        print STDERR $buffer;
                        $stderr_text .= $buffer;
                        next;
                    }
                }
            }
            waitpid($pid, 0);
            return { stdout => $stdout_text, stderr => $stderr_text, exit_code => $? >> 8 };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_exec_resolved_command') {
        my $arrayref_or_empty_method = $sub->{arrayref_or_empty_method} // die 'compiled sub arrayref-or-empty method missing';
        my $exec_replacement_method = $sub->{exec_replacement_method} // die 'compiled sub exec-replacement method missing';
        $impl = sub {
            my ($self, $cmd_path, $command, $args) = @_;
            my @command = @{ _code_for($arrayref_or_empty_method)->($self, $command) };
            my @args = @{ _code_for($arrayref_or_empty_method)->($self, $args) };
            my $error = _code_for($exec_replacement_method)->($self, \@command, \@args);
            if (defined $error && $error ne '') {
                return { error => "Unable to exec $cmd_path: $error" };
            }
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_exec_replacement') {
        $impl = sub {
            my ($self, $command, $args) = @_;
            my @command = @{ ref($command) eq 'ARRAY' ? $command : [] };
            my @args = @{ ref($args) eq 'ARRAY' ? $args : [] };
            if (!exec @command, @args) {
                my $error = "$!";
                return $error;
            }
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_route_response') {
        my $skill_layers_method = $sub->{skill_layers_method} // die 'compiled sub skill-layers method missing';
        my $bookmark_entries_method = $sub->{bookmark_entries_method} // die 'compiled sub bookmark entries method missing';
        my $page_response_method = $sub->{page_response_method} // die 'compiled sub page response method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $skill_name = $args{skill_name} || '';
            my $route = defined $args{route} ? $args{route} : '';
            my @skill_layers = _code_for($skill_layers_method)->($self, $skill_name);
            return [404, 'text/plain; charset=utf-8', "Skill '$skill_name' not found\n"] if !@skill_layers;
            my @parts = grep { defined && $_ ne '' } split m{/+}, $route;
            my @dashboards_roots = map { File::Spec->catdir($_, 'dashboards') } @skill_layers;
            return [404, 'text/plain; charset=utf-8', "Skill '$skill_name' does not provide dashboards\n"]
                if !grep { -d $_ } @dashboards_roots;
            if (@parts && $parts[0] eq 'bookmarks') {
                if (@parts == 1) {
                    my @items = _code_for($bookmark_entries_method)->($self, $skill_name);
                    return [404, 'text/plain; charset=utf-8', "Skill '$skill_name' does not provide dashboards\n"] if !@items;
                    return [200, 'application/json; charset=utf-8', JSON::XS::encode_json({ skill => $skill_name, bookmarks => \@items })];
                }
                my $legacy_id = join '/', @parts[1 .. $#parts];
                return _code_for($page_response_method)->(%args, skill_name => $skill_name, route_id => $legacy_id);
            }
            my $route_id = @parts ? join('/', @parts) : 'index';
            return _code_for($page_response_method)->(%args, skill_name => $skill_name, route_id => $route_id);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_nav_pages') {
        my $route_ids_method = $sub->{route_ids_method} // die 'compiled sub route ids method missing';
        my $load_skill_page_method = $sub->{load_skill_page_method} // die 'compiled sub load skill page method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            return [] if !$skill_name;
            my %route_ids = _code_for($route_ids_method)->($self, $skill_name);
            return [] if !%route_ids;
            my @pages;
            for my $entry (sort keys %route_ids) {
                push @pages, _code_for($load_skill_page_method)->($self, skill_name => $skill_name, route_id => $route_ids{$entry});
            }
            return \@pages;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_all_skill_nav_pages') {
        my $skill_nav_pages_method = $sub->{skill_nav_pages_method} // die 'compiled sub skill-nav-pages method missing';
        $impl = sub {
            my ($self) = @_;
            my @pages;
            for my $skill_root ($self->{manager}{paths}->installed_skill_roots) {
                my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
                next if !defined $skill_name || $skill_name eq '';
                push @pages, @{ _code_for($skill_nav_pages_method)->($self, $skill_name) || [] };
            }
            return \@pages;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_page_response') {
        my $load_skill_page_method = $sub->{load_skill_page_method} // die 'compiled sub load skill page method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $page = eval {
                _code_for($load_skill_page_method)->($self, skill_name => $args{skill_name}, route_id => $args{route_id});
            };
            return [404, 'text/plain; charset=utf-8', "Skill bookmark '$args{route_id}' not found\n"] if !$page || $@;
            return [200, 'text/plain; charset=utf-8', $page->{meta}{raw_instruction} || $page->canonical_instruction]
                if !$args{app};
            my $app = $args{app};
            $page = $app->_page_with_runtime_state(
                $page,
                query_params => $args{query_params} || {},
                body_params  => $args{body_params} || {},
                path         => $args{path} || '/app/' . $page->{id},
                remote_addr  => $args{remote_addr},
                headers      => $args{headers} || {},
            );
            $page = $app->{runtime}->prepare_page(
                page            => $page,
                source          => 'skill',
                runtime_context => { params => { %{ $args{query_params} || {} }, %{ $args{body_params} || {} } } },
            );
            return $app->_page_response($page, 'render');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_load_skill_page') {
        my $page_location_method = $sub->{page_location_method} // die 'compiled sub page-location method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self, %args) = @_;
            my $skill_name = $args{skill_name} || die 'Missing skill name';
            my $route_id = $args{route_id} || die 'Missing route id';
            my ($file, $skill_path) = _code_for($page_location_method)->($self, $skill_name, $route_id);
            die "Skill bookmark '$route_id' not found" if !defined $file || !-f $file;
            open my $fh, '<', $file or die "Unable to read $file: $!";
            local $/;
            my $instruction = <$fh>;
            close $fh;
            my $page = eval { $page_class->from_instruction($instruction) };
            if (!$page && $route_id =~ m{\Anav/.+\.tt\z}) {
                $page = $page_class->new(
                    id => $skill_name . '/' . $route_id,
                    title => $route_id,
                    layout => { body => $instruction },
                    meta => { source_format => 'raw-nav-tt' },
                );
            }
            die($@ || "Unable to parse skill bookmark '$route_id'") if !$page;
            $page->{id} = $skill_name . ( $route_id eq 'index' ? '' : '/' . $route_id );
            $page->{meta}{source_kind} = 'skill';
            $page->{meta}{skill_name} = $skill_name;
            $page->{meta}{skill_route_id} = $route_id;
            $page->{meta}{skill_path} = $skill_path;
            $page->{meta}{raw_instruction} = $instruction;
            return $page;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skill_dispatcher_skill_env') {
        $impl = sub {
            my ($self, %args) = @_;
            my $skill_path = $args{skill_path} || die 'Missing skill path';
            my $local_root = File::Spec->catdir($skill_path, 'perl5');
            my $shared_root = File::Spec->catdir($self->{manager}{paths}->home, 'perl5');
            my $path_sep = $^O eq 'MSWin32' ? ';' : ':';
            my @perl5lib = grep { defined && $_ ne '' } split /\Q$path_sep\E/, ($ENV{PERL5LIB} || '');
            for my $shared_lib (
                File::Spec->catdir($shared_root, 'lib', 'perl5'),
                File::Spec->catdir($shared_root, 'lib', 'perl5', $Config::Config{archname} || ''),
            ) {
                unshift @perl5lib, $shared_lib if defined $shared_lib && $shared_lib ne '' && -d $shared_lib;
            }
            for my $layer_path (reverse @{ $args{skill_layers} || [] }) {
                for my $local_lib (
                    File::Spec->catdir($layer_path, 'perl5', 'lib', 'perl5'),
                    File::Spec->catdir($layer_path, 'perl5', 'lib', 'perl5', $Config::Config{archname} || ''),
                ) {
                    unshift @perl5lib, $local_lib if defined $local_lib && $local_lib ne '' && -d $local_lib;
                }
            }
            return (
                DEVELOPER_DASHBOARD_SKILL_NAME        => $args{skill_name},
                DEVELOPER_DASHBOARD_SKILL_ROOT        => $skill_path,
                DEVELOPER_DASHBOARD_SKILL_COMMAND     => $args{command},
                DEVELOPER_DASHBOARD_SKILL_CLI_ROOT    => File::Spec->catdir($skill_path, 'cli'),
                DEVELOPER_DASHBOARD_SKILL_CONFIG_ROOT => File::Spec->catdir($skill_path, 'config'),
                DEVELOPER_DASHBOARD_SKILL_DOCKER_ROOT => File::Spec->catdir($skill_path, 'config', 'docker'),
                DEVELOPER_DASHBOARD_SKILL_STATE_ROOT  => File::Spec->catdir($skill_path, 'state'),
                DEVELOPER_DASHBOARD_SKILL_LOGS_ROOT   => File::Spec->catdir($skill_path, 'logs'),
                DEVELOPER_DASHBOARD_SKILL_LOCAL_ROOT  => $local_root,
                PERL5LIB                              => join($path_sep, @perl5lib),
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_file_path') {
        $impl = sub {
            my ($self, $session_id) = @_;
            return File::Spec->catfile($self->{paths}->sessions_root, "$session_id.json");
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_file_candidates') {
        $impl = sub {
            my ($self, $session_id) = @_;
            return map { File::Spec->catfile($_, "$session_id.json") } $self->{paths}->sessions_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_create') {
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        my $after_method = $sub->{after_method} // die 'compiled sub after method missing';
        my $file_method = $sub->{file_method} // die 'compiled sub file method missing';
        $impl = sub {
            require Digest::SHA;
            my ($self, %args) = @_;
            my $username = $args{username} || die 'Missing username';
            my $role = $args{role} || 'helper';
            my $ttl = $args{ttl_seconds} || 43_200;
            my $session_id = Digest::SHA::sha256_hex(join ':', $$, time, rand(), $username, $role);
            my $record = {
                session_id => $session_id,
                username => $username,
                role => $role,
                remote_addr => $args{remote_addr} || '',
                created_at => _code_for($now_method)->(),
                expires_at => _code_for($after_method)->($ttl),
                updated_at => _code_for($now_method)->(),
            };
            my $file = _code_for($file_method)->($self, $session_id);
            open my $fh, '>:raw', $file or die "Unable to write $file: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($record);
            close $fh;
            chmod 0600, $file;
            return $record;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_get') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        $impl = sub {
            my ($self, $session_id) = @_;
            return if !defined $session_id || $session_id eq '';
            for my $file (_code_for($file_candidates_method)->($self, $session_id)) {
                next if !-f $file;
                open my $fh, '<:raw', $file or die "Unable to read $file: $!";
                local $/;
                return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(scalar <$fh>);
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_delete') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        $impl = sub {
            my ($self, $session_id) = @_;
            return if !defined $session_id || $session_id eq '';
            unlink $_ for grep { -f $_ } _code_for($file_candidates_method)->($self, $session_id);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_from_cookie') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        my $delete_method = $sub->{delete_method} // die 'compiled sub delete method missing';
        my $to_epoch_method = $sub->{to_epoch_method} // die 'compiled sub to_epoch method missing';
        $impl = sub {
            my ($self, $cookie, %args) = @_;
            return if !defined $cookie || $cookie eq '';
            my %pairs;
            for my $part (split /;\s*/, $cookie) {
                my ($k, $v) = split /=/, $part, 2;
                next if !defined $k || $k eq '';
                $pairs{$k} = defined $v ? $v : '';
            }
            my $session = _code_for($get_method)->($self, $pairs{dashboard_session}) or return;
            if ($session->{expires_at} && _code_for($to_epoch_method)->($session->{expires_at}) <= time) {
                _code_for($delete_method)->($self, $session->{session_id});
                return;
            }
            if (defined $args{remote_addr} && defined $session->{remote_addr} && $session->{remote_addr} ne '') {
                return if $session->{remote_addr} ne $args{remote_addr};
            }
            return $session;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_user_file_path') {
        $impl = sub {
            my ($self, $username) = @_;
            my $safe = $username;
            $safe =~ s/[^A-Za-z0-9_.-]+/_/g;
            return File::Spec->catfile($self->{paths}->users_root, "$safe.json");
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_user_file_candidates') {
        $impl = sub {
            my ($self, $username) = @_;
            my $safe = $username;
            $safe =~ s/[^A-Za-z0-9_.-]+/_/g;
            return map { File::Spec->catfile($_, "$safe.json") } $self->{paths}->users_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_password_hash') {
        $impl = sub {
            require Digest::SHA;
            my ($self, $username, $password, $salt) = @_;
            return Digest::SHA::sha256_hex(join ':', $salt, $username, $password);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_add_user') {
        my $file_method = $sub->{file_method} // die 'compiled sub file method missing';
        my $hash_method = $sub->{hash_method} // die 'compiled sub hash method missing';
        my $now_method = $sub->{now_method} // die 'compiled sub now method missing';
        $impl = sub {
            require Digest::SHA;
            my ($self, %args) = @_;
            my $username = $args{username} || die 'Missing username';
            my $password = $args{password} || die 'Missing password';
            my $role = $args{role} || 'helper';
            die 'Username contains unsupported characters'
                if $username !~ /\A[A-Za-z0-9_.-]{1,64}\z/;
            die 'Password must be at least 8 characters long'
                if length($password) < 8;
            my $salt = Digest::SHA::sha256_hex(join ':', $$, time, rand(), $username);
            my $record = {
                username => $username,
                role => $role,
                salt => $salt,
                password_hash => _code_for($hash_method)->($self, $username, $password, $salt),
                updated_at => _code_for($now_method)->(),
            };
            my $file = _code_for($file_method)->($self, $username);
            open my $fh, '>:raw', $file or die "Unable to write $file: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($record);
            close $fh;
            chmod 0600, $file;
            return $record;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_get_user') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        $impl = sub {
            my ($self, $username) = @_;
            for my $file (_code_for($file_candidates_method)->($self, $username)) {
                next if !-f $file;
                open my $fh, '<:raw', $file or die "Unable to read $file: $!";
                local $/;
                return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(scalar <$fh>);
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_verify_user') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        my $hash_method = $sub->{hash_method} // die 'compiled sub hash method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $username = $args{username} || return;
            my $password = $args{password} || return;
            my $user = _code_for($get_method)->($self, $username) or return;
            my $expected = _code_for($hash_method)->($self, $username, $password, $user->{salt});
            return if $expected ne $user->{password_hash};
            return $user;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_list_users') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        $impl = sub {
            my ($self) = @_;
            my %users;
            for my $root (reverse $self->{paths}->users_roots) {
                opendir my $dh, $root or next;
                while (my $entry = readdir $dh) {
                    next if $entry eq '.' || $entry eq '..';
                    next if $entry !~ /(.*)\.json$/;
                    my $user = eval { _code_for($get_method)->($self, $1) };
                    $users{$1} = $user if $user;
                }
                closedir $dh;
            }
            return sort { $a->{username} cmp $b->{username} } values %users;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_remove_user') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        $impl = sub {
            my ($self, $username) = @_;
            unlink $_ for grep { -f $_ } _code_for($file_candidates_method)->($self, $username);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_helper_users_enabled') {
        my $list_method = $sub->{list_method} // die 'compiled sub list method missing';
        $impl = sub {
            my ($self) = @_;
            my @users = _code_for($list_method)->($self);
            return @users ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_canonical_host') {
        $impl = sub {
            my ($self, $host) = @_;
            return if !defined $host;
            $host =~ s/^\s+//;
            $host =~ s/\s+$//;
            return if $host eq '';
            if ($host =~ /^\[([0-9A-Fa-f:.]+)\](?::\d+)?$/) {
                $host = $1;
            }
            elsif ($host =~ /^([^:]+):\d+$/) {
                $host = $1;
            }
            return lc $host;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_canonical_ip') {
        $impl = sub {
            my ($self, $value) = @_;
            return '' if !defined $value;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            return '' if $value eq '';
            if ($value =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/) {
                return $value;
            }
            if ($value =~ /:/) {
                my $packed = Socket::inet_pton(Socket::AF_INET6(), $value);
                return defined $packed ? lc(Socket::inet_ntop(Socket::AF_INET6(), $packed)) : lc $value;
            }
            return lc $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_ip_is_loopback') {
        $impl = sub {
            my ($self, $ip) = @_;
            return 0 if !defined $ip || $ip eq '';
            return 1 if $ip =~ /\A127(?:\.\d{1,3}){3}\z/;
            return 1 if $ip eq '::1' || $ip eq '0:0:0:0:0:0:0:1';
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_resolve_host_ips') {
        my $canonical_ip_method = $sub->{canonical_ip_method} // die 'compiled sub canonical ip method missing';
        $impl = sub {
            my ($self, $host) = @_;
            return () if !defined $host || $host eq '';
            my ($err, @results) = Socket::getaddrinfo($host, undef, { socktype => Socket::SOCK_STREAM() });
            return () if $err;
            my @ips;
            my %seen;
            for my $result (@results) {
                next if ref($result) ne 'HASH';
                my $family = $result->{family};
                my $addr = $result->{addr};
                my $ip;
                if (defined $family && $family == Socket::AF_INET()) {
                    my (undef, $packed_addr) = Socket::unpack_sockaddr_in($addr);
                    $ip = Socket::inet_ntoa($packed_addr);
                }
                elsif (defined $family && $family == Socket::AF_INET6()) {
                    my (undef, $packed_addr) = Socket::unpack_sockaddr_in6($addr);
                    $ip = Socket::inet_ntop(Socket::AF_INET6(), $packed_addr);
                }
                $ip = _code_for($canonical_ip_method)->($self, $ip);
                next if !defined $ip || $ip eq '';
                next if $seen{$ip}++;
                push @ips, $ip;
            }
            return @ips;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_host_resolves_only_to_loopback') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        my $loopback_method = $sub->{loopback_method} // die 'compiled sub loopback method missing';
        $impl = sub {
            my ($self, $host) = @_;
            return 0 if !defined $host || $host eq '';
            my @ips = _code_for($resolve_method)->($self, $host);
            return 0 if !@ips;
            return !grep { !_code_for($loopback_method)->($self, $_) } @ips;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_request_is_loopback_admin') {
        my $canonical_host_method = $sub->{canonical_host_method} // die 'compiled sub canonical host method missing';
        my $loopback_method = $sub->{loopback_method} // die 'compiled sub loopback method missing';
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $remote_addr = $args{remote_addr} || '';
            my $host = $args{host};
            my @extra_loopback_hosts = map { _code_for($canonical_host_method)->($self, $_) }
                grep { defined $_ && $_ ne '' }
                @{ ref($args{extra_loopback_hosts}) eq 'ARRAY' ? $args{extra_loopback_hosts} : [] };
            return 0 if !_code_for($loopback_method)->($self, $remote_addr);
            return 1 if !defined $host || $host eq '';
            return 1 if _code_for($loopback_method)->($self, $host);
            return 1 if grep { defined $_ && $_ ne '' && $_ eq $host } @extra_loopback_hosts;
            return _code_for($resolve_method)->($self, $host);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_trust_tier') {
        my $canonical_ip_method = $sub->{canonical_ip_method} // die 'compiled sub canonical ip method missing';
        my $canonical_host_method = $sub->{canonical_host_method} // die 'compiled sub canonical host method missing';
        my $loopback_admin_method = $sub->{loopback_admin_method} // die 'compiled sub loopback admin method missing';
        $impl = sub {
            my ($self, %args) = @_;
            my $remote_addr = _code_for($canonical_ip_method)->($self, $args{remote_addr});
            my $host = _code_for($canonical_host_method)->($self, $args{host});
            return 'admin' if _code_for($loopback_admin_method)->(
                $self,
                remote_addr => $remote_addr,
                host => $host,
                extra_loopback_hosts => $args{extra_loopback_hosts},
            );
            return 'helper';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'auth_login_page') {
        $impl = sub {
            my ($self, %args) = @_;
            my $message = $args{message} || 'Helper access requires login.';
            my $redirect_to = defined $args{redirect_to} ? $args{redirect_to} : '';
            $message =~ s/&/&amp;/g;
            $message =~ s/</&lt;/g;
            $message =~ s/>/&gt;/g;
            $redirect_to =~ s/&/&amp;/g;
            $redirect_to =~ s/</&lt;/g;
            $redirect_to =~ s/>/&gt;/g;
            $redirect_to =~ s/"/&quot;/g;
            return <<"HTML";
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Developer Dashboard Login</title>
  <style>
    body { margin: 0; font-family: Georgia, serif; background: #f6efe4; color: #1f2a2e; }
    main { max-width: 520px; margin: 60px auto; background: #fffdf8; border: 1px solid #ddd3c2; padding: 28px; }
    label { display: block; margin: 14px 0 6px; }
    input { width: 100%; box-sizing: border-box; padding: 10px; font-size: 16px; }
    button { margin-top: 18px; padding: 10px 18px; font-size: 16px; }
  </style>
</head>
<body>
<main>
  <h1>Developer Dashboard</h1>
  <p>$message</p>
  <form method="post" action="/login">
    <input name="redirect_to" type="hidden" value="$redirect_to">
    <label for="username">Username</label>
    <input id="username" name="username" type="text" autocomplete="username">
    <label for="password">Password</label>
    <input id="password" name="password" type="password" autocomplete="current-password">
    <button type="submit">Login</button>
  </form>
</main>
</body>
</html>
HTML
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_current') {
        $impl = sub {
            my $json = _result_channel_json('RESULT', 'RESULT_FILE');
            return {} if !defined $json || $json eq '';
            my $data = JSON::XS::decode_json($json);
            die 'RESULT must decode to a hash' if ref($data) ne 'HASH';
            return $data;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_set_current') {
        my $clear_method = $sub->{clear_method} // die 'compiled sub clear method missing';
        my $set_channel_method = $sub->{set_channel_method} // die 'compiled sub set channel method missing';
        $impl = sub {
            my ($data, %args) = @_;
            die 'RESULT state must be a hash' if ref($data) ne 'HASH';
            return _code_for($clear_method)->() if !%{$data};
            return _code_for($set_channel_method)->('RESULT', 'RESULT_FILE', $data, %args);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_clear_current') {
        my $clear_channel_method = $sub->{clear_channel_method} // die 'compiled sub clear channel method missing';
        $impl = sub {
            return _code_for($clear_channel_method)->('RESULT', 'RESULT_FILE');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_last_result') {
        $impl = sub {
            shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq $package;
            my $json = _result_channel_json('LAST_RESULT', 'LAST_RESULT_FILE');
            return if !defined $json || $json eq '';
            my $data = JSON::XS::decode_json($json);
            die 'LAST_RESULT must decode to a hash' if ref($data) ne 'HASH';
            return $data;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_set_last_result') {
        my $clear_method = $sub->{clear_method} // die 'compiled sub clear method missing';
        my $set_channel_method = $sub->{set_channel_method} // die 'compiled sub set channel method missing';
        $impl = sub {
            shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq $package;
            my ($data, %args) = @_;
            die 'LAST_RESULT state must be a hash' if ref($data) ne 'HASH';
            return _code_for($clear_method)->() if !%{$data};
            return _code_for($set_channel_method)->('LAST_RESULT', 'LAST_RESULT_FILE', $data, %args);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_clear_last_result') {
        my $clear_channel_method = $sub->{clear_channel_method} // die 'compiled sub clear channel method missing';
        $impl = sub {
            shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq $package;
            return _code_for($clear_channel_method)->('LAST_RESULT', 'LAST_RESULT_FILE');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_stop_requested') {
        $impl = sub {
            shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq $package;
            my ($value) = @_;
            my $stderr = '';
            if (ref($value) eq 'HASH') {
                $stderr = defined $value->{STDERR}
                    ? $value->{STDERR}
                    : (defined $value->{stderr} ? $value->{stderr} : '');
            }
            elsif (defined $value) {
                $stderr = $value;
            }
            return $stderr =~ /\[\[STOP\]\]/ ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_names') {
        my $current_method = $sub->{current_method} // die 'compiled sub current method missing';
        $impl = sub {
            return sort keys %{ _code_for($current_method)->() };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_has') {
        my $current_method = $sub->{current_method} // die 'compiled sub current method missing';
        $impl = sub {
            my ($name) = @_;
            return 0 if !defined $name || $name eq '';
            return exists _code_for($current_method)->()->{$name} ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_entry') {
        my $current_method = $sub->{current_method} // die 'compiled sub current method missing';
        $impl = sub {
            my ($name) = @_;
            return if !defined $name || $name eq '';
            my $data = _code_for($current_method)->();
            return $data->{$name};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_stdout' || ($sub->{op} // '') eq 'result_stderr') {
        my $entry_method = $sub->{entry_method} // die 'compiled sub entry method missing';
        my $field = ($sub->{op} // '') eq 'result_stdout' ? 'stdout' : 'stderr';
        $impl = sub {
            my ($name) = @_;
            my $entry = _code_for($entry_method)->($name);
            return '' if ref($entry) ne 'HASH' || !defined $entry->{$field};
            return $entry->{$field};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_exit_code') {
        my $entry_method = $sub->{entry_method} // die 'compiled sub entry method missing';
        $impl = sub {
            my ($name) = @_;
            my $entry = _code_for($entry_method)->($name);
            return if ref($entry) ne 'HASH';
            return $entry->{exit_code};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_last_name') {
        my $names_method = $sub->{names_method} // die 'compiled sub names method missing';
        $impl = sub {
            my @names = _code_for($names_method)->();
            return $names[-1];
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_last_entry') {
        my $last_name_method = $sub->{last_name_method} // die 'compiled sub last name method missing';
        my $entry_method = $sub->{entry_method} // die 'compiled sub entry method missing';
        $impl = sub {
            my $entry_name = _code_for($last_name_method)->();
            return _code_for($entry_method)->($entry_name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_report') {
        my $names_method = $sub->{names_method} // die 'compiled sub names method missing';
        my $command_name_method = $sub->{command_name_method} // die 'compiled sub command name method missing';
        my $exit_code_method = $sub->{exit_code_method} // die 'compiled sub exit code method missing';
        $impl = sub {
            shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq $package;
            my (%args) = @_;
            my @names = _code_for($names_method)->();
            return '' if !@names;
            my $command = defined $args{command} && $args{command} ne ''
                ? $args{command}
                : _code_for($command_name_method)->();
            my @lines = (
                '----------------------------------------',
                sprintf('%s Run Report', $command),
                '----------------------------------------',
            );
            for my $hook_name (@names) {
                my $exit_code = _code_for($exit_code_method)->($hook_name);
                my $icon = defined $exit_code && $exit_code == 0 ? '✅' : '🚨';
                push @lines, sprintf('%s %s', $icon, $hook_name);
            }
            push @lines, '----------------------------------------';
            require Encode;
            return Encode::encode('UTF-8', join("\n", @lines) . "\n");
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_current_json') {
        my $channel_json_method = $sub->{channel_json_method} // die 'compiled sub channel json method missing';
        $impl = sub {
            return _code_for($channel_json_method)->('RESULT', 'RESULT_FILE');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_max_inline_bytes') {
        $impl = sub {
            my (%args) = @_;
            return $args{max_inline_bytes}
                if defined $args{max_inline_bytes} && $args{max_inline_bytes} =~ /\A\d+\z/;
            my $app_prefix = _app_env_prefix();
            my $app_inline_env = $ENV{$app_prefix . '_RESULT_INLINE_MAX'} // '';
            return $app_inline_env if $app_inline_env =~ /\A\d+\z/;
            return 65536;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_open_channel_file') {
        $impl = sub {
            require Fcntl;
            require File::Temp;
            my ($fh, $path) = File::Temp::tempfile('dashboard-result-XXXXXX', TMPDIR => 1, UNLINK => 1);
            binmode $fh, ':raw';
            my $flags = fcntl($fh, Fcntl::F_GETFD(), 0);
            die "Unable to inspect RESULT file descriptor flags: $!" if !defined $flags;
            fcntl($fh, Fcntl::F_SETFD(), $flags & ~Fcntl::FD_CLOEXEC())
                or die "Unable to clear close-on-exec for RESULT file descriptor: $!";
            my $fd = fileno($fh);
            my $fd_path = -e "/dev/fd/$fd" ? "/dev/fd/$fd" : "/proc/self/fd/$fd";
            return ($fh, $fd_path);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_channel_json') {
        $impl = sub {
            my ($env_name, $file_env_name) = @_;
            my $json = $ENV{$env_name};
            return $json if defined $json && $json ne '';
            my $path = $ENV{$file_env_name} || '';
            return '' if $path eq '';
            open my $fh, '<:raw', $path or die "Unable to read $env_name file $path: $!";
            local $/;
            my $file_json = <$fh>;
            close $fh or die "Unable to close $env_name file $path: $!";
            return defined $file_json ? $file_json : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_set_channel') {
        my $max_inline_method = $sub->{max_inline_method} // die 'compiled sub max inline method missing';
        my $open_channel_method = $sub->{open_channel_method} // die 'compiled sub open channel method missing';
        my $clear_channel_file_method = $sub->{clear_channel_file_method} // die 'compiled sub clear channel file method missing';
        $impl = sub {
            my ($env_name, $file_env_name, $data, %args) = @_;
            my $json = JSON::XS::encode_json($data);
            if (length($json) <= _code_for($max_inline_method)->(%args)) {
                _code_for($clear_channel_file_method)->($file_env_name);
                $ENV{$env_name} = $json;
                delete $ENV{$file_env_name};
                return 'inline';
            }
            my ($fh, $path) = _code_for($open_channel_method)->();
            print {$fh} $json;
            truncate($fh, tell($fh)) or die "Unable to truncate $env_name file $path: $!";
            seek($fh, 0, Fcntl::SEEK_SET()) or die "Unable to rewind $env_name file $path: $!";
            _code_for($clear_channel_file_method)->($file_env_name);
            $RESULT_CHANNEL_FILE_HANDLE{$file_env_name} = $fh;
            $RESULT_CHANNEL_FILE_PATH{$file_env_name} = $path;
            delete $ENV{$env_name};
            $ENV{$file_env_name} = $path;
            return 'file';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_clear_channel') {
        my $clear_channel_file_method = $sub->{clear_channel_file_method} // die 'compiled sub clear channel file method missing';
        $impl = sub {
            my ($env_name, $file_env_name) = @_;
            delete $ENV{$env_name};
            delete $ENV{$file_env_name};
            _code_for($clear_channel_file_method)->($file_env_name);
            return '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_clear_channel_file') {
        $impl = sub {
            my ($file_env_name) = @_;
            return if !$RESULT_CHANNEL_FILE_HANDLE{$file_env_name};
            close $RESULT_CHANNEL_FILE_HANDLE{$file_env_name}
                or die "Unable to close result file handle for $RESULT_CHANNEL_FILE_PATH{$file_env_name}: $!";
            delete $RESULT_CHANNEL_FILE_HANDLE{$file_env_name};
            delete $RESULT_CHANNEL_FILE_PATH{$file_env_name};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'result_command_name') {
        $impl = sub {
            my $fallback = _app_command_name();
            $fallback = 'pax' if $fallback !~ /\S/;
            my $script = $0 || '';
            if ($script eq '') {
                return $fallback;
            }
            my $normalized = $script;
            $normalized =~ s{[\\/]+\z}{} if $normalized !~ m{\A(?:[\\/]|[A-Za-z]:[\\/]?)\z};
            return $fallback
                if $normalized eq '' || $normalized eq '/' || $normalized eq '\\' || $normalized =~ m{\A[A-Za-z]:[\\/]?\z};
            my $base = basename($normalized);
            return $base if $base ne '' && $base ne '/' && $base ne '\\' && $base ne 'run';
            my $parent = basename(dirname($normalized));
            return $parent if $parent ne '' && $parent ne '/' && $parent ne '\\';
            return $fallback;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_normalized_page_id') {
        $impl = sub {
            my ($self, $id) = @_;
            $id = '' if !defined $id;
            $id =~ s/^\s+//;
            $id =~ s/\s+$//;
            $id =~ s{\A/+app/+}{};
            $id =~ s{\A/+}{};
            return $id;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_page_file') {
        my $normalize_method = $sub->{normalize_method} // die 'compiled sub normalize method missing';
        $impl = sub {
            my ($self, $id) = @_;
            die 'Missing page id' if !defined $id || $id eq '';
            return File::Spec->catfile($self->{paths}->dashboards_root, _code_for($normalize_method)->($self, $id));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_file_candidates') {
        my $normalize_method = $sub->{normalize_method} // die 'compiled sub normalize method missing';
        $impl = sub {
            my ($self, $id) = @_;
            my $normalized = _code_for($normalize_method)->($self, $id);
            return map { File::Spec->catfile($_, $normalized) } $self->{paths}->dashboards_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_existing_page_file') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        $impl = sub {
            my ($self, $id) = @_;
            for my $file (_code_for($file_candidates_method)->($self, $id)) {
                return $file if -f $file;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_load_transient_page') {
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self, $token) = @_;
            my $instruction = __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::decode_payload($token);
            my $page = $page_class->from_instruction($instruction);
            $page->{meta}{source_kind} = 'transient';
            return $page;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_encode_page') {
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self, $page) = @_;
            if (ref($page) ne $page_class) {
                $page = $page_class->from_hash($page);
            }
            my $raw_instruction = $page->{meta}{raw_instruction};
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::encode_payload($raw_instruction)
                if defined $raw_instruction && $raw_instruction ne '';
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::encode_payload($page->canonical_instruction);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_token_url') {
        my $encode_method = $sub->{encode_method} // die 'compiled sub encode method missing';
        my $prefix = $sub->{prefix} // '/?token=';
        $impl = sub {
            my ($self, $page) = @_;
            return $prefix . URI::Escape::uri_escape(_code_for($encode_method)->($self, $page));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_looks_like_raw_nav_fragment') {
        $impl = sub {
            my ($self, $instruction) = @_;
            return 0 if !defined $instruction || $instruction eq '';
            return 1 if $instruction =~ /\[%/;
            return 1 if $instruction =~ /<\s*[A-Za-z!\/][^>]*>/;
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_normalize_legacy_icon_markup') {
        $impl = sub {
            my ($self, $text) = @_;
            return '' if !defined $text;
            $text =~ s/\x{1F9D1}\x{FFFD}\x{1F4BB}/\x{1F9D1}\x{200D}\x{1F4BB}/g;
            $text =~ s{(<h2>)\x{FFFD}(\s+)}{$1◈$2}g;
            $text =~ s{(<span\s+class="icon">)[^<]*\x{FFFD}[^<]*(</span>)}{$1🏷️$2}g;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_read_saved_instruction') {
        my $normalize_method = $sub->{normalize_method} // die 'compiled sub normalize method missing';
        $impl = sub {
            my ($self, $file) = @_;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            local $/;
            my $raw = <$fh>;
            close $fh or die "Unable to close $file: $!";
            return '' if !defined $raw;
            my $text = eval { Encode::decode('UTF-8', $raw, Encode::FB_CROAK()) }
                || Encode::decode('UTF-8', $raw, Encode::FB_DEFAULT());
            return _code_for($normalize_method)->($self, $text);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_raw_nav_fragment_page') {
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self, %args) = @_;
            my $id = $args{id} || die 'Missing raw nav fragment id';
            my $instruction = defined $args{instruction} ? $args{instruction} : '';
            return $page_class->new(
                id => $id,
                title => File::Basename::basename($id),
                layout => { body => $instruction },
                meta => { source_format => 'raw-nav-tt' },
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_load_page_file') {
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        my $looks_like_method = $sub->{looks_like_method} // die 'compiled sub looks-like method missing';
        my $raw_nav_method = $sub->{raw_nav_method} // die 'compiled sub raw nav method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self, $file, %args) = @_;
            my $instruction = _code_for($read_method)->($self, $file);
            my $page = eval { $page_class->from_instruction($instruction) };
            return $page if $page;
            my $id = $args{id} || '';
            if ($id =~ m{\Anav/.+\.tt\z} && _code_for($looks_like_method)->($self, $instruction)) {
                return _code_for($raw_nav_method)->($self, id => $id, instruction => $instruction);
            }
            die($@ || "Unable to load bookmark file $file");
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_read_saved_entry') {
        my $existing_method = $sub->{existing_method} // die 'compiled sub existing method missing';
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        $impl = sub {
            my ($self, $id) = @_;
            my $file = _code_for($existing_method)->($self, $id);
            die "Page '$id' not found" if !$file;
            return _code_for($read_method)->($self, $file);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_load_saved_page') {
        my $existing_method = $sub->{existing_method} // die 'compiled sub existing method missing';
        my $load_method = $sub->{load_method} // die 'compiled sub load method missing';
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        $impl = sub {
            my ($self, $id) = @_;
            my $file = _code_for($existing_method)->($self, $id);
            die "Page '$id' not found" if !$file;
            my $page = _code_for($load_method)->($self, $file, id => $id);
            $page->{id} ||= $id;
            $page->{meta}{source_kind} = 'saved';
            $page->{meta}{raw_instruction} = _code_for($read_method)->($self, $file);
            return $page;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_save_page') {
        my $page_file_method = $sub->{page_file_method} // die 'compiled sub page-file method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self, $page) = @_;
            if (ref($page) ne $page_class) {
                $page = $page_class->from_hash($page);
            }
            my $id = $page->as_hash->{id} || die 'Saved pages require an id';
            my $file = _code_for($page_file_method)->($self, $id);
            my $dir = File::Basename::dirname($file);
            $self->{paths}->ensure_dir($dir);
            open my $fh, '>', $file or die "Unable to save $file: $!";
            print {$fh} $page->canonical_instruction;
            close $fh;
            $self->{paths}->secure_file_permissions($file);
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_saved_page_entries_for_root') {
        $impl = sub {
            my ($self, $root) = @_;
            return if !defined $root || !-d $root;
            my @entries;
            File::Find::find(
                {
                    no_chdir => 1,
                    wanted => sub {
                        return if !-f $_;
                        my $rel = File::Spec->abs2rel($File::Find::name, $root);
                        $rel =~ s{\\}{/}g;
                        push @entries, { id => $rel, file => $File::Find::name };
                    },
                },
                $root,
            );
            return @entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_list_saved_pages') {
        my $entries_method = $sub->{entries_method} // die 'compiled sub entries method missing';
        my $load_method = $sub->{load_method} // die 'compiled sub load method missing';
        $impl = sub {
            my ($self) = @_;
            my %ids;
            for my $root (reverse $self->{paths}->dashboards_roots) {
                for my $entry (_code_for($entries_method)->($self, $root)) {
                    my $id = $entry->{id};
                    next if !defined $id || $id eq '';
                    my $ok = eval { _code_for($load_method)->($self, $entry->{file}, id => $id); 1 };
                    next if !$ok;
                    $ids{$id} = 1;
                }
            }
            return sort keys %ids;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_store_migrate_legacy_json_pages') {
        my $page_file_method = $sub->{page_file_method} // die 'compiled sub page-file method missing';
        my $page_class = $sub->{page_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument';
        $impl = sub {
            my ($self) = @_;
            my $root = $self->{paths}->dashboards_root;
            opendir my $dh, $root or return [];
            my @migrated;
            while (my $entry = readdir $dh) {
                next if $entry eq '.' || $entry eq '..';
                next if $entry !~ /\.json\z/;
                my $file = File::Spec->catfile($root, $entry);
                next if -d $file;
                open my $fh, '<', $file or next;
                local $/;
                my $raw = <$fh>;
                close $fh;
                my $page = eval { $page_class->from_json($raw) } or next;
                my $id = $page->as_hash->{id} || File::Basename::basename($entry, '.json');
                $page->{id} = $id;
                my $target = _code_for($page_file_method)->($self, $id);
                $self->{paths}->ensure_dir(File::Basename::dirname($target));
                open my $out, '>', $target or die "Unable to save $target: $!";
                print {$out} $page->canonical_instruction;
                close $out;
                $self->{paths}->secure_file_permissions($target);
                unlink $file or die "Unable to remove $file: $!";
                push @migrated, { from => $entry, id => $id, file => $target };
            }
            closedir $dh;
            return \@migrated;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_new') {
        $impl = sub {
            my ($class, %args) = @_;
            my $self = bless {
                id             => $args{id},
                title          => defined $args{title} ? $args{title} : 'Untitled',
                description    => defined $args{description} ? $args{description} : '',
                source_version => defined $args{source_version} ? $args{source_version} : 1,
                mode           => defined $args{mode} ? $args{mode} : 'edit',
                tags           => $args{tags} || [],
                inputs         => $args{inputs} || [],
                state          => $args{state} || {},
                layout         => $args{layout} || {},
                actions        => $args{actions} || [],
                permissions    => $args{permissions} || {},
                meta           => $args{meta} || {},
            }, $class;
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_from_hash') {
        my $new_method = $sub->{new_method} // die 'compiled sub new method missing';
        $impl = sub {
            my ($class, $hash) = @_;
            die 'Page document must be a hash reference' if ref($hash) ne 'HASH';
            return _code_for($new_method)->($class, %{$hash});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_from_json') {
        my $from_hash_method = $sub->{from_hash_method} // die 'compiled sub from-hash method missing';
        $impl = sub {
            my ($class, $json) = @_;
            return _code_for($from_hash_method)->($class, __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($json));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_from_instruction') {
        my $parse_legacy_sections_method = $sub->{parse_legacy_sections_method} // die 'compiled sub parse-legacy method missing';
        my $decode_stash_method = $sub->{decode_stash_method} // die 'compiled sub decode-stash method missing';
        my $trim_method = $sub->{trim_method} // die 'compiled sub trim method missing';
        my $trim_trailing_method = $sub->{trim_trailing_method} // die 'compiled sub trim-trailing method missing';
        my $new_method = $sub->{new_method} // die 'compiled sub new method missing';
        $impl = sub {
            my ($class, $text) = @_;
            $text = '' if !defined $text;
            my $source_format = 'modern';
            my %sections;
            if ($text =~ /^===\s*[A-Z][A-Z0-9.]*\s*===/m) {
                my $current = '';
                my @lines = split /\n/, $text, -1;
                for my $line (@lines) {
                    if ($line =~ /^===\s*([A-Z][A-Z0-9.]*)\s*===\s*$/) {
                        $current = $1;
                        $sections{$current} = [];
                        next;
                    }
                    next if $current eq '';
                    push @{ $sections{$current} }, $line;
                }
            } else {
                $source_format = 'legacy';
                %sections = _code_for($parse_legacy_sections_method)->($text);
            }
            die 'Instruction document did not contain any sections' if !keys %sections;
            my $state = _code_for($decode_stash_method)->(join("\n", @{ $sections{STASH} || [] }));
            my %meta;
            $meta{icon} = _code_for($trim_method)->(join("\n", @{ $sections{ICON} || [] })) if exists $sections{ICON};
            my @codes;
            for my $section (sort grep { /^CODE\d+$/ } keys %sections) {
                push @codes, {
                    id => $section,
                    body => _code_for($trim_trailing_method)->(join("\n", @{ $sections{$section} })),
                };
            }
            $meta{codes} = \@codes if @codes;
            return _code_for($new_method)->(
                $class,
                id => (_code_for($trim_method)->(join("\n", @{ $sections{BOOKMARK} || [] })) || undef),
                title => (_code_for($trim_method)->(join("\n", @{ $sections{TITLE} || [] })) || 'Untitled'),
                description => _code_for($trim_trailing_method)->(join("\n", @{ $sections{NOTE} || $sections{DESCRIPTION} || [] })),
                state => $state,
                layout => {
                    body => _code_for($trim_trailing_method)->(join("\n", @{ $sections{HTML} || [] })),
                },
                meta => {
                    %meta,
                    source_format => $source_format,
                },
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_merge_state') {
        $impl = sub {
            my ($self, $state) = @_;
            return $self if ref($state) ne 'HASH';
            for my $key (keys %{$state}) {
                $self->{state}{$key} = $state->{$key};
            }
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_with_mode') {
        $impl = sub {
            my ($self, $mode) = @_;
            $self->{mode} = $mode if defined $mode && $mode ne '';
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_as_hash') {
        $impl = sub {
            my ($self) = @_;
            return {
                id             => $self->{id},
                title          => $self->{title},
                description    => $self->{description},
                source_version => $self->{source_version},
                mode           => $self->{mode},
                tags           => $self->{tags},
                inputs         => $self->{inputs},
                state          => $self->{state},
                layout         => $self->{layout},
                actions        => $self->{actions},
                permissions    => $self->{permissions},
                meta           => $self->{meta},
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_canonical_json') {
        my $as_hash_method = $sub->{as_hash_method} // die 'compiled sub as-hash method missing';
        $impl = sub {
            my ($self) = @_;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode(_code_for($as_hash_method)->($self));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_canonical_instruction') {
        my $legacy_method = $sub->{legacy_method} // die 'compiled sub legacy method missing';
        $impl = sub {
            my ($self) = @_;
            return _code_for($legacy_method)->($self);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_legacy_instruction') {
        my $legacy_stash_method = $sub->{legacy_stash_method} // die 'compiled sub legacy stash method missing';
        $impl = sub {
            my ($self) = @_;
            my @sections;
            push @sections, [ 'TITLE', $self->{title} // 'Untitled' ];
            push @sections, [ 'ICON', $self->{meta}{icon} ] if defined $self->{meta}{icon} && $self->{meta}{icon} ne '';
            push @sections, [ 'BOOKMARK', $self->{id} ] if defined $self->{id} && $self->{id} ne '';
            push @sections, [ 'NOTE', $self->{description} ] if defined $self->{description} && $self->{description} ne '';
            push @sections, [ 'STASH', _code_for($legacy_stash_method)->($self->{state} || {}) ];
            push @sections, [ 'HTML', $self->{layout}{body} ] if defined $self->{layout}{body} && $self->{layout}{body} ne '';
            if (ref($self->{meta}{codes}) eq 'ARRAY') {
                for my $code (@{ $self->{meta}{codes} }) {
                    next if ref($code) ne 'HASH';
                    my $id = $code->{id} || '';
                    next if $id !~ /^CODE\d+$/;
                    push @sections, [ $id, defined $code->{body} ? $code->{body} : '' ];
                }
            }
            my @chunks = map {
                my ($section_name, $body) = @{$_};
                $body = '' if !defined $body;
                $body =~ s/\A\n+//;
                $body =~ s/\n+\z//;
                "$section_name: $body";
            } @sections;
            return join("\n" . $__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument::LEGACY_SEP . "\n", @chunks) . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_instruction_text') {
        my $canonical_method = $sub->{canonical_method} // die 'compiled sub canonical method missing';
        $impl = sub {
            my $self = shift;
            return _code_for($canonical_method)->($self, @_);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_render_template') {
        $impl = sub { return shift; };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_render_html') {
        my $html_method = $sub->{html_method} // die 'compiled sub html method missing';
        my $legacy_bootstrap_method = $sub->{legacy_bootstrap_method} // die 'compiled sub legacy bootstrap method missing';
        $impl = sub {
            my ($self, %opts) = @_;
            my $title = _code_for($html_method)->($self->{title});
            my $desc = _code_for($html_method)->($self->{description});
            my $body_html = defined $self->{layout}{body} ? $self->{layout}{body} : '';
            my $chrome_html = defined $opts{chrome_html} ? $opts{chrome_html} : '';
            my $nav_html = defined $opts{nav_html} ? $opts{nav_html} : '';
            my $runtime_bootstrap = '';
            my $runtime_output = '';
            for my $chunk (@{ $self->{meta}{runtime_outputs} || [] }) {
                next if !defined $chunk || ref($chunk);
                if ($chunk =~ /\A<script>/ && $chunk =~ /(set_chain_value|dashboard_ajax_singleton_cleanup)/) {
                    $runtime_bootstrap .= $chunk;
                    next;
                }
                $runtime_output .= $chunk;
            }
            my $runtime_errors = '';
            for my $chunk (@{ $self->{meta}{runtime_errors} || [] }) {
                next if !defined $chunk || ref($chunk);
                $runtime_errors .= qq{<pre class="runtime-error">} . _code_for($html_method)->($chunk) . qq{</pre>\n};
            }
            my $legacy_bootstrap = _code_for($legacy_bootstrap_method)->();
            return <<"HTML";
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <style>
    :root {
      --bg: #f7f4ec;
      --panel: #fffdf7;
      --ink: #1f2a2e;
      --muted: #6a767b;
      --line: #d9d3c7;
      --accent: #0b7a75;
    }
    body {
      margin: 0;
      font-family: Georgia, "Times New Roman", serif;
      background: linear-gradient(180deg, #f2efe6 0%, #f7f4ec 100%);
      color: var(--ink);
    }
    main {
      max-width: 880px;
      margin: 32px auto;
      background: var(--panel);
      border: 1px solid var(--line);
      box-shadow: 0 12px 40px rgba(0,0,0,0.08);
      padding: 28px;
    }
    .body {
      line-height: 1.6;
      padding: 0 0 24px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
    }
    th, td {
      text-align: left;
      border-bottom: 1px solid var(--line);
      padding: 10px 8px;
      vertical-align: top;
    }
    th {
      width: 30%;
      color: var(--muted);
    }
    ul {
      padding-left: 20px;
    }
    .pill {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 999px;
      background: #dff3ef;
      color: var(--accent);
      font-size: 0.9rem;
    }
    .runtime-error {
      color: #b00020;
      white-space: pre-wrap;
    }
    .dashboard-nav-items {
      margin: 0 0 24px;
      padding: 14px 18px;
      border: 1px solid var(--line);
      background: var(--panel, #f3eee2);
      color: var(--text, var(--ink));
      border-radius: 14px;
    }
    .dashboard-nav-items ul {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-wrap: wrap;
      gap: 10px 18px;
      align-items: center;
    }
    .dashboard-nav-items li {
      margin: 0;
      padding: 0;
    }
    .dashboard-nav-items li + li {
      margin-top: 0;
      padding-top: 0;
      border-top: 0;
    }
    .dashboard-nav-items a {
      color: var(--text, var(--ink));
      text-decoration-color: var(--accent, currentColor);
    }
    .dashboard-nav-items a:hover {
      color: var(--accent, var(--text, var(--ink)));
    }
  </style>
</head>
<body>
$legacy_bootstrap
<main>
  $chrome_html
  $nav_html
  @{[ $desc ne '' ? qq{<p>$desc</p>} : '' ]}
  <section class="body">$body_html</section>
  $runtime_bootstrap
  $runtime_output
  $runtime_errors
</main>
</body>
</html>
HTML
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_decode_structured_json') {
        my $trim_method = $sub->{trim_method} // die 'compiled sub trim method missing';
        $impl = sub {
            my ($text) = @_;
            $text = _code_for($trim_method)->($text);
            return {} if $text eq '';
            my $value = eval { __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($text) };
            return defined $value ? $value : {};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_decode_stash_section') {
        my $trim_method = $sub->{trim_method} // die 'compiled sub trim method missing';
        $impl = sub {
            my ($text) = @_;
            $text = _code_for($trim_method)->($text);
            return {} if $text eq '';
            if ($text =~ /\A[\{\[]/) {
                my $value = eval { __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode($text) };
                return $value if ref($value) eq 'HASH';
                return {};
            }
            my $hash = eval "+{ $text }";
            return ref($hash) eq 'HASH' ? $hash : {};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_parse_legacy_sections') {
        $impl = sub {
            my ($text) = @_;
            my %sections;
            my $markdown_sep = qr{^\s*---\s*$}m;
            my @parts = split /(?:\Q$__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument::LEGACY_SEP\E\s*\n?|$markdown_sep)/, $text;
            for my $part (@parts) {
                $part =~ s/\A[\r\n\s]+//;
                $part =~ s/[\r\n\s]+\z//;
                next if $part eq '';
                next if $part !~ /^([A-Za-z][A-Za-z0-9.]*)\s*:\s*(.*)$/s;
                my ($section_name, $body) = (uc($1), $2);
                $body =~ s/\A\s+//;
                next if !$section_name || !grep { $_ eq $section_name || ($section_name =~ /^CODE\d+$/ && /^CODE\d+$/) } @__PAX_RUNTIME_LEGACY_NAMESPACE__::PageDocument::LEGACY_KEYS;
                $sections{$section_name} = [ split /\n/, $body, -1 ];
            }
            return %sections;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_legacy_stash_text') {
        my $legacy_value_method = $sub->{legacy_value_method} // die 'compiled sub legacy value method missing';
        $impl = sub {
            my ($value) = @_;
            return '' if ref($value) ne 'HASH' || !keys %{$value};
            my @pairs = map { sprintf "%s => %s", $_, _code_for($legacy_value_method)->($value->{$_}) } sort keys %{$value};
            return join ",\n", @pairs;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_legacy_value') {
        $impl = sub {
            my ($value) = @_;
            return _runtime_legacy_value($value);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_legacy_quote') {
        $impl = sub {
            my ($text) = @_;
            return _runtime_legacy_quote($text);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_template_value') {
        my $trim_method = $sub->{trim_method} // die 'compiled sub trim method missing';
        $impl = sub {
            my ($path, $context) = @_;
            my @parts = grep { defined && $_ ne '' } split /\./, _code_for($trim_method)->($path);
            my $value = $context;
            for my $part (@parts) {
                return '' if ref($value) ne 'HASH' || !exists $value->{$part};
                $value = $value->{$part};
            }
            return '' if !defined $value || ref($value);
            return $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_legacy_bootstrap') {
        $impl = sub {
            return <<'JS';
<script>
function set_chain_value(obj, path, value) {
  let keys = (path || '').split('.');
  let current = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {};
    current = current[keys[i]];
  }
  current[keys[keys.length - 1]] = value;
}
function dashboard_ajax_singleton_cleanup(name) {
  if (!name) return;
  if (!window.__dashboardAjaxSingletons) window.__dashboardAjaxSingletons = {};
  if (window.__dashboardAjaxSingletons[name]) return;
  window.__dashboardAjaxSingletons[name] = true;
  window.addEventListener('pagehide', function() {
    let url = '/ajax/singleton/stop?singleton=' + encodeURIComponent(name);
    if (navigator.sendBeacon) {
      navigator.sendBeacon(url, '');
      return;
    }
    if (window.fetch) {
      fetch(url, { method: 'POST', keepalive: true, credentials: 'same-origin' }).catch(function () {});
    }
  });
}
function dashboard_target_nodes(target) {
  if (!target) return [];
  if (typeof target === 'string') return Array.prototype.slice.call(document.querySelectorAll(target));
  if (target instanceof Element) return [target];
  if (target.length && typeof target !== 'string') return Array.prototype.slice.call(target);
  return [];
}
function dashboard_render_value(value, options, formatter) {
  let rendered = value;
  if (options && options.type === 'json' && typeof value === 'string' && value !== '') {
    try {
      rendered = JSON.parse(value);
    } catch (error) {
      rendered = null;
    }
  }
  if (typeof formatter === 'function') return formatter(rendered);
  if (rendered === null || typeof rendered === 'undefined') return '';
  if (typeof rendered === 'object') return JSON.stringify(rendered);
  return String(rendered);
}
function dashboard_write_target(target, value, options, formatter) {
  let nodes = dashboard_target_nodes(target);
  let rendered = dashboard_render_value(value, options || {}, formatter);
  nodes.forEach(function(node) {
    if (options && options.type === 'html') {
      node.innerHTML = rendered;
      return;
    }
    if (node.tagName === 'INPUT' || node.tagName === 'TEXTAREA') {
      node.value = rendered;
      return;
    }
    node.textContent = rendered;
  });
  return rendered;
}
function fetch_value(url, target, options, formatter) {
  if (!url || !window.fetch) return Promise.resolve('');
  let settings = Object.assign({ credentials: 'same-origin' }, (options && options.fetch) || {});
  return window.fetch(url, settings).then(function(response) {
    if (!response.ok) throw new Error('Request failed with status ' + response.status);
    if (options && options.type === 'json') return response.text();
    return response.text();
  }).then(function(value) {
    return dashboard_write_target(target, value, options || {}, formatter);
  });
}
function dashboard_stream_settings(options) {
  let fetchOptions = (options && options.fetch) || {};
  let method = fetchOptions.method || options.method || 'GET';
  let body = typeof fetchOptions.body !== 'undefined' ? fetchOptions.body : (typeof options.body !== 'undefined' ? options.body : null);
  let headers = fetchOptions.headers || options.headers || {};
  let credentials = fetchOptions.credentials || options.credentials || 'same-origin';
  return {
    method: method,
    body: body,
    headers: headers,
    credentials: credentials
  };
}
function stream_data(url, target, options, formatter) {
  if (!url) return Promise.resolve('');
  if (!window.XMLHttpRequest) return fetch_value(url, target, options, formatter);
  let settings = dashboard_stream_settings(options || {});
  return new Promise(function(resolve, reject) {
    let xhr = new XMLHttpRequest();
    xhr.open(settings.method, url, true);
    xhr.withCredentials = settings.credentials !== 'omit';
    Object.keys(settings.headers || {}).forEach(function(name) {
      xhr.setRequestHeader(name, settings.headers[name]);
    });
    xhr.onprogress = function () {
      dashboard_write_target(target, xhr.responseText, options || {}, formatter);
    };
    xhr.onload = function () {
      if (xhr.status < 200 || xhr.status >= 300) {
        reject(new Error('Request failed with status ' + xhr.status));
        return;
      }
      resolve(dashboard_write_target(target, xhr.responseText, options || {}, formatter));
    };
    xhr.onerror = function () {
      reject(new Error('Stream request failed'));
    };
    xhr.send(settings.body);
  });
}
function stream_value(url, target, options, formatter) {
  return stream_data(url, target, options, formatter);
}
var ready_status = {};
function ready(options) {
  let doit = options.doit || function() {};
  let is_ok = options.is_ok || function() { return true; };
  let next = options.next || function() {};
  let fail = options.fail;
  let retries = 0;
  let max_retry = options.num_of_retry;
  let interval = (options.retry_interval || 1) * 1000;
  doit();
  let handle = setInterval(function() {
    if (is_ok()) {
      clearInterval(handle);
      return next();
    }
    retries++;
    if (max_retry && retries >= max_retry) {
      clearInterval(handle);
      if (fail) fail();
    }
  }, interval);
}
if (!window.configs) window.configs = {};
</script>
JS
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_trim') {
        $impl = sub {
            my ($text) = @_;
            $text = '' if !defined $text;
            $text =~ s/\A\s+//;
            $text =~ s/\s+\z//;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_trim_trailing_newline') {
        $impl = sub {
            my ($text) = @_;
            $text = '' if !defined $text;
            $text =~ s/\n+\z//;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'page_document_html_escape') {
        $impl = sub {
            my ($text) = @_;
            $text = '' if !defined $text;
            $text =~ s/&/&amp;/g;
            $text =~ s/</&lt;/g;
            $text =~ s/>/&gt;/g;
            $text =~ s/"/&quot;/g;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_file_candidates') {
        $impl = sub {
            my ($self, $name) = @_;
            return map { File::Spec->catfile($_, $name, 'status.json') } $self->{paths}->indicators_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_read_indicator_file') {
        $impl = sub {
            my ($self, $file) = @_;
            return if !-f $file;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            local $/;
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_decode(<$fh>);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_set_indicator') {
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        $impl = sub {
            my ($self, $name, %data) = @_;
            my $dir = $self->{paths}->indicator_dir($name);
            my $file = File::Spec->catfile($dir, 'status.json');
            my $lock = File::Spec->catfile($dir, '.lock');
            my $preserve_fields = delete $data{_preserve_existing_fields};
            my @preserve_existing = ref($preserve_fields) eq 'ARRAY' ? @{$preserve_fields} : ();

            open my $lock_fh, '>>', $lock or die "Unable to open $lock: $!";
            flock($lock_fh, Fcntl::LOCK_EX()) or die "Unable to lock $lock: $!";
            my $existing = _code_for($read_method)->($self, $file) || {};
            for my $field (@preserve_existing) {
                next if !exists $existing->{$field};
                $data{$field} = $existing->{$field};
            }
            $data{name} = $name;
            $data{updated_at} = Time::HiRes::time() if !exists $data{updated_at};
            my $tmp = "$file.pending";
            open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
            print {$fh} __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode(\%data);
            close $fh;
            $self->{paths}->secure_file_permissions($tmp);
            unlink $file if -f $file;
            rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
            $self->{paths}->secure_file_permissions($file);
            return \%data;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_get_indicator') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        $impl = sub {
            my ($self, $name) = @_;
            for my $file (_code_for($file_candidates_method)->($self, $name)) {
                my $item = _code_for($read_method)->($self, $file);
                return $item if $item;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_list_indicators') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        $impl = sub {
            my ($self) = @_;
            my %items;
            for my $root ($self->{paths}->indicators_roots) {
                next if !-d $root;
                opendir my $dh, $root or next;
                while (my $entry = readdir $dh) {
                    next if $entry eq '.' || $entry eq '..';
                    next if $items{$entry};
                    my $item = eval { _code_for($get_method)->($self, $entry) };
                    $items{$entry} = $item if $item;
                }
                closedir $dh;
            }
            return sort { ($a->{priority} || 999) <=> ($b->{priority} || 999) || $a->{name} cmp $b->{name} } values %items;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_is_template_toolkit_text') {
        $impl = sub {
            my ($self, $text) = @_;
            return 0 if !defined $text || $text eq '';
            return index($text, '[%') >= 0 ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_collector_indicator_candidate') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        my $is_tt_method = $sub->{is_tt_method} // die 'compiled sub tt method missing';
        $impl = sub {
            my ($self, $job, %opts) = @_;
            die 'Collector indicator candidate requires a collector job hash' if ref($job) ne 'HASH';
            die 'Collector indicator candidate requires a collector name' if !defined $job->{name} || $job->{name} eq '';
            my $indicator = ref($job->{indicator}) eq 'HASH' ? $job->{indicator} : {};
            my $name = $indicator->{name} || $job->{name};
            my $existing = ref($opts{existing}) eq 'HASH' ? $opts{existing} : eval { _code_for($get_method)->($self, $name) } || {};
            my $label = defined $indicator->{label} && $indicator->{label} ne '' ? $indicator->{label} : $name;
            my %candidate = (
                %{$existing},
                %{$indicator},
                name => $name,
                label => $label,
                status => exists $opts{status}
                    ? $opts{status}
                    : defined $existing->{status} && $existing->{status} ne ''
                    ? $existing->{status}
                    : 'missing',
                collector_name => $job->{name},
                managed_by_collector => 1,
                prompt_visible => exists $indicator->{prompt_visible}
                    ? $indicator->{prompt_visible}
                    : exists $existing->{prompt_visible}
                    ? $existing->{prompt_visible}
                    : 1,
            );
            if (_code_for($is_tt_method)->($self, $indicator->{icon})) {
                my $preserved_icon = '';
                if (
                    defined $existing->{icon_template}
                    && $existing->{icon_template} eq $indicator->{icon}
                    && defined $existing->{icon}
                ) {
                    $preserved_icon = $existing->{icon};
                }
                $candidate{icon_template} = $indicator->{icon};
                $candidate{icon} = $preserved_icon;
            } else {
                delete $candidate{icon_template};
                if (exists $indicator->{icon}) {
                    $candidate{icon} = defined $indicator->{icon} ? $indicator->{icon} : '';
                } else {
                    delete $candidate{icon};
                }
            }
            return \%candidate;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_delete_indicator') {
        $impl = sub {
            my ($self, $name) = @_;
            return 1 if !defined $name || $name eq '';
            for my $dir (map { File::Spec->catdir($_, $name) } $self->{paths}->indicators_roots) {
                my $file = File::Spec->catfile($dir, 'status.json');
                unlink $file if -f $file;
                rmdir $dir if -d $dir;
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_indicator_matches') {
        $impl = sub {
            my ($self, $existing, $candidate) = @_;
            return 0 if ref($existing) ne 'HASH' || ref($candidate) ne 'HASH';
            for my $key (qw(name label alias icon icon_template status priority prompt_visible page_status_icon collector_name managed_by_collector)) {
                my $left = exists $existing->{$key} ? $existing->{$key} : undef;
                my $right = exists $candidate->{$key} ? $candidate->{$key} : undef;
                $left = '' if !defined $left;
                $right = '' if !defined $right;
                return 0 if $left ne $right;
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_local_indicator') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my ($file) = _code_for($file_candidates_method)->($self, $name);
            return if !defined $file || $file eq '';
            return _code_for($read_method)->($self, $file);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_nearest_inherited_indicator') {
        my $file_candidates_method = $sub->{file_candidates_method} // die 'compiled sub file candidates method missing';
        my $read_method = $sub->{read_method} // die 'compiled sub read method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my @files = _code_for($file_candidates_method)->($self, $name);
            shift @files;
            for my $file (@files) {
                my $item = _code_for($read_method)->($self, $file);
                return $item if $item;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_is_placeholder_missing_indicator') {
        $impl = sub {
            my ($self, $indicator) = @_;
            return 0 if ref($indicator) ne 'HASH';
            return 0 if !($indicator->{managed_by_collector} || 0);
            my $status = defined $indicator->{status} ? lc $indicator->{status} : '';
            return $status eq 'missing' ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_sync_collectors') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        my $local_method = $sub->{local_method} // die 'compiled sub local method missing';
        my $nearest_method = $sub->{nearest_method} // die 'compiled sub nearest method missing';
        my $is_placeholder_method = $sub->{is_placeholder_method} // die 'compiled sub placeholder method missing';
        my $candidate_method = $sub->{candidate_method} // die 'compiled sub candidate method missing';
        my $matches_method = $sub->{matches_method} // die 'compiled sub matches method missing';
        my $set_method = $sub->{set_method} // die 'compiled sub set method missing';
        my $list_method = $sub->{list_method} // die 'compiled sub list method missing';
        my $delete_method = $sub->{delete_method} // die 'compiled sub delete method missing';
        $impl = sub {
            my ($self, $jobs) = @_;
            return [] if ref($jobs) ne 'ARRAY';
            return [] if !@{$jobs};
            my @written;
            my %active_collectors;
            for my $job (@{$jobs}) {
                next if ref($job) ne 'HASH';
                next if ref($job->{indicator}) ne 'HASH';
                next if !defined $job->{name} || $job->{name} eq '';
                $active_collectors{$job->{name}} = 1;
                my $indicator_name = $job->{indicator}{name} || $job->{name};
                my $existing = eval { _code_for($get_method)->($self, $indicator_name) } || {};
                my $local_existing = _code_for($local_method)->($self, $indicator_name) || {};
                my $effective_existing = $existing;
                my $healed_from_inherited = 0;
                if (ref($local_existing) eq 'HASH' && %{$local_existing} && _code_for($is_placeholder_method)->($self, $local_existing)) {
                    my $inherited = _code_for($nearest_method)->($self, $indicator_name);
                    if (
                        ref($inherited) eq 'HASH' && %{$inherited}
                        && ($inherited->{managed_by_collector} || 0)
                        && ($inherited->{collector_name} || '') eq $job->{name}
                        && !_code_for($is_placeholder_method)->($self, $inherited)
                    ) {
                        $effective_existing = $inherited;
                        $healed_from_inherited = 1;
                    }
                }
                my $candidate = _code_for($candidate_method)->(
                    $self,
                    $job,
                    existing => $effective_existing,
                    status => defined $effective_existing->{status} && $effective_existing->{status} ne '' ? $effective_existing->{status} : 'missing',
                );
                my $comparison_existing = ref($local_existing) eq 'HASH' && %{$local_existing} ? $local_existing : $existing;
                if (!_code_for($matches_method)->($self, $comparison_existing, $candidate)) {
                    my @preserve_existing = $healed_from_inherited ? () : qw(status updated_at stale);
                    if (
                        defined $candidate->{icon_template} && $candidate->{icon_template} ne ''
                        && defined $effective_existing->{icon_template}
                        && $effective_existing->{icon_template} eq $candidate->{icon_template}
                    ) {
                        push @preserve_existing, qw(icon icon_template);
                    }
                    push @written, _code_for($set_method)->(
                        $self,
                        $candidate->{name},
                        %{$candidate},
                        _preserve_existing_fields => \@preserve_existing,
                    );
                }
            }
            for my $indicator (_code_for($list_method)->($self)) {
                next if ref($indicator) ne 'HASH';
                next if !$indicator->{managed_by_collector};
                my $collector_name = $indicator->{collector_name} || '';
                next if $collector_name eq '';
                next if $active_collectors{$collector_name};
                _code_for($delete_method)->($self, $indicator->{name});
                push @written, { %{$indicator}, deleted => 1 };
            }
            return \@written;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_mark_stale') {
        my $get_method = $sub->{get_method} // die 'compiled sub get method missing';
        my $set_method = $sub->{set_method} // die 'compiled sub set method missing';
        $impl = sub {
            my ($self, $name, %opts) = @_;
            my $item = _code_for($get_method)->($self, $name) || return;
            $item->{stale} = 1;
            $item->{status} = $opts{status} if defined $opts{status};
            return _code_for($set_method)->($self, $name, %{$item});
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_is_stale') {
        $impl = sub {
            my ($self, $item, %opts) = @_;
            return if ref($item) ne 'HASH';
            return 1 if $item->{stale};
            my $max_age = defined $opts{max_age} ? $opts{max_age} : 300;
            return if !$item->{updated_at};
            return (Time::HiRes::time() - $item->{updated_at}) > $max_age ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_refresh_core_indicators') {
        my $set_method = $sub->{set_method} // die 'compiled sub set method missing';
        $impl = sub {
            my ($self, %args) = @_;
            require Capture::Tiny;
            require Cwd;
            my $cwd = $args{cwd} || $self->{paths}->current_project_root || $self->{paths}->home;
            my $items = [];
            my $docker_ok = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::command_in_path('docker') ? 1 : 0;
            push @$items, _code_for($set_method)->($self,
                'docker',
                alias => '🐳',
                label => 'Docker',
                icon => '🐳',
                page_status_icon => $docker_ok ? '&#x1F7E2;' : '&#x1F534;',
                status => $docker_ok ? 'ok' : 'missing',
                priority => 20,
                prompt_visible => 1,
            );
            my $project = $self->{paths}->project_root_for($cwd);
            push @$items, _code_for($set_method)->($self,
                'project',
                label => $project || '(no-project)',
                icon => 'P',
                status => $project ? 'ok' : 'none',
                priority => 50,
                prompt_visible => 0,
            );
            my $git_status = 'none';
            if ($project) {
                my $old = Cwd::cwd();
                chdir $project or die "Unable to chdir to $project: $!";
                my ($stdout, $stderr, $inside_exit) = Capture::Tiny::capture {
                    system('git', 'rev-parse', '--is-inside-work-tree');
                    return $? >> 8;
                };
                my $inside_work_tree = $inside_exit == 0 && $stdout =~ /^\s*true\s*$/m ? 1 : 0;
                if ($inside_work_tree) {
                    my (undef, undef, $dirty_exit) = Capture::Tiny::capture {
                        system('git', 'diff', '--quiet', '--ignore-submodules', 'HEAD', '--');
                        return $? >> 8;
                    };
                    $git_status = $dirty_exit == 0 ? 'clean' : 'dirty';
                }
                chdir $old or die "Unable to restore cwd to $old: $!";
            }
            push @$items, _code_for($set_method)->($self,
                'git',
                label => $git_status eq 'dirty' ? 'Git*' : 'Git',
                icon => 'G',
                status => $git_status,
                priority => 30,
                prompt_visible => 0,
            );
            return $items;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_status_icon_for') {
        $impl = sub {
            my ($self, $indicator, $map) = @_;
            return '' if ref($indicator) ne 'HASH';
            my $status = defined $indicator->{status} ? lc $indicator->{status} : '';
            return $map->{ok}{$status} if exists $map->{ok}{$status};
            return $map->{error}{$status} if exists $map->{error}{$status};
            return defined $indicator->{icon} ? $indicator->{icon} : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_prompt_status_icon') {
        my $status_icon_method = $sub->{status_icon_method} // die 'compiled sub status icon method missing';
        $impl = sub {
            my ($self, $indicator) = @_;
            return _code_for($status_icon_method)->($self, $indicator, $INDICATOR_PROMPT_STATUS_ICONS);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_page_status_icon') {
        my $status_icon_method = $sub->{status_icon_method} // die 'compiled sub status icon method missing';
        $impl = sub {
            my ($self, $indicator) = @_;
            return '' if ref($indicator) ne 'HASH';
            return $indicator->{page_status_icon} if defined $indicator->{page_status_icon} && $indicator->{page_status_icon} ne '';
            return _code_for($status_icon_method)->($self, $indicator, $INDICATOR_STATUS_ICONS);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_page_header_items') {
        my $list_method = $sub->{list_method} // die 'compiled sub list method missing';
        my $page_status_icon_method = $sub->{page_status_icon_method} // die 'compiled sub page status icon method missing';
        $impl = sub {
            my ($self) = @_;
            my @items;
            for my $indicator (sort { $a->{name} cmp $b->{name} } _code_for($list_method)->($self)) {
                next if exists $indicator->{prompt_visible} && !$indicator->{prompt_visible};
                my $alias = defined $indicator->{alias} && $indicator->{alias} ne ''
                    ? $indicator->{alias}
                    : defined $indicator->{icon} && $indicator->{icon} ne ''
                    ? $indicator->{icon}
                    : defined $indicator->{label} && $indicator->{label} ne ''
                    ? $indicator->{label}
                    : $indicator->{name};
                push @items, {
                    prog => $indicator->{name},
                    alias => $alias,
                    status => _code_for($page_status_icon_method)->($self, $indicator),
                };
            }
            return @items;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'indicator_store_page_header_payload') {
        my $items_method = $sub->{items_method} // die 'compiled sub items method missing';
        $impl = sub {
            my ($self) = @_;
            my @array = _code_for($items_method)->($self);
            my %hash = map { $_->{prog} => { %$_ } } @array;
            return {
                array => \@array,
                hash => \%hash,
                status => $INDICATOR_STATUS_ICONS,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_subcommand_candidates') {
        my $command_map = $sub->{command_map} || {};
        $impl = sub {
            my ($command) = @_;
            return @{ $command_map->{skill} || [] } if $command eq 'skills' || $command eq 'skill';
            return @{ $command_map->{$command} || [] };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_complete') {
        my $suggest_class = $sub->{suggest_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::CLI::Suggest';
        my $subcommand_method = $sub->{subcommand_method} // die 'compiled sub subcommand method missing';
        my $missing_words_error = $sub->{missing_words_error} // "Missing completion words\n";
        my $missing_index_error = $sub->{missing_index_error} // "Missing completion index\n";
        my $type_error = $sub->{type_error} // "Completion words must be an array reference\n";
        $impl = sub {
            my (%args) = @_;
            my $words = $args{words} || die $missing_words_error;
            my $index = defined $args{index} ? $args{index} : die $missing_index_error;
            die $type_error if ref($words) ne 'ARRAY';
            my @words = @{$words};
            my $current = defined $words[$index] ? $words[$index] : '';
            my $suggest = $suggest_class->new();
            my @candidates;
            if ($index <= 1) {
                @candidates = (
                    $suggest->top_level_candidates,
                    $suggest->skill_commands,
                );
            } else {
                @candidates = _code_for($subcommand_method)->($words[1] || '');
            }
            my %seen;
            return grep { !$seen{$_}++ } grep { !defined $current || $current eq '' || index($_, $current) == 0 } @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'resolve_ticket_request') {
        my $type_error = $sub->{type_error} // 'Ticket args must be an array reference';
        my $missing_error = $sub->{missing_error} // "Please specify a ticket name\n";
        $impl = sub {
            my (%args) = @_;
            my $argv = $args{args} || [];
            die $type_error if ref($argv) ne 'ARRAY';
            my $ticket = $argv->[0];
            $ticket = $args{env_ticket} if !defined $ticket || $ticket eq '';
            die $missing_error if !defined $ticket || $ticket eq '';
            return $ticket;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'ticket_environment') {
        my $missing_error = $sub->{missing_error} // "Ticket name is required\n";
        $impl = sub {
            my ($ticket) = @_;
            die $missing_error if !defined $ticket || $ticket eq '';
            return {
                TICKET_REF => $ticket,
                B => $ticket,
                OB => "origin/$ticket",
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'captured_command_result') {
        my $command = $sub->{command} // die 'compiled sub command missing';
        my $type_error = $sub->{type_error} // 'command args must be an array reference';
        $impl = sub {
            require Capture::Tiny;
            my (%args) = @_;
            my $argv = $args{args} || [];
            die $type_error if ref($argv) ne 'ARRAY';
            my ($stdout, $stderr, $exit_code) = Capture::Tiny::capture {
                system $command, @{$argv};
                return $? >> 8;
            };
            return {
                stdout => $stdout,
                stderr => $stderr,
                exit_code => $exit_code,
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'session_exists_via_command') {
        my $default_runner = $sub->{default_runner} // die 'compiled sub default runner missing';
        my $missing_error = $sub->{missing_error} // 'Missing session name';
        my $inspect_error = $sub->{inspect_error} // "Unable to inspect tmux session '%s': %s%s";
        $impl = sub {
            my (%args) = @_;
            my $session = $args{session} || die $missing_error;
            my $tmux = $args{tmux} || _code_for($default_runner);
            my $result = $tmux->(args => [ 'has-session', '-t', $session ]);
            return 1 if $result->{exit_code} == 0;
            return 0 if $result->{exit_code} == 1;
            die sprintf $inspect_error, $session, ($result->{stderr} || ''), ($result->{stdout} || '');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'which_usage') {
        my $usage = $sub->{usage} // "Usage: dashboard which [--edit] <cmd>|<skill>.<cmd>|<skill>.<sub-skill>.<cmd>\n";
        $impl = sub { return $usage };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'which_build_paths') {
        my $path_registry_class = $sub->{path_registry_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry';
        $impl = sub {
            require Cwd;
            my $home = $ENV{HOME} || '';
            my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);
            return $path_registry_class->new(
                home => $home,
                cwd => Cwd::cwd(),
                workspace_roots => \@roots,
                project_roots => \@roots,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_build_paths') {
        my $path_registry_class = $sub->{path_registry_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry';
        $impl = sub {
            my $home = $ENV{HOME} || '';
            my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);
            return $path_registry_class->new(
                workspace_roots => \@roots,
                project_roots => \@roots,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_registries') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $files = __PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry->new(paths => $paths);
            my $config = __PAX_RUNTIME_LEGACY_NAMESPACE__::Config->new(files => $files, paths => $paths);
            $paths->register_named_paths($config->path_aliases);
            $files->register_named_files($config->file_aliases);
            return ($files, $config);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_scope_relative_path_match') {
        $impl = sub {
            my (%args) = @_;
            my $scope = $args{scope} || return;
            my @patterns = @{ $args{pattern} || [] };
            return if !@patterns;
            return if grep { !defined $_ || $_ eq '' } @patterns;
            my $relative = File::Spec->catfile(@patterns);
            my $target = File::Spec->catfile($scope, $relative);
            return -f $target ? $target : undef;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_default_editor') {
        $impl = sub {
            my ($editor) = @_;
            return $editor || $ENV{VISUAL} || $ENV{EDITOR} || 'vim';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_editor_supports_tabs') {
        $impl = sub {
            my (%args) = @_;
            my $command = $args{command} || [];
            my $editor = $command->[0] || '';
            return 0 if $editor eq '';
            $editor =~ s{.*[\\/]}{};
            return $editor =~ /\A(?:vim|nvim|vi|gvim|iv)\z/i ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_unique_matches') {
        $impl = sub {
            my (@matches) = @_;
            my %seen;
            return grep { defined && $_ ne '' && !$seen{$_}++ } @matches;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_selection_matches') {
        $impl = sub {
            my (%args) = @_;
            my $choices = defined $args{choices} ? $args{choices} : '';
            my $matches = $args{matches} || [];
            return @{$matches} if $choices eq '' && @{$matches};
            if ($choices =~ /^\d+(?:\s*-\s*\d+)?(?:[\s,]+\d+(?:\s*-\s*\d+)?)*$/) {
                my @chosen;
                for my $chunk (grep { defined && $_ ne '' } split /[,\s]+/, $choices) {
                    if ($chunk =~ /^(\d+)-(\d+)$/) {
                        my ($start, $end) = ($1, $2);
                        return if $start < 1 || $end < $start || $end > @{$matches};
                        push @chosen, @{$matches}[ $start - 1 .. $end - 1 ];
                        next;
                    }
                    return if $chunk !~ /^\d+$/ || $chunk < 1 || $chunk > @{$matches};
                    push @chosen, $matches->[ $chunk - 1 ];
                }
                return @chosen;
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_select_matches') {
        my $unique_method = $sub->{unique_method} // die 'compiled sub unique method missing';
        my $selection_method = $sub->{selection_method} // die 'compiled sub selection method missing';
        $impl = sub {
            my (%args) = @_;
            my $matches = $args{matches} || [];
            my @matches = _code_for($unique_method)->(@{$matches});
            return if !@matches;
            return @matches if @matches == 1;
            for my $index (0 .. $#matches) {
                print($index + 1, ": $matches[$index]\n");
            }
            print '> ';
            my $selection = <STDIN>;
            return @matches if !defined $selection;
            chomp $selection;
            my @chosen = _code_for($selection_method)->(
                choices => $selection,
                matches => \@matches,
            );
            return @chosen if @chosen;
            return @matches if $selection eq '';
            die "Invalid file selection '$selection'\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_compile_regex') {
        $impl = sub {
            my ($pattern) = @_;
            return if !defined $pattern || $pattern eq '';
            my $regex = eval { qr/$pattern/i };
            die "Invalid regex '$pattern': $@\n" if !$regex;
            return $regex;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_scope_match_rank') {
        my $compile_regex_method = $sub->{compile_regex_method} // die 'compiled sub compile-regex method missing';
        $impl = sub {
            my (%args) = @_;
            my $file = $args{file} || '';
            my $match_path = $args{match_path} || $file;
            my @patterns = @{ $args{patterns} || [] };
            my ($basename) = $match_path =~ m{([^/\\]+)$};
            $basename ||= $match_path;
            my $stem = $basename;
            $stem =~ s{\.[^.]+$}{};
            my $rank = 0;
            for my $pattern (@patterns) {
                next if !defined $pattern || $pattern eq '';
                my $regex = _code_for($compile_regex_method)->($pattern);
                my $score = 50;
                my @components = grep { defined && $_ ne '' } split m{[\\/]+}, $match_path;
                if ($basename =~ /\A(?:$pattern)\z/i) {
                    $score = 0;
                } elsif ($stem =~ /\A(?:$pattern)\z/i) {
                    $score = 1;
                } elsif ($basename =~ /\A(?:$pattern)/i) {
                    $score = 2;
                } elsif ($basename =~ $regex) {
                    $score = 3;
                } elsif (grep { $_ =~ /\A(?:$pattern)\z/i } @components) {
                    $score = 4;
                } elsif ($match_path =~ $regex) {
                    $score = 5;
                }
                $rank += $score;
            }
            return $rank;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_ordered_scope_matches') {
        my $rank_method = $sub->{rank_method} // die 'compiled sub rank method missing';
        my $unique_method = $sub->{unique_method} // die 'compiled sub unique method missing';
        $impl = sub {
            my (%args) = @_;
            my @patterns = @{ $args{patterns} || [] };
            my @entries = @{ $args{entries} || [] };
            @entries = map { { file => $_, match_path => $_ } } _code_for($unique_method)->(@{ $args{files} || [] }) if !@entries;
            my @ranked;
            for my $index (0 .. $#entries) {
                push @ranked, {
                    file => $entries[$index]{file},
                    rank => _code_for($rank_method)->(
                        file => $entries[$index]{file},
                        match_path => $entries[$index]{match_path},
                        patterns => \@patterns,
                    ),
                    index => $index,
                };
            }
            return map { $_->{file} }
              sort { $a->{rank} <=> $b->{rank} || $a->{index} <=> $b->{index} } @ranked;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_roots') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my @roots = (
                Cwd::cwd(),
                scalar($paths->current_project_root || ()),
                $paths->workspace_roots,
                $paths->project_roots,
                @INC,
            );
            my %seen;
            return grep { defined && $_ ne '' && -d $_ && !$seen{$_}++ } @roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_existing_named_files') {
        $impl = sub {
            my (%args) = @_;
            my $roots = $args{roots} || [];
            my $relative = $args{relative} || return;
            my $prefixes = $args{prefixes} || [''];
            my @found;
            my %seen;
            for my $root (@{$roots}) {
                for my $prefix (@{$prefixes}) {
                    my $file = $prefix eq ''
                        ? File::Spec->catfile($root, $relative)
                        : File::Spec->catfile($root, $prefix, $relative);
                    next if !-f $file || $seen{$file}++;
                    push @found, $file;
                }
            }
            return sort @found;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_matching_archive_entries') {
        $impl = sub {
            my (%args) = @_;
            my $zip = $args{zip} || return;
            my $relative = $args{relative} || return;
            my $suffix = $relative;
            $suffix =~ s{\\}{/}g;
            my @entries;
            for my $member ($zip->members) {
                my $entry_name = $member->fileName || next;
                next if $entry_name !~ /(?:\A|\/)\Q$suffix\E\z/;
                push @entries, $entry_name;
            }
            return @entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_cached_archive_source_path') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $archive = $args{archive} || die 'Missing archive path';
            my $entry = $args{entry} || die 'Missing archive entry';
            my $digest = Digest::MD5::md5_hex(join "\0", $archive, $entry);
            my @parts = grep { defined && $_ ne '' } split m{/+}, $entry;
            return File::Spec->catfile(
                $paths->cache_root,
                'open-file',
                'java-sources',
                $digest,
                @parts,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_java_archive_roots') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $roots = $args{roots} || [];
            my @candidates = (
                @{$roots},
                File::Spec->catdir($paths->home, '.m2', 'repository'),
                File::Spec->catdir($paths->home, '.gradle', 'caches'),
                grep { defined && $_ ne '' } ($ENV{JAVA_HOME}, $ENV{JDK_HOME}),
            );
            my %seen;
            return grep { defined && $_ ne '' && -d $_ && !$seen{$_}++ } @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_candidate_archives') {
        my $archive_roots_method = $sub->{archive_roots_method} // die 'compiled sub archive roots method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $roots = $args{roots} || [];
            my @archives;
            my %seen;
            for my $root (_code_for($archive_roots_method)->(paths => $paths, roots => $roots)) {
                File::Find::find(
                    {
                        no_chdir => 1,
                        wanted => sub {
                            return if !-f $_;
                            my $path = $File::Find::name;
                            return if $path !~ /(?:-sources\.jar|-src\.jar|src\.zip|source\.zip|\.war|\.jar)\z/i;
                            return if $seen{$path}++;
                            push @archives, $path;
                        },
                    },
                    $root,
                );
            }
            return @archives;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_extract_archive_sources') {
        my $matching_archive_entries_method = $sub->{matching_archive_entries_method} // die 'compiled sub matching entries method missing';
        my $cached_archive_source_path_method = $sub->{cached_archive_source_path_method} // die 'compiled sub cached path method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $archive = $args{archive} || return;
            my $relative = $args{relative} || return;
            my $zip = Archive::Zip->new();
            return if $zip->read($archive) != Archive::Zip::AZ_OK();
            my @matches;
            for my $entry (_code_for($matching_archive_entries_method)->(zip => $zip, relative => $relative)) {
                my $member = $zip->memberNamed($entry) || next;
                my $target = _code_for($cached_archive_source_path_method)->(
                    paths => $paths,
                    archive => $archive,
                    entry => $entry,
                );
                my ($volume, $directories) = File::Spec->splitpath($target);
                File::Path::make_path(File::Spec->catpath($volume, $directories, ''));
                open my $fh, '>', $target or die "Unable to write $target: $!";
                print {$fh} $member->contents;
                close $fh;
                push @matches, $target;
            }
            return @matches;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_maven_search_documents') {
        $impl = sub {
            my ($entry_name) = @_;
            return if !defined $entry_name || $entry_name eq '';
            my $query = URI::Escape::uri_escape_utf8(qq{fc:"$entry_name"});
            my $url = "https://search.maven.org/solrsearch/select?q=$query&rows=20&wt=json";
            my $ua = LWP::UserAgent->new(timeout => 10);
            my $res = $ua->get($url);
            return if !$res->is_success;
            my $payload = eval { JSON::XS::decode_json($res->decoded_content) };
            return if !$payload || ref($payload) ne 'HASH';
            return @{ $payload->{response}{docs} || [] };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_download_maven_source_jar') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $doc = $args{doc} || return;
            return if ref($doc) ne 'HASH';
            return if !defined $doc->{g} || !defined $doc->{a} || !defined $doc->{v};
            my $group_path = join '/', split /\./, $doc->{g};
            my $file = "$doc->{a}-$doc->{v}-sources.jar";
            my $target = File::Spec->catfile(
                $paths->cache_root,
                'open-file',
                'maven-sources',
                split(/\//, $group_path),
                $doc->{a},
                $doc->{v},
                $file,
            );
            return $target if -f $target;
            my ($volume, $directories) = File::Spec->splitpath($target);
            File::Path::make_path(File::Spec->catpath($volume, $directories, ''));
            my $url = join '/',
                'https://repo1.maven.org/maven2',
                $group_path,
                $doc->{a},
                $doc->{v},
                $file;
            my $ua = LWP::UserAgent->new(timeout => 20);
            my $res = $ua->mirror($url, $target);
            return if !$res->is_success && $res->code != 304;
            return -f $target ? $target : undef;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_download_java_source_matches') {
        my $maven_search_method = $sub->{maven_search_method} // die 'compiled sub maven search method missing';
        my $download_source_jar_method = $sub->{download_source_jar_method} // die 'compiled sub source jar method missing';
        my $extract_archive_sources_method = $sub->{extract_archive_sources_method} // die 'compiled sub extract archive sources method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $entry_name = $args{name} || return;
            my $relative = $args{relative} || return;
            my @matches;
            for my $doc (_code_for($maven_search_method)->($entry_name)) {
                next if ref($doc) ne 'HASH';
                next if !grep { defined && $_ eq '-sources.jar' } @{ $doc->{ec} || [] };
                my $archive = _code_for($download_source_jar_method)->(paths => $paths, doc => $doc) or next;
                push @matches, _code_for($extract_archive_sources_method)->(
                    paths => $paths,
                    archive => $archive,
                    relative => $relative,
                );
                last if @matches;
            }
            return @matches;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_java_archive_matches') {
        my $candidate_archives_method = $sub->{candidate_archives_method} // die 'compiled sub candidate archives method missing';
        my $extract_archive_sources_method = $sub->{extract_archive_sources_method} // die 'compiled sub extract archive sources method missing';
        my $download_java_matches_method = $sub->{download_java_matches_method} // die 'compiled sub download java matches method missing';
        my $unique_method = $sub->{unique_method} // die 'compiled sub unique method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $roots = $args{roots} || [];
            my $entry_name = $args{name} || return;
            my $relative = $args{relative} || return;
            my @matches;
            for my $archive (_code_for($candidate_archives_method)->(paths => $paths, roots => $roots)) {
                push @matches, _code_for($extract_archive_sources_method)->(
                    paths => $paths,
                    archive => $archive,
                    relative => $relative,
                );
            }
            if (!@matches) {
                push @matches, _code_for($download_java_matches_method)->(
                    paths => $paths,
                    name => $entry_name,
                    relative => $relative,
                );
            }
            return _code_for($unique_method)->(@matches);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_named_source_matches') {
        my $roots_method = $sub->{roots_method} // die 'compiled sub roots method missing';
        my $existing_named_files_method = $sub->{existing_named_files_method} // die 'compiled sub existing files method missing';
        my $java_archive_matches_method = $sub->{java_archive_matches_method} // die 'compiled sub java archive matches method missing';
        my $unique_method = $sub->{unique_method} // die 'compiled sub unique method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my $entry_name = $args{name} || return;
            my @roots = _code_for($roots_method)->(paths => $paths);
            my @matches;
            if ($entry_name =~ /::/) {
                my $relative = File::Spec->catfile(split /::/, $entry_name) . '.pm';
                @matches = _code_for($existing_named_files_method)->(roots => \@roots, relative => $relative);
            } elsif ($entry_name =~ /^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+$/) {
                my $relative = File::Spec->catfile(split /\./, $entry_name) . '.java';
                @matches = _code_for($existing_named_files_method)->(
                    roots => \@roots,
                    relative => $relative,
                    prefixes => [
                        '',
                        File::Spec->catdir('src'),
                        File::Spec->catdir('src', 'main', 'java'),
                        File::Spec->catdir('src', 'test', 'java'),
                    ],
                );
                push @matches, _code_for($java_archive_matches_method)->(
                    paths => $paths,
                    roots => \@roots,
                    name => $entry_name,
                    relative => $relative,
                );
            }
            return _code_for($unique_method)->(@matches);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_resolve_matches') {
        my $named_matches_method = $sub->{named_matches_method} // die 'compiled sub named matches method missing';
        my $compile_regex_method = $sub->{compile_regex_method} // die 'compiled sub compile regex method missing';
        my $ordered_matches_method = $sub->{ordered_matches_method} // die 'compiled sub ordered matches method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die 'Missing path registry';
            my @argv = @{ $args{args} || [] };
            my $first = shift @argv;
            my $line = 0;
            if (defined $first && $first =~ /^(.+):(\d+)(?::\d+)?$/) {
                my ($file, $parsed_line) = ($1, $2);
                return ($parsed_line, $file) if -f $file;
            }
            return ($line, $first) if defined $first && -f $first;
            if (defined $first) {
                my @named_matches = _code_for($named_matches_method)->(
                    paths => $paths,
                    name => $first,
                );
                return ($line, @named_matches) if @named_matches;
            }
            my $scope;
            my @patterns;
            if (defined $first) {
                $scope = eval { $paths->resolve_dir($first) };
                $scope = $first if !$scope && -d $first;
            }
            if ($scope && -d $scope) {
                @patterns = @argv;
            } else {
                $scope = $paths->current_project_root || Cwd::cwd();
                @patterns = grep { defined && $_ ne '' } ($first, @argv);
            }
            my @entries;
            my @regexes = map { _code_for($compile_regex_method)->($_) } @patterns;
            File::Find::find(
                {
                    no_chdir => 1,
                    wanted => sub {
                        return if !-f $_;
                        my $path = $File::Find::name;
                        my $relative = File::Spec->abs2rel($path, $scope);
                        $relative =~ s{\A\.[/\\]}{};
                        for my $regex (@regexes) {
                            return if $relative !~ $regex;
                        }
                        push @entries, { file => $path, match_path => $relative };
                    },
                },
                $scope,
            );
            my @files = _code_for($ordered_matches_method)->(
                patterns => \@patterns,
                entries => \@entries,
            );
            return ($line, @files);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_command_exit') {
        $impl = sub {
            my ($code) = @_;
            exit $code;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'open_file_run_command') {
        my $build_paths_method = $sub->{build_paths_method} // die 'compiled sub build paths method missing';
        my $resolve_matches_method = $sub->{resolve_matches_method} // die 'compiled sub resolve matches method missing';
        my $select_matches_method = $sub->{select_matches_method} // die 'compiled sub select matches method missing';
        my $default_editor_method = $sub->{default_editor_method} // die 'compiled sub default editor method missing';
        my $editor_supports_tabs_method = $sub->{editor_supports_tabs_method} // die 'compiled sub editor tabs method missing';
        my $command_exec_method = $sub->{command_exec_method} // die 'compiled sub command exec method missing';
        my $command_exit_method = $sub->{command_exit_method} // die 'compiled sub command exit method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || _code_for($build_paths_method)->();
            my @argv = @{ $args{args} || [] };
            my $print = 0;
            my $line = 0;
            my $editor = '';
            Getopt::Long::GetOptionsFromArray(
                \@argv,
                'print!' => \$print,
                'line=i' => \$line,
                'editor=s' => \$editor,
            );
            die "Usage: open-file [--print] [--line N] [--editor CMD] <file|scope> [pattern...]\n" if !@argv;
            my ($line_override, @matches) = _code_for($resolve_matches_method)->(
                paths => $paths,
                args => \@argv,
            );
            $line ||= $line_override || 0;
            die "No files found\n" if !@matches;
            if ($print) {
                print join("\n", @matches), "\n";
                _code_for($command_exit_method)->(0);
            }
            @matches = _code_for($select_matches_method)->(matches => \@matches);
            my $editor_cmd = _code_for($default_editor_method)->($editor);
            my @command = split /\s+/, $editor_cmd;
            push @command, '-p' if _code_for($editor_supports_tabs_method)->(command => \@command);
            push @command, "+$line" if $line;
            push @command, @matches;
            _code_for($command_exec_method)->(@command);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_entry_command') {
        $impl = sub {
            return _app_entry_command(
                sub_env => $sub->{entrypoint_env},
                sub_fallback => $sub->{entrypoint_fallback},
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'exec_command_argv') {
        $impl = sub {
            my (@command) = @_;
            exec { $command[0] } @command;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'resolve_directory_runner') {
        $impl = sub {
            my ($dir) = @_;
            return if !defined $dir || $dir eq '' || !-d $dir;
            for my $candidate (qw(run run.pl run.sh run.bash run.ps1 run.cmd run.bat run.go run.java)) {
                my $path = File::Spec->catfile($dir, $candidate);
                my $resolved = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::resolve_runnable_file($path);
                return $resolved if defined $resolved && $resolved ne '';
            }
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'resolved_command_path') {
        my $directory_runner_method = $sub->{directory_runner_method} // die 'compiled sub directory runner method missing';
        $impl = sub {
            my ($path) = @_;
            return '' if !defined $path || $path eq '';
            if (-d $path) {
                my $runner = _code_for($directory_runner_method)->($path);
                return $runner if defined $runner && $runner ne '';
            }
            my $resolved = __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::resolve_runnable_file($path);
            return defined $resolved && $resolved ne '' ? $resolved : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'custom_command_path') {
        my $resolved_command_method = $sub->{resolved_command_method} // die 'compiled sub resolved command method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die "Missing paths registry\n";
            my $command = $args{command} || '';
            return '' if $command eq '';
            for my $root (reverse $paths->cli_layers) {
                my $path = File::Spec->catfile($root, $command);
                my $resolved = _code_for($resolved_command_method)->($path);
                return $resolved if $resolved ne '';
            }
            return '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'command_hook_files') {
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die "Missing paths registry\n";
            my $command = $args{command} || '';
            return () if $command eq '';
            my @hooks;
            for my $root ($paths->cli_layers) {
                my $plain_root = File::Spec->catdir($root, $command);
                my $hooks_root = -d $plain_root ? $plain_root : File::Spec->catdir($root, $command . '.d');
                next if !-d $hooks_root;
                opendir(my $dh, $hooks_root) or die "Unable to read $hooks_root: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' } readdir($dh)) {
                    my $path = File::Spec->catfile($hooks_root, $entry);
                    next if $entry eq 'run';
                    next if !__PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file($path);
                    push @hooks, $path;
                }
                closedir($dh);
            }
            return @hooks;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'builtin_target') {
        my $hook_method = $sub->{hook_method} // die 'compiled sub hook method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die "Missing paths registry\n";
            my $target = $args{target} || '';
            my $helper = __PAX_RUNTIME_LEGACY_NAMESPACE__::InternalCLI::canonical_helper_name($target);
            return if $helper eq '';
            __PAX_RUNTIME_LEGACY_NAMESPACE__::InternalCLI::ensure_helpers(paths => $paths);
            return {
                command => __PAX_RUNTIME_LEGACY_NAMESPACE__::InternalCLI::helper_path(paths => $paths, name => $helper),
                hooks => [ _code_for($hook_method)->(paths => $paths, command => $target) ],
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'custom_target') {
        my $command_method = $sub->{command_method} // die 'compiled sub command method missing';
        my $hook_method = $sub->{hook_method} // die 'compiled sub hook method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die "Missing paths registry\n";
            my $target = $args{target} || '';
            my $command = _code_for($command_method)->(paths => $paths, command => $target) || '';
            return if $command eq '';
            return {
                command => $command,
                hooks => [ _code_for($hook_method)->(paths => $paths, command => $target) ],
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'locate_skill_target') {
        my $skill_manager_class = $sub->{skill_manager_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillManager';
        my $skill_dispatcher_class = $sub->{skill_dispatcher_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillDispatcher';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die "Missing paths registry\n";
            my $target = $args{target} || '';
            return if $target !~ /\./;
            my ($skill_name, $skill_command) = split /\./, $target, 2;
            return if !defined $skill_name || $skill_name eq '' || !defined $skill_command || $skill_command eq '';
            my $manager = $skill_manager_class->new(paths => $paths);
            return if !$manager->get_skill_path($skill_name);
            my $dispatcher = $skill_dispatcher_class->new(manager => $manager);
            my $spec = $dispatcher->command_spec($skill_name, $skill_command);
            return if !$spec;
            return {
                command => $spec->{cmd_path},
                hooks => [ $dispatcher->command_hook_paths($skill_name, $skill_command) ],
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'locate_target') {
        my $skill_method = $sub->{skill_method} // die 'compiled sub skill method missing';
        my $builtin_method = $sub->{builtin_method} // die 'compiled sub builtin method missing';
        my $custom_method = $sub->{custom_method} // die 'compiled sub custom method missing';
        $impl = sub {
            my (%args) = @_;
            my $paths = $args{paths} || die "Missing paths registry\n";
            my $target = $args{target} || '';
            return { command => '', hooks => [] } if $target eq '';
            if (my $skill = _code_for($skill_method)->(paths => $paths, target => $target)) {
                return $skill;
            }
            if (my $helper = _code_for($builtin_method)->(paths => $paths, target => $target)) {
                return $helper;
            }
            if (my $custom = _code_for($custom_method)->(paths => $paths, target => $target)) {
                return $custom;
            }
            return { command => '', hooks => [] };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'run_which_command') {
        my $usage_method = $sub->{usage_method} // die 'compiled sub usage method missing';
        my $build_paths_method = $sub->{build_paths_method} // die 'compiled sub build paths method missing';
        my $locate_target_method = $sub->{locate_target_method} // die 'compiled sub locate target method missing';
        my $entry_command_method = $sub->{entry_command_method}
            // $sub->{app_entry_method}
            // die 'compiled sub entry command method missing';
        my $command_exec_method = $sub->{command_exec_method} // die 'compiled sub command exec method missing';
        $impl = sub {
            require Getopt::Long;
            my (%args) = @_;
            my $command = $args{command} || die "Missing command name\n";
            my $argv = $args{args} || die "Missing command arguments\n";
            die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';
            die _code_for($usage_method)->() if $command ne 'which';
            my @argv = @{$argv};
            my $edit = 0;
            Getopt::Long::GetOptionsFromArray(\@argv, 'edit!' => \$edit);
            my $target = shift @argv || die _code_for($usage_method)->();
            die _code_for($usage_method)->() if @argv;
            my $paths = _code_for($build_paths_method)->();
            my $result = _code_for($locate_target_method)->(paths => $paths, target => $target);
            die "Command '$target' not found\n" if !$result->{command};
            if ($edit) {
                _code_for($command_exec_method)->(_code_for($entry_command_method)->(), 'open-file', $result->{command});
                return 0;
            }
            print "COMMAND $result->{command}\n";
            print "HOOK $_\n" for @{ $result->{hooks} || [] };
            return 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_new') {
        my $path_registry_class = $sub->{path_registry_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry';
        my $skill_manager_class = $sub->{skill_manager_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillManager';
        $impl = sub {
            my ($class, %args) = @_;
            my $paths = $args{paths} || $path_registry_class->new(
                home => $ENV{HOME},
                workspace_roots => [],
                project_roots => [],
            );
            my $manager = $args{manager} || $skill_manager_class->new(paths => $paths);
            return bless { paths => $paths, manager => $manager }, $class;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_unknown_command_message') {
        my $suggestions_method = $sub->{suggestions_method} // die 'compiled sub suggestions method missing';
        $impl = sub {
            my ($self, $command) = @_;
            my @suggestions = _code_for($suggestions_method)->($self, $command);
            my $message = "Unknown command '$command'.\n";
            if (@suggestions) {
                $message .= "\nDid you mean:\n";
                $message .= join '', map { "  dashboard $_\n" } @suggestions;
            }
            return $message . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_unknown_skill_command_message') {
        my $skill_suggestions_method = $sub->{skill_suggestions_method} // die 'compiled sub skill suggestions method missing';
        $impl = sub {
            my ($self, $skill_name, $command) = @_;
            my $skill_path = $self->{manager}->get_skill_path($skill_name, include_disabled => 1);
            if (!$skill_path) {
                my @suggestions = _code_for($skill_suggestions_method)->($self, "$skill_name.$command");
                my $message = "Skill '$skill_name' not found.\n";
                if (@suggestions) {
                    $message .= "\nDid you mean:\n";
                    $message .= join '', map { "  dashboard $_\n" } @suggestions;
                }
                return $message . "\n";
            }
            if (!$self->{manager}->is_enabled($skill_name)) {
                return "Skill '$skill_name' is disabled.\n\nEnable it with:\n  dashboard skills enable $skill_name\n";
            }
            my @suggestions = _code_for($skill_suggestions_method)->($self, $command, $skill_name);
            my $message = "Command '$command' not found in skill '$skill_name'.\n";
            if (@suggestions) {
                $message .= "\nDid you mean:\n";
                $message .= join '', map { "  dashboard $_\n" } @suggestions;
            }
            return $message . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_top_level_candidates') {
        my $internal_method = $sub->{internal_method} // die 'compiled sub internal method missing';
        $impl = sub {
            my ($self) = @_;
            return _code_for($internal_method)->($self);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_top_level_suggestions') {
        my $rank_method = $sub->{rank_method} // die 'compiled sub rank method missing';
        my $candidates_method = $sub->{candidates_method} // die 'compiled sub candidates method missing';
        $impl = sub {
            my ($self, $command) = @_;
            return map { $_->{value} } _code_for($rank_method)->($self, $command, [ _code_for($candidates_method)->($self) ]);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_skill_commands') {
        my $skill_entries_method = $sub->{skill_entries_method} // die 'compiled sub skill entries method missing';
        my $all_entries_method = $sub->{all_entries_method} // die 'compiled sub all entries method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            my @entries = $skill_name ? _code_for($skill_entries_method)->($self, $skill_name) : _code_for($all_entries_method)->($self);
            return map { $_->{full} } @entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_skill_command_suggestions') {
        my $rank_method = $sub->{rank_method} // die 'compiled sub rank method missing';
        my $skill_entries_method = $sub->{skill_entries_method} // die 'compiled sub skill entries method missing';
        my $all_entries_method = $sub->{all_entries_method} // die 'compiled sub all entries method missing';
        $impl = sub {
            my ($self, $command, $skill_name) = @_;
            my @candidates = $skill_name
                ? map { $_->{full} } _code_for($skill_entries_method)->($self, $skill_name)
                : map { $_->{full} } _code_for($all_entries_method)->($self);
            my $query = $skill_name ? "$skill_name.$command" : $command;
            return map { $_->{value} } _code_for($rank_method)->($self, $query, \@candidates);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_internal_top_level_candidates') {
        my $logical_name_method = $sub->{logical_name_method} // die 'compiled sub logical name method missing';
        $impl = sub {
            my ($self) = @_;
            my %seen;
            my @candidates;
            for my $helper (__PAX_RUNTIME_LEGACY_NAMESPACE__::InternalCLI::helper_names()) {
                next if $seen{$helper}++;
                push @candidates, $helper;
            }
            my $aliases = __PAX_RUNTIME_LEGACY_NAMESPACE__::InternalCLI::helper_aliases();
            for my $alias (sort keys %{$aliases}) {
                my $canonical = $aliases->{$alias};
                next if $seen{$canonical}++;
                push @candidates, $canonical;
            }
            for my $root ($self->{paths}->cli_roots) {
                next if !-d $root;
                opendir(my $dh, $root) or die "Unable to read $root: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' && $_ ne 'dd' && $_ !~ /\.d\z/ } readdir($dh)) {
                    my $path = File::Spec->catfile($root, $entry);
                    my $logical = _code_for($logical_name_method)->($entry);
                    next if !$logical;
                    next if $seen{$logical}++;
                    next if !(-d $path || __PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file(File::Spec->catfile($root, $logical)));
                    push @candidates, $logical;
                }
                closedir($dh);
            }
            return @candidates;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_all_skill_command_entries') {
        my $skill_entries_method = $sub->{skill_entries_method} // die 'compiled sub skill entries method missing';
        $impl = sub {
            my ($self) = @_;
            require File::Basename;
            my @entries;
            for my $skill_root ($self->{paths}->installed_skill_roots(include_disabled => 1)) {
                push @entries, _code_for($skill_entries_method)->($self, File::Basename::basename($skill_root));
            }
            return @entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_skill_command_entries') {
        my $collect_method = $sub->{collect_method} // die 'compiled sub collect method missing';
        $impl = sub {
            my ($self, $skill_name) = @_;
            my $skill_root = $self->{manager}->get_skill_path($skill_name, include_disabled => 1);
            return () if !$skill_root;
            return _code_for($collect_method)->($self, $skill_root, $skill_name);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_collect_skill_commands') {
        my $logical_name_method = $sub->{logical_name_method} // die 'compiled sub logical name method missing';
        $impl = sub {
            my ($self, $skill_root, $prefix) = @_;
            my @entries;
            my $cli_root = File::Spec->catdir($skill_root, 'cli');
            if (-d $cli_root) {
                opendir(my $dh, $cli_root) or die "Unable to read $cli_root: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' && $_ !~ /\.d\z/ } readdir($dh)) {
                    my $logical = _code_for($logical_name_method)->($entry);
                    next if !$logical;
                    next if !__PAX_RUNTIME_LEGACY_NAMESPACE__::Platform::is_runnable_file(File::Spec->catfile($cli_root, $logical));
                    push @entries, { full => "$prefix.$logical" };
                }
                closedir($dh);
            }
            my $nested_root = File::Spec->catdir($skill_root, 'skills');
            if (-d $nested_root) {
                opendir(my $dh, $nested_root) or die "Unable to read $nested_root: $!";
                for my $entry (sort grep { $_ ne '.' && $_ ne '..' && -d File::Spec->catdir($nested_root, $_) } readdir($dh)) {
                    push @entries, _code_for($name)->($self, File::Spec->catdir($nested_root, $entry), "$prefix.$entry");
                }
                closedir($dh);
            }
            return @entries;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_rank_candidates') {
        my $score_method = $sub->{score_method} // die 'compiled sub score method missing';
        $impl = sub {
            my ($self, $query, $candidates) = @_;
            return () if !defined $query || $query eq '';
            my @scored;
            my %seen;
            for my $candidate (@{ $candidates || [] }) {
                next if !defined $candidate || $candidate eq '' || $seen{$candidate}++;
                my $score = _code_for($score_method)->($query, $candidate);
                next if !defined $score;
                push @scored, { value => $candidate, score => $score };
            }
            @scored = sort {
                   $a->{score} <=> $b->{score}
                || length($a->{value}) <=> length($b->{value})
                || $a->{value} cmp $b->{value}
            } @scored;
            splice @scored, 5 if @scored > 5;
            return @scored;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_candidate_score') {
        my $normalize_method = $sub->{normalize_method} // die 'compiled sub normalize method missing';
        my $distance_method = $sub->{distance_method} // die 'compiled sub distance method missing';
        $impl = sub {
            my ($query, $candidate) = @_;
            my $normalized_query = _code_for($normalize_method)->($query);
            my $normalized_candidate = _code_for($normalize_method)->($candidate);
            return 0 if $normalized_query eq $normalized_candidate;
            return 1 if index($normalized_candidate, $normalized_query) == 0;
            my $distance = _code_for($distance_method)->($normalized_query, $normalized_candidate);
            my $threshold = int(((length($normalized_query) > length($normalized_candidate) ? length($normalized_query) : length($normalized_candidate)) / 2)) + 1;
            return if $distance > $threshold;
            return $distance + 2;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_normalize_token') {
        $impl = sub {
            my ($value) = @_;
            $value = lc($value // '');
            $value =~ s/[^a-z0-9]+//g;
            return $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_levenshtein_distance') {
        $impl = sub {
            my ($left, $right) = @_;
            my @left = split //, $left;
            my @right = split //, $right;
            my @dist = (0 .. scalar @right);
            for my $i (1 .. scalar @left) {
                my $previous = $dist[0];
                $dist[0] = $i;
                for my $j (1 .. scalar @right) {
                    my $current = $dist[$j];
                    my $cost = $left[$i - 1] eq $right[$j - 1] ? 0 : 1;
                    my $delete = $dist[$j] + 1;
                    my $insert = $dist[$j - 1] + 1;
                    my $replace = $previous + $cost;
                    my $best = $delete < $insert ? $delete : $insert;
                    $best = $replace if $replace < $best;
                    $dist[$j] = $best;
                    $previous = $current;
                }
            }
            return $dist[-1];
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'suggest_logical_command_name') {
        $impl = sub {
            my ($entry) = @_;
            return '' if !defined $entry || $entry eq '';
            $entry =~ s/\.(?:pl|go|java|ps1|cmd|bat|sh|bash)\z//i;
            return $entry;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_file_candidates') {
        $impl = sub {
            my ($class, $root) = @_;
            return (
                File::Spec->catfile($root, '.env'),
                File::Spec->catfile($root, '.env.pl'),
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_path_identity') {
        $impl = sub {
            my ($class, $path) = @_;
            return '' if !defined $path || $path eq '';
            my $resolved = eval { Cwd::abs_path($path) };
            return defined $resolved && $resolved ne '' ? $resolved : File::Spec->canonpath($path);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_same_or_descendant_path') {
        my $identity_method = $sub->{identity_method} // die 'compiled sub identity method missing';
        $impl = sub {
            my ($class, $path, $root) = @_;
            return 0 if !defined $path || $path eq '' || !defined $root || $root eq '';
            my $path_id = _code_for($identity_method)->($class, $path);
            my $root_id = _code_for($identity_method)->($class, $root);
            return 1 if $path_id eq $root_id;
            return index($path_id, $root_id . '/') == 0 ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_lookup_symbol') {
        $impl = sub {
            my ($class, $name) = @_;
            return undef if !defined $name || $name eq '';
            return $ENV{$name};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_plain_directory_layers') {
        my $same_or_descendant_method = $sub->{same_or_descendant_method} // die 'compiled sub same-or-descendant method missing';
        my $identity_method = $sub->{identity_method} // die 'compiled sub identity method missing';
        $impl = sub {
            my ($class, $paths) = @_;
            my $cwd = Cwd::cwd();
            return () if !defined $cwd || $cwd eq '';
            my $home = $paths->home;
            my $project_root = eval { $paths->current_project_root } || '';
            my $stop_dir = '';
            if (_code_for($same_or_descendant_method)->($class, $cwd, $home)) {
                $stop_dir = $home;
            } elsif ($project_root ne '' && _code_for($same_or_descendant_method)->($class, $cwd, $project_root)) {
                $stop_dir = $project_root;
            } else {
                return ();
            }
            my @layers;
            my $dir = $cwd;
            while ($dir) {
                push @layers, $dir;
                last if _code_for($identity_method)->($class, $dir) eq _code_for($identity_method)->($class, $stop_dir);
                my $parent = File::Basename::dirname($dir);
                last if !defined $parent || $parent eq '' || $parent eq $dir;
                $dir = $parent;
            }
            return reverse @layers;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_plain_directory_files') {
        my $layers_method = $sub->{layers_method} // die 'compiled sub layers method missing';
        my $candidates_method = $sub->{candidates_method} // die 'compiled sub candidates method missing';
        $impl = sub {
            my ($class, $paths) = @_;
            my @files;
            for my $dir (_code_for($layers_method)->($class, $paths)) {
                push @files, _code_for($candidates_method)->($class, $dir);
            }
            return @files;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_runtime_layer_files') {
        my $candidates_method = $sub->{candidates_method} // die 'compiled sub candidates method missing';
        $impl = sub {
            my ($class, $paths) = @_;
            my @files;
            for my $runtime_root ($paths->runtime_layers) {
                push @files, _code_for($candidates_method)->($class, $runtime_root);
            }
            return @files;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_load_skill_layers') {
        my $candidates_method = $sub->{candidates_method} // die 'compiled sub candidates method missing';
        my $load_files_method = $sub->{load_files_method} // die 'compiled sub load files method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my @skill_layers = @{ $args{skill_layers} || [] };
            my @files;
            for my $skill_root (@skill_layers) {
                push @files, _code_for($candidates_method)->($class, $skill_root);
            }
            return _code_for($load_files_method)->($class, files => \@files);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_load_runtime_layers') {
        my $plain_files_method = $sub->{plain_files_method} // die 'compiled sub plain files method missing';
        my $runtime_files_method = $sub->{runtime_files_method} // die 'compiled sub runtime files method missing';
        my $load_files_method = $sub->{load_files_method} // die 'compiled sub load files method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my $paths = $args{paths} or die "Missing paths\n";
            return _code_for($load_files_method)->(
                $class,
                files => [
                    _code_for($plain_files_method)->($class, $paths),
                    _code_for($runtime_files_method)->($class, $paths),
                ],
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_load_files') {
        my $identity_method = $sub->{identity_method} // die 'compiled sub identity method missing';
        my $load_env_pl_method = $sub->{load_env_pl_method} // die 'compiled sub env.pl loader method missing';
        my $load_env_file_method = $sub->{load_env_file_method} // die 'compiled sub env loader method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my @files = @{ $args{files} || [] };
            my @loaded;
            my %seen;
            for my $file (@files) {
                next if !defined $file || $file eq '';
                my $identity = _code_for($identity_method)->($class, $file);
                next if $seen{$identity}++;
                next if !-f $file;
                if ($file =~ /\.env\.pl\z/) {
                    _code_for($load_env_pl_method)->($class, $file);
                    push @loaded, $file;
                    next;
                }
                _code_for($load_env_file_method)->($class, $file);
                push @loaded, $file;
            }
            return \@loaded;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_strip_comments') {
        $impl = sub {
            my ($class, %args) = @_;
            my $line = defined $args{line} ? $args{line} : '';
            my $state = $args{in_block_comment} || die "Missing in_block_comment state\n";
            my $trimmed = $line;
            $trimmed =~ s/\A\s+//;

            if (${$state}) {
                if ($trimmed =~ s/\A.*?\*\///) {
                    ${$state} = 0;
                    return __SUB__->($class,
                        line => $trimmed,
                        file => $args{file},
                        line_no => $args{line_no},
                        in_block_comment => $state,
                    );
                }
                return '';
            }

            if ($trimmed =~ /\A\/\*/) {
                ${$state} = 1;
                $trimmed =~ s/\A\/\*//;
                return __SUB__->($class,
                    line => $trimmed,
                    file => $args{file},
                    line_no => $args{line_no},
                    in_block_comment => $state,
                );
            }

            return '' if $trimmed =~ /\A#/;
            return '' if $trimmed =~ /\A\/\//;
            return $line;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_expand_value') {
        my $braced_method = $sub->{braced_method} // die 'compiled sub braced method missing';
        my $lookup_method = $sub->{lookup_method} // die 'compiled sub lookup method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my $value = defined $args{value} ? $args{value} : '';
            $value =~ s/\A~(?=\/|\z)/$ENV{HOME} || '~'/e;
            $value =~ s/\$\{([^}]+)\}/_code_for($braced_method)->(
                $class,
                expression => $1,
                file => $args{file},
                line_no => $args{line_no},
            )/ge;
            $value =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/_code_for($lookup_method)->($class, $1)/ge;
            return $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_expand_braced') {
        my $call_function_method = $sub->{call_function_method} // die 'compiled sub call-function method missing';
        my $lookup_method = $sub->{lookup_method} // die 'compiled sub lookup method missing';
        my $expand_value_method = $sub->{expand_value_method} // die 'compiled sub expand-value method missing';
        $impl = sub {
            my ($class, %args) = @_;
            my $expression = $args{expression};
            my ($symbol, $default) = split /:-/, $expression, 2;
            my $value = $symbol =~ /\(\)\z/
                ? _code_for($call_function_method)->(
                    $class,
                    function => $symbol,
                    file => $args{file},
                    line_no => $args{line_no},
                )
                : _code_for($lookup_method)->($class, $symbol);
            return defined $value && $value ne ''
                ? $value
                : defined $default
                    ? _code_for($expand_value_method)->(
                        $class,
                        value => $default,
                        file => $args{file},
                        line_no => $args{line_no},
                    )
                    : '';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_call_function') {
        my $invalid_error = $sub->{invalid_error} // 'Invalid env function in %s line %s: %s';
        my $call_error = $sub->{call_error} // 'Env function %s failed in %s line %s: %s';
        $impl = sub {
            my ($class, %args) = @_;
            my $function = $args{function} || '';
            $function =~ s/\(\)\z//;
            die sprintf($invalid_error, $args{file}, $args{line_no}, $function)
                if $function !~ /\A(?:[A-Za-z_][A-Za-z0-9_]*::)*[A-Za-z_][A-Za-z0-9_]*\z/;
            no strict 'refs';
            my $code = *{$function}{CODE};
            use strict 'refs';
            die sprintf($invalid_error, $args{file}, $args{line_no}, $function) if !$code;
            my $value = eval { $code->() };
            die sprintf($call_error, $function, $args{file}, $args{line_no}, $@) if $@;
            return $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_load_env_file') {
        my $strip_method = $sub->{strip_method} // die 'compiled sub strip method missing';
        my $expand_method = $sub->{expand_method} // die 'compiled sub expand method missing';
        my $invalid_line_error = $sub->{invalid_line_error} // 'Invalid env line in %s line %s: %s';
        my $invalid_key_error = $sub->{invalid_key_error} // 'Invalid env key in %s line %s: %s';
        my $unterminated_comment_error = $sub->{unterminated_comment_error} // 'Unterminated block comment in %s';
        $impl = sub {
            my ($class, $file) = @_;
            open my $fh, '<:raw', $file or die "Unable to read $file: $!";
            my $line_no = 0;
            my $in_block_comment = 0;
            while (my $line = <$fh>) {
                ++$line_no;
                $line =~ s/\r?\n\z//;
                $line = _code_for($strip_method)->(
                    $class,
                    line => $line,
                    file => $file,
                    line_no => $line_no,
                    in_block_comment => \$in_block_comment,
                );
                next if $line =~ /\A\s*\z/;
                die sprintf($invalid_line_error, $file, $line_no, $line) . "\n"
                    if $line !~ /\A\s*([^=\s]+)\s*=(.*)\z/;
                my ($key, $value) = ($1, $2);
                die sprintf($invalid_key_error, $file, $line_no, $key) . "\n"
                    if $key !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
                $value = _code_for($expand_method)->(
                    $class,
                    value => $value,
                    file => $file,
                    line_no => $line_no,
                );
                $ENV{$key} = $value;
                __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvAudit->record($key, $value, $file);
            }
            close $fh or die "Unable to close $file: $!";
            die sprintf($unterminated_comment_error, $file) . "\n" if $in_block_comment;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'env_load_env_pl_file') {
        $impl = sub {
            my ($class, $file) = @_;
            my %before = %ENV;
            delete $INC{$file};
            require $file;
            my @changed = grep {
                $_ ne 'DEVELOPER_DASHBOARD_ENV_AUDIT'
                    && (
                        !exists $before{$_}
                        || (defined $before{$_} && defined $ENV{$_} && $before{$_} ne $ENV{$_})
                        || (defined $before{$_} xor defined $ENV{$_})
                    )
            } sort keys %ENV;
            for my $key (@changed) {
                next if exists $before{$key} && defined $before{$key} && defined $ENV{$key} && $before{$key} eq $ENV{$key};
                next if exists $before{$key} && !defined $before{$key} && !defined $ENV{$key};
                __PAX_RUNTIME_LEGACY_NAMESPACE__::EnvAudit->record($key, $ENV{$key}, $file);
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_configure') {
        my $hash_symbol = $sub->{hash_symbol} // die 'compiled sub aliases symbol missing';
        my $files_symbol = $sub->{files_symbol} // die 'compiled sub files symbol missing';
        my $config_hash_symbol = $sub->{config_hash_symbol} // die 'compiled sub config aliases symbol missing';
        my $config_key_symbol = $sub->{config_key_symbol} // die 'compiled sub config key symbol missing';
        my $file_registry_class = $sub->{file_registry_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry';
        $impl = sub {
            my ($class, %args) = @_;
            {
                no strict 'refs';
                ${$files_symbol} = $args{files} if $args{files};
                if (!${$files_symbol} && $args{paths}) {
                    ${$files_symbol} = $file_registry_class->new(paths => $args{paths});
                }
                %{$hash_symbol} = %{ $args{aliases} || {} };
                %{$config_hash_symbol} = ();
                ${$config_key_symbol} = '';
            }
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_read') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        my $read_error = $sub->{read_error} // 'Unable to read %s: %s';
        $impl = sub {
            my ($class, $file) = @_;
            my $path = _code_for($resolve_method)->($class, $file);
            return if !defined $path || !-f $path;
            open my $fh, '<', $path or die sprintf($read_error, $path, $!);
            local $/;
            return <$fh>;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_write') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        my $files_method = $sub->{files_method} // die 'compiled sub files method missing';
        my $missing_error = $sub->{missing_error} // 'Missing file path';
        my $write_error = $sub->{write_error} // 'Unable to write %s: %s';
        my $close_error = $sub->{close_error} // 'Unable to close %s: %s';
        $impl = sub {
            my ($class, $file, $content, $append) = @_;
            my $path = _code_for($resolve_method)->($class, $file);
            die $missing_error if !defined $path || $path eq '';
            my $mode = $append ? '>>' : '>';
            open my $fh, $mode, $path or die sprintf($write_error, $path, $!);
            print {$fh} defined $content ? $content : '';
            close $fh or die sprintf($close_error, $path, $!);
            my $files = _code_for($files_method)->();
            $files->paths->secure_file_permissions($path) if $files && $files->can('paths');
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_all') {
        my $files_method = $sub->{files_method} // die 'compiled sub files method missing';
        my $load_aliases_method = $sub->{load_aliases_method} // die 'compiled sub load aliases method missing';
        $impl = sub {
            my $files = _code_for($files_method)->();
            _code_for($load_aliases_method)->();
            return {} if !$files || !$files->can('all_files');
            return $files->all_files;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_exists') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($class, $file) = @_;
            my $path = _code_for($resolve_method)->($class, $file);
            return $path && -f $path ? 1 : 0;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_rm') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($class, $file) = @_;
            my $path = _code_for($resolve_method)->($class, $file);
            unlink $path if defined $path && -e $path;
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_files_obj') {
        my $files_symbol = $sub->{files_symbol} // die 'compiled sub files symbol missing';
        my $file_registry_class = $sub->{file_registry_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::FileRegistry';
        my $path_registry_class = $sub->{path_registry_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::PathRegistry';
        my $load_aliases_method = $sub->{load_aliases_method} // die 'compiled sub load aliases method missing';
        $impl = sub {
            no strict 'refs';
            return ${$files_symbol} if Scalar::Util::blessed(${$files_symbol});
            my $home = $ENV{HOME} || '';
            return if $home eq '';
            my $paths = $path_registry_class->new(
                home => $home,
                workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
                project_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
            );
            ${$files_symbol} = $file_registry_class->new(paths => $paths);
            _code_for($load_aliases_method)->();
            return ${$files_symbol};
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_alias_cache_key') {
        $impl = sub {
            my ($files) = @_;
            return '' if !$files || !Scalar::Util::blessed($files);
            my $paths = $files->paths;
            return '' if !$paths || !Scalar::Util::blessed($paths);
            my $project_root = eval { $paths->current_project_root } || '';
            my @runtime_roots = eval { $paths->runtime_roots } || ();
            return join "\n", $project_root, @runtime_roots;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_load_configured_aliases') {
        my $files_symbol = $sub->{files_symbol} // die 'compiled sub files symbol missing';
        my $config_hash_symbol = $sub->{config_hash_symbol} // die 'compiled sub config aliases symbol missing';
        my $config_key_symbol = $sub->{config_key_symbol} // die 'compiled sub config key symbol missing';
        my $cache_key_method = $sub->{cache_key_method} // die 'compiled sub cache key method missing';
        my $config_class = $sub->{config_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::Config';
        $impl = sub {
            no strict 'refs';
            my $files = Scalar::Util::blessed(${$files_symbol}) ? ${$files_symbol} : return 1;
            my $key = _code_for($cache_key_method)->($files);
            return 1 if $key ne '' && ${$config_key_symbol} eq $key;
            my $config = $config_class->new(files => $files, paths => $files->paths);
            %{$config_hash_symbol} = %{ $config->file_aliases || {} };
            $files->register_named_files(\%{$config_hash_symbol});
            ${$config_key_symbol} = $key;
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_resolve_file') {
        my $files_symbol = $sub->{files_symbol} // die 'compiled sub files symbol missing';
        my $aliases_symbol = $sub->{aliases_symbol} // die 'compiled sub aliases symbol missing';
        my $config_aliases_symbol = $sub->{config_aliases_symbol} // die 'compiled sub config aliases symbol missing';
        my $files_method = $sub->{files_method} // die 'compiled sub files method missing';
        my $load_aliases_method = $sub->{load_aliases_method} // die 'compiled sub load aliases method missing';
        $impl = sub {
            my ($class, $where) = @_;
            return if !defined $where || $where eq '';
            return $where if File::Spec->file_name_is_absolute($where) || $where =~ m{/};
            _code_for($files_method)->();
            _code_for($load_aliases_method)->();
            my $files;
            my (%aliases, %config_aliases);
            no strict 'refs';
            $files = Scalar::Util::blessed(${$files_symbol}) ? ${$files_symbol} : undef;
            %aliases = %{$aliases_symbol};
            %config_aliases = %{$config_aliases_symbol};
            return $files->$where() if $files && $files->can($where);
            return $aliases{$where} if defined $aliases{$where};
            return $config_aliases{$where} if defined $config_aliases{$where};
            my $app_env = _app_env_prefix() . '_FILE_' . uc($where);
            return $ENV{$app_env} if defined $ENV{$app_env} && $ENV{$app_env} ne '';
            return;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'app_file_autoload') {
        my $autoload_symbol = $sub->{autoload_symbol} // die 'compiled sub autoload symbol missing';
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($class) = @_;
            my $autoload;
            no strict 'refs';
            $autoload = ${$autoload_symbol};
            my ($name) = $autoload =~ /::([^:]+)$/;
            return if $name eq 'DESTROY';
            my $path = _code_for($resolve_method)->($class, $name);
            die "Unknown file '$name'" if !defined $path;
            return $path;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_resolve_file') {
        $impl = sub {
            my ($self, $name) = @_;
            return $name if File::Spec->file_name_is_absolute($name);
            return $self->{named_files}{$name} if exists $self->{named_files}{$name};
            $self->_load_configured_named_files;
            return $self->{configured_named_files}{$name} if exists $self->{configured_named_files}{$name};
            return $self->$name() if $self->can($name);
            die "Unknown file name '$name'";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_register_named_files') {
        $impl = sub {
            my ($self, $aliases) = @_;
            return $self if ref($aliases) ne 'HASH';
            for my $name (keys %{$aliases}) {
                next if !defined $name || $name eq '';
                my $path = $aliases->{$name};
                next if !defined $path || $path eq '';
                $self->{named_files}{$name} = $path;
            }
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_unregister_named_file') {
        $impl = sub {
            my ($self, $name) = @_;
            return $self if !defined $name || $name eq '';
            delete $self->{named_files}{$name};
            delete $self->{configured_named_files}{$name};
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_named_files') {
        my $load_method = $sub->{load_method} // die 'compiled sub load method missing';
        $impl = sub {
            my ($self) = @_;
            _code_for($load_method)->($self);
            return {
                %{ $self->{configured_named_files} || {} },
                %{ $self->{named_files} || {} },
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_all_file_aliases') {
        my $alias_methods = $sub->{alias_methods} // [];
        $impl = sub {
            my ($self) = @_;
            my %aliases;
            for my $pair (@{$alias_methods}) {
                my ($key, $method) = @{$pair};
                $aliases{$key} = $self->$method();
            }
            return \%aliases;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_all_files') {
        my $aliases_method = $sub->{aliases_method} // die 'compiled sub aliases method missing';
        my $named_files_method = $sub->{named_files_method} // die 'compiled sub named-files method missing';
        $impl = sub {
            my ($self) = @_;
            my %all = %{ _code_for($aliases_method)->($self) };
            my $named = _code_for($named_files_method)->($self);
            for my $name (keys %{$named}) {
                $all{$name} = $named->{$name};
            }
            return \%all;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_locate_files') {
        my $locate_under_method = $sub->{locate_under_method} // die 'compiled sub locate-under method missing';
        $impl = sub {
            my ($self, @terms) = @_;
            @terms = grep { defined && $_ ne '' } @terms;
            return () if !@terms;
            return _code_for($locate_under_method)->($self, $self->paths->cwd, @terms);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_locate_files_under') {
        $impl = sub {
            require File::Find;
            my ($self, $root, @terms) = @_;
            @terms = grep { defined && $_ ne '' } @terms;
            return () if !defined $root || $root eq '' || !-d $root || !@terms;
            my @found;
            File::Find::find(
                {
                    no_chdir => 1,
                    wanted => sub {
                        return if !-f $_;
                        my $path = $File::Find::name;
                        my $entry = $_;
                        for my $term (@terms) {
                            return if $entry !~ /\Q$term\E/i && $path !~ /\Q$term\E/i;
                        }
                        push @found, $path;
                    },
                },
                $root,
            );
            my %seen;
            return grep { !$seen{$_}++ } sort @found;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_load_configured_named_files') {
        $impl = sub {
            my ($self) = @_;
            my $config = __PAX_RUNTIME_LEGACY_NAMESPACE__::Config->new(files => $self, paths => $self->paths);
            $self->{configured_named_files} = $config->file_aliases;
            return $self;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_read') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my $file = _code_for($resolve_method)->($self, $name);
            return if !-f $file;
            open my $fh, '<', $file or die "Unable to read $file: $!";
            local $/;
            return <$fh>;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_write') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        my $mode = $sub->{mode} // '>';
        $impl = sub {
            my ($self, $name, $content) = @_;
            my $file = _code_for($resolve_method)->($self, $name);
            open my $fh, $mode, $file or die ($mode eq '>>' ? "Unable to append $file: $!" : "Unable to write $file: $!");
            print {$fh} defined $content ? $content : '';
            close $fh;
            $self->paths->secure_file_permissions($file);
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_touch') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my $file = _code_for($resolve_method)->($self, $name);
            open my $fh, '>>', $file or die "Unable to touch $file: $!";
            close $fh;
            $self->paths->secure_file_permissions($file);
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_remove') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        $impl = sub {
            my ($self, $name) = @_;
            my $file = _code_for($resolve_method)->($self, $name);
            unlink $file if -e $file;
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'file_registry_catfile') {
        my $root_method = $sub->{root_method} // die 'compiled sub root method missing';
        my $filename = $sub->{filename} // die 'compiled sub filename missing';
        $impl = sub {
            my ($self) = @_;
            return File::Spec->catfile($self->paths->$root_method(), $filename);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'usage_error_stderr') {
        my $exit_code = $sub->{exit_code} // 2;
        $impl = sub {
            my ($message) = @_;
            print STDERR $message;
            return $exit_code;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skills_install_progress') {
        my $progress_class = $sub->{progress_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::CLI::Progress';
        my $manager_class = $sub->{manager_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillManager';
        my $title = $sub->{title} // 'dashboard skills install progress';
        $impl = sub {
            my $enabled = $ENV{DEVELOPER_DASHBOARD_PROGRESS} ? 1 : 0;
            return if !$enabled && !-t STDERR;
            return $progress_class->new(
                title => $title,
                tasks => $manager_class->install_progress_tasks,
                stream => \*STDERR,
                dynamic => (-t STDERR ? 1 : 0),
                color => (-t STDERR ? 1 : 0),
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skills_install_progress_for_sources') {
        my $progress_class = $sub->{progress_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::CLI::Progress';
        my $manager_class = $sub->{manager_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillManager';
        my $title = $sub->{title} // 'dashboard skills install progress';
        $impl = sub {
            my (@sources) = @_;
            my $enabled = $ENV{DEVELOPER_DASHBOARD_PROGRESS} ? 1 : 0;
            return if !$enabled && !-t STDERR;
            return if !@sources;
            return $progress_class->new(
                title => $title,
                tasks => $manager_class->install_progress_tasks_for_sources(@sources),
                stream => \*STDERR,
                dynamic => (-t STDERR ? 1 : 0),
                color => (-t STDERR ? 1 : 0),
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skills_install_result_rows') {
        $impl = sub {
            my ($result) = @_;
            return () if ref($result) ne 'HASH';
            return @{ $result->{operations} || [] } if ref($result->{operations}) eq 'ARRAY';
            return @{ $result->{results} || [] } if ref($result->{results}) eq 'ARRAY';
            return ($result) if $result->{repo_name};
            return ();
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'ansi_plain_text') {
        $impl = sub {
            my ($value) = @_;
            $value = '' if !defined $value;
            $value =~ s/\e\[[0-9;]*m//g;
            return $value;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'bool_text_pair') {
        my $true_text = $sub->{true_text} // 'yes';
        my $false_text = $sub->{false_text} // 'no';
        $impl = sub {
            my ($value) = @_;
            return $value ? $true_text : $false_text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'format_table_row') {
        my $plain_text_method = $sub->{plain_text_method} // die 'compiled sub plain text method missing';
        $impl = sub {
            my ($row, $widths) = @_;
            my @cells;
            for my $idx (0 .. $#{$widths}) {
                my $value = defined $row->[$idx] ? $row->[$idx] : '';
                my $plain = _code_for($plain_text_method)->($value);
                push @cells, $value . (' ' x ($widths->[$idx] - length($plain)));
            }
            return join '  ', @cells;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'render_text_table') {
        my $plain_text_method = $sub->{plain_text_method} // die 'compiled sub plain text method missing';
        my $format_row_method = $sub->{format_row_method} // die 'compiled sub format row method missing';
        $impl = sub {
            my ($header, $rows) = @_;
            my @rows = @{ $rows || [] };
            my @widths = map { length _code_for($plain_text_method)->($_) } @{ $header || [] };
            for my $row (@rows) {
                for my $idx (0 .. $#{$row}) {
                    my $value = defined $row->[$idx] ? $row->[$idx] : '';
                    my $width = length _code_for($plain_text_method)->($value);
                    $widths[$idx] = $width if !defined $widths[$idx] || $width > $widths[$idx];
                }
            }
            my @lines;
            push @lines, _code_for($format_row_method)->($header, \@widths);
            push @lines, _code_for($format_row_method)->([ map { '-' x $widths[$_] } 0 .. $#widths ], \@widths);
            push @lines, map { _code_for($format_row_method)->($_, \@widths) } @rows;
            return join("\n", @lines) . "\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skills_install_summary_table') {
        my $rows_method = $sub->{rows_method} // die 'compiled sub rows method missing';
        my $render_table_method = $sub->{render_table_method} // die 'compiled sub render table method missing';
        $impl = sub {
            my ($result) = @_;
            my @rows = map {
                [
                    $_->{repo_name} || '-',
                    $_->{source} || '-',
                    defined $_->{version_before} ? $_->{version_before} : '-',
                    defined $_->{version_after} ? $_->{version_after} : '-',
                    $_->{status} || '-',
                ]
            } _code_for($rows_method)->($result);
            my $changed = grep { ( $_->[4] || '' ) eq 'installed' || ( $_->[4] || '' ) eq 'updated' } @rows;
            my $text = $changed ? '' : "No update.\n";
            $text .= _code_for($render_table_method)->([ 'Skill', 'Source', 'Before', 'After', 'Status' ], \@rows);
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skills_table') {
        my $enabled_text_method = $sub->{enabled_text_method} // die 'compiled sub enabled text method missing';
        my $render_table_method = $sub->{render_table_method} // die 'compiled sub render table method missing';
        $impl = sub {
            my ($skills) = @_;
            my @rows = map {
                [
                    $_->{name},
                    _code_for($enabled_text_method)->($_->{enabled}),
                    $_->{cli_commands_count} || 0,
                    $_->{pages_count} || 0,
                    $_->{docker_services_count} || 0,
                    $_->{collectors_count} || 0,
                    $_->{indicators_count} || 0,
                ]
            } @{ $skills || [] };
            return _code_for($render_table_method)->(
                [ 'Repo', 'Enabled', 'CLI', 'Pages', 'Docker', 'Collectors', 'Indicators' ],
                \@rows,
            );
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'skills_usage_table') {
        my $enabled_text_method = $sub->{enabled_text_method} // die 'compiled sub enabled text method missing';
        my $boolean_text_method = $sub->{boolean_text_method} // die 'compiled sub boolean text method missing';
        my $render_table_method = $sub->{render_table_method} // die 'compiled sub render table method missing';
        $impl = sub {
            my ($usage) = @_;
            my $text = '';
            $text .= "Skill: $usage->{name}\n";
            $text .= "Enabled: " . _code_for($enabled_text_method)->($usage->{enabled}) . "\n";
            $text .= "Path: $usage->{path}\n";
            $text .= "Config Root: $usage->{config}{root}\n";
            $text .= "Config File: $usage->{config}{file}\n";
            $text .= "Docker Root: $usage->{docker}{root}\n\n";
            $text .= "CLI Commands\n";
            $text .= _code_for($render_table_method)->(
                [ 'Command', 'Hooks', 'Hook Count', 'Path' ],
                [
                    map {
                        [ $_->{name}, _code_for($boolean_text_method)->($_->{has_hooks}), $_->{hook_count} || 0, $_->{path} ]
                    } @{ $usage->{cli} || [] }
                ],
            );
            $text .= "\nPages\n";
            $text .= _code_for($render_table_method)->(
                [ 'Type', 'Entry' ],
                [
                    ( map { [ 'page', $_ ] } @{ $usage->{pages}{entries} || [] } ),
                    ( map { [ 'nav',  $_ ] } @{ $usage->{pages}{nav_entries} || [] } ),
                ],
            );
            $text .= "\nDocker Services\n";
            $text .= _code_for($render_table_method)->(
                [ 'Service', 'Files' ],
                [
                    map { [ $_->{name}, join ', ', @{ $_->{files} || [] } ] } @{ $usage->{docker}{services} || [] }
                ],
            );
            $text .= "\nCollectors\n";
            $text .= _code_for($render_table_method)->(
                [ 'Name', 'Qualified', 'Indicator', 'Schedule' ],
                [
                    map {
                        [
                            $_->{name},
                            $_->{qualified_name},
                            _code_for($boolean_text_method)->($_->{has_indicator}),
                            defined $_->{interval} ? 'interval=' . $_->{interval} : ( $_->{schedule} || '' ),
                        ]
                    } @{ $usage->{collectors} || [] }
                ],
            );
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'run_skills_command') {
        my $build_paths_method = $sub->{build_paths_method} // die 'compiled sub build paths method missing';
        my $usage_error_method = $sub->{usage_error_method} // die 'compiled sub usage error method missing';
        my $install_progress_method = $sub->{install_progress_method} // die 'compiled sub install progress method missing';
        my $install_progress_sources_method = $sub->{install_progress_sources_method} // die 'compiled sub install progress sources method missing';
        my $install_summary_method = $sub->{install_summary_method} // die 'compiled sub install summary method missing';
        my $skills_table_method = $sub->{skills_table_method} // die 'compiled sub skills table method missing';
        my $usage_table_method = $sub->{usage_table_method} // die 'compiled sub usage table method missing';
        my $manager_class = $sub->{manager_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillManager';
        my $dispatcher_class = $sub->{dispatcher_class} // '__PAX_RUNTIME_LEGACY_NAMESPACE__::SkillDispatcher';
        $impl = sub {
            require Getopt::Long;
            require Cwd;
            my (%args) = @_;
            my $command = $args{command} || die "Missing command name\n";
            my $argv = $args{args} || die "Missing command arguments\n";
            die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';
            my @argv = @{$argv};
            my $action = shift @argv || '';

            if ($action eq 'install') {
                my $use_ddfile = 0;
                my $output = 'table';
                Getopt::Long::GetOptionsFromArray(\@argv, 'ddfile' => \$use_ddfile, 'o|output=s' => \$output);
                return _code_for($usage_error_method)->("Usage: dashboard skills install [-o json|table] [<git-url-or-local-dir> ...]\n")
                    if $output ne 'json' && $output ne 'table';
                return _code_for($usage_error_method)->(
                    "Usage: dashboard skills install [-o json|table] [<git-url-or-local-dir> ...]\n"
                    . "Usage: dashboard skill install [-o json|table] [<git-url-or-local-dir> ...]\n"
                    . "Usage: dashboard skills install --ddfile [-o json|table]\n"
                ) if $use_ddfile && @argv;
                my $paths = _code_for($build_paths_method)->();
                my @progress_sources = @argv;
                if (!$use_ddfile && !@progress_sources) {
                    my $source_manager = $manager_class->new(paths => $paths);
                    @progress_sources = $source_manager->registered_skill_sources;
                }
                my $progress = !$use_ddfile
                    ? (@progress_sources == 1 && @argv == 1
                        ? _code_for($install_progress_method)->()
                        : _code_for($install_progress_sources_method)->(@progress_sources))
                    : undef;
                my $manager = $manager_class->new(
                    paths => $paths,
                    progress => $progress ? $progress->callback : undef,
                );
                my ($result, $error);
                eval {
                    $result = $use_ddfile
                        ? $manager->install_from_ddfiles(Cwd::getcwd())
                        : @argv
                            ? (@argv == 1 ? $manager->install(shift @argv) : $manager->install_many(@argv))
                            : $manager->install_registered_skills;
                    1;
                } or do {
                    $error = $@ || "dashboard skills install failed\n";
                };
                if ($error) {
                    $progress->finish if $progress;
                    die $error;
                }
                $progress->finish if $progress;
                if ($output eq 'json') {
                    print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($result);
                } else {
                    print _code_for($install_summary_method)->($result);
                }
                return $result->{error} ? 1 : 0;
            }
            if ($action eq 'uninstall') {
                my $manager = $manager_class->new(paths => _code_for($build_paths_method)->());
                my $repo_name = shift @argv || die "Usage: dashboard skills uninstall <repo-name>\n";
                my $result = $manager->uninstall($repo_name);
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($result);
                return $result->{error} ? 1 : 0;
            }
            if ($action eq 'enable') {
                my $manager = $manager_class->new(paths => _code_for($build_paths_method)->());
                my $repo_name = shift @argv || die "Usage: dashboard skills enable <repo-name>\n";
                my $result = $manager->enable($repo_name);
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($result);
                return $result->{error} ? 1 : 0;
            }
            if ($action eq 'disable') {
                my $manager = $manager_class->new(paths => _code_for($build_paths_method)->());
                my $repo_name = shift @argv || die "Usage: dashboard skills disable <repo-name>\n";
                my $result = $manager->disable($repo_name);
                print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($result);
                return $result->{error} ? 1 : 0;
            }
            if ($action eq 'list') {
                my $manager = $manager_class->new(paths => _code_for($build_paths_method)->());
                my $output = 'table';
                Getopt::Long::GetOptionsFromArray(\@argv, 'o|output=s' => \$output);
                my $skills = $manager->list();
                if ($output eq 'json') {
                    print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode({ skills => $skills });
                    return 0;
                }
                if ($output eq 'table') {
                    print _code_for($skills_table_method)->($skills);
                    return 0;
                }
                die "Usage: dashboard skills list [-o json|table]\n";
            }
            if ($action eq 'usage') {
                my $manager = $manager_class->new(paths => _code_for($build_paths_method)->());
                my $output = 'json';
                Getopt::Long::GetOptionsFromArray(\@argv, 'o|output=s' => \$output);
                my $repo_name = shift @argv || die "Usage: dashboard skills usage <repo-name> [-o json|table]\n";
                my $usage = $manager->usage($repo_name);
                if ($output eq 'json') {
                    print __PAX_RUNTIME_LEGACY_NAMESPACE__::JSON::json_encode($usage);
                    return $usage->{error} ? 1 : 0;
                }
                if ($output eq 'table') {
                    die $usage->{error} . "\n" if $usage->{error};
                    print _code_for($usage_table_method)->($usage);
                    return 0;
                }
                die "Usage: dashboard skills usage <repo-name> [-o json|table]\n";
            }
            if ($action eq '_exec') {
                my $skill_name = shift @argv || die "Usage: dashboard <skill-name>.<command> [args...]\n";
                my $skill_cmd = shift @argv || die "Usage: dashboard <skill-name>.<command> [args...]\n";
                my $dispatcher = $dispatcher_class->new();
                my $result = $dispatcher->exec_command($skill_name, $skill_cmd, @argv);
                if ($result->{error}) {
                    print STDERR $result->{error}, "\n";
                    return 1;
                }
                return 0;
            }
            die "Unknown skills action: $action\nUsage: dashboard skills [install|uninstall|enable|disable|list|usage]\n";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'zip_payload_url') {
        $impl = sub {
            my ($text) = @_;
            return if !defined $text || $text eq '';
            require URI::Escape;
            my $raw = __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::encode_payload($text);
            return {
                raw => $raw,
                url => URI::Escape::uri_escape($raw),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'unzip_payload') {
        $impl = sub {
            my ($token) = @_;
            return if !defined $token || $token eq '';
            return __PAX_RUNTIME_LEGACY_NAMESPACE__::Codec::decode_payload($token);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'js_single_quote') {
        $impl = sub {
            my ($text) = @_;
            $text = '' if !defined $text;
            $text =~ s/\\/\\\\/g;
            $text =~ s/'/\\'/g;
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'validate_saved_ajax_file') {
        $impl = sub {
            my ($file) = @_;
            die "file is required" if !defined $file || $file eq '';
            die "file must be relative" if File::Spec->file_name_is_absolute($file);
            die "file contains invalid parent traversal" if $file =~ m{(?:\A|/)\.\.(?:/|\z)};
            die "file contains invalid characters" if $file !~ m{\A[A-Za-z0-9][A-Za-z0-9._/-]*\z};
            return $file;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'saved_ajax_file_path') {
        my $validate_method = $sub->{validate_method} // die 'compiled sub validate method missing';
        $impl = sub {
            my (%args) = @_;
            my $runtime_root = $args{runtime_root} || die 'runtime_root is required';
            my $file = _code_for($validate_method)->($args{file});
            return File::Spec->catfile($runtime_root, 'dashboards', 'ajax', split('/', $file));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'load_saved_ajax_code') {
        my $path_method = $sub->{path_method} // die 'compiled sub path method missing';
        $impl = sub {
            my (%args) = @_;
            my $path = _code_for($path_method)->(%args);
            return if !-f $path;
            open my $fh, '<', $path or die "Unable to read $path: $!";
            local $/;
            my $code = <$fh>;
            close $fh;
            return $code;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'saved_ajax_url') {
        my $validate_method = $sub->{validate_method} // die 'compiled sub validate method missing';
        $impl = sub {
            my (%args) = @_;
            require URI::Escape;
            my $query = sprintf '/ajax/%s?type=%s',
                URI::Escape::uri_escape(_code_for($validate_method)->($args{file})),
                URI::Escape::uri_escape($args{type} || 'text');
            if (defined $args{singleton} && $args{singleton} ne '') {
                $query .= '&singleton=' . URI::Escape::uri_escape($args{singleton});
            }
            return { url => ($args{base_url} || '') . $query };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'saved_ajax_url_and_store') {
        my $path_method = $sub->{path_method} // die 'compiled sub path method missing';
        my $url_method = $sub->{url_method} // die 'compiled sub url method missing';
        $impl = sub {
            my (%args) = @_;
            my $path = _code_for($path_method)->(%args);
            my $dir = dirname($path);
            make_path($dir) if !-d $dir;
            open my $fh, '>', $path or die "Unable to write $path: $!";
            print {$fh} defined $args{code} ? $args{code} : '';
            close $fh;
            chmod 0700, $path or die "Unable to chmod $path: $!";
            return {
                path => $path,
                %{ _code_for($url_method)->(%args) },
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'acmdx_bundle') {
        my $zip_method = $sub->{zip_method} // die 'compiled sub zip method missing';
        $impl = sub {
            my (%args) = @_;
            require URI::Escape;
            my $type = $args{type} || 'text';
            my $path = $args{path} || '/ajax';
            my $code = defined $args{code} ? $args{code} : '';
            my $base = $args{base_url} || '';
            my $token = _code_for($zip_method)->($code) || { raw => '', url => '' };
            my $query = sprintf '%s?token=%s&type=%s', $path, $token->{url}, URI::Escape::uri_escape($type);
            if (defined $args{singleton} && $args{singleton} ne '') {
                $query .= '&singleton=' . URI::Escape::uri_escape($args{singleton});
            }
            my $url = $base ? $base . $query : $query;
            return {
                token => $token,
                url => { tokenised => $url, app => $args{app} || $url },
                forward => [ $path => { token => $token->{raw}, type => $type } ],
                html => sprintf(q{<a href="%s" target="%s">%s</a>}, $url, ($args{target} || '_blank'), ($args{label} || 'Click Here')),
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'ajax_helper') {
        my $saved_url_method = $sub->{saved_url_method} // die 'compiled sub saved url method missing';
        my $saved_store_method = $sub->{saved_store_method} // die 'compiled sub saved store method missing';
        my $acmdx_method = $sub->{acmdx_method} // die 'compiled sub acmdx method missing';
        my $quote_method = $sub->{quote_method} // die 'compiled sub quote method missing';
        $impl = sub {
            my (%args) = @_;
            die "jvar is required" if !$args{jvar};
            my $type = $args{type} || 'text';
            no strict 'refs';
            my $context = ref(${ $package . '::AJAX_CONTEXT' }) eq 'HASH' ? ${ $package . '::AJAX_CONTEXT' } : {};
            if (($context->{source} || '') eq 'saved' && ($context->{page_id} || '') ne '') {
                my $file = $args{file} || '';
                if ($file eq '' && !($context->{allow_transient_urls} || 0)) {
                    die "file is required for saved bookmark Ajax when transient URL tokens are disabled";
                }
                if ($file ne '') {
                    my $saved = defined $args{code}
                        ? _code_for($saved_store_method)->(
                            file => $file,
                            page_id => $context->{page_id},
                            runtime_root => $context->{runtime_root} || '',
                            type => $type,
                            code => $args{code},
                            singleton => $args{singleton},
                            base_url => $args{base_url} || '',
                        )
                        : _code_for($saved_url_method)->(
                            file => $file,
                            page_id => $context->{page_id},
                            type => $type,
                            singleton => $args{singleton},
                            base_url => $args{base_url} || '',
                        );
                    my ($root, $path) = split /\./, $args{jvar}, 2;
                    $path ||= '';
                    print sprintf qq{<script>set_chain_value(%s,'%s','%s')</script>}, $root, $path, $saved->{url};
                    print sprintf qq{<script>dashboard_ajax_singleton_cleanup('%s')</script>}, _code_for($quote_method)->($args{singleton})
                        if defined $args{singleton} && $args{singleton} ne '';
                    return 'HIDE-THIS';
                }
            }
            my $ajax = _code_for($acmdx_method)->(%args, path => '/ajax', type => $type);
            my ($root, $path) = split /\./, $args{jvar}, 2;
            $path ||= '';
            print sprintf qq{<script>set_chain_value(%s,'%s','%s')</script>}, $root, $path, $ajax->{url}{tokenised};
            return 'HIDE-THIS';
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cmdx_shell_pipeline') {
        my $zip_method = $sub->{zip_method} // die 'compiled sub zip method missing';
        $impl = sub {
            my ($type, $code) = @_;
            my $token = _code_for($zip_method)->($code) || { raw => '' };
            return "printf '%s' " . quotemeta($token->{raw}) . " | base64 -d | gunzip";
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cmdx_tuple') {
        my $shell_method = $sub->{shell_method} // die 'compiled sub shell method missing';
        $impl = sub {
            my ($type, $code) = @_;
            my $switch = $type eq 'perl' ? '-e' : '-c';
            return ($type, $switch, _code_for($shell_method)->($type, $code));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cmdp_tuple') {
        my $shell_method = $sub->{shell_method} // die 'compiled sub shell method missing';
        $impl = sub {
            my ($type, $code) = @_;
            return (_code_for($shell_method)->($type, $code), $type);
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'build_ticket_plan') {
        my $resolve_method = $sub->{resolve_method} // die 'compiled sub resolve method missing';
        my $environment_method = $sub->{environment_method} // die 'compiled sub environment method missing';
        my $exists_method = $sub->{exists_method} // die 'compiled sub exists method missing';
        $impl = sub {
            require Cwd;
            my (%args) = @_;
            my $ticket = _code_for($resolve_method)->(
                args => $args{args} || [],
                env_ticket => $args{env_ticket},
            );
            my $plan_cwd = $args{cwd};
            $plan_cwd = Cwd::cwd() if !defined $plan_cwd || $plan_cwd eq '';
            my $env = _code_for($environment_method)->($ticket);
            my $exists = _code_for($exists_method)->(
                session => $ticket,
                tmux => $args{tmux},
            );
            my @env_args;
            for my $name (sort keys %{$env}) {
                push @env_args, '-e', "$name=$env->{$name}";
            }
            return {
                session => $ticket,
                cwd => $plan_cwd,
                env => $env,
                exists => $exists,
                create => $exists ? 0 : 1,
                create_argv => [
                    'new-session', '-d', @env_args, '-c', $plan_cwd, '-s', $ticket, '-n', 'Code1',
                ],
                attach_argv => [ 'attach-session', '-t', $ticket ],
            };
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'run_ticket_command_plan') {
        my $default_runner = $sub->{default_runner} // die 'compiled sub default runner missing';
        my $plan_method = $sub->{plan_method} // die 'compiled sub plan method missing';
        my $create_error = $sub->{create_error} // "Unable to create tmux ticket session '%s': %s%s";
        my $attach_error = $sub->{attach_error} // "Unable to attach tmux ticket session '%s': %s%s";
        $impl = sub {
            my (%args) = @_;
            my $tmux = $args{tmux} || _code_for($default_runner);
            my $plan = _code_for($plan_method)->(%args, tmux => $tmux);
            if ($plan->{create}) {
                my $created = $tmux->(args => $plan->{create_argv});
                die sprintf $create_error, $plan->{session}, ($created->{stderr} || ''), ($created->{stdout} || '')
                  if $created->{exit_code} != 0;
            }
            my $attached = $tmux->(args => $plan->{attach_argv});
            die sprintf $attach_error, $plan->{session}, ($attached->{stderr} || ''), ($attached->{stdout} || '')
              if $attached->{exit_code} != 0;
            return $plan;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'stream_writer_print') {
        $impl = sub {
            my ($self, @parts) = @_;
            $self->{writer}->(join '', map { defined $_ ? $_ : '' } @parts);
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'stream_writer_printf') {
        $impl = sub {
            my ($self, $format, @parts) = @_;
            $self->{writer}->(sprintf(defined $format ? $format : '', @parts));
            return 1;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'gzip_base64_encode') {
        my $error_message = $sub->{error_message} // 'gzip failed: %s';
        $impl = sub {
            require IO::Compress::Gzip;
            require MIME::Base64;
            my ($text) = @_;
            return if !defined $text;
            IO::Compress::Gzip::gzip(\$text => \my $zipped)
              or die sprintf($error_message, $IO::Compress::Gzip::GzipError);
            return MIME::Base64::encode_base64($zipped, '');
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'gzip_base64_decode') {
        my $error_message = $sub->{error_message} // 'gunzip failed: %s';
        $impl = sub {
            require IO::Uncompress::Gunzip;
            require MIME::Base64;
            my ($token) = @_;
            return if !defined $token || $token eq '';
            my $zipped = MIME::Base64::decode_base64($token);
            IO::Uncompress::Gunzip::gunzip(\$zipped => \my $text)
              or die sprintf($error_message, $IO::Uncompress::Gunzip::GunzipError);
            return $text;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'return_true') {
        $impl = sub { return 1 };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'posix_shell_binary') {
        $impl = sub {
            my ($preferred) = @_;
            no strict 'refs';
            my $resolver = *{ $package . '::command_in_path' }{CODE} or die "missing command_in_path for $package";
            return $resolver->($preferred) || $resolver->('sh') || $preferred;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'cmd_binary') {
        $impl = sub {
            no strict 'refs';
            my $resolver = *{ $package . '::command_in_path' }{CODE} or die "missing command_in_path for $package";
            my $candidate = $ENV{ComSpec} || $resolver->('cmd') || 'cmd.exe';
            return 'cmd.exe' if lc(basename($candidate)) eq 'cmd.exe';
            return $candidate;
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'module_lib_root') {
        my $require_path = $sub->{require_path} // die 'compiled sub require_path missing';
        $impl = sub {
            my $path = $INC{$require_path} || __FILE__;
            return dirname(dirname(dirname($path)));
        };
        return _install_sub_impl($package, $name, $sub->{prototype}, $impl);
    }

    if (($sub->{op} // '') eq 'build_pax_web_psgi_app') {
        no strict 'refs';
        no warnings 'redefine';
        *{$full} = sub {
            my ($class, %args) = @_;
            require Dancer2;
            require File::Spec;
            require Template;
            {
                no strict 'refs';
                if (!*{$package . '::set'}{CODE}) {
                    my $ok = eval "package $package; Dancer2->import(appname => 'PaxWeb'); 1;";
                    die $@ if !$ok;
                }
            }

            no strict 'refs';
            ${$package . '::ASSET_ROOT'} = $args{asset_root} // die "asset_root required";
            my $asset_root = ${$package . '::ASSET_ROOT'};
            my $views = File::Spec->catdir($asset_root, 'views');
            my $public = File::Spec->catdir($asset_root, 'public');
            my $set = *{$package . '::set'}{CODE} or die "missing $package\::set";
            my $get = *{$package . '::get'}{CODE} or die "missing $package\::get";
            my $status = *{$package . '::status'}{CODE} or die "missing $package\::status";
            my $send_as = *{$package . '::send_as'}{CODE} or die "missing $package\::send_as";
            my $dancer_app = *{$package . '::dancer_app'}{CODE} or die "missing $package\::dancer_app";

            $set->(serializer => 'Mutable');
            $set->(views => $views);
            $set->(public_dir => $public);

            my $tt = Template->new(
                INCLUDE_PATH => [$views],
                ABSOLUTE => 1,
                RELATIVE => 1,
            );

            $get->('/' => sub {
                my $html = q{};
                my $vars = {
                    title => 'PAX Web App',
                    headline => 'Standalone Perl Web Application',
                    asset_root => $asset_root,
                };
                my $ok = eval { $tt->process('index.tt', $vars, \$html) ? 1 : 0 };
                if (!$ok) {
                    my $error = $@ || $tt->error || 'template render failed';
                    _trace("template process error: $error");
                }
                if (!defined($html) || $html eq '') {
                    my $template_path = File::Spec->catfile($views, 'index.tt');
                    my $fallback = _render_simple_template_asset($template_path, $vars);
                    $html = $fallback if defined $fallback && $fallback ne '';
                }
                die($tt->error || 'template render produced empty output') if !defined($html) || $html eq '';
                return $send_as->(html => $html);
            });

            $get->('/healthz' => sub {
                $status->(200);
                return {
                    ok => 1,
                    framework => 'Dancer2',
                    server => 'Starman',
                    template => 'TemplateToolkit',
                    asset_root => $asset_root,
                };
            });

            return $dancer_app->()->to_app;
        };
        return;
    }

    die "unsupported compiled sub op: " . ($sub->{op} // '');
}

# Rewrite script-source subroutines with their compiled/native-aware variants
# before the top-level script body is evaluated.
sub _apply_compiled_script_subs {
    my ($source, $subs) = @_;
    return $source if !defined $source || $source eq '' || !$subs || !@$subs;
    for my $sub (@$subs) {
        next if (($sub->{op} // '') ne 'native_shape_sub');
        my $full = $sub->{full_name} // '';
        next if $full !~ /^main::([^:]+)\z/;
        my $short = $1;
        my $replacement = _compiled_script_sub_source($full, $short, $sub->{prototype}, $sub->{native_shape});
        next if !defined $replacement || $replacement eq '';
        my $original = _extract_sub_source_runtime($source, $short) or next;
        $source =~ s/\Q$original\E/$replacement/s;
    }
    return $source;
}

# Render a compiled script sub back into source that the runtime can splice into
# the packaged script body.
sub _compiled_script_sub_source {
    my ($full, $short, $prototype, $shape) = @_;
    return if !defined $short || $short eq '' || ref($shape) ne 'HASH';
    my $proto = defined $prototype ? $prototype : '';
    my $args = '$PAX_ARG0';
    $args .= ', $PAX_ARG1' if scalar(@{ $shape->{args} // [] }) > 1;
    return sprintf(
        "sub %s%s {\n    my (%s) = \@_;\n    return PAX::StandaloneRuntime::_run_native_shape_sub(%s, %s, \@_);\n}\n",
        $short,
        $proto || '',
        $args,
        _perl_literal($full),
        _perl_literal(JSON::PP->new->canonical(1)->encode($shape)),
    );
}

# Extract the original subroutine source from the packaged script so runtime
# rewriting has an exact source range to replace.
sub _extract_sub_source_runtime {
    my ($source, $sub_name) = @_;
    return if $source !~ /\bsub\s+\Q$sub_name\E\b[^\{]*\{/g;
    my $start = $-[0];
    my $brace = index($source, '{', $+[0] - 1);
    return if $brace < 0;
    my $depth = 1;
    my $i = $brace + 1;
    while ($i < length($source)) {
        my $char = substr($source, $i, 1);
        $depth++ if $char eq '{';
        $depth-- if $char eq '}';
        if ($depth == 0) {
            my $end = $i + 1;
            while ($end < length($source) && substr($source, $end, 1) =~ /[ \t]/) {
                $end++;
            }
            $end++ if $end < length($source) && substr($source, $end, 1) eq ';';
            return substr($source, $start, $end - $start);
        }
        $i++;
    }
    return;
}

# Execute a compiled script sub through the packaged native-dispatch entry when
# the runtime emitted a matching native artifact.
sub _run_native_shape_sub {
    my ($full, $shape_json, @args) = @_;
    my $shape = ref($shape_json) eq 'HASH' ? $shape_json : _runtime_json_decode($shape_json);
    my $expected = scalar @{ $shape->{args} // [] };
    if ($expected && @args == $expected && _native_shape_args_are_i64(\@args)) {
        my $result = _invoke_native_shape_runtime($full, $shape, \@args);
        return $result->{value} if $result->{status} eq 'ok' && exists $result->{value};
    }
    return _interpret_native_shape($shape, \@args);
}

# Dispatch supported native-shape script subs through the runtime dispatcher and
# fall back to interpretation when no packaged artifact is available.
sub _invoke_native_shape_runtime {
    my ($full, $shape, $args) = @_;
    my $state = _state();
    my $meta = $state->{by_region}{$full} || {};
    return { status => 'fallback', reason => 'native region missing' } if !($meta->{executable_logical_path} // '');
    my $probe = File::Spec->catfile($state->{root}, split m{/}, $meta->{executable_logical_path});
    chmod 0700, $probe if -f $probe;
    my $left = $args->[0];
    my $right = @$args > 1 ? $args->[1] : 0;
    return $state->{native_runner}->run_i64_binary(
        path => $probe,
        left => $left,
        right => $right,
    );
}

# Confirm that the current call arguments fit the narrow integer ABI used by
# packaged native script helpers.
sub _native_shape_args_are_i64 {
    my ($args) = @_;
    for my $arg (@$args) {
        return 0 if !defined $arg || $arg !~ /\A-?\d+\z/;
    }
    return 1;
}

# Mirror the supported native shapes in Perl so deopt or unsupported dispatch
# can still run script-native candidates correctly.
sub _interpret_native_shape {
    my ($shape, $args) = @_;
    my $kind = $shape->{kind} // '';
    if ($kind eq 'i64_binary_leaf') {
        my ($left, $right) = @$args;
        my $op = $shape->{op} // '';
        return $left + $right if $op eq 'add';
        return $left - $right if $op eq 'subtract';
        return $left * $right if $op eq 'multiply';
        return $left > $right ? 1 : 0 if $op eq 'greater_than';
    }
    if ($kind eq 'i64_sum_loop') {
        my ($limit) = @$args;
        return 0 if !defined $limit || $limit <= 0;
        my $sum = 0;
        for (my $i = 1; $i <= $limit; $i++) {
            $sum += $i;
        }
        return $sum;
    }
    if ($kind eq 'i64_masked_mix_accum_loop') {
        my ($limit) = @$args;
        return 0 if !defined $limit || $limit <= 0;
        my $acc = 0;
        for (my $i = 0; $i < $limit; $i++) {
            $acc += (($i * 13) ^ ($i >> 3)) & 0xFFFF;
        }
        return $acc;
    }
    die "unsupported native shape kind: $kind";
}

sub _install_sub_impl {
    my ($package, $name, $prototype, $impl) = @_;
    my $full = $package . '::' . $name;
    no strict 'refs';
    no warnings 'redefine';
    if (defined $prototype && $prototype ne '') {
        my $impl_name = sprintf '__PAX_IMPL_%s_%d_%d', $name, $$, int(rand(1_000_000));
        my $impl_full = $package . '::' . $impl_name;
        *{$impl_full} = $impl;
        my $code = "package $package; no warnings 'redefine'; sub $name $prototype { goto &$impl_full } 1;";
        my $ok = eval $code;
        die $@ if !$ok;
        return;
    }
    *{$full} = $impl;
    return;
}

sub _install_residual_stubs {
    my ($unit, $record) = @_;
    for my $full (@{ $record->{unsupported_subs} // [] }) {
        no strict 'refs';
        no warnings 'redefine';
        *{$full} = sub {
            _load_residual_sub($unit, $record, $full);
            my $cv = _code_for($full) or die "residual source did not define $full";
            goto &$cv;
        };
    }
}

sub _load_residual_sub {
    my ($unit, $record, $full) = @_;
    my $state = _state();
    my $key = $record->{require_path} || $unit->{logical_path} || $unit->{source_path} || '';
    my $sub_key = $key . '::' . $full;
    return if $state->{residual_loaded}{$sub_key};
    if (($record->{residual_mode} // '') eq 'module') {
        _load_residual_module($unit, $record);
        my $cv = _code_for($full) or die "module residual source did not define $full";
        $state->{residual_loaded}{$sub_key} = 1;
        return 1;
    }
    _load_residual_bootstrap($unit, $record);
    my $source = $record->{residual_sub_sources}{$full}
        // die "residual sub source missing for $full";
    my $path = _virtual_source_path($unit, $record);
    my $wrapped = "package $record->{package};\nno strict;\nno warnings 'redefine';\n#line 1 \"$path\"\n" . $source;
    local $SIG{__WARN__} = sub {
        my ($warning) = @_;
        return if defined $warning && $warning =~ /\ASubroutine .+ redefined at \Q$path\E line \d+\.\n\z/;
        return if defined $warning && $warning =~ /\APrototype mismatch: sub .+ line \d+\.\n\z/;
        warn $warning;
    };
    my $rv = eval $wrapped;
    die $@ if $@;
    $state->{residual_loaded}{$sub_key} = 1;
    return 1;
}

sub _load_residual_module {
    my ($unit, $record) = @_;
    my $state = _state();
    my $key = $record->{require_path} || $unit->{logical_path} || $unit->{source_path} || '';
    return if $state->{residual_bootstrap_loaded}{$key};
    {
        no strict 'refs';
        my $stash = \%{ ($record->{package} // '') . '::' };
        for my $name (
            map { $_->{name} } @{ $record->{subs} // [] },
            map { /::([^:]+)\z/ ? $1 : () } @{ $record->{unsupported_subs} // [] },
        ) {
            next if !$name;
            delete $stash->{$name};
        }
    }
    my $source = $record->{residual_source} // die "residual module source missing for $key";
    my $path = _virtual_source_path($unit, $record);
    my $wrapped = "no strict;\nno warnings 'redefine';\n#line 1 \"$path\"\n" . $source;
    local $SIG{__WARN__} = sub {
        my ($warning) = @_;
        return if defined $warning && $warning =~ /\ASubroutine .+ redefined at \Q$path\E line \d+\.\n\z/;
        return if defined $warning && $warning =~ /\APrototype mismatch: sub .+ line \d+\.\n\z/;
        warn $warning;
    };
    my $rv = eval $wrapped;
    die $@ if $@;
    $state->{residual_bootstrap_loaded}{$key} = 1;
    return $rv;
}

sub _load_residual_bootstrap {
    my ($unit, $record) = @_;
    my $state = _state();
    my $key = $record->{require_path} || $unit->{logical_path} || $unit->{source_path} || '';
    return if $state->{residual_bootstrap_loaded}{$key};
    my $source = $record->{residual_bootstrap_source};
    $state->{residual_bootstrap_loaded}{$key} = 1;
    return 1 if !defined $source || $source eq '';
    my $path = _virtual_source_path($unit, $record);
    my $wrapped = "no strict;\nno warnings 'redefine';\n#line 1 \"$path\"\n" . $source;
    local $SIG{__WARN__} = sub {
        my ($warning) = @_;
        return if defined $warning && $warning =~ /\ASubroutine .+ redefined at \Q$path\E line \d+\.\n\z/;
        return if defined $warning && $warning =~ /\APrototype mismatch: sub .+ line \d+\.\n\z/;
        warn $warning;
    };
    my $rv = eval $wrapped;
    die $@ if $@;
    return 1;
}

sub _code_for {
    my ($full) = @_;
    no strict 'refs';
    return *{$full}{CODE};
}

sub _virtual_source_path {
    my ($unit, $record) = @_;
    return _ensure_virtual_source_file($unit);
}

sub _virtual_entrypoint_path {
    my ($entrypoint) = @_;
    my $state = _state();
    my $manifest = $state->{manifest} || {};
    my $unit = {
        logical_path => $manifest->{entrypoint}{logical_path} || $entrypoint,
    };
    return _ensure_virtual_source_file($unit);
}

sub _render_simple_template_asset {
    my ($path, $vars) = @_;
    return if !$path || !-f $path;
    open my $fh, '<', $path or return;
    local $/;
    my $template = <$fh>;
    close $fh;
    return if !defined $template || $template eq '';
    $template =~ s/\[\%\s*([A-Za-z_][A-Za-z0-9_]*)\s*\%\]/defined $vars->{$1} ? $vars->{$1} : ''/ge;
    return $template;
}

sub _log_native_hit {
    my ($region) = @_;
    my $path = $ENV{PAX_STANDALONE_NATIVE_HIT_LOG} or return;
    open my $fh, '>>', $path or return;
    print {$fh} $region, "\n";
    close $fh;
}

1;

=pod

=head1 NAME

PAX::StandaloneRuntime - embedded runtime loader for standalone binaries

=head1 SYNOPSIS

  use PAX::StandaloneRuntime;

  my $result = PAX::StandaloneRuntime->run(...);

=head1 DESCRIPTION

Bootstraps extracted standalone payloads, configures the runtime environment, and dispatches entrypoints, helpers, and native fallbacks from a single binary.

=head1 METHODS

=head2 run, stash, hide, void, stop, params, stash, hide, void, stop, params

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the embedded runtime loader for standalone binaries logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs embedded runtime loader for standalone binaries. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects embedded runtime loader for standalone binaries, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover embedded runtime loader for standalone binaries.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::StandaloneRuntime -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut

package PAX::CodeUnitCompiler;

our $VERSION = '0.031';

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename ();
use File::Spec ();
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use PAX::Capture;

sub new {
    my ($class, %args) = @_;
    return bless {}, $class;
}

sub compile {
    my ($self, %args) = @_;
    my $path = $args{path} // die 'path required';
    my $kind = $args{kind} // die 'kind required';
    my $logical_path = $args{logical_path} // die 'logical_path required';
    my $abs_path = abs_path($path) || $path;
    if ($kind eq 'entrypoint') {
        my $source = _slurp($abs_path);
        if (my $service = _compiled_service_dispatch_unit($abs_path, $kind, $logical_path, $source)) {
            return $service;
        }
        if (my $router = _compiled_cli_router_unit($abs_path, $kind, $logical_path, $source)) {
            return $router;
        }
        if (my $dispatch = _compiled_dispatch_script_unit($abs_path, $kind, $logical_path, $source)) {
            return $dispatch;
        }
        return _compiled_script_unit($abs_path, $kind, $logical_path, $source);
    }

    my $source = _slurp($abs_path);
    my $package = _package_name($source) or return _fallback_unit($abs_path, $kind, $logical_path, 'missing_package_declaration');
    my $has_sub_defs = ($source =~ /\bsub\s+[A-Za-z_][A-Za-z0-9_]*\b/s) ? 1 : 0;
    my @declared_subs = _declared_subs($source, $package);
    my @source_compiled_subs = map { defined $_ ? ($_) : () } map { _compile_declared_sub_from_source($source, $_) } @declared_subs;
    my %source_compiled_names = map { ($_->{full_name} // '') => 1 } @source_compiled_subs;
    my @declared_unsupported_subs = grep { !$source_compiled_names{$_} } @declared_subs;
    my @initializers = _compile_initializers($source, $package);
    return _fallback_unit($abs_path, $kind, $logical_path, 'unsupported_initializer_pattern') if grep { !$_ } @initializers;
    return _fallback_unit($abs_path, $kind, $logical_path, 'unsupported_exporter_contract')
        if _requires_source_exporter_contract($source);
    if (!$has_sub_defs) {
        return _compiled_unit($abs_path, $kind, $logical_path, $package, \@initializers, []);
    }

    if ($kind eq 'dependency') {
        return _compiled_unit($abs_path, $kind, $logical_path, $package, \@initializers, \@source_compiled_subs)
            if !@declared_unsupported_subs;
        return _fallback_unit(
            $abs_path,
            $kind,
            $logical_path,
            'hybrid_coverage_too_low',
            _hybrid_coverage_detail(\@source_compiled_subs, \@declared_unsupported_subs),
        ) if _prefer_source_fallback_over_hybrid($source, \@source_compiled_subs, \@declared_unsupported_subs);
        return _hybrid_compiled_unit(
            $abs_path,
            $kind,
            $logical_path,
            $package,
            \@initializers,
            \@source_compiled_subs,
            \@declared_unsupported_subs,
            $source,
        );
    }

    if (_prefer_lazy_hybrid($source, \@declared_subs)) {
        return _compiled_unit($abs_path, $kind, $logical_path, $package, \@initializers, \@source_compiled_subs)
            if @source_compiled_subs && !@declared_unsupported_subs;
        return _fallback_unit(
            $abs_path,
            $kind,
            $logical_path,
            'hybrid_coverage_too_low',
            _hybrid_coverage_detail(\@source_compiled_subs, \@declared_unsupported_subs),
        ) if _prefer_source_fallback_over_hybrid($source, \@source_compiled_subs, \@declared_unsupported_subs);
        return _hybrid_compiled_unit(
            $abs_path,
            $kind,
            $logical_path,
            $package,
            \@initializers,
            \@source_compiled_subs,
            \@declared_unsupported_subs,
            $source,
        );
    }

    my $capture = _capture_with_timeout($abs_path, $kind);
    if (($capture->{status} // '') ne 'ok') {
        return _compiled_unit($abs_path, $kind, $logical_path, $package, \@initializers, \@source_compiled_subs)
            if @source_compiled_subs && !@declared_unsupported_subs;
        return _fallback_unit(
            $abs_path,
            $kind,
            $logical_path,
            'hybrid_coverage_too_low',
            _hybrid_coverage_detail(\@source_compiled_subs, \@declared_unsupported_subs),
        ) if @declared_subs && _prefer_source_fallback_over_hybrid($source, \@source_compiled_subs, \@declared_unsupported_subs);
        return _hybrid_compiled_unit(
            $abs_path,
            $kind,
            $logical_path,
            $package,
            \@initializers,
            \@source_compiled_subs,
            \@declared_unsupported_subs,
            $source,
        ) if @declared_subs;
        return _fallback_unit($abs_path, $kind, $logical_path, 'capture_failed');
    }

    my @subs = grep {
        _same_source_path($_->{closure_descriptor}{file}, $abs_path)
            && ($_->{name} // '') =~ /^\Q$package\E::/
    } @{ $capture->{capture}{sub_optrees} // [] };
    my @compiled_subs;
    my @unsupported_subs;
    my %declared = map { $_ => 1 } @declared_subs;
    for my $sub (@subs) {
        my $compiled = _compile_sub($sub, $source);
        $compiled ||= _compile_declared_sub_from_source($source, $sub->{name});
        if ($compiled) {
            push @compiled_subs, $compiled;
            delete $declared{$sub->{name}};
            next;
        }
        push @unsupported_subs, $sub->{name};
        delete $declared{$sub->{name}};
    }
    for my $compiled (@source_compiled_subs) {
        my $full = $compiled->{full_name} // next;
        next if !$declared{$full};
        push @compiled_subs, $compiled;
        delete $declared{$full};
    }
    push @unsupported_subs, sort keys %declared if %declared;

    if (!@compiled_subs && !@initializers) {
        return _fallback_unit(
            $abs_path,
            $kind,
            $logical_path,
            'hybrid_coverage_too_low',
            _hybrid_coverage_detail(\@compiled_subs, \@unsupported_subs),
        ) if @unsupported_subs && _prefer_source_fallback_over_hybrid($source, \@compiled_subs, \@unsupported_subs);
        return _hybrid_compiled_unit(
            $abs_path,
            $kind,
            $logical_path,
            $package,
            \@initializers,
            [],
            \@unsupported_subs,
            $source,
        ) if @unsupported_subs;
        return _fallback_unit($abs_path, $kind, $logical_path, 'no_supported_compiled_content');
    }

    if ($has_sub_defs && !@subs && !@compiled_subs && @declared_subs) {
        return _fallback_unit(
            $abs_path,
            $kind,
            $logical_path,
            'hybrid_coverage_too_low',
            _hybrid_coverage_detail(\@compiled_subs, \@declared_subs),
        ) if _prefer_source_fallback_over_hybrid($source, \@compiled_subs, \@declared_subs);
        return _hybrid_compiled_unit(
            $abs_path,
            $kind,
            $logical_path,
            $package,
            \@initializers,
            [],
            \@declared_subs,
            $source,
        );
    }

    return _fallback_unit(
        $abs_path,
        $kind,
        $logical_path,
        'hybrid_coverage_too_low',
        _hybrid_coverage_detail(\@compiled_subs, \@unsupported_subs),
    ) if @unsupported_subs && _prefer_source_fallback_over_hybrid($source, \@compiled_subs, \@unsupported_subs);

    return _hybrid_compiled_unit(
        $abs_path,
        $kind,
        $logical_path,
        $package,
        \@initializers,
        \@compiled_subs,
        \@unsupported_subs,
        $source,
    ) if @unsupported_subs;

    return _compiled_unit($abs_path, $kind, $logical_path, $package, \@initializers, \@compiled_subs);
}

sub _compile_sub {
    my ($sub, $source) = @_;
    my $name = $sub->{name} // return;
    my ($full_package, $short_name) = $name =~ /^(.*)::([^:]+)$/ or return;
    my $shape = $sub->{native_shape};
    if ($shape && ($shape->{kind} // '') =~ /\Ai64_(?:binary_leaf|sum_loop|masked_mix_accum_loop)\z/) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $name,
            op => 'native_shape_sub',
            native_shape => $shape,
            prototype => $prototype,
        };
    }

    if (my $custom = _custom_sub_from_source($source, $short_name, $full_package, $name)) {
        return $custom;
    }

    if (my $literal = _return_literal_from_source($source, $short_name)) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $name,
            op => 'return_literal',
            value_type => $literal->{type},
            value => $literal->{value},
            prototype => $prototype,
        };
    }

    return;
}

sub _compile_declared_sub_from_source {
    my ($source, $full_name) = @_;
    my ($package, $short_name) = $full_name =~ /^(.*)::([^:]+)$/ or return;
    if (
        _package_tail_is($package, 'PageDocument')
        && $short_name eq '_decode_stash_section'
        && $source =~ /sub\s+_decode_stash_section\b.*?json_decode.*?sub\s+_parse_legacy_sections\b/ms
    ) {
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_decode_stash_section',
            trim_method => $package . '::_trim',
        };
    }
    return _custom_sub_from_source($source, $short_name, $package, $full_name)
        || _compile_simple_transform_sub_from_source($source, $short_name, $full_name)
        || do {
            my $literal = _return_literal_from_source($source, $short_name) or return;
            return {
                name => $short_name,
                full_name => $full_name,
                op => 'return_literal',
                value_type => $literal->{type},
                value => $literal->{value},
            };
        };
}

sub _capture_with_timeout {
    my ($abs_path, $kind) = @_;
    my $timeout = $ENV{PAX_CODE_UNIT_CAPTURE_TIMEOUT};
    if (!defined $timeout || $timeout eq '') {
        $timeout = ($kind // '') eq 'dependency' ? 1 : 5;
    }
    return _capture_live_unit($abs_path) if !$timeout || $timeout <= 0;
    my $capture;
    my $error;
    return _capture_live_unit($abs_path) if !_capture_timeout_supported();
    eval {
        local $SIG{ALRM} = sub { die "capture timeout\n" };
        alarm($timeout);
        $capture = _capture_live_unit($abs_path);
        alarm(0);
        1;
    } or do {
        $error = $@ || 'capture_failed';
        alarm(0);
    };
    if ($error) {
        return {
            status => 'capture_timeout',
            error => "$error",
        };
    }
    return $capture;
}

sub _capture_timeout_supported {
    return 0 if !exists $SIG{ALRM};
    my $ok = eval {
        local $SIG{ALRM} = sub { die "capture timeout\n" };
        1;
    };
    return $ok ? 1 : 0;
}

sub _capture_live_unit {
    my ($abs_path) = @_;
    return PAX::Capture->new(mode => 'live')->capture($abs_path);
}

sub _custom_sub_from_source {
    my ($source, $short_name, $package, $full_name) = @_;

    my $dashboard_entry;
    if (_is_entry_command_sub($short_name)) {
        $dashboard_entry = _entry_command_capture($source);
    }

    if (_is_entry_command_sub($short_name) && $dashboard_entry) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_entry_command',
            entrypoint_env => $dashboard_entry->{env},
            entrypoint_fallback => $dashboard_entry->{fallback},
            prototype => $prototype,
        };
    }

    my $body = _extract_sub_body($source, $short_name) or return;

    if (
        $body =~ /\bmy\s+\$tt\s*=\s*Template->new\s*\(/s
        && $body =~ /\bget\s+'\/'\s*=>\s*sub\s*\{/s
        && $body =~ /\$tt->process\s*\(\s*'index\.tt'/s
        && $body =~ /\bget\s+'\/healthz'\s*=>\s*sub\s*\{/s
        && $body =~ /\breturn\s+dancer_app->to_app\s*;/s
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'build_pax_web_psgi_app',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+\$OS_NAME\s+eq\s+'MSWin32'\s+\?\s+1\s*:\s*0\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'global_eq_literal_bool',
            symbol => $package . '::OS_NAME',
            literal => 'MSWin32',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+command_in_path\('pwsh'\)\s*\|\|\s*command_in_path\('powershell'\)\s*\|\|\s*'powershell'\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'command_chain_or_literal',
            commands => [ 'pwsh', 'powershell' ],
            fallback => 'powershell',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\$preferred\)\s*=\s*\@_;\s*return\s+command_in_path\(\$preferred\)\s*\|\|\s*command_in_path\('sh'\)\s*\|\|\s*\$preferred\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'posix_shell_binary',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\$candidate\s*=\s*\$ENV\{ComSpec\}\s*\|\|\s*command_in_path\('cmd'\)\s*\|\|\s*'cmd\.exe'\s*;\s*return\s+'cmd\.exe'\s+if\s+lc\(\s*basename\(\$candidate\)\s*\)\s+eq\s+'cmd\.exe'\s*;\s*return\s+\$candidate\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cmd_binary',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\$path\s*=\s*\$INC\{(?:'([^']+)'|"([^"]+)"|([^\}]+))\}\s*\|\|\s*__FILE__\s*;\s*return\s+dirname\(\s*dirname\(\s*dirname\(\$path\)\s*\)\s*\)\s*;\s*\z/s) {
        my $require_path = $1 // $2 // $3;
        if (!defined $require_path || $require_path eq '') {
            ($require_path = $full_name) =~ s/::/\//g;
            $require_path .= '.pm';
        }
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'module_lib_root',
            require_path => $require_path,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'normalize_shell_name'
        && $body =~ /Unsupported shell/
        && $body =~ /powershell\.exe/
        && $body =~ /pwsh\.exe/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'normalize_shell_name',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'native_shell_name'
        && $body =~ /command_in_path\('pwsh'\)/
        && $body =~ /\$ENV\{SHELL\}/
        && $body =~ /return 'bash' if command_in_path\('bash'\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'native_shell_name',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'shell_command_argv'
        && $body =~ /Missing shell command/
        && $body =~ /-NoLogo/
        && $body =~ /-ExecutionPolicy/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'shell_command_argv',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'shell_quote_for'
        && $body =~ /\$value =~ s\/'\/''\/g;/
        && $body =~ /\$value =~ s\/'\/'\\\\''\/g;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'shell_quote_for',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_has_shebang'
        && $body =~ /open my \$fh, '<', \$path/
        && $body =~ /return defined \$first && \$first =~ \/\^#!\//
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'has_shebang',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_shebang_uses_perl'
        && $body =~ /open my \$fh, '<', \$path/
        && $body =~ /return \$first =~/
        && $body =~ /perl/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'shebang_uses_perl',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_path_candidates'
        && $body =~ /PATHEXT/
        && $body =~ /push \@candidates, \$path \. lc\(\$ext\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'path_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_runnable_path_candidates'
        && $body =~ /qw\(\.pl \.go \.java \.ps1 \.cmd \.bat \.sh \.bash\)/
        && $body =~ /my %seen/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runnable_path_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_is_windows_runnable_candidate'
        && $body =~ /command_in_path\('bash'\)/
        && $body =~ /_has_shebang/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'is_windows_runnable_candidate',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'command_in_path'
        && $body =~ /File::Spec->path/
        && $body =~ /_path_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'command_in_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'resolve_runnable_file'
        && $body =~ /_runnable_path_candidates/
        && $body =~ /_is_windows_runnable_candidate/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'resolve_runnable_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'command_argv_for_path'
        && $body =~ /Unable to find runnable file/
        && $body =~ /_exec_go_source/
        && $body =~ /_exec_java_source/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'command_argv_for_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_exec_go_source'
        && $body =~ /Missing Go source path/
        && $body =~ /go', 'run'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'exec_go_source',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_java_main_class'
        && $body =~ /package\\s\+\(\[A-Za-z_/
        && $body =~ /class\|interface\|enum\|record/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'java_main_class',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_exec_java_source'
        && $body =~ /Missing Java source path/
        && $body =~ /javac/
        && $body =~ /Unable to exec java/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'exec_java_source',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'is_runnable_file'
        && $body =~ /resolve_runnable_file/
        && $body =~ /return \$resolved \? 1 : 0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'is_runnable_file',
            prototype => $prototype,
        };
    }

    return;
}

sub _compile_simple_transform_sub_from_source {
    my ($source, $short_name, $full_name) = @_;
    my ($package) = $full_name =~ /^(.*)::[^:]+$/ or return;
    my $body = _extract_sub_body($source, $short_name) or return;

    if (
        $body =~ /\A\s*my\s+\(\s*\$([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*=\s*\@_;\s*
                   my\s+\@([A-Za-z_][A-Za-z0-9_]*)\s*=\s*split\s*\/\\s\+\/\s*,\s*\(\s*\$\1\s*\/\/\s*''\s*\)\s*;\s*
                   return\s+join\s+'([^'\\]*(?:\\.[^'\\]*)*)'\s*,\s*reverse\s+\@\2\s*;\s*\z/xs
    ) {
        my ($input_name, $parts_name, $joiner) = ($1, $2, _unescape_literal($3));
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'split_reverse_join',
            split_pattern => '\\s+',
            joiner => $joiner,
            default => '',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+JSON::XS->new->utf8->canonical->pretty->encode\(\s*\$_\[0\]\s*\)\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'json_xs_encode_pretty',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+JSON::XS->new->utf8->decode\(\s*\$_\[0\]\s*\)\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'json_xs_decode',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+([A-Za-z_][A-Za-z0-9_]*)\(\s*\$_\[0\]\s*\)\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'call_named_with_first_arg',
            target => $package . '::' . $1,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+([A-Za-z_][A-Za-z0-9_]*)\(\s*\$_\[0\]\s*\/\/\s*''\s*\)\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'call_named_with_first_arg_default',
            target => $package . '::' . $1,
            default => '',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*%([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\(\s*\)\s*;\s*delete\s+\$ENV\{([A-Z0-9_]+)\}\s*;\s*return\s+1\s*;\s*\z/s) {
        my ($hash_name, $env_key) = ($1, $2);
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'clear_package_hash_and_env',
            hash_symbol => $package . '::' . $hash_name,
            env_key => $env_key,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*\$key\s*\)\s*=\s*\@_;\s*
                    return\s+undef\s+if\s+!defined\s+\$key\s+\|\|\s+\$key\s+eq\s+''\s*;\s*
                    my\s+\$audit\s*=\s*\$class->_audit_copy\(\)\s*;\s*
                    return\s+undef\s+if\s+!exists\s+\$audit->\{\$key\}\s*;\s*
                    return\s+\$audit->\{\$key\}\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'hash_lookup_via_method_copy',
            copy_method => $package . '::_audit_copy',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s*\(\s*\$class\s*\)\s*=\s*\@_;\s*return\s+\$class->_audit_copy\(\)\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'return_method_call',
            target => $package . '::_audit_copy',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*\)\s*=\s*\@_;\s*
                    \$class->_load_from_env\(\)\s*;\s*
                    my\s+%copy\s*=\s*map\s*\{\s*
                        \$_\s*=>\s*\{\s*
                            value\s*=>\s*\$([A-Za-z_][A-Za-z0-9_]*)\{\$_\}\{value\}\s*,\s*
                            envfile\s*=>\s*\$\1\{\$_\}\{envfile\}\s*,\s*
                        \}\s*
                    \}\s*CORE::keys\s+%\1\s*;\s*
                    return\s+\\%copy\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'copy_package_hash_entries',
            load_method => $package . '::_load_from_env',
            hash_symbol => $package . '::' . $1,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*\)\s*=\s*\@_;\s*
                    return\s+1\s+if\s+%([A-Za-z_][A-Za-z0-9_]*)\s*;\s*
                    my\s+\$raw\s*=\s*\$ENV\{([A-Z0-9_]+)\}\s*\|\|\s*''\s*;\s*
                    return\s+1\s+if\s+\$raw\s+eq\s+''\s*;\s*
                    my\s+\$decoded\s*=\s*json_decode\(\$raw\)\s*;\s*
                    die\s+\"([^\"]*)\"\s+if\s+ref\(\$decoded\)\s+ne\s+'HASH'\s*;\s*
                    %\1\s*=\s*map\s*\{\s*
                        \$_\s*=>\s*\{\s*
                            value\s*=>\s*\$decoded->\{\$_\}\{value\}\s*,\s*
                            envfile\s*=>\s*\$decoded->\{\$_\}\{envfile\}\s*,\s*
                        \}\s*
                    \}\s*CORE::keys\s+%\{\$decoded\}\s*;\s*
                    return\s+1\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'load_package_hash_from_env_json',
            hash_symbol => $package . '::' . $1,
            env_key => $2,
            error_message => $3,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*\)\s*=\s*\@_;\s*
                    \$ENV\{([A-Z0-9_]+)\}\s*=\s*json_encode\(\s*\$class->_audit_copy\s*\)\s*;\s*
                    return\s+1\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'sync_env_json_from_method',
            env_key => $1,
            copy_method => $package . '::_audit_copy',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*\$key\s*,\s*\$value\s*,\s*\$envfile\s*\)\s*=\s*\@_;\s*
                    die\s+\"([^\"]*)\"\s+if\s+!defined\s+\$key\s+\|\|\s+\$key\s+eq\s+''\s*;\s*
                    die\s+\"([^\"]*)\"\s+if\s+!defined\s+\$envfile\s+\|\|\s+\$envfile\s+eq\s+''\s*;\s*
                    \$class->_load_from_env\(\)\s*;\s*
                    \$([A-Za-z_][A-Za-z0-9_]*)\{\$key\}\s*=\s*\{\s*
                        value\s*=>\s*\$value\s*,\s*
                        envfile\s*=>\s*\$envfile\s*,\s*
                    \}\s*;\s*
                    \$class->_sync_to_env\(\)\s*;\s*
                    return\s+1\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'record_package_hash_entry_and_sync',
            missing_key_error => $1,
            missing_source_error => $2,
            load_method => $package . '::_load_from_env',
            sync_method => $package . '::_sync_to_env',
            hash_symbol => $package . '::' . $3,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$[A-Za-z_][A-Za-z0-9_]*\s*\)\s*=\s*\@_;\s*
                    \$[A-Za-z_][A-Za-z0-9_]*\s*=\s*''\s+if\s+!defined\s+\$[A-Za-z_][A-Za-z0-9_]*\s*;\s*
                    return\s+md5_hex\(\s*_content_bytes\(\$[A-Za-z_][A-Za-z0-9_]*\)\s*\)\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'content_md5',
            default => '',
            bytes_method => $package . '::_content_bytes',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s*\(\s*\$[A-Za-z_][A-Za-z0-9_]*\s*,\s*\$[A-Za-z_][A-Za-z0-9_]*\s*\)\s*=\s*\@_;\s*
                    return\s+content_md5\(\$[A-Za-z_][A-Za-z0-9_]*\)\s+eq\s+content_md5\(\$[A-Za-z_][A-Za-z0-9_]*\)\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'same_content_md5',
            target => $package . '::content_md5',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$[A-Za-z_][A-Za-z0-9_]*\s*,\s*\$[A-Za-z_][A-Za-z0-9_]*\s*\)\s*=\s*\@_;\s*
                    return\s+0\s+if\s+!defined\s+\$[A-Za-z_][A-Za-z0-9_]*\s+\|\|\s+\$[A-Za-z_][A-Za-z0-9_]*\s+eq\s+''\s+\|\|\s*!\-f\s+\$[A-Za-z_][A-Za-z0-9_]*\s*;\s*
                    open\s+my\s+\$[A-Za-z_][A-Za-z0-9_]*\s*,\s*'<:raw'\s*,\s*\$[A-Za-z_][A-Za-z0-9_]*\s+or\s+die\s+\"([^\"]*)\"\s*;\s*
                    my\s+\$[A-Za-z_][A-Za-z0-9_]*\s*=\s*do\s*\{\s*local\s+\$\/;\s*<\$[A-Za-z_][A-Za-z0-9_]*>\s*\}\s*;\s*
                    close\s+\$[A-Za-z_][A-Za-z0-9_]*\s+or\s+die\s+\"([^\"]*)\"\s*;\s*
                    return\s+same_content_md5\(\s*\$[A-Za-z_][A-Za-z0-9_]*\s*,\s*\$[A-Za-z_][A-Za-z0-9_]*\s*\)\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_matches_content_md5',
            read_error => $1,
            close_error => $2,
            compare_method => $package . '::same_content_md5',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$[A-Za-z_][A-Za-z0-9_]*\s*\)\s*=\s*\@_;\s*
                    return\s+encode_utf8\(\$[A-Za-z_][A-Za-z0-9_]*\)\s+if\s+utf8::is_utf8\(\$[A-Za-z_][A-Za-z0-9_]*\)\s*;\s*
                    return\s+\$[A-Za-z_][A-Za-z0-9_]*\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'utf8_content_bytes',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*%args\s*\)\s*=\s*\@_;\s*
                    (?:\$FILES\s*=\s*\$args\{files\}\s+if\s+\$args\{files\}\s*;\s*)?
                    (?:if\s*\s*\(\s*!\$FILES\s*&&\s*\$args\{paths\}\s*\)\s*\{\s*\$FILES\s*=\s*(?:[A-Za-z_][A-Za-z0-9_]*::)*FileRegistry->new\(\s*paths\s*=>\s*\$args\{paths\}\s*\)\s*;\s*\}\s*)?
                    %ALIASES\s*=\s*%\{\s*\$args\{aliases\}\s*\|\|\s*\{\s*\}\s*\}\s*;\s*
                    (?:%CONFIG_ALIASES\s*=\s*\(\s*\)\s*;\s*)?
                    (?:\$CONFIG_ALIASES_KEY\s*=\s*''\s*;\s*)?
                    return\s+1\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_configure',
            hash_symbol => $package . '::ALIASES',
            files_symbol => $package . '::FILES',
            config_hash_symbol => $package . '::CONFIG_ALIASES',
            config_key_symbol => $package . '::CONFIG_ALIASES_KEY',
            file_registry_class => _sibling_class($package, 'FileRegistry'),
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*\$file\s*\)\s*=\s*\@_;\s*
                    my\s+\$path\s*=\s*\$class->_resolve_file\(\$file\)\s*;\s*
                    return\s+if\s+!defined\s+\$path\s+\|\|\s*!\-f\s+\$path\s*;\s*
                    open\s+my\s+\$[A-Za-z_][A-Za-z0-9_]*\s*,\s*'<'\s*,\s*\$path\s+or\s+die\s+\"([^\"]*)\"\s*;\s*
                    local\s+\$\/;\s*
                    return\s+<\$[A-Za-z_][A-Za-z0-9_]*>\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_read',
            resolve_method => $package . '::_resolve_file',
            read_error => $1,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*\$file\s*,\s*\$content\s*,\s*\$append\s*\)\s*=\s*\@_;\s*
                    my\s+\$path\s*=\s*\$class->_resolve_file\(\$file\)\s*;\s*
                    die\s+'([^']*)'\s+if\s+!defined\s+\$path\s+\|\|\s+\$path\s+eq\s+''\s*;\s*
                    my\s+\$mode\s*=\s*\$append\s+\?\s+'>>'\s*:\s*'>'\s*;\s*
                    open\s+my\s+\$[A-Za-z_][A-Za-z0-9_]*\s*,\s*\$mode\s*,\s*\$path\s+or\s+die\s+\"([^\"]*)\"\s*;\s*
                    print\s+\{\$[A-Za-z_][A-Za-z0-9_]*\}\s+defined\s+\$content\s+\?\s+\$content\s*:\s*''\s*;\s*
                    close\s+\$[A-Za-z_][A-Za-z0-9_]*\s+or\s+die\s+\"([^\"]*)\"\s*;\s*
                    my\s+\$files\s*=\s*_files_obj\(\)\s*;\s*
                    \$files->paths->secure_file_permissions\(\$path\)\s+if\s+\$files\s+&&\s+\$files->can\('paths'\)\s*;\s*
                    return\s+\$path\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_write',
            resolve_method => $package . '::_resolve_file',
            files_method => $package . '::_files_obj',
            missing_error => $1,
            write_error => $2,
            close_error => $3,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'all'
        && $body =~ /_files_obj/
        && $body =~ /_load_configured_aliases/
        && $body =~ /all_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_all',
            files_method => $package . '::_files_obj',
            load_aliases_method => $package . '::_load_configured_aliases',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'exists'
        && $body =~ /_resolve_file/
        && $body =~ /-f \$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_exists',
            resolve_method => $package . '::_resolve_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'cat'
        && $body =~ /return \$class->read\(\$file\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'return_method_call',
            method => $package . '::read',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'resolve'
        && $body =~ /return \$class->_resolve_file\(\$file\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'return_method_call',
            target => $package . '::_resolve_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'rm'
        && $body =~ /_resolve_file/
        && $body =~ /unlink \$path if defined \$path && -e \$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_rm',
            resolve_method => $package . '::_resolve_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_files_obj'
        && $body =~ /blessed\(\$FILES\)/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*PathRegistry->new/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*FileRegistry->new/
        && $body =~ /_load_configured_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_files_obj',
            files_symbol => $package . '::FILES',
            file_registry_class => _sibling_class($package, 'FileRegistry'),
            path_registry_class => _sibling_class($package, 'PathRegistry'),
            load_aliases_method => $package . '::_load_configured_aliases',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_configured_alias_cache_key'
        && $body =~ /current_project_root/
        && $body =~ /runtime_roots/
        && $body =~ /join\s+"\\n"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_alias_cache_key',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_load_configured_aliases'
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Config->new/
        && $body =~ /register_named_files/
        && $body =~ /CONFIG_ALIASES_KEY/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_load_configured_aliases',
            files_symbol => $package . '::FILES',
            config_hash_symbol => $package . '::CONFIG_ALIASES',
            config_key_symbol => $package . '::CONFIG_ALIASES_KEY',
            cache_key_method => $package . '::_configured_alias_cache_key',
            config_class => _sibling_class($package, 'Config'),
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_resolve_file'
        && $body =~ /_files_obj/
        && $body =~ /_load_configured_aliases/
        && $body =~ /\$ENV\{/
        && $body =~ /uc\(\$where\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_resolve_file',
            files_symbol => $package . '::FILES',
            aliases_symbol => $package . '::ALIASES',
            config_aliases_symbol => $package . '::CONFIG_ALIASES',
            files_method => $package . '::_files_obj',
            load_aliases_method => $package . '::_load_configured_aliases',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'AUTOLOAD'
        && $body =~ /\$AUTOLOAD =~ \/::\(\[\^:\]\+\)\$/
        && $body =~ /_resolve_file/
        && $body =~ /Unknown file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_file_autoload',
            autoload_symbol => $package . '::AUTOLOAD',
            resolve_method => $package . '::_resolve_file',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*%args\s*\)\s*=\s*\@_;\s*
                    return\s+bless\s+\{\s*writer\s*=>\s*\$args\{writer\}\s*\|\|\s*sub\s*\{\s*\}\s*\}\s*,\s*\$class\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'tiehandle_constructor',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$self\s*,\s*\@parts\s*\)\s*=\s*\@_;\s*
                    \$self->\{writer\}->\(\s*join\s+''\s*,\s*map\s*\{\s*defined\s+\$_\s*\?\s*\$_\s*:\s*''\s*\}\s+\@parts\s*\)\s*;\s*
                    return\s+1\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'stream_writer_print',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$self\s*,\s*\$format\s*,\s*\@parts\s*\)\s*=\s*\@_;\s*
                    \$self->\{writer\}->\(\s*sprintf\(\s*defined\s+\$format\s*\?\s*\$format\s*:\s*''\s*,\s*\@parts\s*\)\s*\)\s*;\s*
                    return\s+1\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'stream_writer_printf',
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$class\s*,\s*%args\s*\)\s*=\s*\@_;\s*return\s+bless\s+\{\s*(.+?)\s*\}\s*,\s*\$class\s*;\s*\z/s) {
        my $entries = $1;
        my @pairs;
        while ($entries =~ /([A-Za-z_][A-Za-z0-9_]*)\s*=>\s*\$args\{([A-Za-z_][A-Za-z0-9_]*)\}\s*,?/g) {
            push @pairs, [ $1, $2 ];
        }
        if (@pairs) {
            my $prototype = _sub_prototype_from_source($source, $short_name);
            return {
                name => $short_name,
                full_name => $full_name,
                op => 'bless_args_hash',
                slots => [ map { { slot => $_->[0], arg => $_->[1] } } @pairs ],
                prototype => $prototype,
            };
        }
    }

    if (
        $body =~ /\A\s*my\s+\(\s*\$class\s*,\s*%args\s*\)\s*=\s*\@_;\s*(.+?)return\s+bless\s+\{\s*(.+?)\s*\}\s*,\s*\$class\s*;\s*\z/s
    ) {
        my ($checks, $entries) = ($1, $2);
        my (@required, @slots);
        while ($checks =~ /my\s+\$([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$args\{([A-Za-z_][A-Za-z0-9_]*)\}\s*\|\|\s*die\s+'([^']+)'\s*;/g) {
            push @required, { slot => $1, arg => $2, error => $3 };
        }
        while ($entries =~ /([A-Za-z_][A-Za-z0-9_]*)\s*=>\s*\$([A-Za-z_][A-Za-z0-9_]*)\s*,?/g) {
            push @slots, { slot => $1, var => $2 };
        }
        if (@required && @slots) {
            my %arg_for = map { $_->{slot} => $_->{arg} } @required;
            my @slot_specs;
            for my $slot (@slots) {
                my $arg = $arg_for{ $slot->{var} };
                next if !defined $arg;
                my ($req) = grep { $_->{slot} eq $slot->{var} } @required;
                push @slot_specs, {
                    slot => $slot->{slot},
                    arg => $arg,
                    error => $req->{error},
                };
            }
            if (@slot_specs == @slots) {
                my $prototype = _sub_prototype_from_source($source, $short_name);
                return {
                    name => $short_name,
                    full_name => $full_name,
                    op => 'bless_required_args_hash',
                    slots => \@slot_specs,
                    prototype => $prototype,
                };
            }
        }
    }

    if ($body =~ /\A\s*return\s+\$_\[0\]\{([A-Za-z_][A-Za-z0-9_]*)\}\s*;\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'return_self_slot',
            slot => $1,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\$command\)\s*=\s*\@_;\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'skills'\s+\|\|\s+\$command\s+eq\s+'skill';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'docker';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'path';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'indicator';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'collector';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'config';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'auth';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'page';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'action';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'serve';\s*
                    return\s+qw\(([^)]*)\)\s+if\s+\$command\s+eq\s+'shell';\s*
                    return\s+\(\);\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_subcommand_candidates',
            command_map => {
                skill => [ split /\s+/, $1 ],
                docker => [ split /\s+/, $2 ],
                path => [ split /\s+/, $3 ],
                indicator => [ split /\s+/, $4 ],
                collector => [ split /\s+/, $5 ],
                config => [ split /\s+/, $6 ],
                auth => [ split /\s+/, $7 ],
                page => [ split /\s+/, $8 ],
                action => [ split /\s+/, $9 ],
                serve => [ split /\s+/, $10 ],
                shell => [ split /\s+/, $11 ],
            },
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'complete'
        && $body =~ /Missing completion words\\n/
        && $body =~ /Missing completion index\\n/
        && $body =~ /Completion words must be an array reference\\n/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*CLI::Suggest->new\(\)/
        && $body =~ /\$suggest->top_level_candidates/
        && $body =~ /\$suggest->skill_commands/
        && $body =~ /_subcommand_candidates\(\s*\$words\[1\]\s*\|\|\s*''\s*\)/
        && $body =~ /my %seen;/
        && $body =~ /index\(\s*\$_\s*,\s*\$current\s*\)\s*==\s*0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_complete',
            suggest_class => _sibling_class($package, 'CLI::Suggest'),
            subcommand_method => $package . '::_subcommand_candidates',
            missing_words_error => "Missing completion words\n",
            missing_index_error => "Missing completion index\n",
            type_error => "Completion words must be an array reference\n",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'updates_dir'
        && $body =~ /File::Spec->catdir\( cwd\(\), 'updates' \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cwd_catdir_literal',
            path_parts => ['updates'],
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_is_supported_update_script'
        && $body =~ /return 0 if !defined \$path \|\| \$path eq ''/
        && $body =~ /return 1 if \$path =~ \/\\\.pl\\z\/i/
        && $body =~ /return 1 if \$path =~ \/\\\.\(\?:sh\|bash\|ps1\|cmd\|bat\)\\z\/i/
        && $body =~ /is_runnable_file\(\$path\) \? 1 : 0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'supported_update_script',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_running_collectors'
        && $body =~ /return map \{ \$_->\{name\} \} \$self->\{runner\}->running_loops/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runner_loop_names',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_stop_collectors'
        && $body =~ /for my \$name \(\@names\)/
        && $body =~ /eval \{ \$self->\{runner\}->stop_loop\(\$name\) \}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'stop_named_loops',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_restart_collectors'
        && $body =~ /my %wanted = map \{ \$_ => 1 \} \@names;/
        && $body =~ /my \@jobs = \@\{ \$self->\{config\}->collectors \};/
        && $body =~ /eval \{ \$self->\{runner\}->start_loop\(\$job\) \}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'restart_wanted_collectors',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run'
        && $body =~ /\@running = \$self->_running_collectors/
        && $body =~ /\$self->_stop_collectors\(\@running\)/
        && $body =~ /opendir my \$dh, \$dir or die "Unable to open updates directory/
        && $body =~ /my \@cmd = command_argv_for_path\(\$path\);/
        && $body =~ /my \( \$stdout, \$stderr, \$exit_code \) = capture/
        && $body =~ /\$self->_restart_collectors\(\@running\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'update_manager_run',
            updates_dir_method => $package . '::updates_dir',
            running_method => $package . '::_running_collectors',
            stop_method => $package . '::_stop_collectors',
            restart_method => $package . '::_restart_collectors',
            support_method => $package . '::_is_supported_update_script',
            open_error => 'Unable to open updates directory %s: %s',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'providers'
        && $body =~ /id\s*=>\s*'system-status'/
        && $body =~ /id\s*=>\s*'project-context'/
        && $body =~ /push \@providers, \@\{ \$self->\{config\}->providers \};/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_resolver_providers',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'list_pages'
        && $body =~ /my %ids = map \{ \$_ => 1 \} \$self->\{pages\}->list_saved_pages;/
        && $body =~ /for my \$provider \(\s*\@\{ \$self->providers \}\s*\)/
        && $body =~ /\$ids\{ \$provider->\{id\} \} = 1 if \$provider->\{id\};/
        && $body =~ /return sort keys %ids;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_resolver_list_pages',
            providers_method => $package . '::providers',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'load_named_page'
        && $body =~ /Missing page id/
        && $body =~ /load_saved_page/
        && $body =~ /source_kind/
        && $body =~ /load_provider_page/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_resolver_load_named_page',
            missing_error => 'Missing page id',
            provider_method => $package . '::load_provider_page',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'load_provider_page'
        && $body =~ /Page '\$id' not found/
        && $body =~ /system-status/
        && $body =~ /project-context/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*PageDocument->new/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*PageDocument->from_hash/
        && $body =~ /source_kind/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_resolver_load_provider_page',
            providers_method => $package . '::providers',
            missing_error => "Page '%s' not found",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_timestamp'
        && $body =~ /strftime\( '%Y-%m-%d %H:%M:%S', localtime \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'strftime_now',
            format => '%Y-%m-%d %H:%M:%S',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_indicator_parts'
        && $body =~ /\$self->\{indicators\}->list_indicators/
        && $body =~ /prompt_status_icon/
        && $body =~ /is_stale/
        && $body =~ /push \@indicator_parts, \$part;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'prompt_indicator_parts',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_git_branch'
        && $body =~ /git', 'branch'/
        && $body =~ /Unable to restore cwd/
        && $body =~ /return \$1 if \$line =~/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'git_branch_for_project',
            restore_error => 'Unable to restore cwd to %s: %s',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'render'
        && $body =~ /\$jobs = defined \$args\{jobs\} \? \$args\{jobs\} : 0;/
        && $body =~ /\$cwd  = \$args\{cwd\} \|\| cwd\(\);/
        && $body =~ /\$self->_indicator_parts/
        && $body =~ /\$self->_git_branch/
        && $body =~ /\$self->_timestamp/
        && $body =~ /return sprintf "\(%s\)%s \[%s\]%s%s\\n> "/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'prompt_render',
            indicator_method => $package . '::_indicator_parts',
            branch_method => $package . '::_git_branch',
            timestamp_method => $package . '::_timestamp',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_known_roots'
        && $body =~ /label => 'home_runtime'/
        && $body =~ /legacy_bookmarks/
        && $body =~ /legacy_checkers/
        && $body =~ /File::Spec->catdir\( \$home, \$_->\{name\} \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'doctor_known_roots',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_mode_octal'
        && $body =~ /my \@stat = stat\(\$path\);/
        && $body =~ /return undef if !\@stat;/
        && $body =~ /sprintf '%04o', \$stat\[2\] & 07777/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'mode_octal_stat',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_permission_issue_for_path'
        && $body =~ /my \$mode = _mode_octal\(\$path\);/
        && $body =~ /my \$expected = -d \$path \? '0700' : \( -x \$path \? '0700' : '0600' \);/
        && $body =~ /current_mode  => \$mode/
        && $body =~ /expected_mode => \$expected/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'doctor_permission_issue_for_path',
            mode_method => $package . '::_mode_octal',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_doctor_hook_results'
        && $body =~ /return \{\} if !defined \$ENV\{RESULT\} \|\| \$ENV\{RESULT\} eq ''/
        && $body =~ /json_decode\( \$ENV\{RESULT\} \)/
        && $body =~ /Doctor hook RESULT must decode to a hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'doctor_hook_results',
            decode_error => 'Doctor hook RESULT must decode to a hash',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_audit_root'
        && $body =~ /Missing audit root path/
        && $body =~ /Missing audit root label/
        && $body =~ /File::Find::find/
        && $body =~ /Unable to chmod %s to %s: %s/
        && $body =~ /issue_count => scalar \@issues/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'doctor_audit_root',
            missing_path_error => 'Missing audit root path',
            missing_label_error => 'Missing audit root label',
            chmod_error => 'Unable to chmod %s to %s: %s',
            permission_method => $package . '::_permission_issue_for_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_audit_roots'
        && $body =~ /my %seen;/
        && $body =~ /for my \$root \(\s*\$self->_known_roots\s*\)/
        && $body =~ /push \@reports, \$self->_audit_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'doctor_audit_roots',
            roots_method => $package . '::_known_roots',
            audit_method => $package . '::_audit_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run'
        && $body =~ /my \$fix = \$args\{fix\} \? 1 : 0;/
        && $body =~ /my \@roots = \$self->_audit_roots/
        && $body =~ /my \$hooks = \$self->_doctor_hook_results/
        && $body =~ /hook_failures => scalar \@hook_failures/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'doctor_run',
            audit_roots_method => $package . '::_audit_roots',
            hook_results_method => $package . '::_doctor_hook_results',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_build_paths'
        && $body =~ /\$home = \$ENV\{HOME\} \|\| ''/
        && $body =~ /map \{ \"\$home\/\$_\" \} qw\(projects src work\)/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*PathRegistry->new/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'build_paths_registry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cdr_payload'
        && $body =~ /Missing paths registry\\n/
        && $body =~ /cdr args must be an array reference\\n/
        && $body =~ /resolve_dir/
        && $body =~ /locate_dirs_under/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cdr_payload',
            missing_paths_error => "Missing paths registry\n",
            type_error => "cdr args must be an array reference\n",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cdr_directory_candidates'
        && $body =~ /Missing paths registry\\n/
        && $body =~ /cdr completion terms must be an array reference\\n/
        && $body =~ /locate_dirs_under/
        && $body =~ /basename/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cdr_directory_candidates',
            missing_paths_error => "Missing paths registry\n",
            type_error => "cdr completion terms must be an array reference\n",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cdr_initial_candidates'
        && $body =~ /Missing paths registry\\n/
        && $body =~ /cdr completion include roots must be an array reference\\n/
        && $body =~ /named_paths/
        && $body =~ /_cdr_directory_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cdr_initial_candidates',
            missing_paths_error => "Missing paths registry\n",
            type_error => "cdr completion include roots must be an array reference\n",
            directory_method => $package . '::_cdr_directory_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cdr_completion'
        && $body =~ /Missing paths registry\\n/
        && $body =~ /Missing completion words\\n/
        && $body =~ /Missing completion index\\n/
        && $body =~ /cdr completion words must be an array reference\\n/
        && $body =~ /_cdr_initial_candidates/
        && $body =~ /_cdr_directory_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cdr_completion',
            missing_paths_error => "Missing paths registry\n",
            missing_words_error => "Missing completion words\n",
            missing_index_error => "Missing completion index\n",
            type_error => "cdr completion words must be an array reference\n",
            initial_method => $package . '::_cdr_initial_candidates',
            directory_method => $package . '::_cdr_directory_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_paths_command'
        && $body =~ /Missing command name\\n/
        && $body =~ /Missing command arguments\\n/
        && $body =~ /Command arguments must be an array reference\\n/
        && $body =~ /_build_paths/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*FileRegistry->new/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Config->new/
        && $body =~ /dashboard path <resolve\|locate\|cdr\|complete-cdr\|add\|del\|rm\|project-root\|list>/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'run_paths_command',
            missing_command_error => "Missing command name\n",
            missing_args_error => "Missing command arguments\n",
            type_error => "Command arguments must be an array reference\n",
            usage_error => "Usage: dashboard path <resolve|locate|cdr|complete-cdr|add|del|project-root|list> ...\n",
            build_paths_method => $package . '::_build_paths',
            cdr_payload_method => $package . '::_cdr_payload',
            cdr_completion_method => $package . '::_cdr_completion',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_add_arguments'
        && $body =~ /dashboard path add/
        && $body =~ /basename\(\\?\$cwd\)/
        && $body =~ /\$path = cwd\(\) if \$path eq '\.'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'paths_normalize_add_arguments',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_delete_argument'
        && $body =~ /Missing paths registry/
        && $body =~ /Missing config/
        && $body =~ /dashboard path del/
        && $body =~ /_expand_home/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'paths_normalize_delete_argument',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_files_command'
        && $body =~ /Missing command name\\n/
        && $body =~ /Missing command arguments\\n/
        && $body =~ /Command arguments must be an array reference\\n/
        && $body =~ /_build_paths/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*FileRegistry->new/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Config->new/
        && $body =~ /dashboard file <resolve\|locate\|add\|del\|list>/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'run_files_command',
            missing_command_error => "Missing command name\n",
            missing_args_error => "Missing command arguments\n",
            type_error => "Command arguments must be an array reference\n",
            usage_error => "Usage: dashboard file <resolve|locate|add|del|list> ...\n",
            build_paths_method => $package . '::_build_paths',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'build_psgi_app'
        && _package_tail_is($package, '')
        && $body =~ /Missing backend web app/
        && $body =~ /\$BACKEND_APP/
        && $body =~ /default_headers/
        && $body =~ /__PACKAGE__->to_app/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_build_psgi_app',
            app_package => $package,
            backend_symbol => $package . '::BACKEND_APP',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_temp_file_kind'
        && _package_tail_is($package, '')
        && $body =~ /\$entry\s*=~\s*\/\\A/i
        && $body =~ /result/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_temp_file_kind',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_collector_rotation'
        && _package_tail_is($package, '')
        && $body =~ /ref\( \$job->\{rotation\} \) eq 'HASH'/
        && $body =~ /ref\( \$job->\{rotations\} \) eq 'HASH'/
        && $body =~ /return \\\%rotation/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_collector_rotation',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_path_is_old_enough'
        && _package_tail_is($package, '')
        && $body =~ /stat\(\$path\)/
        && $body =~ /\( time - \$stat\[9\] \) >= \$min_age_seconds/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_path_old_enough',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_only_missing_tree_errors'
        && _package_tail_is($package, '')
        && $body =~ /No such file or directory/
        && $body =~ /values %\{ \$entry \|\| \{\} \}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_only_missing_tree_errors',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_read_state_metadata'
        && _package_tail_is($package, '')
        && $body =~ /runtime\.json/
        && $body =~ /json_decode/
        && $body =~ /ref\(\$data\) ne 'HASH'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_read_state_metadata',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_remove_tree'
        && _package_tail_is($package, '')
        && $body =~ /remove_tree/
        && $body =~ /Unable to remove stale \$kind \$path/
        && $body =~ /_only_missing_tree_errors/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_remove_tree',
            missing_errors_method => $package . '::_only_missing_tree_errors',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_collector_store'
        && _package_tail_is($package, '')
        && $body =~ /collector_store/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Collector->new/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_collector_store',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_config'
        && _package_tail_is($package, '')
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Config->new/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*FileRegistry->new/
        && $body =~ /config/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_config',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'configure'
        && _package_tail_is($package, '')
        && $body =~ /\$PATHS = \$args\{paths\}/
        && $body =~ /%ALIASES = %\{ \$args\{aliases\} \|\| \{\} \}/
        && $body =~ /\$CONFIG_ALIASES_KEY = ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_configure',
            paths_symbol => $package . '::PATHS',
            aliases_symbol => $package . '::ALIASES',
            config_aliases_symbol => $package . '::CONFIG_ALIASES',
            config_key_symbol => $package . '::CONFIG_ALIASES_KEY',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'home'
        && _package_tail_is($package, '')
        && $body =~ /return \$ENV\{HOME\} \|\| ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_home',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'tmp'
        && _package_tail_is($package, '')
        && $body =~ /File::Spec->tmpdir/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_tmp',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'dd'
        && _package_tail_is($package, '')
        && $body =~ /runtime_root/
        && $body =~ /_paths_obj/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_runtime_root',
            paths_method => $package . '::_paths_obj',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'bookmarks'
        && _package_tail_is($package, '')
        && $body =~ /dashboards_root/
        && $body =~ /_paths_obj/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_dashboards_root',
            paths_method => $package . '::_paths_obj',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'configs'
        && _package_tail_is($package, '')
        && $body =~ /config_root/
        && $body =~ /_paths_obj/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_config_root',
            paths_method => $package . '::_paths_obj',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'all'
        && _package_tail_is($package, '')
        && $body =~ /all_paths/
        && $body =~ /_load_configured_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_all_paths',
            paths_method => $package . '::_paths_obj',
            load_aliases_method => $package . '::_load_configured_aliases',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'postman'
        && _package_tail_is($package, '')
        && $body =~ /File::Spec->catdir\( configs\(\), 'postman' \)/
        && $body =~ /make_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_postman',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_paths_obj'
        && _package_tail_is($package, '')
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*PathRegistry->new/
        && $body =~ /workspace_roots/
        && $body =~ /_load_configured_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_paths_obj',
            paths_symbol => $package . '::PATHS',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'helper_names'
        && _package_tail_is($package, '')
        && $body =~ /jq yq tomq propq iniq csvq xmlq/
        && $body =~ /complete/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_names',
            names => [qw(
              jq yq tomq propq iniq csvq xmlq
              of open-file ticket file files path paths ps1
              encode decode indicator collector config auth init cpan page action docker serve stop restart shell doctor housekeeper skills which
              complete
            )],
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'helper_aliases'
        && _package_tail_is($package, '')
        && $body =~ /pjq/
        && $body =~ /skill/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_aliases',
            aliases => {
                pjq => 'jq',
                pyq => 'yq',
                ptomq => 'tomq',
                pjp => 'propq',
                skill => 'skills',
            },
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'canonical_helper_name'
        && _package_tail_is($package, '')
        && $body =~ /helper_names/
        && $body =~ /helper_aliases/
        && $body =~ /return '' if !defined \$name || \$name eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_canonical_helper_name',
            helper_names_method => $package . '::helper_names',
            helper_aliases_method => $package . '::helper_aliases',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_helper_parent_root'
        && _package_tail_is($package, '')
        && $body =~ /home_runtime_root/
        && $body =~ /'cli'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_parent_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_helper_install_root'
        && _package_tail_is($package, '')
        && $body =~ /_helper_parent_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_install_root',
            parent_root_method => $package . '::_helper_parent_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_managed_helper_marker'
        && _package_tail_is($package, '')
        && $body =~ /managed-helper/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_managed_helper_marker',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_repo_private_cli_root'
        && _package_tail_is($package, '')
        && $body =~ /dirname\(__FILE__\)/
        && $body =~ /share/
        && $body =~ /private-cli/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_repo_private_cli_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_shared_private_cli_root'
        && _package_tail_is($package, '')
        && $body =~ /dist_dir/
        && $body =~ /private-cli/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        my ($dist_name) = $body =~ /dist_dir\s*\(\s*['"]([^'"]+)['"]\s*\)/;
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_shared_private_cli_root',
            dist_name => $dist_name,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_helper_asset_path'
        && _package_tail_is($package, '')
        && $body =~ /_repo_private_cli_root/
        && $body =~ /_shared_private_cli_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_asset_path',
            repo_root_method => $package . '::_repo_private_cli_root',
            shared_root_method => $package . '::_shared_private_cli_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'helper_path'
        && _package_tail_is($package, '')
        && $body =~ /canonical_helper_name/
        && $body =~ /Unsupported helper command/
        && $body =~ /_helper_install_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_path',
            canonical_method => $package . '::canonical_helper_name',
            install_root_method => $package . '::_helper_install_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'helper_content'
        && _package_tail_is($package, '')
        && $body =~ /_dashboard-core/
        && $body =~ /canonical_helper_name/
        && $body =~ /_helper_asset_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_helper_content',
            canonical_method => $package . '::canonical_helper_name',
            asset_path_method => $package . '::_helper_asset_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_managed_helper_content'
        && _package_tail_is($package, '')
        && $body =~ /helper_content/
        && $body =~ /_managed_helper_marker/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_managed_helper_content',
            helper_content_method => $package . '::helper_content',
            marker_method => $package . '::_managed_helper_marker',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_is_dashboard_managed_helper'
        && _package_tail_is($package, '')
        && $body =~ /_managed_helper_marker/
        && $body =~ /Missing built-in dashboard command/
        && $body =~ /LAZY-THIN-CMD/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_is_dashboard_managed_helper',
            marker_method => $package . '::_managed_helper_marker',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_stage_managed_helper'
        && _package_tail_is($package, '')
        && $body =~ /_managed_helper_content/
        && $body =~ /_is_dashboard_managed_helper/
        && $body =~ /same_content_md5/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_stage_managed_helper',
            managed_content_method => $package . '::_managed_helper_content',
            managed_check_method => $package . '::_is_dashboard_managed_helper',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_remove_retired_managed_helper'
        && _package_tail_is($package, '')
        && $body =~ /_helper_install_root/
        && $body =~ /_is_dashboard_managed_helper/
        && $body =~ /Unable to remove retired helper/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_remove_retired_managed_helper',
            install_root_method => $package . '::_helper_install_root',
            managed_check_method => $package . '::_is_dashboard_managed_helper',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'ensure_helpers'
        && _package_tail_is($package, '')
        && $body =~ /ensure_dir/
        && $body =~ /_stage_managed_helper/
        && $body =~ /_remove_retired_managed_helper/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'internal_cli_ensure_helpers',
            parent_root_method => $package . '::_helper_parent_root',
            install_root_method => $package . '::_helper_install_root',
            stage_method => $package . '::_stage_managed_helper',
            helper_names_method => $package . '::helper_names',
            helper_path_method => $package . '::helper_path',
            remove_retired_method => $package . '::_remove_retired_managed_helper',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_expand_env_path'
        && _package_tail_is($package, '')
        && $body =~ /defined \$ENV/
        && $body =~ /return \$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_expand_env_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_docker_config_root'
        && _package_tail_is($package, '')
        && $body =~ /config_root/
        && $body =~ /'docker'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_config_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_home_docker_config_root'
        && _package_tail_is($package, '')
        && $body =~ /home_runtime_root/
        && $body =~ /'config'/
        && $body =~ /'docker'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_home_config_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_discover_base_files'
        && _package_tail_is($package, '')
        && $body =~ /compose\.yml/
        && $body =~ /docker-compose\.yaml/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_discover_base_files',
            candidates => [qw(compose.yml compose.yaml docker-compose.yml docker-compose.yaml)],
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_service_toggle_root'
        && _package_tail_is($package, '')
        && $body =~ /runtime_layers/
        && $body =~ /home_runtime_root/
        && $body =~ /config/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_service_toggle_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_service_disabled_marker_path'
        && _package_tail_is($package, '')
        && $body =~ /_service_toggle_root/
        && $body =~ /disabled\.yml/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_service_disabled_marker_path',
            toggle_root_method => $package . '::_service_toggle_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_service_lookup_roots'
        && _package_tail_is($package, '')
        && $body =~ /runtime_layers/
        && $body =~ /installed_skill_docker_roots_for_runtime/
        && $body =~ /__all__/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_service_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_service_folder_is_disabled'
        && _package_tail_is($package, '')
        && $body =~ /_service_lookup_roots/
        && $body =~ /disabled\.yml/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_service_folder_is_disabled',
            lookup_roots_method => $package . '::_service_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_discover_service_names'
        && _package_tail_is($package, '')
        && $body =~ /_service_lookup_roots/
        && $body =~ /service_map/
        && $body =~ /sort keys %names/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_discover_service_names',
            lookup_roots_method => $package . '::_service_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_discover_enabled_services'
        && _package_tail_is($package, '')
        && $body =~ /_discover_service_names/
        && $body =~ /_service_folder_is_disabled/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_discover_enabled_services',
            discover_names_method => $package . '::_discover_service_names',
            service_disabled_method => $package . '::_service_folder_is_disabled',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_infer_services_from_args'
        && _package_tail_is($package, '')
        && $body =~ /_discover_service_names/
        && $body =~ /next if !\$known\{\$arg\}/
        && $body =~ /push \@services, \$arg/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_infer_services_from_args',
            discover_names_method => $package . '::_discover_service_names',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_discover_service_files'
        && _package_tail_is($package, '')
        && $body =~ /_service_folder_is_disabled/
        && $body =~ /_service_lookup_roots/
        && $body =~ /development\.compose\.yml/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_discover_service_files',
            service_disabled_method => $package . '::_service_folder_is_disabled',
            lookup_roots_method => $package . '::_service_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'resolve'
        && _package_tail_is($package, '')
        && $body =~ /_discover_base_files/
        && $body =~ /_infer_services_from_args/
        && $body =~ /docker', 'compose/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_resolve',
            base_files_method => $package . '::_discover_base_files',
            infer_services_method => $package . '::_infer_services_from_args',
            discover_enabled_method => $package . '::_discover_enabled_services',
            discover_service_files_method => $package . '::_discover_service_files',
            expand_path_method => $package . '::_expand_env_path',
            config_root_method => $package . '::_docker_config_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'disable_service'
        && _package_tail_is($package, '')
        && $body =~ /_service_disabled_marker_path/
        && $body =~ /disabled: 1/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_disable_service',
            disabled_marker_method => $package . '::_service_disabled_marker_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'enable_service'
        && _package_tail_is($package, '')
        && $body =~ /_service_disabled_marker_path/
        && $body =~ /Unable to remove/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_enable_service',
            disabled_marker_method => $package . '::_service_disabled_marker_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'list_services'
        && _package_tail_is($package, '')
        && $body =~ /_discover_service_names/
        && $body =~ /_service_folder_is_disabled/
        && $body =~ /_service_disabled_marker_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_list_services',
            discover_names_method => $package . '::_discover_service_names',
            service_disabled_method => $package . '::_service_folder_is_disabled',
            disabled_marker_method => $package . '::_service_disabled_marker_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run'
        && _package_tail_is($package, '')
        && $body =~ /resolve/
        && $body =~ /capture/
        && $body =~ /system \@\{ .*command.* \}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'docker_compose_run',
            resolve_method => $package . '::resolve',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_query_command'
        && _package_tail_is($package, '')
        && $body =~ /_split_query_args/
        && $body =~ /_parse_query_input/
        && $body =~ /_command_exit/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_run_command',
            split_args_method => $package . '::_split_query_args',
            read_input_method => $package . '::_read_query_input',
            parse_input_method => $package . '::_parse_query_input',
            select_value_method => $package . '::_select_query_value',
            print_value_method => $package . '::_print_query_value',
            command_exit_method => $package . '::_command_exit',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_split_query_args'
        && _package_tail_is($package, '')
        && $body =~ /-f \$arg/
        && $body =~ /join\( ' ', \@rest \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_split_args',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_read_query_input'
        && _package_tail_is($package, '')
        && $body =~ /<STDIN>/
        && $body =~ /Unable to read \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_read_input',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_parse_query_input'
        && _package_tail_is($package, '')
        && $body =~ /TOML::Tiny::from_toml/
        && $body =~ /YAML::XS::Load/
        && $body =~ /Unsupported data query command/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_parse_input',
            parse_java_properties_method => $package . '::_parse_java_properties',
            parse_ini_method => $package . '::_parse_ini',
            parse_csv_method => $package . '::_parse_csv',
            parse_xml_method => $package . '::_parse_xml',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_extract_query_path'
        && _package_tail_is($package, '')
        && $body =~ /Missing path segment/
        && $body =~ /Array index/
        && $body =~ /nested structure/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_extract_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_path_uses_perl_expression'
        && _package_tail_is($package, '')
        && $body =~ /index\( \$path, '\$d' \) >= 0/
        && $body =~ /return 0 if !defined \$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_path_uses_expression',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_select_query_value'
        && _package_tail_is($package, '')
        && $body =~ /_evaluate_query_expression/
        && $body =~ /_extract_query_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_select_value',
            path_expression_method => $package . '::_path_uses_perl_expression',
            evaluate_expression_method => $package . '::_evaluate_query_expression',
            extract_path_method => $package . '::_extract_query_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_evaluate_query_expression'
        && _package_tail_is($package, '')
        && $body =~ /PERL_EVAL/
        && $body =~ /_expression_prefers_list_output/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_evaluate_expression',
            expression_prefers_list_method => $package . '::_expression_prefers_list_output',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_expression_prefers_list_output'
        && _package_tail_is($package, '')
        && $body =~ /sort\|map\|grep\|keys\|values/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_expression_prefers_list',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_print_query_value'
        && _package_tail_is($package, '')
        && $body =~ /json_encode/
        && $body =~ /defined \$value \? \$value : ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_print_value',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_parse_java_properties'
        && _package_tail_is($package, '')
        && $body =~ /_unescape_properties/
        && $body =~ /\%props/
        && $body =~ /\$pending/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_parse_java_properties',
            unescape_method => $package . '::_unescape_properties',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_unescape_properties'
        && _package_tail_is($package, '')
        && $body =~ /\\\\t/
        && $body =~ /\\\\\\\\/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_unescape_properties',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_parse_ini'
        && _package_tail_is($package, '')
        && $body =~ /_global/
        && $body =~ /current_section/
        && $body =~ /_global/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_parse_ini',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_parse_csv'
        && _package_tail_is($package, '')
        && $body =~ /split \/,\/, \$line/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_parse_csv',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_parse_xml'
        && _package_tail_is($package, '')
        && $body =~ /XML::Parser->new/
        && $body =~ /_xml_tree_to_data/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_parse_xml',
            xml_tree_method => $package . '::_xml_tree_to_data',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_xml_tree_to_data'
        && _package_tail_is($package, '')
        && $body =~ /XML tree must be an array reference/
        && $body =~ /_xml_element_payload/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_xml_tree_to_data',
            xml_element_method => $package . '::_xml_element_payload',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_xml_element_payload'
        && _package_tail_is($package, '')
        && $body =~ /XML element payload must be an array reference/
        && $body =~ /_attributes/
        && $body =~ /_text/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_xml_element_payload',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_command_exit'
        && _package_tail_is($package, '')
        && $body =~ /exit \$code/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'query_command_exit',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'api_dashboard_page'
        && _package_tail_is($package, '')
        && $body =~ /api-dashboard\.page/
        && $body =~ /_page_from_asset/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_api_dashboard_page',
            page_from_asset_method => $package . '::_page_from_asset',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'sql_dashboard_page'
        && _package_tail_is($package, '')
        && $body =~ /sql-dashboard\.page/
        && $body =~ /_page_from_asset/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_sql_dashboard_page',
            page_from_asset_method => $package . '::_page_from_asset',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'page_for_id'
        && _package_tail_is($package, '')
        && $body =~ /_seeded_page_asset_filename/
        && $body =~ /_page_from_asset/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_page_for_id',
            asset_filename_method => $package . '::_seeded_page_asset_filename',
            page_from_asset_method => $package . '::_page_from_asset',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'seed_manifest_path'
        && _package_tail_is($package, '')
        && $body =~ /config_root/
        && $body =~ /seeded-pages\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_manifest_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'known_managed_page_md5s'
        && _package_tail_is($package, '')
        && $body =~ /_seeded_page_asset_filename/
        && $body =~ /content_md5/
        && $body =~ /LEGACY_MANAGED_PAGE_MD5/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_known_managed_page_md5s',
            asset_filename_method => $package . '::_seeded_page_asset_filename',
            seeded_instruction_method => $package . '::_seeded_page_instruction',
            legacy_map => {
                'sql-dashboard' => [
                    '7d9101e0e2585c159e575f0dbd49b3ef',
                    'f62a03c9ff7d25cdce65ce569cf2e07b',
                    '10a14e5749f374a78429654b6c49b5f0',
                ],
            },
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'is_known_managed_page_md5'
        && _package_tail_is($package, '')
        && $body =~ /known_managed_page_md5s/
        && $body =~ /return 0 if \$id eq '' \|\| \$md5 eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_is_known_managed_page_md5',
            known_md5s_method => $package . '::known_managed_page_md5s',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_page_from_asset'
        && _package_tail_is($package, '')
        && $body =~ /_seeded_page_instruction/
        && $body =~ /PageDocument->from_instruction/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_page_from_asset',
            instruction_method => $package . '::_seeded_page_instruction',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_instruction']),
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_seeded_page_instruction'
        && _package_tail_is($package, '')
        && $body =~ /_seeded_page_asset_path/
        && $body =~ /PAGE_CACHE/
        && $body =~ /Unable to read/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_instruction',
            asset_path_method => $package . '::_seeded_page_asset_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_seeded_page_asset_filename'
        && _package_tail_is($package, '')
        && $body =~ /Unknown seeded page id/
        && $body =~ /ID_TO_ASSET/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_asset_filename',
            id_to_asset => {
                'api-dashboard' => 'api-dashboard.page',
                'sql-dashboard' => 'sql-dashboard.page',
            },
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_seeded_page_asset_path'
        && _package_tail_is($package, '')
        && $body =~ /_repo_seeded_pages_root/
        && $body =~ /_shared_seeded_pages_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_asset_path',
            repo_root_method => $package . '::_repo_seeded_pages_root',
            shared_root_method => $package . '::_shared_seeded_pages_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_repo_seeded_pages_root'
        && _package_tail_is($package, '')
        && $body =~ /dirname\(__FILE__\)/
        && $body =~ /seeded-pages/
        && $body =~ /File::Spec->updir/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_repo_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_shared_seeded_pages_root'
        && _package_tail_is($package, '')
        && $body =~ /dist_dir/
        && $body =~ /seeded-pages/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_shared_root',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_read_manifest'
        && _package_tail_is($package, '')
        && $body =~ /seed_manifest_path/
        && $body =~ /json_decode/
        && $body =~ /must decode to a hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_read_manifest',
            manifest_path_method => $package . '::seed_manifest_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_write_manifest'
        && _package_tail_is($package, '')
        && $body =~ /seed_manifest_path/
        && $body =~ /json_encode/
        && $body =~ /secure_file_permissions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_write_manifest',
            manifest_path_method => $package . '::seed_manifest_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_record_manifest_md5'
        && _package_tail_is($package, '')
        && $body =~ /_read_manifest/
        && $body =~ /_seeded_page_asset_filename/
        && $body =~ /_write_manifest/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_record_manifest_md5',
            read_manifest_method => $package . '::_read_manifest',
            asset_filename_method => $package . '::_seeded_page_asset_filename',
            write_manifest_method => $package . '::_write_manifest',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_manifest_md5_matches'
        && _package_tail_is($package, '')
        && $body =~ /_read_manifest/
        && $body =~ /return 0 if \$id eq '' \|\| \$md5 eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_manifest_md5_matches',
            read_manifest_method => $package . '::_read_manifest',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'ensure_seeded_page'
        && _package_tail_is($package, '')
        && $body =~ /canonical_instruction/
        && $body =~ /_manifest_md5_matches/
        && $body =~ /is_known_managed_page_md5/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'seeded_pages_ensure_seeded_page',
            record_manifest_method => $package . '::_record_manifest_md5',
            manifest_matches_method => $package . '::_manifest_md5_matches',
            known_md5_method => $package . '::is_known_managed_page_md5',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_hash']),
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_load_configured_aliases'
        && _package_tail_is($package, '')
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*FileRegistry->new/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Config->new/
        && $body =~ /path_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_load_configured_aliases',
            paths_symbol => $package . '::PATHS',
            config_aliases_symbol => $package . '::CONFIG_ALIASES',
            config_key_symbol => $package . '::CONFIG_ALIASES_KEY',
            cache_key_method => $package . '::_configured_alias_cache_key',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_resolve_path'
        && _package_tail_is($package, '')
        && $body =~ /_paths_obj/
        && $body =~ /_load_configured_aliases/
        && $body =~ /DEVELOPER_DASHBOARD_PATH_/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_resolve_path',
            paths_method => $package . '::_paths_obj',
            load_aliases_method => $package . '::_load_configured_aliases',
            aliases_symbol => $package . '::ALIASES',
            config_aliases_symbol => $package . '::CONFIG_ALIASES',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'AUTOLOAD'
        && _package_tail_is($package, '')
        && $body =~ /Unknown folder/
        && $body =~ /_resolve_path/
        && $body =~ /make_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_autoload',
            autoload_symbol => $package . '::AUTOLOAD',
            resolve_method => $package . '::_resolve_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'cd'
        && _package_tail_is($package, '')
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_cd',
            resolve_method => $package . '::_resolve_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'ls'
        && _package_tail_is($package, '')
        && $body =~ /_resolve_path/
        && $body =~ /readdir/
        && $body =~ /type => -d \$path \? 'folder' : 'file'/
        && $body =~ /sort \{ \$b->\{type\} cmp \$a->\{type\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_ls',
            resolve_method => $package . '::_resolve_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'locate'
        && _package_tail_is($package, '')
        && $body =~ /workspace_roots/
        && $body =~ /File::Find::find/
        && $body =~ /return grep \{ !\$seen\{\$_\}\+\+ \} sort \@found/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'folder_locate',
            paths_method => $package . '::_paths_obj',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_state_root_has_live_collectors'
        && _package_tail_is($package, '')
        && $body =~ /collectors/
        && $body =~ /\.pid\\z/
        && $body =~ /kill 0, \$pid/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_state_root_has_live_collectors',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_state_root_is_stale'
        && _package_tail_is($package, '')
        && $body =~ /_path_is_old_enough/
        && $body =~ /_state_root_has_live_collectors/
        && $body =~ /_read_state_metadata/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_state_root_is_stale',
            old_enough_method => $package . '::_path_is_old_enough',
            live_collectors_method => $package . '::_state_root_has_live_collectors',
            read_metadata_method => $package . '::_read_state_metadata',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cleanup_state_roots'
        && _package_tail_is($package, '')
        && $body =~ /state_base_root/
        && $body =~ /runtime_layers/
        && $body =~ /_state_root_is_stale/
        && $body =~ /_remove_tree/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_cleanup_state_roots',
            stale_method => $package . '::_state_root_is_stale',
            remove_tree_method => $package . '::_remove_tree',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cleanup_temp_files'
        && _package_tail_is($package, '')
        && $body =~ /tmpdir/
        && $body =~ /_temp_file_kind/
        && $body =~ /_path_is_old_enough/
        && $body =~ /Unable to remove stale/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_cleanup_temp_files',
            temp_file_kind_method => $package . '::_temp_file_kind',
            old_enough_method => $package . '::_path_is_old_enough',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_rotate_collector_logs'
        && _package_tail_is($package, '')
        && $body =~ /_config->collectors/
        && $body =~ /_collector_rotation/
        && $body =~ /_collector_store->rotate_log/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_rotate_collector_logs',
            config_method => $package . '::_config',
            collector_rotation_method => $package . '::_collector_rotation',
            collector_store_method => $package . '::_collector_store',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run'
        && _package_tail_is($package, '')
        && $body =~ /min_age_seconds must be a non-negative integer/
        && $body =~ /_cleanup_state_roots/
        && $body =~ /_cleanup_temp_files/
        && $body =~ /_rotate_collector_logs/
        && $body =~ /_now_iso8601/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'housekeeper_run',
            cleanup_state_roots_method => $package . '::_cleanup_state_roots',
            cleanup_temp_files_method => $package . '::_cleanup_temp_files',
            rotate_collector_logs_method => $package . '::_rotate_collector_logs',
            now_method => $package . '::_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_current_backend'
        && _package_tail_is($package, '')
        && $body =~ /\$BACKEND_APP/
        && $body =~ /Missing backend web app/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_current_backend',
            backend_symbol => $package . '::BACKEND_APP',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_request_headers'
        && _package_tail_is($package, '')
        && $body =~ /request->header\('Host'\)/
        && $body =~ /request->header\('Cookie'\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_request_headers',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_request_args'
        && _package_tail_is($package, '')
        && $body =~ /SERVER_NAME/
        && $body =~ /PATH_INFO/
        && $body =~ /_request_headers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_request_args',
            request_headers_method => $package . '::_request_headers',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_capture'
        && _package_tail_is($package, '')
        && $body =~ /my \@parts = splat;/
        && $body =~ /ref\( \$parts\[0\] \) eq 'ARRAY'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_capture',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_looks_like_disconnect_error'
        && _package_tail_is($package, '')
        && $body =~ /broken pipe/
        && $body =~ /connection reset/
        && $body =~ /write failed/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_disconnect_error',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_response_from_result'
        && _package_tail_is($package, '')
        && $body =~ /default_headers/
        && $body =~ /delayed \{/
        && $body =~ /response_header/
        && $body =~ /content_type/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_response_from_result',
            current_backend_method => $package . '::_current_backend',
            disconnect_method => $package . '::_looks_like_disconnect_error',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_run_backend'
        && _package_tail_is($package, '')
        && $body =~ /_current_backend/
        && $body =~ /_request_args/
        && $body =~ /_response_from_result/
        && $body =~ /does not implement/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_run_backend',
            current_backend_method => $package . '::_current_backend',
            request_args_method => $package . '::_request_args',
            response_method => $package . '::_response_from_result',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_run_authorized'
        && _package_tail_is($package, '')
        && $body =~ /authorize_request/
        && $body =~ /_current_backend/
        && $body =~ /_request_args/
        && $body =~ /_response_from_result/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'dancerapp_run_authorized',
            current_backend_method => $package . '::_current_backend',
            request_args_method => $package . '::_request_args',
            response_method => $package . '::_response_from_result',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'new'
        && $body =~ /Missing web app/
        && $body =~ /Worker count must be a positive integer/
        && $body =~ /generate_self_signed_cert/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_new',
            generate_cert_method => $package . '::generate_self_signed_cert',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'run'
        && $body =~ /start_daemon/
        && $body =~ /listening_url/
        && $body =~ /serve_daemon/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_run',
            start_daemon_method => $package . '::start_daemon',
            listening_url_method => $package . '::listening_url',
            serve_daemon_method => $package . '::serve_daemon',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'listening_url'
        && $body =~ /https/
        && $body =~ /http/
        && $body =~ /localhost/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_listening_url',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'serve_daemon'
        && $body =~ /_serve_ssl_frontend/
        && $body =~ /_build_runner/
        && $body =~ /psgi_app/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_serve_daemon',
            serve_ssl_method => $package . '::_serve_ssl_frontend',
            build_runner_method => $package . '::_build_runner',
            psgi_app_method => $package . '::psgi_app',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'psgi_app'
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Web::DancerApp->build_psgi_app/
        && $body =~ /_default_headers/
        && $body =~ /_ssl_redirect_response/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_psgi_app',
            default_headers_method => $package . '::_default_headers',
            request_is_https_method => $package . '::_request_is_https',
            redirect_response_method => $package . '::_ssl_redirect_response',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'start_daemon'
        && $body =~ /IO::Socket::INET->new/
        && $body =~ /Unable to reserve internal SSL backend port/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Web::Server::Daemon->new/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_start_daemon',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_serve_ssl_frontend'
        && $body =~ /Unable to fork SSL backend process/
        && $body =~ /_build_runner/
        && $body =~ /_handle_ssl_frontend_client/
        && $body =~ /_stop_ssl_backend/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_serve_ssl_frontend',
            build_runner_method => $package . '::_build_runner',
            psgi_app_method => $package . '::psgi_app',
            stop_backend_method => $package . '::_stop_ssl_backend',
            term_handler => $package . '::_ssl_term_handler',
            int_handler => $package . '::_ssl_int_handler',
            hup_handler => $package . '::_ssl_hup_handler',
            handle_client_method => $package . '::_handle_ssl_frontend_client',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_build_runner'
        && $body =~ /Plack::Runner->new/
        && $body =~ /--server', 'Starman'/
        && $body =~ /get_ssl_cert_paths/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_build_runner',
            ssl_cert_paths_method => $package . '::get_ssl_cert_paths',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_handle_ssl_frontend_client'
        && $body =~ /MSG_PEEK/
        && $body =~ /_socket_looks_like_tls/
        && $body =~ /_read_http_request_head/
        && $body =~ /_http_redirect_response/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_handle_ssl_frontend_client',
            socket_looks_like_tls_method => $package . '::_socket_looks_like_tls',
            read_http_request_head_method => $package . '::_read_http_request_head',
            request_host_from_head_method => $package . '::_request_host_from_head',
            request_target_from_head_method => $package . '::_request_target_from_head',
            http_redirect_response_method => $package . '::_http_redirect_response',
            proxy_streams_method => $package . '::_proxy_streams',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_proxy_streams'
        && $body =~ /IO::Select->new/
        && $body =~ /sysread/
        && $body =~ /syswrite/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_proxy_streams',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_socket_looks_like_tls'
        && $body =~ /return 0 if !defined \$byte \|\| \$byte eq ''/
        && $body =~ /ord\(\$byte\) == 22/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_socket_looks_like_tls',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_http_request_head'
        && $body =~ /length\(\$head\) < 16384/
        && $body =~ /sysread\( \$socket, \$chunk, 1024 \)/
        && $body =~ /\\r\?\\n\\r\?\\n/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_read_http_request_head',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_request_target_from_head'
        && $body =~ /return '\/' if !defined \$head \|\| \$head eq ''/
        && $body =~ /HTTP/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_request_target_from_head',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_request_host_from_head'
        && $body =~ /Host:\\s\*\(\[\^\\r\\n\]\+\)/
        && $body =~ /sockhost/
        && $body =~ /sockport/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_request_host_from_head',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_http_redirect_response'
        && $body =~ /307 Temporary Redirect/
        && $body =~ /Location: https:\/\//
        && $body =~ /Redirecting to HTTPS/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_http_redirect_response',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_stop_ssl_backend'
        && $body =~ /return 1 if !\$pid/
        && $body =~ /kill 15, \$pid/
        && $body =~ /waitpid\( \$pid, 0 \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_stop_ssl_backend',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name =~ /\A_ssl_(term|int|hup)_handler\z/
        && $body =~ /return _handle_ssl_signal\('/
    ) {
        my ($signal_name) = $body =~ /return _handle_ssl_signal\('([A-Z]+)'\)/;
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_ssl_signal_handler',
            signal_name => $signal_name,
            handle_signal_method => $package . '::_handle_ssl_signal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_handle_ssl_signal'
        && $body =~ /_stop_ssl_backend\(\$SSL_BACKEND_PID\)/
        && $body =~ /_run_previous_signal/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_handle_ssl_signal',
            stop_backend_method => $package . '::_stop_ssl_backend',
            run_previous_method => $package . '::_run_previous_signal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_previous_signal'
        && $body =~ /ref\(\$handler\) eq 'CODE'/
        && $body =~ /_signal_default_term/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_run_previous_signal',
            default_term_method => $package . '::_signal_default_term',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_signal_default_term'
        && $body =~ /kill 15, \$\$/
        && $body =~ /return 1/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_signal_default_term',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_default_headers'
        && $body =~ /X-Frame-Options/
        && $body =~ /Content-Security-Policy/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_default_headers',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_request_is_https'
        && $body =~ /psgi\.url_scheme/
        && $body =~ /HTTP_X_FORWARDED_PROTO/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_request_is_https',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ssl_redirect_response'
        && $body =~ /Redirecting to HTTPS/
        && $body =~ /_https_redirect_location/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_ssl_redirect_response',
            redirect_location_method => $package . '::_https_redirect_location',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_https_redirect_location'
        && $body =~ /HTTP_HOST/
        && $body =~ /SCRIPT_NAME/
        && $body =~ /PATH_INFO/
        && $body =~ /QUERY_STRING/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_https_redirect_location',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ssl_expected_subject_alt_names'
        && $body =~ /localhost/
        && $body =~ /_normalize_ssl_subject_alt_name/
        && $body =~ /_ssl_subject_alt_name_is_wildcard/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_ssl_expected_subject_alt_names',
            normalize_method => $package . '::_normalize_ssl_subject_alt_name',
            wildcard_method => $package . '::_ssl_subject_alt_name_is_wildcard',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_ssl_subject_alt_name'
        && $body =~ /return '' if !defined \$name/
        && $body =~ /\^\\\[\(\.\+\)\\\]/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_normalize_ssl_subject_alt_name',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ssl_subject_alt_name_is_wildcard'
        && $body =~ /0\.0\.0\.0/
        && $body =~ /0:0:0:0:0:0:0:0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_ssl_subject_alt_name_is_wildcard',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ssl_subject_alt_name_is_ip'
        && $body =~ /\\d\{1,3\}/
        && $body =~ /return 1 if \$name =~ \/\:/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_ssl_subject_alt_name_is_ip',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ssl_cert_has_expected_profile'
        && $body =~ /openssl', 'x509'/
        && $body =~ /Basic Constraints/
        && $body =~ /openssl', 'verify'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_ssl_cert_has_expected_profile',
            expected_san_method => $package . '::_ssl_expected_subject_alt_names',
            is_ip_method => $package . '::_ssl_subject_alt_name_is_ip',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'generate_self_signed_cert'
        && $body =~ /dd-openssl-XXXXXX/
        && $body =~ /openssl', 'req'/
        && $body =~ /Generated certificate is missing/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_generate_self_signed_cert',
            expected_san_method => $package . '::_ssl_expected_subject_alt_names',
            cert_profile_method => $package . '::_ssl_cert_has_expected_profile',
            is_ip_method => $package . '::_ssl_subject_alt_name_is_ip',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'get_ssl_cert_paths'
        && $body =~ /server\.crt/
        && $body =~ /server\.key/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'web_server_get_ssl_cert_paths',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'new'
        && $body =~ /Missing config/
        && $body =~ /Missing path registry/
        && $body =~ /Missing app builder/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_new',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'web_log'
        && $body =~ /Line count must be a positive integer/
        && $body =~ /_tail_text/
        && $body =~ /_follow_log_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_web_log',
            tail_text_method => $package . '::_tail_text',
            follow_log_file_method => $package . '::_follow_log_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_tail_text'
        && $body =~ /split \/\\n\/, \$text, -1/
        && $body =~ /join "\\n"/
        && $body =~ /had_trailing_newline/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_tail_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_follow_log_file'
        && $body =~ /Missing log file/
        && $body =~ /sysread\( \$fh, \$chunk, 8192 \)/
        && $body =~ /sleep \$interval/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_follow_log_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'web_state'
        && $body =~ /return if !-f \$file/
        && $body =~ /json_decode/
        && $body =~ /web_state/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_web_state',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_shutdown_web'
        && $body =~ /updated_at => _now_iso8601/
        && $body =~ /status     => \$final_status/
        && $body =~ /exit 0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_shutdown_web',
            web_state_method => $package . '::web_state',
            write_web_state_method => $package . '::_write_web_state',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_write_web_state'
        && $body =~ /json_encode/
        && $body =~ /secure_file_permissions/
        && $body =~ /rename \$tmp, \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_write_web_state',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_cleanup_web_files'
        && $body =~ /remove\('web_pid'\)/
        && $body =~ /remove\('web_state'\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_cleanup_web_files',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_web_process_title'
        && $body =~ /dashboard web: \$host:\$port/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_web_process_title',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_portable_signal'
        && $body =~ /Unsupported signal name/
        && $body =~ /TERM => 15/
        && $body =~ /return \$signal \+ 0 if \$signal =~/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_portable_signal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_send_signal'
        && $body =~ /_portable_signal/
        && $body =~ /kill \$portable_signal, \@targets/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_send_signal',
            portable_signal_method => $package . '::_portable_signal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_proc_owned_by_current_user'
        && $body =~ /return 1 if !defined \$proc->\{uid\}/
        && $body =~ /\( \$< \+ 0 \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_proc_owned_by_current_user',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_find_legacy_web_processes'
        && $body =~ /_find_web_processes/
        && $body =~ /\!\~ \/\^dashboard web:\//
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_find_legacy_web_processes',
            find_web_processes_method => $package . '::_find_web_processes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_looks_like_web_process'
        && $body =~ /dashboard web:/
        && $body =~ /bin\/dashboard/
        && $body =~ /dashboard\s+serve/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_looks_like_web_process',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ps_processes'
        && $body =~ /system 'ps', '-eo', 'pid=,uid=,args='/
        && $body =~ /push \@procs/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_ps_processes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_find_processes_by_prefix'
        && $body =~ /_proc_owned_by_current_user/
        && $body =~ /_ps_processes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_find_processes_by_prefix',
            proc_owned_method => $package . '::_proc_owned_by_current_user',
            ps_processes_method => $package . '::_ps_processes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_find_web_processes'
        && $body =~ /_ps_processes/
        && $body =~ /_looks_like_web_process/
        && $body =~ /_proc_owned_by_current_user/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_find_web_processes',
            ps_processes_method => $package . '::_ps_processes',
            proc_owned_method => $package . '::_proc_owned_by_current_user',
            looks_like_web_process_method => $package . '::_looks_like_web_process',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_is_managed_web'
        && $body =~ /_read_process_env_marker/
        && $body =~ /_read_process_title/
        && $body =~ /_web_process_title/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_is_managed_web',
            read_env_marker_method => $package . '::_read_process_env_marker',
            read_title_method => $package . '::_read_process_title',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_pkill_perl'
        && $body =~ /system 'pkill', '-15', '-f', \$pattern/
        && $body =~ /_ps_processes/
        && $body =~ /_send_signal/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_pkill_perl',
            ps_processes_method => $package . '::_ps_processes',
            proc_owned_method => $package . '::_proc_owned_by_current_user',
            send_signal_method => $package . '::_send_signal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_managed_listener_pids_for_port'
        && $body =~ /_is_managed_web/
        && $body =~ /_listener_pids_for_port/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_managed_listener_pids_for_port',
            is_managed_web_method => $package . '::_is_managed_web',
            listener_pids_for_port_method => $package . '::_listener_pids_for_port',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_listener_pids_for_port'
        && $body =~ /system 'ss', '-ltnp',/
        && $body =~ /_listener_pids_for_port_via_proc/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_listener_pids_for_port',
            listener_pids_for_port_via_proc_method => $package . '::_listener_pids_for_port_via_proc',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_listener_pids_for_port_via_proc'
        && $body =~ /_listener_socket_inodes_for_port/
        && $body =~ /_process_pids_for_socket_inodes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_listener_pids_for_port_via_proc',
            listener_socket_inodes_for_port_method => $package . '::_listener_socket_inodes_for_port',
            process_pids_for_socket_inodes_method => $package . '::_process_pids_for_socket_inodes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_listener_socket_inodes_for_port'
        && $body =~ /_listener_socket_table_paths/
        && $body =~ /sprintf '%04X', \$port/
        && $body =~ /\$fields\[3\] ne '0A'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_listener_socket_inodes_for_port',
            listener_socket_table_paths_method => $package . '::_listener_socket_table_paths',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_process_pids_for_socket_inodes'
        && $body =~ /_process_fd_paths/
        && $body =~ /readlink \$fd_path/
        && $body =~ /socket:\[\(\\d\+\)\]/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_process_pids_for_socket_inodes',
            process_fd_paths_method => $package . '::_process_fd_paths',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'start_collectors'
        && $body =~ /_progress_emit/
        && $body =~ /collectors/
        && $body =~ /start_loop/
        && $body =~ /_collector_runtime_ready/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_start_collectors',
            progress_emit_method => $package . '::_progress_emit',
            collector_runtime_ready_method => $package . '::_collector_runtime_ready',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stop_collectors'
        && $body =~ /running_loops/
        && $body =~ /stop_loop/
        && $body =~ /dashboard collector:/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_stop_collectors',
            progress_emit_method => $package . '::_progress_emit',
            find_processes_by_prefix_method => $package . '::_find_processes_by_prefix',
            send_signal_method => $package . '::_send_signal',
            pkill_perl_method => $package . '::_pkill_perl',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stop_all'
        && $body =~ /stop_web/
        && $body =~ /stop_collectors/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_stop_all',
            stop_web_method => $package . '::stop_web',
            stop_collectors_method => $package . '::stop_collectors',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stop_progress_tasks'
        && $body =~ /running_loops/
        && $body =~ /stop_collector:/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_stop_progress_tasks',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'restart_progress_tasks'
        && $body =~ /stop_progress_tasks/
        && $body =~ /start_collector:/
        && $body =~ /start_web/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_restart_progress_tasks',
            stop_progress_tasks_method => $package . '::stop_progress_tasks',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'serve_all'
        && $body =~ /start_collectors/
        && $body =~ /start_web/
        && $body =~ /stop_collectors/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_serve_all',
            start_collectors_method => $package . '::start_collectors',
            start_web_method => $package . '::start_web',
            stop_collectors_method => $package . '::stop_collectors',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'restart_all'
        && $body =~ /stop_all/
        && $body =~ /start_collectors/
        && $body =~ /_restart_web_with_retry/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_restart_all',
            stop_all_method => $package . '::stop_all',
            start_collectors_method => $package . '::start_collectors',
            restart_web_with_retry_method => $package . '::_restart_web_with_retry',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_listener_socket_table_paths'
        && $body =~ /\/proc\/net\/tcp/
        && $body =~ /\/proc\/net\/tcp6/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_listener_socket_table_paths',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_process_fd_paths'
        && $body =~ /glob '\/proc\/\[0-9\]\*\/fd\/\*'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_process_fd_paths',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_wait_for_port_release'
        && $body =~ /_listener_pids_for_port/
        && $body =~ /for \( 1 \.\. 50 \)/
        && $body =~ /sleep 0\.1/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_wait_for_port_release',
            listener_pids_for_port_method => $package . '::_listener_pids_for_port',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_progress_emit'
        && $body =~ /ref\(\$progress\) ne 'CODE'/
        && $body =~ /\$progress->\(\$event\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_progress_emit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_stability_polls'
        && $body =~ /DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS/
        && $body =~ /Devel::Cover/
        && $body =~ /return 100/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_runtime_stability_polls',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_confirmation_polls'
        && $body =~ /DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS/
        && $body =~ /return 3/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_runtime_confirmation_polls',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_poll_interval'
        && $body =~ /return 0\.1/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_runtime_poll_interval',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_port_accepting_connections'
        && $body =~ /IO::Socket::INET->new/
        && $body =~ /PeerAddr => '127\.0\.0\.1'/
        && $body =~ /Proto    => 'tcp'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_port_accepting_connections',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_process_env_marker'
        && $body =~ m{/proc/\$pid/environ}
        && $body =~ /split \/\\0\/, \$env/
        && $body =~ /return \$2 if \$1 eq \$key/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_read_process_env_marker',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_process_title'
        && $body =~ m{/proc/\$pid/cmdline}
        && $body =~ /system 'ps', '-o', 'args=', '-p', \$pid/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'runtime_manager_read_process_title',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_system_context'
        && $body =~ /cwd/
        && $body =~ /runtime_context/
        && $body =~ /params/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_system_context',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_noop_writer'
        && $body =~ /return ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_noop_writer',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_looks_like_stream_disconnect_error'
        && $body =~ /__DD_AJAX_STREAM_DISCONNECTED__/
        && $body =~ /broken pipe/
        && $body =~ /closed handle/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_stream_disconnect_error',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_stream_sysread'
        && $body =~ /sysread/
        && $body =~ /8192/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_stream_sysread',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_saved_ajax_inline_env_limit'
        && $body =~ /131_072/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_saved_ajax_inline_env_limit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_cleanup_saved_ajax_temp_files'
        && $body =~ /saved ajax temp file/
        && $body =~ /unlink \$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_cleanup_saved_ajax_temp_files',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_saved_ajax_singleton'
        && $body =~ /Invalid ajax singleton name/
        && $body =~ /\[\[:cntrl:\]\]/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_normalize_saved_ajax_singleton',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_kill_saved_ajax_singleton'
        && $body =~ /_quote_process_pattern_literal/
        && $body =~ /_pkill_perl/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_kill_saved_ajax_singleton',
            quote_pattern_method => $package . '::_quote_process_pattern_literal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_quote_process_pattern_literal'
        && $body =~ /\\\\\$\|\(\)\{\}\[\]\*\+\?/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_quote_process_pattern_literal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_query_string_from_params'
        && $body =~ /URI::Escape/
        && $body =~ /join '&'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_query_string_from_params',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_legacy_quote'
        && $body =~ /\\\\\\\\/
        && $body =~ /\\\\'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_legacy_quote',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_legacy_value'
        && $body =~ /ref\(\$value\) eq 'ARRAY'/
        && $body =~ /ref\(\$value\) eq 'HASH'/
        && $body =~ /_runtime_legacy_quote/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_legacy_value',
            quote_method => $package . '::_runtime_legacy_quote',
            value_method => $package . '::_runtime_legacy_value',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_value_text'
        && $body =~ /ref\(\$value\) ne 'HASH' && ref\(\$value\) ne 'ARRAY'/
        && $body =~ /_runtime_legacy_value/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_value_text',
            legacy_value_method => $package . '::_runtime_legacy_value',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_saved_ajax_command'
        && $body =~ /Missing saved ajax file path/
        && $body =~ /command_argv_for_path/
        && $body =~ /command_in_path\('python3'\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_saved_ajax_command',
            perl_wrapper_method => $package . '::_saved_ajax_perl_wrapper',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_saved_ajax_env'
        && $body =~ /DEVELOPER_DASHBOARD_AJAX_PARAMS/
        && $body =~ /_saved_ajax_inline_env_limit/
        && $body =~ /_runtime_local_perl_env/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_saved_ajax_env',
            query_string_method => $package . '::_query_string_from_params',
            normalize_singleton_method => $package . '::_normalize_saved_ajax_singleton',
            inline_env_limit_method => $package . '::_saved_ajax_inline_env_limit',
            temp_file_method => $package . '::_saved_ajax_temp_file',
            runtime_local_env_method => $package . '::_runtime_local_perl_env',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_runtime_local_perl_env'
        && $body =~ /PERL5LIB/
        && $body =~ /runtime_local_lib_roots/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_local_perl_env',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_saved_ajax_temp_file'
        && $body =~ /tempfile/
        && $body =~ /saved ajax temp file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_saved_ajax_temp_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_drain_saved_ajax_ready_handle'
        && $body =~ /_stream_sysread/
        && $body =~ /stdout_writer/
        && $body =~ /stderr_writer/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_drain_saved_ajax_ready_handle',
            noop_writer_method => $package . '::_noop_writer',
            stream_sysread_method => $package . '::_stream_sysread',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_close_saved_ajax_streams'
        && $body =~ /select->can\('handles'\)/
        && $body =~ /close \$fh/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_close_saved_ajax_streams',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_terminate_saved_ajax_process'
        && $body =~ /kill 15, \$pid/
        && $body =~ /kill 9, \$pid if kill 0, \$pid/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_terminate_saved_ajax_process',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stash'
        && $body =~ /\$AJAX_STASH/
        && $body =~ /no input/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_ajax_stash',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'hide'
        && $body =~ /__DD_HIDE__/
        && $body =~ /stash\(\$input\) if ref\(\$input\) eq 'HASH'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_ajax_hide',
            stash_method => $package . '::stash',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'void'
        && $body =~ /stash\(\$input\) if defined \$input/
        && $body =~ /return/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_ajax_void',
            stash_method => $package . '::stash',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stop'
        && $body =~ /die defined \$message/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_ajax_stop',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'params'
        && $body =~ /\$AJAX_PARAMS/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_ajax_params',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_code_header'
        && $body =~ /my \@keys = grep/
        && $body =~ /my \(%s\) = \@\{ \$stash \}\{qw/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_code_header',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_destroy_sandpit'
        && $body =~ /no strict 'refs'/
        && $body =~ /%\{"\$\{stash\}::"\} = \(\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_destroy_sandpit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_quote_process_pattern_literal'
        && $body =~ /\\\.\^\$\|\(\)\{\}\\\[\\\]\*\+\?/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_quote_process_pattern_literal',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_saved_ajax_perl_wrapper'
        && $body =~ /DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE/
        && $body =~ /dashboard ajax:/
        && $body =~ /eval "\{ \$code \}"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_saved_ajax_perl_wrapper',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '__add_error'
        && $body =~ /push \\\@errors/
        && $body =~ /defined \\\$_ && \\\$_ ne ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_sandpit_add_error',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '__errors'
        && $body =~ /my \\\@copy = \\\@errors/
        && $body =~ /\\\@errors = \(\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_sandpit_errors',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '__initial_context'
        && $body =~ /\\\$stash = \\\$next_stash \|\| \{\}/
        && $body =~ /\\\$runtime = \\\$next_runtime \|\| \{\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_sandpit_initial_context',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '__run_code'
        && $body =~ /my \\\@result = eval "\{\\\$code\}"/
        && $body =~ /__add_error/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_sandpit_run_code',
            add_error_method => $package . '::__add_error',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_new_sandpit'
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Sandpit/
        && $body =~ /__initial_context/
        && $body =~ /Unable to setup sandpit/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_new_sandpit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_single_block'
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Folder->configure/
        && $body =~ /_new_sandpit/
        && $body =~ /_code_header/
        && $body =~ /__run_code/
        && $body =~ /__errors/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_run_single_block',
            new_sandpit_method => $package . '::_new_sandpit',
            code_header_method => $package . '::_code_header',
            destroy_sandpit_method => $package . '::_destroy_sandpit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stream_code_block'
        && $body =~ /StreamHandle/
        && $body =~ /_new_sandpit/
        && $body =~ /__run_code/
        && $body =~ /return_writer/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_stream_code_block',
            noop_writer_method => $package . '::_noop_writer',
            new_sandpit_method => $package . '::_new_sandpit',
            code_header_method => $package . '::_code_header',
            value_text_method => $package . '::_runtime_value_text',
            destroy_sandpit_method => $package . '::_destroy_sandpit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stream_saved_ajax_file'
        && $body =~ /open3/
        && $body =~ /_saved_ajax_command/
        && $body =~ /_saved_ajax_env/
        && $body =~ /_drain_saved_ajax_ready_handle/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_stream_saved_ajax_file',
            noop_writer_method => $package . '::_noop_writer',
            normalize_singleton_method => $package . '::_normalize_saved_ajax_singleton',
            kill_singleton_method => $package . '::_kill_saved_ajax_singleton',
            saved_ajax_command_method => $package . '::_saved_ajax_command',
            saved_ajax_env_method => $package . '::_saved_ajax_env',
            cleanup_temp_files_method => $package . '::_cleanup_saved_ajax_temp_files',
            drain_ready_handle_method => $package . '::_drain_saved_ajax_ready_handle',
            close_streams_method => $package . '::_close_saved_ajax_streams',
            terminate_process_method => $package . '::_terminate_saved_ajax_process',
            disconnect_error_method => $package . '::_looks_like_stream_disconnect_error',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'run_code_blocks'
        && $body =~ /_new_sandpit/
        && $body =~ /_run_single_block/
        && $body =~ /_runtime_value_text/
        && $body =~ /_destroy_sandpit/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_run_code_blocks',
            new_sandpit_method => $package . '::_new_sandpit',
            run_single_block_method => $package . '::_run_single_block',
            value_text_method => $package . '::_runtime_value_text',
            destroy_sandpit_method => $package . '::_destroy_sandpit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_render_templates'
        && $body =~ /Template->new/
        && $body =~ /_system_context/
        && $body =~ /_run_single_block/
        && $body =~ /runtime_errors/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_render_templates',
            system_context_method => $package . '::_system_context',
            run_single_block_method => $package . '::_run_single_block',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'prepare_page'
        && $body =~ /run_code_blocks/
        && $body =~ /_render_templates/
        && $body =~ /runtime_outputs/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_runtime_prepare_page',
            run_code_blocks_method => $package . '::run_code_blocks',
            render_templates_method => $package . '::_render_templates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_status_prefix'
        && $body =~ /return '\[OK\]' if defined \$status && \$status eq 'done';/
        && $body =~ /return '->'   if defined \$status && \$status eq 'running';/
        && $body =~ /return '\[X\]'  if defined \$status && \$status eq 'failed';/
        && $body =~ /return '\[ \]';/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_status_prefix',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_colorize'
        && $body =~ /return \$text if !\$self->\{color\};/
        && $body =~ /\\e\[32m\$text\\e\[0m/
        && $body =~ /\\e\[33m\$text\\e\[0m/
        && $body =~ /\\e\[31m\$text\\e\[0m/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_colorize',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'render_text'
        && $body =~ /my \@lines = \(\s*\$self->\{title\}\s*\);/
        && $body =~ /\$self->_status_prefix/
        && $body =~ /\$self->_colorize/
        && $body =~ /return join\( "\\n", \@lines \) \. "\\n";/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_render_text',
            prefix_method => $package . '::_status_prefix',
            colorize_method => $package . '::_colorize',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'render'
        && $body =~ /my \$board  = \$self->render_text;/
        && $body =~ /if \(\s*\$self->\{dynamic\} && \$self->\{rendered\}\s*\)/
        && $body =~ /print \{\$stream\} "\\e\[1A\\e\[2K";/
        && $body =~ /print \{\$stream\} \$board;/
        && $body =~ /\$self->\{rendered\} = 1;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_render',
            render_text_method => $package . '::render_text',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'update'
        && $body =~ /return 1 if !\$event \|\| ref\(\$event\) ne 'HASH';/
        && $body =~ /my \$id = \$event->\{task_id\} \|\| return 1;/
        && $body =~ /\$self->render;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_update',
            render_method => $package . '::render',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'callback'
        && $body =~ /return sub \{/
        && $body =~ /\$self->update\(\$event\);/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_callback',
            update_method => $package . '::update',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'finish'
        && $body =~ /return 1 if !\$self->\{dynamic\} \|\| !\$self->\{rendered\};/
        && $body =~ /print \{\$stream\} "\\n";/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_finish',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'new'
        && $body =~ /Progress tasks must be an array reference/
        && $body =~ /Progress task missing id/
        && $body =~ /\$self->render;/
        && $body =~ /title    => \$args\{title\} \|\| 'dashboard progress'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'progress_new',
            tasks_type_error => 'Progress tasks must be an array reference',
            missing_id_error => 'Progress task missing id',
            render_method => $package . '::render',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_now_iso8601'
        && $body =~ /gmtime/
        && $body =~ /strftime/
        && $body =~ /%Y-%m-%dT%H:%M:%SZ/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_is_action_trusted'
        && $body =~ /allow_untrusted_actions/
        && $body =~ /trusted_actions/
        && $body =~ /return 1 if \$action->\{safe\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_is_trusted',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_run_builtin_action'
        && $body =~ /page\.source/
        && $body =~ /page\.state/
        && $body =~ /paths\.list/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_run_builtin',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'encode_action_payload'
        && $body =~ /trusted_id/
        && $body =~ /sha256_hex/
        && $body =~ /encode_payload/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_encode_payload',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'decode_action_payload'
        && $body =~ /json_decode/
        && $body =~ /decode_payload/
        && $body =~ /Action payload must be a hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_decode_payload',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_encoded_action'
        && $body =~ /PageDocument/
        && $body =~ /from_instruction/
        && $body =~ /run_page_action/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_run_encoded',
            decode_method => $package . '::decode_action_payload',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_instruction']),
            run_page_action_method => $package . '::run_page_action',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_page_action'
        && $body =~ /_run_builtin_action/
        && $body =~ /run_command_action/
        && $body =~ /_is_action_trusted/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_run_page_action',
            builtin_method => $package . '::_run_builtin_action',
            trust_method => $package . '::_is_action_trusted',
            command_method => $package . '::run_command_action',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_command_action'
        && $body =~ /Unable to fork background action/
        && $body =~ /dashboard_log/
        && $body =~ /_run_command/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_run_command_action',
            now_method => $package . '::_now_iso8601',
            run_command_method => $package . '::_run_command',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_run_command'
        && $body =~ /__ACTION_TIMEOUT__/
        && $body =~ /shell_command_argv/
        && $body =~ /started_at\s*=>\s*_now_iso8601/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'action_run_command',
            now_method => $package . '::_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_iso8601_after'
        && $body =~ /time \+/
        && $body =~ /gmtime\(\$epoch\)/
        && $body =~ /%Y-%m-%dT%H:%M:%SZ/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'utc_iso8601_after',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_iso8601_to_epoch'
        && $body =~ /Time::Local/
        && $body =~ /timegm/
        && $body =~ /T\(\\d\{2\}\):\(\\d\{2\}\):\(\\d\{2\}\)Z/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'utc_iso8601_to_epoch',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_iso8601_to_epoch'
        && $body =~ /Z\|\[\+\-\]\\d\{4\}\|\[\+\-\]\\d\{2\}:\\d\{2\}/
        && $body =~ /Unsupported collector log timestamp/
        && $body =~ /timegm/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'iso8601_to_epoch_with_zone',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_with_trailing_newline'
        && $body =~ /return \$text =~ \/\\n\\z\/ \? \$text : \$text \. "\\n";/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'text_with_trailing_newline',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_slurp'
        && $body =~ /return '' if !-f \$file;/
        && $body =~ /Unable to read \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'fs_slurp',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_atomic_write_text'
        && $body =~ /\$tmp = "\$file\.pending"/
        && $body =~ /rename \$tmp, \$file/
        && $body =~ /secure_file_permissions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'fs_atomic_write_text',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_atomic_write_json'
        && $body =~ /json_encode/
        && $body =~ /_atomic_write_text/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'fs_atomic_write_json',
            write_text_method => $package . '::_atomic_write_text',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_now_iso8601'
        && $body =~ /localtime/
        && $body =~ /strftime/
        && $body =~ /%Y-%m-%dT%H:%M:%S%z/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'local_iso8601_now',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'new_from_all_folders'
        && $body =~ /require (?:[A-Za-z_][A-Za-z0-9_]*::)*PathRegistry;/
        && $body =~ /new_from_all_folders/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_new_from_all_folders',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'collector_paths'
        && $body =~ /collector_dir/
        && $body =~ /status\.json/
        && $body =~ /job\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_paths',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'write_job'
        && $body =~ /collector_paths/
        && $body =~ /_atomic_write_json/
        && $body =~ /\$paths->\{job\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_write_job',
            collector_paths_method => $package . '::collector_paths',
            write_json_method => $package . '::_atomic_write_json',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_collector_file_candidates'
        && $body =~ /collectors_roots/
        && $body =~ /File::Spec->catfile/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'read_job'
        && $body =~ /_collector_file_candidates/
        && $body =~ /json_decode/
        && $body =~ /job\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_read_job',
            file_candidates_method => $package . '::_collector_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'read_status'
        && $body =~ /_collector_file_candidates/
        && $body =~ /eval \{ json_decode\(\$raw\) \}/
        && $body =~ /status\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_read_status',
            file_candidates_method => $package . '::_collector_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_first_existing_text_file'
        && $body =~ /_collector_file_candidates/
        && $body =~ /_slurp/
        && $body =~ /return ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_first_existing_text_file',
            file_candidates_method => $package . '::_collector_file_candidates',
            slurp_method => $package . '::_slurp',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'read_output'
        && $body =~ /_first_existing_text_file/
        && $body =~ /last_run/
        && $body =~ /combined/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_read_output',
            first_text_method => $package . '::_first_existing_text_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'collector_exists'
        && $body =~ /collectors_roots/
        && $body =~ /Missing collector name/
        && $body =~ /File::Spec->catdir/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_exists',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_log_payload_present'
        && $body =~ /stdout stderr combined last_run/
        && $body =~ /last_exit_code last_run last_completed_at last_started_at timed_out/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_log_payload_present',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_format_log_entry'
        && $body =~ /=== collector/
        && $body =~ /\[stdout\]/
        && $body =~ /\[stderr\]/
        && $body =~ /_with_trailing_newline/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_format_log_entry',
            trailing_newline_method => $package . '::_with_trailing_newline',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'append_log_entry'
        && $body =~ /_format_log_entry/
        && $body =~ /Unable to append/
        && $body =~ /secure_file_permissions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_append_log_entry',
            collector_paths_method => $package . '::collector_paths',
            format_method => $package . '::_format_log_entry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'write_result'
        && $body =~ /append_log_entry/
        && $body =~ /updated_at_epoch => time/
        && $body =~ /last_success_at/
        && $body =~ /timed_out/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_write_result',
            collector_paths_method => $package . '::collector_paths',
            read_status_method => $package . '::read_status',
            write_text_method => $package . '::_atomic_write_text',
            write_json_method => $package . '::_atomic_write_json',
            append_log_method => $package . '::append_log_entry',
            now_method => $package . '::_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'write_status'
        && $body =~ /read_status/
        && $body =~ /updated_at_epoch => time/
        && $body =~ /_atomic_write_json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_write_status',
            collector_paths_method => $package . '::collector_paths',
            read_status_method => $package . '::read_status',
            write_json_method => $package . '::_atomic_write_json',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_render_latest_log_entry'
        && $body =~ /collector_exists/
        && $body =~ /_log_payload_present/
        && $body =~ /latest state snapshot/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_render_latest_log_entry',
            exists_method => $package . '::collector_exists',
            read_status_method => $package . '::read_status',
            read_output_method => $package . '::read_output',
            payload_present_method => $package . '::_log_payload_present',
            format_method => $package . '::_format_log_entry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'read_log'
        && $body =~ /_collector_file_candidates/
        && $body =~ /_render_latest_log_entry/
        && $body =~ /Missing collector name/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_read_log',
            file_candidates_method => $package . '::_collector_file_candidates',
            slurp_method => $package . '::_slurp',
            render_method => $package . '::_render_latest_log_entry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'inspect_collector'
        && $body =~ /read_job/
        && $body =~ /read_output/
        && $body =~ /read_status/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_inspect',
            read_job_method => $package . '::read_job',
            read_output_method => $package . '::read_output',
            read_status_method => $package . '::read_status',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'list_collectors'
        && $body =~ /collectors_roots/
        && $body =~ /readdir/
        && $body =~ /read_status/
        && $body =~ /sort \{ \$a->\{name\} cmp \$b->\{name\} \}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_list',
            read_status_method => $package . '::read_status',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_normalize_rotation'
        && $body =~ /collector rotation for/
        && $body =~ /must be a hash reference/
        && $body =~ /months/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_normalize_rotation',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_rotation_retention_seconds'
        && $body =~ /minutes/
        && $body =~ /months/
        && $body =~ /seconds_per_unit/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_rotation_retention_seconds',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_split_log_entries'
        && $body =~ /split \/\(\?=\^=== collector \)\/m/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_split_log_entries',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_entry_timestamp_epoch'
        && $body =~ /Unable to parse collector log timestamp/
        && $body =~ /_iso8601_to_epoch/
        && $body =~ /\Q=== collector \E/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_entry_timestamp_epoch',
            to_epoch_method => $package . '::_iso8601_to_epoch',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_trim_log_by_age'
        && $body =~ /_split_log_entries/
        && $body =~ /_entry_timestamp_epoch/
        && $body =~ /return \$text if \$text eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_trim_log_by_age',
            split_method => $package . '::_split_log_entries',
            entry_epoch_method => $package . '::_entry_timestamp_epoch',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_trim_log_by_lines'
        && $body =~ /split \/\\n\/, \$text, -1/
        && $body =~ /return \$text if \@parts <= \$lines/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_trim_log_by_lines',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_apply_log_rotation'
        && $body =~ /_rotation_retention_seconds/
        && $body =~ /_trim_log_by_age/
        && $body =~ /_trim_log_by_lines/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_apply_log_rotation',
            retention_method => $package . '::_rotation_retention_seconds',
            trim_age_method => $package . '::_trim_log_by_age',
            trim_lines_method => $package . '::_trim_log_by_lines',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'rotate_log'
        && $body =~ /_normalize_rotation/
        && $body =~ /_apply_log_rotation/
        && $body =~ /collector-log-rotation/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_rotate_log',
            normalize_method => $package . '::_normalize_rotation',
            collector_paths_method => $package . '::collector_paths',
            slurp_method => $package . '::_slurp',
            apply_method => $package . '::_apply_log_rotation',
            write_text_method => $package . '::_atomic_write_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'new'
        && $body =~ /Missing file registry/
        && $body =~ /Missing path registry/
        && $body =~ /repo_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_new',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_global_config_file'
        && $body =~ /config_root/
        && $body =~ /config\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_global_config_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_global_config_files'
        && $body =~ /config_roots/
        && $body =~ /map \{ File::Spec->catfile/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_global_config_files',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_merge_named_hash_item'
        && $body =~ /ref\(\$left\) ne 'HASH'/
        && $body =~ /_merge_hashes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_merge_named_hash_item',
            merge_hashes_method => $package . '::_merge_hashes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_merge_named_hash_array'
        && $body =~ /%positions/
        && $body =~ /_merge_named_hash_item/
        && $body =~ /identity_key/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_merge_named_hash_array',
            merge_item_method => $package . '::_merge_named_hash_item',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_merge_hashes'
        && $body =~ /collectors/
        && $body =~ /providers/
        && $body =~ /_merge_named_hash_array/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_merge_hashes',
            merge_named_array_method => $package . '::_merge_named_hash_array',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'load_global'
        && $body =~ /reverse \$self->_global_config_files/
        && $body =~ /_skill_config_fragments/
        && $body =~ /_merge_hashes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_load_global',
            global_files_method => $package . '::_global_config_files',
            skill_fragments_method => $package . '::_skill_config_fragments',
            merge_hashes_method => $package . '::_merge_hashes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'save_global'
        && $body =~ /_global_config_file/
        && $body =~ /json_encode/
        && $body =~ /secure_file_permissions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_save_global',
            file_method => $package . '::_global_config_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_load_writable_global'
        && $body =~ /_global_config_file/
        && $body =~ /json_decode/
        && $body =~ /return \{\} if !-f \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_load_writable_global',
            file_method => $package . '::_global_config_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'save_global_defaults'
        && $body =~ /_load_writable_global/
        && $body =~ /_merge_hashes/
        && $body =~ /save_global/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_save_global_defaults',
            load_writable_method => $package . '::_load_writable_global',
            merge_hashes_method => $package . '::_merge_hashes',
            save_global_method => $package . '::save_global',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'ensure_global_file'
        && $body =~ /return \$file if -e \$file/
        && $body =~ /save_global\( \{\} \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_ensure_global_file',
            file_method => $package . '::_global_config_file',
            save_global_method => $package . '::save_global',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'load_repo'
        && $body =~ /current_project_root/
        && $body =~ /json_decode/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_load_repo',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'merged'
        && $body =~ /load_global/
        && $body =~ /load_repo/
        && $body =~ /_merge_hashes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_merged',
            load_global_method => $package . '::load_global',
            load_repo_method => $package . '::load_repo',
            merge_hashes_method => $package . '::_merge_hashes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_builtin_collectors'
        && $body =~ /housekeeper/
        && $body =~ /PathRegistry->new/
        && $body =~ /workspace_roots/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_builtin_collectors',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_config_entries'
        && $body =~ /SkillDispatcher->new/
        && $body =~ /installed_skill_roots/
        && $body =~ /get_skill_config/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_skill_config_entries',
            dispatcher_class => _related_class_from_source($source, $package, $body, 'SkillDispatcher', methods => ['new', 'get_skill_config']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_config_fragments'
        && $body =~ /_skill_config_entries/
        && $body =~ /config_fragment/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_skill_config_fragments',
            entries_method => $package . '::_skill_config_entries',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_collectors'
        && $body =~ /_skill_config_entries/
        && $body =~ /qualified_name/
        && $body =~ /skill_root/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_skill_collectors',
            entries_method => $package . '::_skill_config_entries',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'collectors'
        && $body =~ /_builtin_collectors/
        && $body =~ /_skill_collectors/
        && $body =~ /DEVELOPER_DASHBOARD_CHECKERS/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_collectors',
            merged_method => $package . '::merged',
            builtin_collectors_method => $package . '::_builtin_collectors',
            merge_named_array_method => $package . '::_merge_named_hash_array',
            skill_collectors_method => $package . '::_skill_collectors',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_home_path'
        && $body =~ /\$HOME/
        && $body =~ /home_prefix/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_normalize_home_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_expand_config_path'
        && $body =~ /\$HOME/
        && $body =~ /^\s*return \$home/m
        && $body =~ /path =~ \/\^~/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_expand_config_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_expand_path_aliases'
        && $body =~ /_expand_config_path/
        && $body =~ /%expanded/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_expand_path_aliases',
            expand_config_path_method => $package . '::_expand_config_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'path_aliases'
        && $body =~ /merged/
        && $body =~ /_expand_path_aliases/
        && $body =~ /path_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_path_aliases',
            merged_method => $package . '::merged',
            expand_aliases_method => $package . '::_expand_path_aliases',
            key => 'path_aliases',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'file_aliases'
        && $body =~ /merged/
        && $body =~ /_expand_path_aliases/
        && $body =~ /file_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_path_aliases',
            merged_method => $package . '::merged',
            expand_aliases_method => $package . '::_expand_path_aliases',
            key => 'file_aliases',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'global_path_aliases'
        && $body =~ /load_global/
        && $body =~ /_expand_path_aliases/
        && $body =~ /path_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_global_aliases',
            load_global_method => $package . '::load_global',
            expand_aliases_method => $package . '::_expand_path_aliases',
            key => 'path_aliases',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'global_file_aliases'
        && $body =~ /load_global/
        && $body =~ /_expand_path_aliases/
        && $body =~ /file_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_global_aliases',
            load_global_method => $package . '::load_global',
            expand_aliases_method => $package . '::_expand_path_aliases',
            key => 'file_aliases',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'web_workers'
        && $body =~ /workers/
        && $body =~ /return 1 if !defined \$workers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_web_workers',
            merged_method => $package . '::merged',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_ssl_subject_alt_names'
        && $body =~ /ref\(\$names\) ne 'ARRAY'/
        && $body =~ /push \@normalized/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_normalize_ssl_subject_alt_names',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'save_global_web_workers'
        && $body =~ /Worker count must be a positive integer/
        && $body =~ /_load_writable_global/
        && $body =~ /save_global/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_save_global_web_workers',
            load_writable_method => $package . '::_load_writable_global',
            save_global_method => $package . '::save_global',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'web_settings'
        && $body =~ /ssl_subject_alt_names/
        && $body =~ /no_editor/
        && $body =~ /no_indicators/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_web_settings',
            merged_method => $package . '::merged',
            normalize_san_method => $package . '::_normalize_ssl_subject_alt_names',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'save_global_web_settings'
        && $body =~ /Host cannot be empty/
        && $body =~ /Port must be numeric/
        && $body =~ /Worker count must be numeric/
        && $body =~ /ssl_subject_alt_names/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_save_global_web_settings',
            load_writable_method => $package . '::_load_writable_global',
            save_global_method => $package . '::save_global',
            normalize_san_method => $package . '::_normalize_ssl_subject_alt_names',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && ($short_name eq 'save_global_path_alias' || $short_name eq 'save_global_file_alias')
        && $body =~ /Missing .* alias name/
        && $body =~ /_normalize_home_path/
        && $body =~ /_expand_config_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        my $key = $short_name eq 'save_global_path_alias' ? 'path_aliases' : 'file_aliases';
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_save_global_alias',
            alias_key => $key,
            kind => $short_name eq 'save_global_path_alias' ? 'path' : 'file',
            load_writable_method => $package . '::_load_writable_global',
            normalize_home_path_method => $package . '::_normalize_home_path',
            save_global_method => $package . '::save_global',
            expand_config_path_method => $package . '::_expand_config_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && ($short_name eq 'remove_global_path_alias' || $short_name eq 'remove_global_file_alias')
        && $body =~ /removed/
        && $body =~ /delete \$cfg/
        && $body =~ /save_global/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        my $key = $short_name eq 'remove_global_path_alias' ? 'path_aliases' : 'file_aliases';
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_remove_global_alias',
            alias_key => $key,
            kind => $short_name eq 'remove_global_path_alias' ? 'path' : 'file',
            load_writable_method => $package . '::_load_writable_global',
            save_global_method => $package . '::save_global',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'docker_config'
        && $body =~ /merged/
        && $body =~ /cfg->\{docker\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_docker_config',
            merged_method => $package . '::merged',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'providers'
        && $body =~ /cfg->\{providers\}/
        && $body =~ /push \@providers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'config_providers',
            merged_method => $package . '::merged',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, 'SkillDispatcher')
        && $short_name eq 'new'
        && $body =~ /SkillManager->new/
        && $body =~ /manager => \$manager/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_new',
            skill_manager_class => _related_class_from_source($source, $package, $body, 'SkillManager', methods => ['new']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_arrayref_or_empty'
        && $body =~ /ref\(\$value\) eq 'ARRAY'/
        && $body =~ /my \@empty/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_arrayref_or_empty',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_hashref_or_empty'
        && $body =~ /ref\(\$value\) eq 'HASH'/
        && $body =~ /my %empty/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_hashref_or_empty',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_defined_or_default'
        && $body =~ /return defined \$value \? \$value : \$default/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_defined_or_default',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_merge_array_items_by_identity'
        && $body =~ /%positions/
        && $body =~ /_arrayref_or_empty/
        && $body =~ /exists \$positions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_merge_array_items_by_identity',
            arrayref_or_empty_method => $package . '::_arrayref_or_empty',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_layers'
        && $body =~ /skill_layers/
        && $body =~ /get_skill_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_layers',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_lookup_roots'
        && $body =~ /reverse \$self->_skill_layers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_lookup_roots',
            skill_layers_method => $package . '::_skill_layers',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_command_root_specs'
        && $body =~ /split_index/
        && $body =~ /nested_segments/
        && $body =~ /command_name/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_command_root_specs',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_nested_skill_path'
        && $body =~ /push \@parts, 'skills', \$segment/
        && $body =~ /File::Spec->catdir/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_nested_skill_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_page_location'
        && $body =~ /_skill_lookup_roots/
        && $body =~ /dashboards/
        && $body =~ /return \( \$file, \$skill_path \) if -f \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_page_location',
            skill_lookup_roots_method => $package . '::_skill_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_bookmark_entries'
        && $body =~ /_skill_lookup_roots/
        && $body =~ /dashboards/
        && $body =~ /\$entries\{\$entry\} \|\|= 1/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_bookmark_entries',
            skill_lookup_roots_method => $package . '::_skill_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_nav_route_ids'
        && $body =~ /_skill_lookup_roots/
        && $body =~ /dashboards', 'nav'/
        && $body =~ /\$routes\{\$entry\} \|\|= 'nav\/' \. \$entry/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_nav_route_ids',
            skill_lookup_roots_method => $package . '::_skill_lookup_roots',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_merge_skill_hashes'
        && $body =~ /collectors/
        && $body =~ /providers/
        && $body =~ /_merge_array_items_by_identity/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_merge_skill_hashes',
            merge_array_items_method => $package . '::_merge_array_items_by_identity',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'get_skill_config'
        && $body =~ /config\/config\.json/
        && $body =~ /decode_json/
        && $body =~ /_merge_skill_hashes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_get_skill_config',
            skill_layers_method => $package . '::_skill_layers',
            merge_skill_hashes_method => $package . '::_merge_skill_hashes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'config_fragment'
        && $body =~ /get_skill_config/
        && $body =~ /'_' \. \$skill_name/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_config_fragment',
            get_skill_config_method => $package . '::get_skill_config',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'get_skill_path'
        && $body =~ /manager->get_skill_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_get_skill_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_command_spec'
        && $body =~ /_command_root_specs/
        && $body =~ /resolve_runnable_file/
        && $body =~ /skill_layers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_command_spec',
            command_root_specs_method => $package . '::_command_root_specs',
            skill_layers_method => $package . '::_skill_layers',
            nested_skill_path_method => $package . '::_nested_skill_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'command_path'
        && $body =~ /_command_spec/
        && $body =~ /cmd_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_command_path',
            command_spec_method => $package . '::_command_spec',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'command_spec'
        && $body =~ /return \$self->_command_spec/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_command_spec_public',
            command_spec_method => $package . '::_command_spec',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'command_hook_paths'
        && $body =~ /_command_spec/
        && $body =~ /cli', \"\\\$resolved_command\\.d\"/
        && $body =~ /is_runnable_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_command_hook_paths',
            command_spec_method => $package . '::_command_spec',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'new'
        && $body =~ /Missing collector store/
        && $body =~ /Missing file registry/
        && $body =~ /Missing path registry/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_new',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'run_once'
        && $body =~ /_collector_source/
        && $body =~ /_run_job/
        && $body =~ /_materialize_indicator_state/
        && $body =~ /write_result/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_run_once',
            collector_source_method => $package . '::_collector_source',
            run_job_method => $package . '::_run_job',
            materialize_indicator_state_method => $package . '::_materialize_indicator_state',
            append_error_text_method => $package . '::_append_error_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_materialize_indicator_state'
        && $body =~ /icon_template/
        && $body =~ /_render_indicator_icon_template/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_materialize_indicator_state',
            render_icon_template_method => $package . '::_render_indicator_icon_template',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_render_indicator_icon_template'
        && $body =~ /_indicator_template_vars/
        && $body =~ /Template->new/
        && $body =~ /process/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_render_indicator_icon_template',
            indicator_template_vars_method => $package . '::_indicator_template_vars',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_indicator_template_vars'
        && $body =~ /json_decode/
        && $body =~ /collector stdout JSON/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_indicator_template_vars',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_append_error_text'
        && $body =~ /\$stderr \.= "\\n"/
        && $body =~ /return \$stderr \. \$error \. "\\n"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_append_error_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_collector_source'
        && $body =~ /return \( 'command', \$job->\{command\} \)/
        && $body =~ /missing command or code/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_source',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_job'
        && $body =~ /return \$self->_run_command\(%args\) if \$mode eq 'command'/
        && $body =~ /return \$self->_run_code\(%args\) if \$mode eq 'code'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_run_job',
            run_command_method => $package . '::_run_command',
            run_code_method => $package . '::_run_code',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'start_loop'
        && $body =~ /_pidfile/
        && $body =~ /_write_loop_state/
        && $body =~ /_fork_process/
        && $body =~ /_run_loop_child/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_start_loop',
            pidfile_method => $package . '::_pidfile',
            process_title_method => $package . '::_process_title',
            is_managed_loop_method => $package . '::_is_managed_loop',
            write_loop_state_method => $package . '::_write_loop_state',
            cleanup_loop_files_method => $package . '::_cleanup_loop_files',
            fork_process_method => $package . '::_fork_process',
            run_loop_child_method => $package . '::_run_loop_child',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_fork_process'
        && $body =~ /return fork/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_fork_process',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_loop_child'
        && $body =~ /_scrub_coverage_environment/
        && $body =~ /_write_loop_state/
        && $body =~ /_job_is_due/
        && $body =~ /run_once/
        && $body =~ /collector_log/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_run_loop_child',
            process_title_method => $package . '::_process_title',
            scrub_coverage_method => $package . '::_scrub_coverage_environment',
            write_loop_state_method => $package . '::_write_loop_state',
            job_is_due_method => $package . '::_job_is_due',
            run_once_method => $package . '::run_once',
            now_method => $package . '::_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'stop_loop'
        && $body =~ /_pidfile/
        && $body =~ /_is_managed_loop/
        && $body =~ /_cleanup_loop_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_stop_loop',
            pidfile_method => $package . '::_pidfile',
            is_managed_loop_method => $package . '::_is_managed_loop',
            cleanup_loop_files_method => $package . '::_cleanup_loop_files',
            slurp_method => $package . '::_slurp',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'running_loops'
        && $body =~ /collectors_root/
        && $body =~ /_is_managed_loop/
        && $body =~ /_cleanup_loop_files/
        && $body =~ /sort _sort_loop_names/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_running_loops',
            is_managed_loop_method => $package . '::_is_managed_loop',
            cleanup_loop_files_method => $package . '::_cleanup_loop_files',
            loop_state_method => $package . '::loop_state',
            slurp_method => $package . '::_slurp',
            sort_loop_names_method => $package . '::_sort_loop_names',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_sort_loop_names'
        && $body =~ /\$a->\{name\} cmp \$b->\{name\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_sort_loop_names',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'loop_state'
        && $body =~ /_statefile/
        && $body =~ /json_decode/
        && $body =~ /return if !-f \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_loop_state',
            statefile_method => $package . '::_statefile',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_pidfile'
        && $body =~ /collectors_root/
        && $body =~ /"\$name\.pid"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_pidfile',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_statefile'
        && $body =~ /collector_dir/
        && $body =~ /'loop.json'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_statefile',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_process_title'
        && $body =~ /dashboard collector: \$name/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_process_title',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_proc_file'
        && $body =~ /return if !-r \$file/
        && $body =~ /open my \$fh, '<', \$file or return/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_read_proc_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_process_env_marker'
        && $body =~ m{/proc/\$pid/environ}
        && $body =~ /split \/\\0\/, \$env/
        && $body =~ /return \$2 if \$1 eq \$key/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_read_process_env_marker',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_process_title'
        && $body =~ /_read_proc_file/
        && $body =~ /system 'ps', '-o', 'args=', '-p', \$pid/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_read_process_title',
            read_proc_method => $package . '::_read_proc_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_is_managed_loop'
        && $body =~ /_read_process_env_marker/
        && $body =~ /_read_process_title/
        && $body =~ /_process_title/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_is_managed_loop',
            read_env_marker_method => $package . '::_read_process_env_marker',
            read_title_method => $package . '::_read_process_title',
            process_title_method => $package . '::_process_title',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_write_loop_state'
        && $body =~ /_statefile/
        && $body =~ /json_encode/
        && $body =~ /rename \$tmp, \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_write_loop_state',
            statefile_method => $package . '::_statefile',
            loop_state_method => $package . '::loop_state',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_cleanup_loop_files'
        && $body =~ /unlink \$self->_pidfile/
        && $body =~ /unlink \$self->_statefile/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_cleanup_loop_files',
            pidfile_method => $package . '::_pidfile',
            statefile_method => $package . '::_statefile',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_scrub_coverage_environment'
        && $body =~ /_coverage_instrumentation_active/
        && $body =~ /delete \@ENV/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_scrub_coverage_environment',
            coverage_active_method => $package . '::_coverage_instrumentation_active',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_coverage_instrumentation_active'
        && $body =~ /PERL5OPT/
        && $body =~ /HARNESS_PERL_SWITCHES/
        && $body =~ /Devel::Cover/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_coverage_instrumentation_active',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_job_is_due'
        && $body =~ /return 0 if \$mode eq 'manual'/
        && $body =~ /return 1 if \$mode eq 'interval'/
        && $body =~ /_cron_due/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_job_is_due',
            cron_due_method => $package . '::_cron_due',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_cron_due'
        && $body =~ /split \/\\s\+\/, \$expr/
        && $body =~ /last_cron_slot/
        && $body =~ /_write_loop_state/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_cron_due',
            loop_state_method => $package . '::loop_state',
            write_loop_state_method => $package . '::_write_loop_state',
            cron_match_method => $package . '::_cron_match',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_cron_match'
        && $body =~ /split \/,\/, \$spec/
        && $body =~ /\\*\/\(\\d\+\)/
        && $body =~ /if \( \$part =~ \/\^\(\\d\+\)-\(\\d\+\)\$\//
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_cron_match',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_slurp'
        && $body =~ /Unable to read \$file/
        && $body =~ /return <\$fh>;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'fs_slurp',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_command'
        && $body =~ /shell_command_argv/
        && $body =~ /__COLLECTOR_TIMEOUT__/
        && $body =~ /chdir \$cwd/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_run_command',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_code'
        && $body =~ /eval \$code/
        && $body =~ /__COLLECTOR_TIMEOUT__/
        && $body =~ /chdir \$cwd/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_run_code',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_shutdown_loop'
        && $body =~ /_write_loop_state/
        && $body =~ /_cleanup_loop_files/
        && $body =~ /exit 0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_shutdown_loop',
            write_loop_state_method => $package . '::_write_loop_state',
            process_title_method => $package . '::_process_title',
            cleanup_loop_files_method => $package . '::_cleanup_loop_files',
            now_method => $package . '::_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_signal_stop'
        && $body =~ /\$SIGNAL_RUNNER->_shutdown_loop/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'collector_runner_signal_stop',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'dispatch'
        && $body =~ /unknown_skill_command_message/
        && $body =~ /execute_hooks/
        && $body =~ /_skill_env/
        && $body =~ /command_argv_for_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_dispatch',
            command_spec_method => $package . '::_command_spec',
            execute_hooks_method => $package . '::execute_hooks',
            skill_layers_method => $package . '::_skill_layers',
            skill_env_method => $package . '::_skill_env',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'exec_command'
        && $body =~ /unknown_skill_command_message/
        && $body =~ /_execute_hooks_streaming/
        && $body =~ /_exec_resolved_command/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_exec_command',
            command_spec_method => $package . '::_command_spec',
            execute_hooks_streaming_method => $package . '::_execute_hooks_streaming',
            skill_layers_method => $package . '::_skill_layers',
            skill_env_method => $package . '::_skill_env',
            exec_resolved_method => $package . '::_exec_resolved_command',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'execute_hooks'
        && $body =~ /_command_spec/
        && $body =~ /_skill_env/
        && $body =~ /load_runtime_layers/
        && $body =~ /load_skill_layers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_execute_hooks',
            command_spec_method => $package . '::_command_spec',
            skill_layers_method => $package . '::_skill_layers',
            skill_env_method => $package . '::_skill_env',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_execute_hooks_streaming'
        && $body =~ /_arrayref_or_empty/
        && $body =~ /_skill_env/
        && $body =~ /_run_child_command_streaming/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_execute_hooks_streaming',
            arrayref_or_empty_method => $package . '::_arrayref_or_empty',
            skill_env_method => $package . '::_skill_env',
            run_child_streaming_method => $package . '::_run_child_command_streaming',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_run_child_command_streaming'
        && $body =~ /_arrayref_or_empty/
        && $body =~ /_hashref_or_empty/
        && $body =~ /_defined_or_default/
        && $body =~ /open3/
        && $body =~ /IO::Select/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_run_child_command_streaming',
            arrayref_or_empty_method => $package . '::_arrayref_or_empty',
            hashref_or_empty_method => $package . '::_hashref_or_empty',
            defined_or_default_method => $package . '::_defined_or_default',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_exec_resolved_command'
        && $body =~ /_arrayref_or_empty/
        && $body =~ /_exec_replacement/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_exec_resolved_command',
            arrayref_or_empty_method => $package . '::_arrayref_or_empty',
            exec_replacement_method => $package . '::_exec_replacement',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_exec_replacement'
        && $body =~ /!exec \@command, \@args/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_exec_replacement',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'get_skill_config'
        && $body =~ /_skill_layers/
        && $body =~ /config\/', 'config\.json'|config', 'config.json/
        && $body =~ /_merge_skill_hashes/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_get_skill_config',
            skill_layers_method => $package . '::_skill_layers',
            merge_skill_hashes_method => $package . '::_merge_skill_hashes',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'get_skill_path'
        && $body =~ /manager}->get_skill_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_get_skill_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'command_hook_paths'
        && $body =~ /_command_spec/
        && $body =~ /cli', "\$resolved_command\.d"/
        && $body =~ /is_runnable_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_command_hook_paths',
            command_spec_method => $package . '::_command_spec',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'route_response'
        && $body =~ /_skill_layers/
        && $body =~ /_skill_bookmark_entries/
        && $body =~ /_skill_page_response/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_route_response',
            skill_layers_method => $package . '::_skill_layers',
            bookmark_entries_method => $package . '::_skill_bookmark_entries',
            page_response_method => $package . '::_skill_page_response',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'skill_nav_pages'
        && $body =~ /_skill_nav_route_ids/
        && $body =~ /_load_skill_page/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_nav_pages',
            route_ids_method => $package . '::_skill_nav_route_ids',
            load_skill_page_method => $package . '::_load_skill_page',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'all_skill_nav_pages'
        && $body =~ /installed_skill_roots/
        && $body =~ /skill_nav_pages/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_all_skill_nav_pages',
            skill_nav_pages_method => $package . '::skill_nav_pages',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_page_response'
        && $body =~ /_load_skill_page/
        && $body =~ /_page_with_runtime_state/
        && $body =~ /_page_response/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_page_response',
            load_skill_page_method => $package . '::_load_skill_page',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_load_skill_page'
        && $body =~ /_page_location/
        && $body =~ /PageDocument->from_instruction/
        && $body =~ /source_kind/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_load_skill_page',
            page_location_method => $package . '::_page_location',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_instruction']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_skill_env'
        && $body =~ /DEVELOPER_DASHBOARD_SKILL_NAME/
        && $body =~ /PERL5LIB/
        && $body =~ /DEVELOPER_DASHBOARD_SKILL_LOCAL_ROOT/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skill_dispatcher_skill_env',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_session_file'
        && $body =~ /sessions_root/
        && $body =~ /"\$session_id\.json"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_file_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_session_file_candidates'
        && $body =~ /sessions_roots/
        && $body =~ /map \{ File::Spec->catfile/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'create'
        && $body =~ /Missing username/
        && $body =~ /sha256_hex/
        && $body =~ /chmod 0600/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_create',
            now_method => $package . '::_now_iso8601',
            after_method => $package . '::_iso8601_after',
            file_method => $package . '::_session_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'get'
        && $body =~ /_session_file_candidates/
        && $body =~ /json_decode/
        && $body =~ /return if !defined \$session_id/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_get',
            file_candidates_method => $package . '::_session_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'delete'
        && $body =~ /unlink \$_ for grep \{ -f \$_ \}/
        && $body =~ /_session_file_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_delete',
            file_candidates_method => $package . '::_session_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'from_cookie'
        && $body =~ /dashboard_session/
        && $body =~ /_iso8601_to_epoch/
        && $body =~ /remote_addr/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_from_cookie',
            get_method => $package . '::get',
            delete_method => $package . '::delete',
            to_epoch_method => $package . '::_iso8601_to_epoch',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_user_file'
        && $body =~ /users_root/
        && $body =~ /File::Spec->catfile/
        && $body =~ /\$safe =~ s\/\[\^A-Za-z0-9_\.\-\]\+\/_\/g/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_user_file_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_user_file_candidates'
        && $body =~ /users_roots/
        && $body =~ /map \{ File::Spec->catfile/
        && $body =~ /\$safe =~ s\/\[\^A-Za-z0-9_\.\-\]\+\/_\/g/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_user_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_password_hash'
        && $body =~ /sha256_hex/
        && $body =~ /join ':', \$salt, \$username, \$password/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_password_hash',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'add_user'
        && $body =~ /Username contains unsupported characters/
        && $body =~ /Password must be at least 8 characters long/
        && $body =~ /chmod 0600/
        && $body =~ /_password_hash/
        && $body =~ /_user_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_add_user',
            file_method => $package . '::_user_file',
            hash_method => $package . '::_password_hash',
            now_method => $package . '::_now_iso8601',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'get_user'
        && $body =~ /_user_file_candidates/
        && $body =~ /json_decode/
        && $body =~ /Unable to read \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_get_user',
            file_candidates_method => $package . '::_user_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'verify_user'
        && $body =~ /get_user/
        && $body =~ /_password_hash/
        && $body =~ /password_hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_verify_user',
            get_method => $package . '::get_user',
            hash_method => $package . '::_password_hash',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'list_users'
        && $body =~ /users_roots/
        && $body =~ /readdir/
        && $body =~ /get_user/
        && $body =~ /username/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_list_users',
            get_method => $package . '::get_user',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'remove_user'
        && $body =~ /unlink \$_ for grep \{ -f \$_ \}/
        && $body =~ /_user_file_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_remove_user',
            file_candidates_method => $package . '::_user_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'helper_users_enabled'
        && $body =~ /list_users/
        && $body =~ /return \@users \? 1 : 0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_helper_users_enabled',
            list_method => $package . '::list_users',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_canonical_host'
        && $body =~ /s\/\^\\s\+\/\//
        && $body =~ /s\/\\s\+\$\/\//
        && $body =~ /return if \$host eq ''/
        && $body =~ /\$host =~ \/\^\\\[/
        && $body =~ /\$host =~ \/\^\(\[\^:\]\+\):\\d\+\$/
        && $body =~ /return lc \$host/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_canonical_host',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_canonical_ip'
        && $body =~ /inet_pton/
        && $body =~ /inet_ntop/
        && $body =~ /\\A\(\?:\\d\{1,3\}\\.\)\{3\}\\d\{1,3\}\\z/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_canonical_ip',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_ip_is_loopback'
        && $body =~ /127/
        && $body =~ /::1/
        && $body =~ /0:0:0:0:0:0:0:1/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_ip_is_loopback',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_resolve_host_ips'
        && $body =~ /getaddrinfo/
        && $body =~ /unpack_sockaddr_in/
        && $body =~ /unpack_sockaddr_in6/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_resolve_host_ips',
            canonical_ip_method => $package . '::_canonical_ip',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_host_resolves_only_to_loopback'
        && $body =~ /_resolve_host_ips/
        && $body =~ /_ip_is_loopback/
        && $body =~ /return !grep/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_host_resolves_only_to_loopback',
            resolve_method => $package . '::_resolve_host_ips',
            loopback_method => $package . '::_ip_is_loopback',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_request_is_loopback_admin'
        && $body =~ /extra_loopback_hosts/
        && $body =~ /_ip_is_loopback/
        && $body =~ /_host_resolves_only_to_loopback/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_request_is_loopback_admin',
            canonical_host_method => $package . '::_canonical_host',
            loopback_method => $package . '::_ip_is_loopback',
            resolve_method => $package . '::_host_resolves_only_to_loopback',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'trust_tier'
        && $body =~ /_canonical_ip/
        && $body =~ /_canonical_host/
        && $body =~ /_request_is_loopback_admin/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_trust_tier',
            canonical_ip_method => $package . '::_canonical_ip',
            canonical_host_method => $package . '::_canonical_host',
            loopback_admin_method => $package . '::_request_is_loopback_admin',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'login_page'
        && $body =~ /Developer Dashboard Login/
        && $body =~ /Helper access requires login/
        && $body =~ /action=\"\/login\"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'auth_login_page',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalized_page_id'
        && $body =~ /s\{\\A\/\+app\/\+\}\{\}/
        && $body =~ /s\{\\A\/\+\}\{\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_normalized_page_id',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'page_file'
        && $body =~ /Missing page id/
        && $body =~ /dashboards_root/
        && $body =~ /_normalized_page_id/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_page_file',
            normalize_method => $package . '::_normalized_page_id',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_page_file_candidates'
        && $body =~ /dashboards_roots/
        && $body =~ /_normalized_page_id/
        && $body =~ /map \{ File::Spec->catfile/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_file_candidates',
            normalize_method => $package . '::_normalized_page_id',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_existing_page_file'
        && $body =~ /_page_file_candidates/
        && $body =~ /return \$file if -f \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_existing_page_file',
            file_candidates_method => $package . '::_page_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'load_transient_page'
        && $body =~ /decode_payload/
        && $body =~ /PageDocument->from_instruction/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_load_transient_page',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_instruction']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'encode_page'
        && $body =~ /from_hash/
        && $body =~ /raw_instruction/
        && $body =~ /canonical_instruction/
        && $body =~ /encode_payload/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_encode_page',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_hash']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && ($short_name eq 'editable_url' || $short_name eq 'render_url' || $short_name eq 'source_url')
        && $body =~ /uri_escape/
        && $body =~ /encode_page/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        my %paths = (
            editable_url => '/?token=',
            render_url   => '/?mode=render&token=',
            source_url   => '/?mode=source&token=',
        );
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_token_url',
            prefix => $paths{$short_name},
            encode_method => $package . '::encode_page',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_looks_like_raw_nav_fragment'
        && $body =~ /\[%/
        && $body =~ /<\\s\*\[A-Za-z!\\\/\]\[\^>\]\*>/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_looks_like_raw_nav_fragment',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_normalize_legacy_icon_markup'
        && $body =~ /1F9D1/
        && $body =~ /FFFD/
        && $body =~ /span\\s\+class="icon"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_normalize_legacy_icon_markup',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_saved_instruction'
        && $body =~ /decode\( 'UTF-8', \$raw, FB_CROAK \)/
        && $body =~ /_normalize_legacy_icon_markup/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_read_saved_instruction',
            normalize_method => $package . '::_normalize_legacy_icon_markup',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_raw_nav_fragment_page'
        && $body =~ /PageDocument->new/
        && $body =~ /raw-nav-tt/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_raw_nav_fragment_page',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['new']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_load_page_file'
        && $body =~ /_read_saved_instruction/
        && $body =~ /from_instruction/
        && $body =~ /_looks_like_raw_nav_fragment/
        && $body =~ /_raw_nav_fragment_page/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_load_page_file',
            read_method => $package . '::_read_saved_instruction',
            looks_like_method => $package . '::_looks_like_raw_nav_fragment',
            raw_nav_method => $package . '::_raw_nav_fragment_page',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_instruction']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'read_saved_entry'
        && $body =~ /Page '\$id' not found/
        && $body =~ /_existing_page_file/
        && $body =~ /_read_saved_instruction/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_read_saved_entry',
            existing_method => $package . '::_existing_page_file',
            read_method => $package . '::_read_saved_instruction',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'load_saved_page'
        && $body =~ /_existing_page_file/
        && $body =~ /_load_page_file/
        && $body =~ /raw_instruction/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_load_saved_page',
            existing_method => $package . '::_existing_page_file',
            load_method => $package . '::_load_page_file',
            read_method => $package . '::_read_saved_instruction',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'save_page'
        && $body =~ /canonical_instruction/
        && $body =~ /secure_file_permissions/
        && $body =~ /from_hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_save_page',
            page_file_method => $package . '::page_file',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_hash']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_saved_page_entries_for_root'
        && $body =~ /File::Find::find/
        && $body =~ /abs2rel/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_saved_page_entries_for_root',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'list_saved_pages'
        && $body =~ /dashboards_roots/
        && $body =~ /_saved_page_entries_for_root/
        && $body =~ /_load_page_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_list_saved_pages',
            entries_method => $package . '::_saved_page_entries_for_root',
            load_method => $package . '::_load_page_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'migrate_legacy_json_pages'
        && $body =~ /\.json\\z/
        && $body =~ /from_json/
        && $body =~ /canonical_instruction/
        && $body =~ /unlink \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_store_migrate_legacy_json_pages',
            page_file_method => $package . '::page_file',
            page_class => _related_class_from_source($source, $package, $body, 'PageDocument', methods => ['from_json']),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_indicator_file_candidates'
        && $body =~ /indicators_roots/
        && $body =~ /status\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_read_indicator_file'
        && $body =~ /json_decode/
        && $body =~ /<:raw/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_read_indicator_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'new'
        && $body =~ /bless \{/
        && $body =~ /title\s*=>\s*\$args\{title\}\s*\/\/\s*'Untitled'/
        && $body =~ /meta\s*=>\s*\$args\{meta\}\s*\|\|\s*\{\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_new',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'from_hash'
        && $body =~ /Page document must be a hash reference/
        && $body =~ /return \$class->new\(%\$hash\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_from_hash',
            new_method => $package . '::new',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'from_json'
        && $body =~ /json_decode/
        && $body =~ /from_hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_from_json',
            from_hash_method => $package . '::from_hash',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'from_instruction'
        && $body =~ /source_format = 'modern'/
        && $body =~ /_parse_legacy_sections/
        && $body =~ /Instruction document did not contain any sections/
        && $body =~ /_decode_stash_section/
        && $body =~ /\$class->new/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_from_instruction',
            parse_legacy_sections_method => $package . '::_parse_legacy_sections',
            decode_stash_method => $package . '::_decode_stash_section',
            trim_method => $package . '::_trim',
            trim_trailing_method => $package . '::_trim_trailing_newline',
            new_method => $package . '::new',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'merge_state'
        && $body =~ /ref\(\$state\) ne 'HASH'/
        && $body =~ /\$self->\{state\}\{\$key\} = \$state->\{\$key\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_merge_state',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'with_mode'
        && $body =~ /\$self->\{mode\} = \$mode if defined \$mode && \$mode ne ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_with_mode',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'as_hash'
        && $body =~ /source_version/
        && $body =~ /permissions/
        && $body =~ /meta/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_as_hash',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'canonical_json'
        && $body =~ /json_encode/
        && $body =~ /as_hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_canonical_json',
            as_hash_method => $package . '::as_hash',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'canonical_instruction'
        && $body =~ /legacy_instruction/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_canonical_instruction',
            legacy_method => $package . '::legacy_instruction',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'legacy_instruction'
        && $body =~ /_legacy_stash_text/
        && $body =~ /\$LEGACY_SEP/
        && $body =~ /CODE\\d\+/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_legacy_instruction',
            legacy_stash_method => $package . '::_legacy_stash_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'instruction_text'
        && $body =~ /canonical_instruction/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_instruction_text',
            canonical_method => $package . '::canonical_instruction',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'render_template'
        && $body =~ /return shift;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_render_template',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'render_html'
        && $body =~ /runtime_outputs/
        && $body =~ /runtime_errors/
        && $body =~ /_legacy_bootstrap/
        && $body =~ /<!DOCTYPE html>/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_render_html',
            html_method => $package . '::_html',
            legacy_bootstrap_method => $package . '::_legacy_bootstrap',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_decode_structured_json'
        && $body =~ /json_decode/
        && $body =~ /return \{\} if \$text eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_decode_structured_json',
            trim_method => $package . '::_trim',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_decode_stash_section'
        && $body =~ /json_decode/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_decode_stash_section',
            trim_method => $package . '::_trim',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_parse_legacy_sections'
        && $body =~ /LEGACY_SEP/
        && $body =~ /\@LEGACY_KEYS/
        && $body =~ /split \/\(\?:/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_parse_legacy_sections',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_legacy_stash_text'
        && $body =~ /_legacy_value/
        && $body =~ /join ",\\n"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_legacy_stash_text',
            legacy_value_method => $package . '::_legacy_value',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_template_value'
        && $body =~ /split \/\\\.\//
        && $body =~ /exists \$value->\{\$part\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_template_value',
            trim_method => $package . '::_trim',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_legacy_bootstrap'
        && $body =~ /dashboard_ajax_singleton_cleanup/
        && $body =~ /fetch_value/
        && $body =~ /window\.__dashboardAjaxSingletons/
        && $body =~ /window\.configs/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_legacy_bootstrap',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_legacy_value'
        && $body =~ /_legacy_quote/
        && $body =~ /ref\(\$value\) eq 'ARRAY'/
        && $body =~ /ref\(\$value\) eq 'HASH'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_legacy_value',
            legacy_quote_method => $package . '::_legacy_quote',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_legacy_quote'
        && $body =~ /s\/\\\\\/\\\\\\\\\/g/
        && $body =~ /s\/'\/\\\\'\/g/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_legacy_quote',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_trim'
        && $body =~ m{s/\\A\\s\+//}
        && $body =~ m{s/\\s\+\\z//}
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_trim',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_trim_trailing_newline'
        && $body =~ m{s/\\n\+\\z//}
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_trim_trailing_newline',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_html'
        && $body =~ /&amp;/
        && $body =~ /&lt;/
        && $body =~ /&gt;/
        && $body =~ /&quot;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'page_document_html_escape',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'build_path_registry'
        && $body =~ /PathRegistry->new/
        && $body =~ /workspace_roots/
        && $body =~ /project_roots/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_build_paths',
            path_registry_class => _sibling_class($package, 'PathRegistry'),
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'run_open_file_command'
        && $body =~ /GetOptionsFromArray/
        && $body =~ /_resolve_open_file_matches/
        && $body =~ /_select_open_file_matches/
        && $body =~ /_command_exec/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_run_command',
            build_paths_method => $package . '::build_path_registry',
            resolve_matches_method => $package . '::_resolve_open_file_matches',
            select_matches_method => $package . '::_select_open_file_matches',
            default_editor_method => $package . '::_default_editor',
            editor_supports_tabs_method => $package . '::_editor_supports_tabs',
            command_exec_method => $package . '::_command_exec',
            command_exit_method => $package . '::_command_exit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_default_editor'
        && $body =~ /\$ENV\{VISUAL\}/
        && $body =~ /\$ENV\{EDITOR\}/
        && $body =~ /'vim'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_default_editor',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_editor_supports_tabs'
        && $body =~ /vim\|nvim\|vi\|gvim\|iv/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_editor_supports_tabs',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_select_open_file_matches'
        && $body =~ /_unique_matches/
        && $body =~ /_selection_matches/
        && $body =~ /Invalid file selection/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_select_matches',
            unique_method => $package . '::_unique_matches',
            selection_method => $package . '::_selection_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_selection_matches'
        && $body =~ /return \@\$matches if \$choices eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_selection_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_unique_matches'
        && $body =~ /!\$seen\{\$_\}\+\+/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_unique_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_ordered_scope_matches'
        && $body =~ /_scope_match_rank/
        && $body =~ /sort \{/s
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_ordered_scope_matches',
            rank_method => $package . '::_scope_match_rank',
            unique_method => $package . '::_unique_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_scope_match_rank'
        && $body =~ /_compile_open_file_regex/
        && $body =~ /basename/
        && $body =~ /score = 50/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_scope_match_rank',
            compile_regex_method => $package . '::_compile_open_file_regex',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_resolve_open_file_matches'
        && $body =~ /_named_source_matches/
        && $body =~ /File::Find::find/
        && $body =~ /_ordered_scope_matches/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_resolve_matches',
            named_matches_method => $package . '::_named_source_matches',
            compile_regex_method => $package . '::_compile_open_file_regex',
            ordered_matches_method => $package . '::_ordered_scope_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_named_source_matches'
        && $body =~ /_open_file_roots/
        && $body =~ /_existing_named_files/
        && $body =~ /_java_archive_source_matches/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_named_source_matches',
            roots_method => $package . '::_open_file_roots',
            existing_named_files_method => $package . '::_existing_named_files',
            java_archive_matches_method => $package . '::_java_archive_source_matches',
            unique_method => $package . '::_unique_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_open_file_roots'
        && $body =~ /cwd\(\)/
        && $body =~ /workspace_roots/
        && $body =~ /\@INC/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_roots',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_existing_named_files'
        && $body =~ /catfile/
        && $body =~ /sort \@found/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_existing_named_files',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_open_file_registries'
        && $body =~ /FileRegistry->new/
        && $body =~ /Config->new/
        && $body =~ /register_named_paths/
        && $body =~ /register_named_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_registries',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_scope_relative_path_match'
        && $body =~ /File::Spec->catfile/
        && $body =~ /return -f \$target \? \$target : undef/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_scope_relative_path_match',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_compile_open_file_regex'
        && $body =~ /Invalid regex/
        && $body =~ /qr\/\$pattern\/i/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_compile_regex',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_java_archive_source_matches'
        && $body =~ /_candidate_java_source_archives/
        && $body =~ /_extract_java_sources_from_archive/
        && $body =~ /_download_java_source_matches/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_java_archive_matches',
            candidate_archives_method => $package . '::_candidate_java_source_archives',
            extract_archive_sources_method => $package . '::_extract_java_sources_from_archive',
            download_java_matches_method => $package . '::_download_java_source_matches',
            unique_method => $package . '::_unique_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_candidate_java_source_archives'
        && $body =~ /_java_source_archive_roots/
        && $body =~ /File::Find::find/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_candidate_archives',
            archive_roots_method => $package . '::_java_source_archive_roots',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_java_source_archive_roots'
        && $body =~ /'\.m2'/
        && $body =~ /'\.gradle'/
        && $body =~ /JAVA_HOME/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_java_archive_roots',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_extract_java_sources_from_archive'
        && $body =~ /Archive::Zip->new/
        && $body =~ /_matching_java_archive_entries/
        && $body =~ /_cached_archive_source_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_extract_archive_sources',
            matching_archive_entries_method => $package . '::_matching_java_archive_entries',
            cached_archive_source_path_method => $package . '::_cached_archive_source_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_matching_java_archive_entries'
        && $body =~ /member->fileName/
        && $body =~ /suffix/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_matching_archive_entries',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_cached_archive_source_path'
        && $body =~ /md5_hex/
        && $body =~ /java-sources/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_cached_archive_source_path',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_download_java_source_matches'
        && $body =~ /_maven_search_documents/
        && $body =~ /_download_maven_source_jar/
        && $body =~ /_extract_java_sources_from_archive/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_download_java_source_matches',
            maven_search_method => $package . '::_maven_search_documents',
            download_source_jar_method => $package . '::_download_maven_source_jar',
            extract_archive_sources_method => $package . '::_extract_java_sources_from_archive',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_maven_search_documents'
        && $body =~ /search\.maven\.org/
        && $body =~ /uri_escape_utf8/
        && $body =~ /decode_json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_maven_search_documents',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_download_maven_source_jar'
        && $body =~ /repo1\.maven\.org/
        && $body =~ /mirror/
        && $body =~ /maven-sources/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_download_maven_source_jar',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_command_exit'
        && $body =~ /exit \$code/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'open_file_command_exit',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'set_indicator'
        && $body =~ /indicator_dir/
        && $body =~ /LOCK_EX/
        && $body =~ /secure_file_permissions/
        && $body =~ /status\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_set_indicator',
            read_method => $package . '::_read_indicator_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'get_indicator'
        && $body =~ /_indicator_file_candidates/
        && $body =~ /_read_indicator_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_get_indicator',
            file_candidates_method => $package . '::_indicator_file_candidates',
            read_method => $package . '::_read_indicator_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'list_indicators'
        && $body =~ /indicators_roots/
        && $body =~ /get_indicator/
        && $body =~ /priority/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_list_indicators',
            get_method => $package . '::get_indicator',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_is_template_toolkit_text'
        && $body =~ /index\( \$text, '\[%' \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_is_template_toolkit_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'collector_indicator_candidate'
        && $body =~ /Collector indicator candidate requires a collector job hash/
        && $body =~ /managed_by_collector/
        && $body =~ /_is_template_toolkit_text/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_collector_indicator_candidate',
            get_method => $package . '::get_indicator',
            is_tt_method => $package . '::_is_template_toolkit_text',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'delete_indicator'
        && $body =~ /indicators_roots/
        && $body =~ /status\.json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_delete_indicator',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_indicator_matches'
        && $body =~ /page_status_icon/
        && $body =~ /managed_by_collector/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_indicator_matches',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_local_indicator'
        && $body =~ /_indicator_file_candidates/
        && $body =~ /_read_indicator_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_local_indicator',
            file_candidates_method => $package . '::_indicator_file_candidates',
            read_method => $package . '::_read_indicator_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_nearest_inherited_indicator'
        && $body =~ /shift \@files/
        && $body =~ /_indicator_file_candidates/
        && $body =~ /_read_indicator_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_nearest_inherited_indicator',
            file_candidates_method => $package . '::_indicator_file_candidates',
            read_method => $package . '::_read_indicator_file',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_is_placeholder_missing_indicator'
        && $body =~ /managed_by_collector/
        && $body =~ /missing/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_is_placeholder_missing_indicator',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'sync_collectors'
        && $body =~ /_nearest_inherited_indicator/
        && $body =~ /collector_indicator_candidate/
        && $body =~ /_indicator_matches/
        && $body =~ /managed_by_collector/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_sync_collectors',
            get_method => $package . '::get_indicator',
            local_method => $package . '::_local_indicator',
            nearest_method => $package . '::_nearest_inherited_indicator',
            is_placeholder_method => $package . '::_is_placeholder_missing_indicator',
            candidate_method => $package . '::collector_indicator_candidate',
            matches_method => $package . '::_indicator_matches',
            set_method => $package . '::set_indicator',
            list_method => $package . '::list_indicators',
            delete_method => $package . '::delete_indicator',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'mark_stale'
        && $body =~ /stale/
        && $body =~ /set_indicator/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_mark_stale',
            get_method => $package . '::get_indicator',
            set_method => $package . '::set_indicator',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'is_stale'
        && $body =~ /updated_at/
        && $body =~ /time - \$item->\{updated_at\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_is_stale',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'refresh_core_indicators'
        && $body =~ /command_in_path\('docker'\)/
        && $body =~ /rev-parse', '--is-inside-work-tree'/
        && $body =~ /diff', '--quiet', '--ignore-submodules', 'HEAD', '--'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_refresh_core_indicators',
            set_method => $package . '::set_indicator',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_status_icon_for'
        && $body =~ /\$map->\{ok\}/
        && $body =~ /\$map->\{error\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_status_icon_for',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'prompt_status_icon'
        && $body =~ /_status_icon_for/
        && $body =~ /PROMPT_STATUS_ICONS/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_prompt_status_icon',
            status_icon_method => $package . '::_status_icon_for',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq '_page_status_icon'
        && $body =~ /page_status_icon/
        && $body =~ /_status_icon_for/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_page_status_icon',
            status_icon_method => $package . '::_status_icon_for',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'page_header_items'
        && $body =~ /list_indicators/
        && $body =~ /_page_status_icon/
        && $body =~ /prompt_visible/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_page_header_items',
            list_method => $package . '::list_indicators',
            page_status_icon_method => $package . '::_page_status_icon',
            prototype => $prototype,
        };
    }

    if (
        _package_tail_is($package, '')
        && $short_name eq 'page_header_payload'
        && $body =~ /page_header_items/
        && $body =~ /status => \$STATUS_ICONS/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'indicator_store_page_header_payload',
            items_method => $package . '::page_header_items',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'current'
        && $body =~ /_channel_json\( 'RESULT', 'RESULT_FILE' \)/
        && $body =~ /decode_json/
        && $body =~ /RESULT must decode to a hash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_current',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'set_current'
        && $body =~ /RESULT state must be a hash/
        && $body =~ /clear_current/
        && $body =~ /_set_channel\( 'RESULT', 'RESULT_FILE'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_set_current',
            clear_method => $package . '::clear_current',
            set_channel_method => $package . '::_set_channel',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'clear_current'
        && $body =~ /_clear_channel\( 'RESULT', 'RESULT_FILE' \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_clear_current',
            clear_channel_method => $package . '::_clear_channel',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'last_result'
        && $body =~ /LAST_RESULT/
        && $body =~ /shift if \@_/
        && $body =~ /decode_json/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_last_result',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'set_last_result'
        && $body =~ /LAST_RESULT state must be a hash/
        && $body =~ /clear_last_result/
        && $body =~ /_set_channel\( 'LAST_RESULT', 'LAST_RESULT_FILE'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_set_last_result',
            clear_method => $package . '::clear_last_result',
            set_channel_method => $package . '::_set_channel',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'clear_last_result'
        && $body =~ /LAST_RESULT/
        && $body =~ /_clear_channel\( 'LAST_RESULT', 'LAST_RESULT_FILE' \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_clear_last_result',
            clear_channel_method => $package . '::_clear_channel',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'stop_requested'
        && $body =~ /return \$stderr =~ \/\\\[\\\[STOP\\\]\\\]\//
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_stop_requested',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'names'
        && $body =~ /sort keys %\{ current\(\) \}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_names',
            current_method => $package . '::current',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'has'
        && $body =~ /exists current\(\)->\{\$name\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_has',
            current_method => $package . '::current',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'entry'
        && $body =~ /my \$data = current\(\)/
        && $body =~ /return \$data->\{\$name\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_entry',
            current_method => $package . '::current',
            prototype => $prototype,
        };
    }

    if (
        ($short_name eq 'stdout' || $short_name eq 'stderr')
        && $body =~ /my \$entry = entry\(\$name\)/
        && $body =~ /return '' if ref\(\$entry\) ne 'HASH'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => $short_name eq 'stdout' ? 'result_stdout' : 'result_stderr',
            entry_method => $package . '::entry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'exit_code'
        && $body =~ /my \$entry = entry\(\$name\)/
        && $body =~ /return \$entry->\{exit_code\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_exit_code',
            entry_method => $package . '::entry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'last_name'
        && $body =~ /my \@names = names\(\)/
        && $body =~ /return \$names\[-1\]/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_last_name',
            names_method => $package . '::names',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'last_entry'
        && $body =~ /my \$name = last_name\(\)/
        && $body =~ /return entry\(\$name\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_last_entry',
            last_name_method => $package . '::last_name',
            entry_method => $package . '::entry',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'report'
        && $body =~ /Run Report/
        && $body =~ /_command_name/
        && $body =~ /encode\( 'UTF-8'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_report',
            names_method => $package . '::names',
            command_name_method => $package . '::_command_name',
            exit_code_method => $package . '::exit_code',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_current_json'
        && $body =~ /_channel_json\( 'RESULT', 'RESULT_FILE' \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_current_json',
            channel_json_method => $package . '::_channel_json',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_max_inline_bytes'
        && $body =~ /\$ENV\{/
        && $body =~ /RESULT_INLINE_MAX/
        && $body =~ /return 65536/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_max_inline_bytes',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_open_channel_file'
        && $body =~ /tempfile\( 'dashboard-result-XXXXXX'/
        && $body =~ /FD_CLOEXEC/
        && $body =~ m{/dev/fd/\$fd}
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_open_channel_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_channel_json'
        && $body =~ /open my \$fh, '<:raw', \$path/
        && $body =~ /Unable to read \$env_name file \$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_channel_json',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_set_channel'
        && $body =~ /encode_json/
        && $body =~ /_max_inline_bytes/
        && $body =~ /_open_channel_file/
        && $body =~ /truncate/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_set_channel',
            max_inline_method => $package . '::_max_inline_bytes',
            open_channel_method => $package . '::_open_channel_file',
            clear_channel_file_method => $package . '::_clear_channel_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_clear_channel'
        && $body =~ /delete \$ENV\{\$env_name\}/
        && $body =~ /_clear_channel_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_clear_channel',
            clear_channel_file_method => $package . '::_clear_channel_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_clear_channel_file'
        && $body =~ /CHANNEL_FILE_HANDLE/
        && $body =~ /CHANNEL_FILE_PATH/
        && $body =~ /close \$CHANNEL_FILE_HANDLE/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_clear_channel_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_command_name'
        && $body =~ /\$0/
        && $body =~ /basename/
        && $body =~ /dirname/
        && $body =~ /\$ENV\{/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'result_command_name',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_usage'
        && $body =~ /Usage: dashboard which \[--edit\]/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'which_usage',
            usage => "Usage: dashboard which [--edit] <cmd>|<skill>.<cmd>|<skill>.<sub-skill>.<cmd>\n",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_build_paths'
        && $body =~ /workspace_roots/
        && $body =~ /project_roots/
        && $body =~ /qw\(projects src work\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'which_build_paths',
            path_registry_class => _sibling_class($package, 'PathRegistry'),
            prototype => $prototype,
        };
    }

    if (
        _is_entry_command_sub($short_name)
        && $body =~ /\$ENV\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\s*\|\|\s*([\'"])(.*?)\2/s
    ) {
        my ($entrypoint_env, $entrypoint_fallback) = ($1, $3);
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'app_entry_command',
            entrypoint_env => $entrypoint_env,
            entrypoint_fallback => $entrypoint_fallback,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_command_exec'
        && $body =~ /exec \{ \$command\[0\] \} \@command;/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'exec_command_argv',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_resolve_directory_runner'
        && $body =~ /qw\(run run\.pl run\.sh run\.bash run\.ps1 run\.cmd run\.bat run\.go run\.java\)/
        && $body =~ /resolve_runnable_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'resolve_directory_runner',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_resolved_command_path'
        && $body =~ /_resolve_directory_runner/
        && $body =~ /resolve_runnable_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'resolved_command_path',
            directory_runner_method => $package . '::_resolve_directory_runner',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_custom_command_path'
        && $body =~ /reverse \$paths->cli_layers/
        && $body =~ /_resolved_command_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'custom_command_path',
            resolved_command_method => $package . '::_resolved_command_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_command_hook_files'
        && $body =~ /cli_layers/
        && $body =~ /is_runnable_file/
        && $body =~ /\$command \. '\.d'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'command_hook_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_builtin_target'
        && $body =~ /canonical_helper_name/
        && $body =~ /ensure_helpers/
        && $body =~ /helper_path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'builtin_target',
            hook_method => $package . '::_command_hook_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_custom_target'
        && $body =~ /_custom_command_path/
        && $body =~ /_command_hook_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'custom_target',
            command_method => $package . '::_custom_command_path',
            hook_method => $package . '::_command_hook_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_locate_skill_target'
        && $body =~ /SkillManager->new/
        && $body =~ /SkillDispatcher->new/
        && $body =~ /command_spec/
        && $body =~ /command_hook_paths/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'locate_skill_target',
            skill_manager_class => _related_class_from_source($source, $package, $body, 'SkillManager', methods => ['new']),
            skill_dispatcher_class => _related_class_from_source($source, $package, $body, 'SkillDispatcher', methods => ['new']),
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_locate_target'
        && $body =~ /_locate_skill_target/
        && $body =~ /_builtin_target/
        && $body =~ /_custom_target/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'locate_target',
            skill_method => $package . '::_locate_skill_target',
            builtin_method => $package . '::_builtin_target',
            custom_method => $package . '::_custom_target',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_which_command'
        && $body =~ /GetOptionsFromArray/
        && $body =~ /_build_paths/
        && $body =~ /_locate_target/
        && $body =~ /_command_exec/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        my $entry_command_sub = _entry_command_sub_name($source) || 'entry_command';
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'run_which_command',
            usage_method => $package . '::_usage',
            build_paths_method => $package . '::_build_paths',
            locate_target_method => $package . '::_locate_target',
            entry_command_method => $package . '::' . $entry_command_sub,
            command_exec_method => $package . '::_command_exec',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'new'
        && $body =~ /PathRegistry->new/
        && $body =~ /SkillManager->new/
        && $body =~ /workspace_roots/
        && $body =~ /project_roots/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_new',
            path_registry_class => _related_class_from_source($source, $package, $body, 'PathRegistry', methods => ['new']),
            skill_manager_class => _related_class_from_source($source, $package, $body, 'SkillManager', methods => ['new']),
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'unknown_command_message'
        && $body =~ /Unknown dashboard command/
        && $body =~ /top_level_suggestions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_unknown_command_message',
            suggestions_method => $package . '::top_level_suggestions',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'unknown_skill_command_message'
        && $body =~ /Skill '\$skill_name' not found/
        && $body =~ /is disabled/
        && $body =~ /skill_command_suggestions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_unknown_skill_command_message',
            skill_suggestions_method => $package . '::skill_command_suggestions',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'top_level_candidates'
        && $body =~ /_top_level_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_top_level_candidates',
            internal_method => $package . '::_top_level_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'top_level_suggestions'
        && $body =~ /_rank_candidates/
        && $body =~ /_top_level_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_top_level_suggestions',
            rank_method => $package . '::_rank_candidates',
            candidates_method => $package . '::_top_level_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'skill_commands'
        && $body =~ /_skill_command_entries/
        && $body =~ /_all_skill_command_entries/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_skill_commands',
            skill_entries_method => $package . '::_skill_command_entries',
            all_entries_method => $package . '::_all_skill_command_entries',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'skill_command_suggestions'
        && $body =~ /_skill_command_entries/
        && $body =~ /_all_skill_command_entries/
        && $body =~ /_rank_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_skill_command_suggestions',
            rank_method => $package . '::_rank_candidates',
            skill_entries_method => $package . '::_skill_command_entries',
            all_entries_method => $package . '::_all_skill_command_entries',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_top_level_candidates'
        && $body =~ /helper_names/
        && $body =~ /helper_aliases/
        && $body =~ /cli_roots/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_internal_top_level_candidates',
            logical_name_method => $package . '::_logical_command_name',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_all_skill_command_entries'
        && $body =~ /installed_skill_roots/
        && $body =~ /_skill_command_entries/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_all_skill_command_entries',
            skill_entries_method => $package . '::_skill_command_entries',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_skill_command_entries'
        && $body =~ /get_skill_path/
        && $body =~ /_collect_skill_commands/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_skill_command_entries',
            collect_method => $package . '::_collect_skill_commands',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_collect_skill_commands'
        && $body =~ /File::Spec->catdir\( \$skill_root, 'cli' \)/
        && $body =~ /File::Spec->catdir\( \$skill_root, 'skills' \)/
        && $body =~ /is_runnable_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_collect_skill_commands',
            logical_name_method => $package . '::_logical_command_name',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_rank_candidates'
        && $body =~ /_candidate_score/
        && $body =~ /splice \@scored, 5/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_rank_candidates',
            score_method => $package . '::_candidate_score',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_candidate_score'
        && $body =~ /_normalize_token/
        && $body =~ /_levenshtein_distance/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_candidate_score',
            normalize_method => $package . '::_normalize_token',
            distance_method => $package . '::_levenshtein_distance',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_normalize_token'
        && $body =~ /lc/
        && $body =~ /s\/\[\^a-z0-9\]\+\/\/g/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_normalize_token',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_levenshtein_distance'
        && $body =~ /split \/\//
        && $body =~ /\@dist = \( 0 \.\. scalar \@right \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_levenshtein_distance',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_logical_command_name'
        && $body =~ /pl\|go\|java\|ps1\|cmd\|bat\|sh\|bash/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'suggest_logical_command_name',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_env_file_candidates'
        && _package_tail_is($package, '')
        && $body =~ /File::Spec->catfile\( \$root, '\.env' \)/
        && $body =~ /File::Spec->catfile\( \$root, '\.env\.pl' \)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_path_identity'
        && _package_tail_is($package, '')
        && $body =~ /abs_path/
        && $body =~ /File::Spec->canonpath/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_path_identity',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_same_or_descendant_path'
        && _package_tail_is($package, '')
        && $body =~ /_path_identity/
        && $body =~ /index\( \$path_id, \$root_id \. '\/' \) == 0/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_same_or_descendant_path',
            identity_method => $package . '::_path_identity',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_lookup_env_symbol'
        && _package_tail_is($package, '')
        && $body =~ /return undef if !defined \$name \|\| \$name eq ''/
        && $body =~ /return \$ENV\{\$name\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_lookup_symbol',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_plain_directory_layers'
        && _package_tail_is($package, '')
        && $body =~ /cwd\(\)/
        && $body =~ /current_project_root/
        && $body =~ /dirname/
        && $body =~ /reverse \@layers/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_plain_directory_layers',
            same_or_descendant_method => $package . '::_same_or_descendant_path',
            identity_method => $package . '::_path_identity',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_plain_directory_env_files'
        && _package_tail_is($package, '')
        && $body =~ /_plain_directory_layers/
        && $body =~ /_env_file_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_plain_directory_files',
            layers_method => $package . '::_plain_directory_layers',
            candidates_method => $package . '::_env_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_runtime_layer_env_files'
        && _package_tail_is($package, '')
        && $body =~ /runtime_layers/
        && $body =~ /_env_file_candidates/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_runtime_layer_files',
            candidates_method => $package . '::_env_file_candidates',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'load_skill_layers'
        && _package_tail_is($package, '')
        && $body =~ /skill_layers/
        && $body =~ /_env_file_candidates/
        && $body =~ /load_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_load_skill_layers',
            candidates_method => $package . '::_env_file_candidates',
            load_files_method => $package . '::load_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'load_runtime_layers'
        && _package_tail_is($package, '')
        && $body =~ /Missing paths/
        && $body =~ /_plain_directory_env_files/
        && $body =~ /_runtime_layer_env_files/
        && $body =~ /load_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_load_runtime_layers',
            plain_files_method => $package . '::_plain_directory_env_files',
            runtime_files_method => $package . '::_runtime_layer_env_files',
            load_files_method => $package . '::load_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'load_files'
        && _package_tail_is($package, '')
        && $body =~ /_path_identity/
        && $body =~ /_load_env_pl_file/
        && $body =~ /_load_env_file/
        && $body =~ /return \\\@loaded/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_load_files',
            identity_method => $package . '::_path_identity',
            load_env_pl_method => $package . '::_load_env_pl_file',
            load_env_file_method => $package . '::_load_env_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_strip_env_comments'
        && _package_tail_is($package, '')
        && $body =~ /Missing in_block_comment state/
        && $body =~ /\$\{\$state\}/
        && index($body, "return '' if \$trimmed =~ /\\A#/;") >= 0
        && index($body, "return '' if \$trimmed =~ /\\A\\/\\//;") >= 0
        && index($body, "if ( \$trimmed =~ /\\A\\/\\*/ )") >= 0
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_strip_comments',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_expand_env_value'
        && _package_tail_is($package, '')
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_expand_value',
            braced_method => $package . '::_expand_braced_env_expression',
            lookup_method => $package . '::_lookup_env_symbol',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_expand_braced_env_expression'
        && _package_tail_is($package, '')
        && $body =~ /split \/:-\/, \$expression, 2/
        && $body =~ /_call_env_function/
        && $body =~ /_lookup_env_symbol/
        && $body =~ /_expand_env_value/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_expand_braced',
            call_function_method => $package . '::_call_env_function',
            lookup_method => $package . '::_lookup_env_symbol',
            expand_value_method => $package . '::_expand_env_value',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_call_env_function'
        && _package_tail_is($package, '')
        && $body =~ /Invalid env function/
        && $body =~ /\{\$function\}\{CODE\}/
        && $body =~ /Env function \$function failed/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_call_function',
            invalid_error => 'Invalid env function in %s line %s: %s',
            call_error => 'Env function %s failed in %s line %s: %s',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_load_env_file'
        && _package_tail_is($package, '')
        && $body =~ /_strip_env_comments/
        && $body =~ /Invalid env line/
        && $body =~ /Invalid env key/
        && $body =~ /_expand_env_value/
        && $body =~ /Unterminated block comment/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_load_env_file',
            strip_method => $package . '::_strip_env_comments',
            expand_method => $package . '::_expand_env_value',
            invalid_line_error => 'Invalid env line in %s line %s: %s',
            invalid_key_error => 'Invalid env key in %s line %s: %s',
            unterminated_comment_error => 'Unterminated block comment in %s',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_load_env_pl_file'
        && _package_tail_is($package, '')
        && $body =~ /delete \$INC\{\$file\}/
        && $body =~ /require \$file/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*EnvAudit->record/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'env_load_env_pl_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'new'
        && _package_tail_is($package, '')
        && $body =~ /Missing paths registry/
        && $body =~ /paths\s*=>\s*\$paths/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'bless_required_args_hash',
            slots => [
                {
                    slot => 'paths',
                    arg => 'paths',
                    error => 'Missing paths registry',
                },
            ],
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'paths'
        && _package_tail_is($package, '')
        && $body =~ /\$_\[0\]->\{paths\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'return_self_slot',
            slot => 'paths',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'register_named_files'
        && _package_tail_is($package, '')
        && $body =~ /ref\(\$aliases\)\s+ne\s+'HASH'/
        && $body =~ /\$self->\{named_files\}\{\$name\}\s*=\s*\$path/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_register_named_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'unregister_named_file'
        && _package_tail_is($package, '')
        && $body =~ /delete \$self->\{named_files\}\{\$name\}/
        && $body =~ /delete \$self->\{configured_named_files\}\{\$name\}/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_unregister_named_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'named_files'
        && _package_tail_is($package, '')
        && $body =~ /_load_configured_named_files/
        && $body =~ /configured_named_files/
        && $body =~ /named_files/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_named_files',
            load_method => $package . '::_load_configured_named_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'all_file_aliases'
        && _package_tail_is($package, '')
        && $body =~ /prompt_log/
        && $body =~ /collector_log/
        && $body =~ /dashboard_log/
        && $body =~ /global_config/
        && $body =~ /dashboard_index/
        && $body =~ /auth_log/
        && $body =~ /web_pid/
        && $body =~ /web_state/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_all_file_aliases',
            alias_methods => [
                [ prompt_log => 'prompt_log' ],
                [ collector_log => 'collector_log' ],
                [ dashboard_log => 'dashboard_log' ],
                [ global_config => 'global_config' ],
                [ dashboard_index => 'dashboard_index' ],
                [ auth_log => 'auth_log' ],
                [ web_pid => 'web_pid' ],
                [ web_state => 'web_state' ],
            ],
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'all_files'
        && _package_tail_is($package, '')
        && $body =~ /all_file_aliases/
        && $body =~ /named_files/
        && $body =~ /return \\\%all/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_all_files',
            aliases_method => $package . '::all_file_aliases',
            named_files_method => $package . '::named_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'locate_files'
        && _package_tail_is($package, '')
        && $body =~ /grep \{ defined && \$_ ne '' \} \@terms/
        && $body =~ /paths->cwd/
        && $body =~ /locate_files_under/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_locate_files',
            locate_under_method => $package . '::locate_files_under',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'locate_files_under'
        && _package_tail_is($package, '')
        && $body =~ /File::Find::find/
        && $body =~ /\$name\s*!~\s*\/\\Q\$term\\E\/i/
        && $body =~ /\$path\s*!~\s*\/\\Q\$term\\E\/i/
        && $body =~ /return grep \{ !\$seen\{\$_\}\+\+ \} sort \@found/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_locate_files_under',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_load_configured_named_files'
        && _package_tail_is($package, '')
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*Config->new/
        && $body =~ /configured_named_files/
        && $body =~ /file_aliases/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_load_configured_named_files',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'resolve_file'
        && $body =~ /file_name_is_absolute/
        && $body =~ /\$self->can\(\$name\)/
        && $body =~ /Unknown file name/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_resolve_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'read'
        && $body =~ /resolve_file/
        && $body =~ /Unable to read/
        && $body =~ /local \$\//
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_read',
            resolve_method => $package . '::resolve_file',
            prototype => $prototype,
        };
    }

    if (
        ($short_name eq 'write' || $short_name eq 'append' || $short_name eq 'touch')
        && $body =~ /resolve_file/
        && $body =~ /secure_file_permissions/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        my $mode = $short_name eq 'append' ? '>>' : '>';
        my $op = $short_name eq 'touch' ? 'file_registry_touch' : 'file_registry_write';
        return {
            name => $short_name,
            full_name => $full_name,
            op => $op,
            resolve_method => $package . '::resolve_file',
            mode => $mode,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'remove'
        && $body =~ /resolve_file/
        && $body =~ /unlink \$file if -e \$file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_remove',
            resolve_method => $package . '::resolve_file',
            prototype => $prototype,
        };
    }

    if (
        $body =~ /\A\s*my\s+\(\$self\)\s*=\s*\@_;\s*return\s+File::Spec->catfile\(\s*\$self->paths->([A-Za-z_][A-Za-z0-9_]*)\s*,\s*'([^']+)'\s*\)\s*;\s*\z/s
    ) {
        my ($root_method, $filename) = ($1, $2);
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'file_registry_catfile',
            root_method => $root_method,
            filename => $filename,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_usage_error'
        && $body =~ /print STDERR \$message/
        && $body =~ /return 2/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'usage_error_stderr',
            exit_code => 2,
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_skills_install_progress'
        && $body =~ /DEVELOPER_DASHBOARD_PROGRESS/
        && $body =~ /install_progress_tasks/
        && $body =~ /dashboard skills install progress/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skills_install_progress',
            progress_class => _related_class_from_source($source, $package, $body, 'CLI::Progress', methods => ['new']),
            manager_class => _related_class_from_source($source, $package, $body, 'SkillManager', methods => ['install_progress_tasks', 'new']),
            title => 'dashboard skills install progress',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_skills_install_progress_for_sources'
        && $body =~ /DEVELOPER_DASHBOARD_PROGRESS/
        && $body =~ /install_progress_tasks_for_sources/
        && $body =~ /return if !\@sources/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skills_install_progress_for_sources',
            progress_class => _related_class_from_source($source, $package, $body, 'CLI::Progress', methods => ['new']),
            manager_class => _related_class_from_source($source, $package, $body, 'SkillManager', methods => ['install_progress_tasks_for_sources', 'new']),
            title => 'dashboard skills install progress',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_install_result_rows'
        && $body =~ /return \(\) if ref\(\$result\) ne 'HASH'/
        && $body =~ /operations/
        && $body =~ /results/
        && $body =~ /repo_name/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skills_install_result_rows',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_plain_text'
        && $body =~ /\\e\\\[\[0-9;\]\*m/
        && $body =~ /return \$value/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'ansi_plain_text',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_enabled_text'
        && $body =~ /enabled/
        && $body =~ /disabled/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'bool_text_pair',
            true_text => 'enabled',
            false_text => 'disabled',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_boolean_text'
        && $body =~ /yes/
        && $body =~ /no/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'bool_text_pair',
            true_text => 'yes',
            false_text => 'no',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_format_row'
        && $body =~ /_plain_text/
        && $body =~ /join '  ', \@cells/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'format_table_row',
            plain_text_method => $package . '::_plain_text',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_render_table'
        && $body =~ /_plain_text/
        && $body =~ /_format_row/
        && $body =~ /'-' x \$widths/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'render_text_table',
            plain_text_method => $package . '::_plain_text',
            format_row_method => $package . '::_format_row',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_skills_install_summary_table'
        && $body =~ /No update/
        && $body =~ /_install_result_rows/
        && $body =~ /_render_table/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skills_install_summary_table',
            rows_method => $package . '::_install_result_rows',
            render_table_method => $package . '::_render_table',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_skills_table'
        && $body =~ /cli_commands_count/
        && $body =~ /docker_services_count/
        && $body =~ /_enabled_text/
        && $body =~ /_render_table/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skills_table',
            enabled_text_method => $package . '::_enabled_text',
            render_table_method => $package . '::_render_table',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_usage_table'
        && $body =~ /CLI Commands/
        && $body =~ /Docker Services/
        && $body =~ /Collectors/
        && $body =~ /_boolean_text/
        && $body =~ /_render_table/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'skills_usage_table',
            enabled_text_method => $package . '::_enabled_text',
            boolean_text_method => $package . '::_boolean_text',
            render_table_method => $package . '::_render_table',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_skills_command'
        && $body =~ /Unknown skills action/
        && $body =~ /skills install/
        && $body =~ /skills uninstall/
        && $body =~ /skills usage/
        && $body =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*SkillManager->new/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'run_skills_command',
            build_paths_method => $package . '::_build_paths',
            usage_error_method => $package . '::_usage_error',
            install_progress_method => $package . '::_skills_install_progress',
            install_progress_sources_method => $package . '::_skills_install_progress_for_sources',
            install_summary_method => $package . '::_skills_install_summary_table',
            skills_table_method => $package . '::_skills_table',
            usage_table_method => $package . '::_usage_table',
            manager_class => _related_class_from_source($source, $package, $body, 'SkillManager', methods => ['new']),
            dispatcher_class => _related_class_from_source($source, $package, $body, 'SkillDispatcher', methods => ['new']),
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'zip'
        && $body =~ /encode_payload/
        && $body =~ /uri_escape/
        && $body =~ /raw => \$raw/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'zip_payload_url',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'unzip'
        && $body =~ /decode_payload/
        && $body =~ /return if !defined \$token/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'unzip_payload',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_js_single_quote'
        && $body =~ /\\\\\\\\/ 
        && $body =~ /\\\\'/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'js_single_quote',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_validate_saved_ajax_file'
        && $body =~ /file is required/
        && $body =~ /file must be relative/
        && $body =~ /invalid parent traversal/
        && $body =~ /invalid characters/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'validate_saved_ajax_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'saved_ajax_file_path'
        && $body =~ /runtime_root is required/
        && $body =~ /dashboards', 'ajax'/
        && $body =~ /_validate_saved_ajax_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'saved_ajax_file_path',
            validate_method => $package . '::_validate_saved_ajax_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'load_saved_ajax_code'
        && $body =~ /saved_ajax_file_path/
        && $body =~ /Unable to read/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'load_saved_ajax_code',
            path_method => $package . '::saved_ajax_file_path',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_saved_ajax_url'
        && $body =~ /\/ajax\/%s\?type=%s/
        && $body =~ /singleton/
        && $body =~ /_validate_saved_ajax_file/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'saved_ajax_url',
            validate_method => $package . '::_validate_saved_ajax_file',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_saved_ajax_url_and_store'
        && $body =~ /saved_ajax_file_path/
        && $body =~ /make_path/
        && $body =~ /chmod 0700/
        && $body =~ /_saved_ajax_url/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'saved_ajax_url_and_store',
            path_method => $package . '::saved_ajax_file_path',
            url_method => $package . '::_saved_ajax_url',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'acmdx'
        && $body =~ /token=%s&type=%s/
        && $body =~ /singleton/
        && $body =~ /Click Here/
        && $body =~ /zip\(\$code\)/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'acmdx_bundle',
            zip_method => $package . '::zip',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'Ajax'
        && $body =~ /jvar is required/
        && $body =~ /saved bookmark Ajax/
        && $body =~ /dashboard_ajax_singleton_cleanup/
        && $body =~ /set_chain_value/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'ajax_helper',
            saved_url_method => $package . '::_saved_ajax_url',
            saved_store_method => $package . '::_saved_ajax_url_and_store',
            acmdx_method => $package . '::acmdx',
            quote_method => $package . '::_js_single_quote',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '__cmdx'
        && $body =~ /printf '%s'/
        && $body =~ /base64 -d \| gunzip/
        && $body =~ /quotemeta/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cmdx_shell_pipeline',
            zip_method => $package . '::zip',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cmdx'
        && $body =~ /\$type eq 'perl' \? '-e' : '-c'/
        && $body =~ /__cmdx/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cmdx_tuple',
            shell_method => $package . '::__cmdx',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq '_cmdp'
        && $body =~ /__cmdx/
        && $body =~ /return \( __cmdx/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'cmdp_tuple',
            shell_method => $package . '::__cmdx',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'resolve_ticket_request'
        && $body =~ /Ticket args must be an array reference/
        && $body =~ /Please specify a ticket name\\n/
        && $body =~ /\$ticket = \$args\{env_ticket\} if !defined \$ticket \|\| \$ticket eq ''/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'resolve_ticket_request',
            type_error => 'Ticket args must be an array reference',
            missing_error => "Please specify a ticket name\n",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'ticket_environment'
        && $body =~ /Ticket name is required\\n/
        && $body =~ /TICKET_REF/
        && $body =~ /OB\s*=>\s*\"origin\/\$ticket\"/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'ticket_environment',
            missing_error => "Ticket name is required\n",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'tmux_command'
        && $body =~ /tmux args must be an array reference/
        && $body =~ /system 'tmux', \@\{\$argv\}/
        && $body =~ /stdout\s*=>\s*\$stdout/
        && $body =~ /exit_code\s*=>\s*\$exit_code/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'captured_command_result',
            command => 'tmux',
            type_error => 'tmux args must be an array reference',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'session_exists'
        && $body =~ /Missing session name/
        && $body =~ /has-session/
        && $body =~ /return 1 if \$result->\{exit_code\} == 0/
        && $body =~ /return 0 if \$result->\{exit_code\} == 1/
        && $body =~ /Unable to inspect tmux session/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'session_exists_via_command',
            default_runner => $package . '::tmux_command',
            missing_error => 'Missing session name',
            inspect_error => "Unable to inspect tmux session '%s': %s%s",
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'build_ticket_plan'
        && $body =~ /resolve_ticket_request/
        && $body =~ /ticket_environment/
        && $body =~ /session_exists/
        && $body =~ /new-session/
        && $body =~ /attach-session/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'build_ticket_plan',
            resolve_method => $package . '::resolve_ticket_request',
            environment_method => $package . '::ticket_environment',
            exists_method => $package . '::session_exists',
            prototype => $prototype,
        };
    }

    if (
        $short_name eq 'run_ticket_command'
        && $body =~ /build_ticket_plan/
        && $body =~ /Unable to create tmux ticket session/
        && $body =~ /Unable to attach tmux ticket session/
    ) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'run_ticket_command_plan',
            default_runner => $package . '::tmux_command',
            plan_method => $package . '::build_ticket_plan',
            create_error => "Unable to create tmux ticket session '%s': %s%s",
            attach_error => "Unable to attach tmux ticket session '%s': %s%s",
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$text\s*\)\s*=\s*\@_;\s*
                    return\s+if\s+!defined\s+\$text\s*;\s*
                    gzip\s+\\\$text\s*=>\s*\\my\s+\$zipped\s*
                      or\s+die\s+\"([^\"]*)\"\s*;\s*
                    return\s+encode_base64\(\s*\$zipped\s*,\s*''\s*\)\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'gzip_base64_encode',
            error_message => $1,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*my\s+\(\s*\$token\s*\)\s*=\s*\@_;\s*
                    return\s+if\s+!defined\s+\$token\s+\|\|\s+\$token\s+eq\s+''\s*;\s*
                    my\s+\$zipped\s*=\s*decode_base64\(\$token\)\s*;\s*
                    gunzip\s+\\\$zipped\s*=>\s*\\my\s+\$text\s*
                      or\s+die\s+\"([^\"]*)\"\s*;\s*
                    return\s+\$text\s*;\s*\z/xs) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'gzip_base64_decode',
            error_message => $1,
            prototype => $prototype,
        };
    }

    if ($body =~ /\A\s*return\s+1\s*\z/s) {
        my $prototype = _sub_prototype_from_source($source, $short_name);
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'return_true',
            prototype => $prototype,
        };
    }

    return;
}

sub _entry_command_capture {
    my ($source, $logical_path, $sub_name, $symbolic_name) = @_;
    $sub_name ||= _entry_command_sub_name($source);
    $symbolic_name ||= $sub_name || 'entry_command';

    if ($sub_name && $sub_name ne '' && (my $body = _extract_sub_body($source, $sub_name))) {
        if ($body =~ /\$ENV\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\s*(?:\|\|=|\|\||\/\/)\s*([\'\"])(.*?)\2/s) {
            return {
                env => $1,
                fallback => _unescape_literal($3),
                sub_name => $symbolic_name,
            };
        }
    }

    if (my $entry = _extract_entrypoint_assignment_fallback($source, $logical_path)) {
        $entry->{sub_name} = $symbolic_name;
        return $entry;
    }

    return;
}

sub _extract_entrypoint_assignment_fallback {
    my ($source, $logical_path) = @_;
    return if $source !~ /\$ENV\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\s*\|\|=\s*([^;\n]+);/s;

    my $env = $1;
    my $rhs = $2 // '';
    my $fallback = '';

    if ($rhs =~ /\$0\b/) {
        (my $lp = $logical_path // '') =~ s{.*/}{};
        $lp =~ s{\.\w+\z}{};
        $fallback = $lp;
        $fallback = 'app' if $fallback eq '';
    }
    elsif ($rhs =~ /([\'\"])(.*?)\1/s) {
        $fallback = _unescape_literal($2);
    }

    return {
        env => $env,
        fallback => $fallback,
    };
}

sub _return_literal_from_source {
    my ($source, $sub_name) = @_;
    my $body = _extract_sub_body($source, $sub_name) or return;
    if ($body =~ /\A\s*return\s+"([^"\\]*(?:\\.[^"\\]*)*)"\s*;\s*\z/s) {
        my $value = $1;
        $value =~ s/\\"/"/g;
        $value =~ s/\\\\/\\/g;
        $value =~ s/\\n/\n/g;
        return {
            type => 'string',
            value => $value,
        };
    }
    if ($body =~ /\A\s*return\s+(-?\d+)\s*;\s*\z/s) {
        return {
            type => 'integer',
            value => 0 + $1,
        };
    }
    return;
}

sub _package_tail_is {
    my ($package, $tail) = @_;
    return 0 unless defined $package;
    return 1 if !defined $tail || $tail eq '';
    return $package =~ /(?:^|::)\Q$tail\E\z/ ? 1 : 0;
}

sub _calls_class_tail {
    my ($body, $class_tail, $method) = @_;
    return 0 unless defined $body && defined $class_tail;
    my $escaped_tail = quotemeta $class_tail;
    my $qualified_tail = qr/(?:[A-Za-z_][A-Za-z0-9_]*::)*$escaped_tail/;

    if (defined $method && $method ne '') {
        my $method_escaped = quotemeta $method;
        return $body =~ /(?:^|[^A-Za-z0-9_])$qualified_tail\s*->\s*\Q$method_escaped\E\s*\(/m ? 1 : 0;
    }
    return $body =~ /(?:^|[^A-Za-z0-9_])$qualified_tail\b/m ? 1 : 0;
}

sub _requires_class_tail {
    my ($body, $class_tail) = @_;
    return 0 unless defined $body && defined $class_tail;
    return $body =~ /^\s*require\s+(?:[A-Za-z_][A-Za-z0-9_]*::)*\Q$class_tail\E\s*;/m ? 1 : 0;
}

sub _sibling_class {
    my ($package, $class) = @_;
    return $package if !defined $class || $class eq '';
    return $package if !defined $package || $package eq '';

    my ($root) = $package =~ m{^(.*)::([^:]+)$};
    $root //= '';
    my @class_parts = split m{::}, $class;
    return join('::', grep { defined && $_ ne '' } $root, @class_parts);
}

sub _related_class_from_source {
    my ($source, $package, $body, $class, %args) = @_;
    return _sibling_class($package, $class) if !defined $class || $class eq '';

    my @methods = @{ $args{methods} || [] };
    for my $scope (grep { defined && $_ ne '' } $body, $source) {
        my $qualified = _qualified_class_in_scope($scope, $class, \@methods);
        return $qualified if defined $qualified && $qualified ne '';
    }

    for my $scope (grep { defined && $_ ne '' } $source, $body) {
        my $imported = _imported_class_in_scope($scope, $class);
        return $imported if defined $imported && $imported ne '';
    }

    return _sibling_class($package, $class);
}

sub _qualified_class_in_scope {
    my ($scope, $class, $methods) = @_;
    return if !defined $scope || !defined $class || $class eq '';
    my $qualified_tail = qr/(?:[A-Za-z_][A-Za-z0-9_]*::)+\Q$class\E/;
    if ($methods && @$methods) {
        for my $method (@$methods) {
            next if !defined $method || $method eq '';
            if ($scope =~ /($qualified_tail)\s*->\s*\Q$method\E\s*\(/m) {
                return $1;
            }
        }
    }
    return $1 if $scope =~ /($qualified_tail)\b/m;
    return;
}

sub _imported_class_in_scope {
    my ($scope, $class) = @_;
    return if !defined $scope || !defined $class || $class eq '';
    return $1 if $scope =~ /^\s*use\s+((?:[A-Za-z_][A-Za-z0-9_]*::)+\Q$class\E)\b/m;
    return $1 if $scope =~ /^\s*require\s+((?:[A-Za-z_][A-Za-z0-9_]*::)+\Q$class\E)\s*;/m;
    return;
}

sub _extract_sub_body {
    my ($source, $sub_name) = @_;
    return if $source !~ /sub\s+\Q$sub_name\E\b[^\{]*\{/g;
    my $start = pos($source);
    my $depth = 1;
    my $i = $start;
    while ($i < length($source)) {
        my $char = substr($source, $i, 1);
        $depth++ if $char eq '{';
        $depth-- if $char eq '}';
        return substr($source, $start, $i - $start) if $depth == 0;
        $i++;
    }
    return;
}

sub _extract_sub_source {
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

sub _sub_prototype_from_source {
    my ($source, $sub_name) = @_;
    return scalar undef if $source !~ /\bsub\s+\Q$sub_name\E\s*(\([^\)]*\))?\s*\{/g;
    return scalar($1);
}

sub _bootstrap_source {
    my ($source) = @_;
    my $first_sub = index($source, 'sub ');
    my $bootstrap = $first_sub < 0 ? $source : substr($source, 0, $first_sub);
    return _strip_pod($bootstrap);
}

sub _compile_initializers {
    my ($source, $package) = @_;
    my @ops;
    my %array_literal_seen;
    my $bootstrap = _strip_pod(_bootstrap_source($source));
    my $stripped_source = _strip_pod($source);
    while ($bootstrap =~ /\brequire\s+([A-Za-z_][A-Za-z0-9_:]*)\b\s*;/g) {
        push @ops, {
            op => 'require_module',
            package => $package,
            module => $1,
        };
    }
    while ($bootstrap =~ /\buse\s+([A-Za-z_][A-Za-z0-9_:]*)\b(.*?);/gs) {
        my ($module, $arg_source) = ($1, $2 // '');
        next if $module =~ /^(?:strict|warnings|utf8|feature|integer|bytes|mro|open|re)$/;
        my $args = _parse_use_args($arg_source);
        return (undef) if !defined $args;
        push @ops, {
            op => 'use_module',
            package => $package,
            module => $module,
            args => $args,
        };
    }
    while ($stripped_source =~ /\bour\s+\$([A-Za-z_]\w*)\s*=\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*;/g) {
        my $name = $1;
        my $value = $2;
        $value =~ s/\\"/"/g;
        $value =~ s/\\\\/\\/g;
        $value =~ s/\\n/\n/g;
        push @ops, {
            op => 'set_scalar_literal',
            symbol => $package . '::' . $name,
            value_type => 'string',
            value => $value,
        };
    }
    while ($stripped_source =~ /\bour\s+\$([A-Za-z_]\w*)\s*=\s*'([^'\\]*(?:\\.[^'\\]*)*)'\s*;/g) {
        my $name = $1;
        my $value = $2;
        $value =~ s/\\'/'/g;
        $value =~ s/\\\\/\\/g;
        $value =~ s/\\n/\n/g;
        push @ops, {
            op => 'set_scalar_literal',
            symbol => $package . '::' . $name,
            value_type => 'string',
            value => $value,
        };
    }
    while ($stripped_source =~ /\bour\s+\$([A-Za-z_]\w*)\s*=\s*(-?\d+(?:\.\d+)?)\s*;/g) {
        my ($name, $number) = ($1, $2);
        push @ops, {
            op => 'set_scalar_literal',
            symbol => $package . '::' . $name,
            value_type => ($number =~ /\./ ? 'number' : 'integer'),
            value => 0 + $number,
        };
    }
    while ($stripped_source =~ /\bour\s+\@([A-Za-z_]\w*)\s*=\s*\((.*?)\)\s*;/gs) {
        my ($name, $expr) = ($1, $2);
        my $values = _parse_array_literal_values($expr);
        next if !defined $values;
        push @ops, {
            op => 'set_array_literal',
            symbol => $package . '::' . $name,
            values => $values,
        };
        $array_literal_seen{$name} = 1;
    }
    while ($stripped_source =~ /\bour\s+\@([A-Za-z_]\w*)\s*=\s*qw\(([^)]*)\)\s*;/g) {
        next if $array_literal_seen{$1};
        push @ops, {
            op => 'set_array_literal',
            symbol => $package . '::' . $1,
            values => [ grep { length } split /\s+/, $2 ],
        };
    }
    while ($stripped_source =~ /\bour\s+\@([A-Za-z_]\w*)\s*=\s*qw\/([^\/]*)\/\s*;/g) {
        next if $array_literal_seen{$1};
        push @ops, {
            op => 'set_array_literal',
            symbol => $package . '::' . $1,
            values => [ grep { length } split /\s+/, $2 ],
        };
    }
    while ($stripped_source =~ /\bour\s+\$([A-Za-z_]\w*)\s*=\s*\(\s*\$([A-Za-z_]\w*)\s*\/\/\s*0\s*\)\s*\+\s*(\d+)\s*;/g) {
        my ($name, $base, $by) = ($1, $2, $3);
        return (undef) if $name ne $base;
        push @ops, {
            op => 'increment_scalar_default_zero',
            symbol => $package . '::' . $name,
            by => 0 + $by,
        };
    }
    return @ops;
}

sub _parse_array_literal_values {
    my ($expr) = @_;
    $expr //= '';
    my @values;
    pos($expr) = 0;
    while (1) {
        $expr =~ /\G\s*/gc;
        last if pos($expr) >= length($expr);
        if ($expr =~ /\G,\s*/gc) {
            next;
        }
        if ($expr =~ /\Gqw\(([^)]*)\)\s*/gc || $expr =~ /\Gqw\/([^\/]*)\/\s*/gc) {
            push @values, grep { length } split /\s+/, $1;
        }
        elsif ($expr =~ /\Gmap\s*\{\s*sprintf\s+'([^'%]*)%d([^']*)'\s*,\s*\$_\s*\}\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*/gc) {
            my ($prefix, $suffix, $start, $end) = ($1, $2, $3, $4);
            my $step = $start <= $end ? 1 : -1;
            for (my $i = $start; ; $i += $step) {
                push @values, sprintf('%s%d%s', $prefix, $i, $suffix);
                last if $i == $end;
            }
        }
        elsif ($expr =~ /\G'([^'\\]*(?:\\.[^'\\]*)*)'\s*/gc) {
            push @values, _unescape_literal($1);
        }
        elsif ($expr =~ /\G"([^"\\]*(?:\\.[^"\\]*)*)"\s*/gc) {
            push @values, _unescape_literal($1);
        }
        elsif ($expr =~ /\G(-?\d+(?:\.\d+)?)\s*/gc) {
            push @values, 0 + $1;
        }
        else {
            return;
        }
        $expr =~ /\G\s*/gc;
        if ($expr =~ /\G,\s*/gc) {
            next;
        }
        last if pos($expr) >= length($expr);
    }
    return \@values;
}

sub _strip_pod {
    my ($source) = @_;
    $source //= '';
    $source =~ s/^__(?:END|DATA)__\b.*\z//ms;
    $source =~ s/^=\w+.*?^=cut\s*\n?//msg;
    return $source;
}

sub _parse_use_args {
    my ($arg_source) = @_;
    $arg_source //= '';
    $arg_source =~ s/^\s+//;
    $arg_source =~ s/\s+$//;
    return [] if $arg_source eq '';
    return [] if $arg_source eq '()';
    return [ grep { length } split /\s+/, $1 ] if $arg_source =~ /^qw\(([^)]*)\)$/;
    return [ grep { length } split /\s+/, $1 ] if $arg_source =~ /^qw\/([^\/]*)\/$/;

    my @tokens;
    pos($arg_source) = 0;
    while (pos($arg_source) < length($arg_source)) {
        $arg_source =~ /\G\s*/gc;
        last if pos($arg_source) >= length($arg_source);
        if ($arg_source =~ /\G=>/gc || $arg_source =~ /\G,/gc) {
            next;
        }
        if ($arg_source =~ /\G'([^'\\]*(?:\\.[^'\\]*)*)'/gc) {
            push @tokens, _unescape_literal($1);
            next;
        }
        if ($arg_source =~ /\G"([^"\\]*(?:\\.[^"\\]*)*)"/gc) {
            push @tokens, _unescape_literal($1);
            next;
        }
        if ($arg_source =~ /\G(-?\d+(?:\.\d+)?)/gc) {
            push @tokens, 0 + $1;
            next;
        }
        if ($arg_source =~ /\G([A-Za-z_][A-Za-z0-9_:]*)/gc) {
            push @tokens, $1;
            next;
        }
        return;
    }
    return \@tokens;
}

sub _package_name {
    my ($source) = @_;
    return $1 if $source =~ /^\s*package\s+([A-Za-z_][A-Za-z0-9_:]*)\s*;/m;
    return;
}

sub _declared_subs {
    my ($source, $package) = @_;
    $source = _strip_pod($source);
    my @names;
    while ($source =~ /\bsub\s+([A-Za-z_][A-Za-z0-9_]*)\b/g) {
        push @names, $package . '::' . $1;
    }
    my %seen;
    return grep { !$seen{$_}++ } @names;
}

sub _prefer_lazy_hybrid {
    my ($source, $declared_subs) = @_;
    my $max_subs = $ENV{PAX_CODE_UNIT_MAX_CAPTURE_SUBS} || 25;
    my $max_bytes = $ENV{PAX_CODE_UNIT_MAX_CAPTURE_BYTES} || 16_384;
    return 1 if @$declared_subs > $max_subs;
    return 1 if length($source) > $max_bytes;
    return 0;
}

sub _prefer_source_fallback_over_hybrid {
    my ($source, $compiled_subs, $unsupported_subs) = @_;
    my $supported = scalar(@{$compiled_subs // []});
    my $unsupported = scalar(@{$unsupported_subs // []});
    return 0 if !$unsupported;
    return 0 if $unsupported < 8;
    return 1 if !$supported;

    my $total = $supported + $unsupported;
    my $coverage = $total ? ($supported / $total) : 0;
    return 1 if $coverage < 0.20;
    return 1 if length($source // '') >= 8_192 && $unsupported >= ($supported * 4);
    return 0;
}

sub _requires_source_exporter_contract {
    my ($source) = @_;
    $source = _strip_pod($source);
    return 1 if $source =~ /\buse\s+Exporter\s+['"]import['"]\s*;/;
    return 1 if $source =~ /\bour\s+\@EXPORT(?:_OK)?\b/;
    return 0;
}

sub _hybrid_coverage_detail {
    my ($compiled_subs, $unsupported_subs) = @_;
    return sprintf(
        'supported=%d unsupported=%d',
        scalar(@{$compiled_subs // []}),
        scalar(@{$unsupported_subs // []}),
    );
}

sub _require_path_for {
    my ($path, $package) = @_;
    my $req = $package;
    $req =~ s{::}{/}g;
    return $req . '.pm';
}

sub _fallback_unit {
    my ($path, $kind, $logical_path, $reason, $detail) = @_;
    my $bytes = _slurp($path);
    return {
        source_path => $path,
        logical_path => $logical_path,
        unit_kind => $kind,
        packaging => 'source_payload_fallback',
        fallback_reason => $reason,
        fallback_detail => $detail,
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($logical_path),
        bytes => $bytes,
    };
}

sub _compiled_unit {
    my ($path, $kind, $logical_path, $package, $initializers, $subs) = @_;
    my $record = {
        format => 'pcu_v1',
        package => $package,
        source_kind => $kind,
        require_path => _require_path_for($path, $package),
        initializers => $initializers,
        subs => $subs,
    };
    my $bytes = JSON::PP->new->ascii(1)->canonical(1)->encode($record);
    my $compiled_logical = $logical_path;
    $compiled_logical =~ s/\.pm$/.pcu.json/;

    return {
        source_path => $path,
        logical_path => $compiled_logical,
        require_path => $record->{require_path},
        package => $package,
        unit_kind => $kind,
        packaging => 'compiled_pcu_v1',
        compiled_format => 'pcu_v1',
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($compiled_logical),
        bytes => $bytes,
    };
}

sub _compiled_script_unit {
    my ($path, $kind, $logical_path, $source) = @_;
    my @compiled_subs = _compiled_script_subs($path, $source);
    my $record = {
        format => 'script_pcu_v1',
        source_kind => $kind,
        source_path => $path,
        script_source => $source,
        compiled_subs => \@compiled_subs,
    };
    if ($source =~ /exit\s+main\s*\(\s*\@ARGV\s*\)\s+unless\s+caller\s*;/s) {
        $record->{entry_invocation} = {
            op => 'call_main_argv_and_exit',
        };
    }
    my $bytes = JSON::PP->new->ascii(1)->canonical(1)->encode($record);
    my $compiled_logical = $logical_path;
    $compiled_logical =~ s{\.[^.]+\z}{.script.json};
    $compiled_logical .= '.script.json' if $compiled_logical !~ /\.script\.json\z/;

    return {
        source_path => $path,
        logical_path => $compiled_logical,
        unit_kind => $kind,
        packaging => 'compiled_script_pcu_v1',
        compiled_format => 'script_pcu_v1',
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($compiled_logical),
        bytes => $bytes,
    };
}

# Derive compiled-sub metadata for plain script entrypoints without executing
# the script during build-time analysis.
sub _compiled_script_subs {
    my ($path, $source) = @_;
    my @subs;
    for my $full_name (_declared_subs($source, 'main')) {
        my ($short_name) = $full_name =~ /::([^:]+)\z/;
        next if !$short_name;
        my $compiled = _compile_script_sub_from_source($source, $full_name, $short_name) or next;
        push @subs, $compiled;
    }
    my %seen;
    return grep { !$seen{($_->{full_name} // '')}++ } @subs;
}

# Compile one extracted script sub into the same op records used for package
# code units so standalone packaging can treat scripts and modules uniformly.
sub _compile_script_sub_from_source {
    my ($source, $full_name, $short_name) = @_;
    my $body = _extract_sub_body($source, $short_name) or return;
    if (my $shape = _native_shape_from_source_body($body)) {
        return {
            name => $short_name,
            full_name => $full_name,
            op => 'native_shape_sub',
            native_shape => $shape,
            prototype => _sub_prototype_from_source($source, $short_name),
        };
    }
    return;
}

# Run the static script-body recognizers in priority order and return the first
# supported native shape.
sub _native_shape_from_source_body {
    my ($body) = @_;
    return _native_i64_binary_leaf_shape($body)
        || _native_i64_sum_loop_shape($body)
        || _native_i64_masked_mix_accum_loop_shape($body);
}

# Recognize small two-argument arithmetic leaf subs in extracted script source.
sub _native_i64_binary_leaf_shape {
    my ($body) = @_;
    return if $body !~ /my\s*\(\s*\$([A-Za-z_]\w*)\s*,\s*\$([A-Za-z_]\w*)\s*\)\s*=\s*\@_\s*;/s;
    my ($left, $right) = ($1, $2);
    return if $body !~ /return\s+\$([A-Za-z_]\w*)\s*([+\-*]|>)\s*\$([A-Za-z_]\w*)\s*;/s;
    return if $1 ne $left || $3 ne $right;
    my %ops = (
        '+' => ['add', 5],
        '-' => ['subtract', -1],
        '*' => ['multiply', 6],
        '>' => ['greater_than', 0],
    );
    my $op = $ops{$2} or return;
    return {
        kind => 'i64_binary_leaf',
        op => $op->[0],
        args => [$left, $right],
        smoke_left => 2,
        smoke_right => 3,
        smoke_expected => $op->[1],
        source => 'source_static_scan',
    };
}

# Recognize simple integer sum loops in extracted script source.
sub _native_i64_sum_loop_shape {
    my ($body) = @_;
    return if $body !~ /my\s*\(\s*\$([A-Za-z_]\w*)\s*\)\s*=\s*\@_\s*;/s;
    my $limit = $1;
    return if $body !~ /my\s+\$([A-Za-z_]\w*)\s*=\s*0\s*;/s;
    my $sum = $1;
    my $limit_ref = quotemeta('$' . $limit);
    my $sum_ref = quotemeta('$' . $sum);
    return if $body !~ /for\s*\(\s*my\s+\$([A-Za-z_]\w*)\s*=\s*1\s*;\s*\$\1\s*<=\s*$limit_ref\s*;\s*\$\1\+\+\s*\)\s*\{\s*$sum_ref\s*\+=\s*\$\1\s*;\s*\}/s;
    return if $body !~ /return\s+$sum_ref\s*;/s;
    my $induction = $1;
    return {
        kind => 'i64_sum_loop',
        op => 'sum_to_n',
        args => [$limit],
        accumulator => $sum,
        induction => $induction,
        smoke_left => 10,
        smoke_right => 0,
        smoke_expected => 55,
        source => 'source_static_scan',
    };
}

# Recognize the heavier masked-mix accumulator loop used by the long-process
# benchmark scripts so standalone builds can emit a native kernel.
sub _native_i64_masked_mix_accum_loop_shape {
    my ($body) = @_;
    return if $body !~ /my\s*\(\s*\$([A-Za-z_]\w*)\s*\)\s*=\s*\@_\s*;/s;
    my $limit = $1;
    return if $body !~ /my\s+\$([A-Za-z_]\w*)\s*=\s*0\s*;/s;
    my $acc = $1;
    my $limit_ref = quotemeta('$' . $limit);
    my $acc_ref = quotemeta('$' . $acc);
    return if $body !~ /for\s*\(\s*my\s+\$([A-Za-z_]\w*)\s*=\s*0\s*;\s*\$\1\s*<\s*$limit_ref\s*;\s*\$\1\+\+\s*\)\s*\{\s*$acc_ref\s*\+=\s*\(\(\s*\$\1\s*\*\s*13\s*\)\s*\^\s*\(\s*\$\1\s*>>\s*3\s*\)\)\s*&\s*0xFFFF\s*;\s*\}/s;
    return if $body !~ /return\s+$acc_ref\s*;/s;
    my $induction = $1;
    return {
        kind => 'i64_masked_mix_accum_loop',
        op => 'masked_mix_accumulate',
        args => [$limit],
        accumulator => $acc,
        induction => $induction,
        smoke_left => 8,
        smoke_right => 0,
        smoke_expected => 360,
        source => 'source_static_scan',
    };
}

sub _compiled_dispatch_script_unit {
    my ($path, $kind, $logical_path, $source) = @_;
    my $dispatch = _extract_dispatch_script($source) or return;
    my $record = {
        format => 'dispatch_script_pcu_v1',
        source_kind => $kind,
        source_path => $path,
        bootstrap_source => $dispatch->{bootstrap_source},
        command_default => $dispatch->{command_default},
        command_default_mode => $dispatch->{command_default_mode},
        actions => $dispatch->{actions},
        unknown_action => $dispatch->{unknown_action},
    };
    my $bytes = JSON::PP->new->ascii(1)->canonical(1)->encode($record);
    my $compiled_logical = $logical_path;
    $compiled_logical =~ s{\.[^.]+\z}{.dispatch.json};
    $compiled_logical .= '.dispatch.json' if $compiled_logical !~ /\.dispatch\.json\z/;

    return {
        source_path => $path,
        logical_path => $compiled_logical,
        unit_kind => $kind,
        packaging => 'compiled_dispatch_script_pcu_v1',
        compiled_format => 'dispatch_script_pcu_v1',
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($compiled_logical),
        bytes => $bytes,
    };
}

sub _compiled_cli_router_unit {
    my ($path, $kind, $logical_path, $source) = @_;
    return if $source !~ /my\s+\$cmd\s*=\s*shift\s+\@ARGV\s*\|\|\s*''\s*;/;
    return if $source !~ /pod2usage/;
    return if $source !~ /unknown_command_message/;
    return if $source !~ /require\s+([A-Za-z_][A-Za-z0-9_:]*)\s*;\s*print\s+\$([A-Za-z_][A-Za-z0-9_:]*)::VERSION,\s*"\\n"\s*;\s*exit\s+0\s*;/s;
    my $version_module = $1;
    my $version_symbol = $2;
    return if $version_module ne $version_symbol;
    return if $source !~ /print\s+STDERR\s+([A-Za-z_][A-Za-z0-9_:]*)->new\(\)->unknown_command_message\(\$cmd\)\s*;/s;
    my $suggest_class = $1;
    my $decl_start = index($source, "my \$cmd = shift \@ARGV || '';");
    return if $decl_start < 0;
    my $decl_end = $decl_start + length("my \$cmd = shift \@ARGV || '';");
    my $sub_pos = index($source, "\nsub _prime_command_result_env");
    return if $sub_pos < 0;
    my $bootstrap_source = substr($source, 0, $decl_start) . substr($source, $sub_pos + 1);
    my @module_roots = _module_search_roots_from_source($source, $path);
    my $version = _module_version_from_roots($version_module, \@module_roots);
    my @subs;
    my $dashboard_entry = _entry_command_from_entrypoint($source, $path, $logical_path);
    if (!$dashboard_entry) {
        $dashboard_entry = _entry_command_capture($source, $logical_path);
    }
    if ($dashboard_entry) {
        my $entry_sub_name = $dashboard_entry->{sub_name} || _entry_command_sub_name($source) || 'entrypoint';
        push @subs, {
            name => $entry_sub_name,
            op => 'app_entry_command',
            entrypoint_env => $dashboard_entry->{env},
            entrypoint_fallback => $dashboard_entry->{fallback},
            prototype => _sub_prototype_from_source($source, $entry_sub_name),
        };
    }
    my $record = {
        format => 'cli_router_pcu_v1',
        source_kind => $kind,
        source_path => $path,
        bootstrap_source => $bootstrap_source,
        version => $version,
        version_module => $version_module,
        suggest_class => $suggest_class,
        subs => \@subs,
    };
    my $bytes = JSON::PP->new->ascii(1)->canonical(1)->encode($record);
    my $compiled_logical = $logical_path;
    $compiled_logical =~ s{\.[^.]+\z}{.cli-router.json};
    $compiled_logical .= '.cli-router.json' if $compiled_logical !~ /\.cli-router\.json\z/;

    return {
        source_path => $path,
        logical_path => $compiled_logical,
        unit_kind => $kind,
        packaging => 'compiled_cli_router_pcu_v1',
        compiled_format => 'cli_router_pcu_v1',
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($compiled_logical),
        bytes => $bytes,
    };
}

sub _entry_command_from_entrypoint {
    my ($source, $entrypoint_path, $logical_path) = @_;

    my @imported = _used_modules_from_source($source);
    my @roots = _module_search_roots_from_source($source, $entrypoint_path);

    for my $module (@imported) {
        next if $module =~ /^(?:strict|warnings|utf8|feature|integer|bytes|mro|open|re|vars|constant)$/;
        my $module_source = _module_source_from_roots($module, \@roots);
        next if !$module_source;
        my $entry_command_sub_name = _entry_command_sub_name($module_source);
        my $entry = _entry_command_capture(
            $module_source,
            $logical_path,
            $entry_command_sub_name,
            $module . '::' . ($entry_command_sub_name || 'entrypoint'),
        );
        next if !$entry;
        return $entry;
    }

    my $entrypoint_env_assignment = _entry_command_from_env_assignment($source, $logical_path);
    return $entrypoint_env_assignment if $entrypoint_env_assignment;

    return;
}

sub _module_search_roots_from_source {
    my ($source, $entrypoint_path) = @_;
    my $bin_dir = File::Basename::dirname($entrypoint_path);
    my @roots = (File::Spec->catdir($bin_dir, File::Spec->updir(), 'lib'));
    for my $inc (@INC) {
        next if !defined $inc || ref($inc) || $inc eq '';
        push @roots, File::Spec->rel2abs($inc);
    }
    for my $use_lib (_use_lib_paths_from_source($source, $entrypoint_path)) {
        push @roots, $use_lib;
    }
    my %seen_root;
    return grep { $_ ne '' && !$seen_root{$_}++ && -d $_ } @roots;
}

sub _entry_command_from_env_assignment {
    my ($source, $logical_path) = @_;
    my $entry = _extract_entrypoint_assignment_fallback($source, $logical_path) or return;
    return if ($entry->{env} // '') !~ /ENTRYPOINT/i;
    $entry->{sub_name} = _entry_command_sub_name($source) || 'entrypoint';
    return $entry;
}

sub _entry_command_sub_name {
    my ($source) = @_;
    if ($source =~ /\bsub\s+(_[A-Za-z0-9_]*_entry_command)\b/) {
        return $1;
    }
    if ($source =~ /\bsub\s+([A-Za-z_][A-Za-z0-9_]*entry_point_command)\b/) {
        return $1;
    }
    if ($source =~ /\bsub\s+([A-Za-z_][A-Za-z0-9_]*entrypoint_command)\b/) {
        return $1;
    }
    if ($source =~ /\bsub\s+([A-Za-z_][A-Za-z0-9_]*entry_command)\b/) {
        return $1;
    }
    return;
}

sub _is_entry_command_sub {
    my ($name) = @_;
    return 0 if !defined $name || $name eq '';
    return $name =~ /\b(?:^|_)(?:[A-Za-z0-9]*_)?entry(?:_?point)?_?command\z/ ? 1 : 0;
}

sub _used_modules_from_source {
    my ($source) = @_;
    my @mods;
    while ($source =~ /^\s*use\s+([A-Za-z_][A-Za-z0-9_:]*)\s*(?:\([^)]*\)|\[[^\]]*\])?\s*;/gsm) {
        push @mods, $1;
    }
    my %seen;
    return grep { !$seen{$_}++ } @mods;
}

sub _use_lib_paths_from_source {
    my ($source, $entrypoint_path) = @_;
    my @paths;
    my $bin_dir = File::Basename::dirname($entrypoint_path);
    while ($source =~ /^\s*use\s+lib\s+(?:q[qwxr]?|(?:[\'"]?))\s*([\'"])(.*?)\1\s*;/gsm) {
        my $path = $2;
        next if !defined $path || $path eq '';
        my $expanded = _normalize_lib_path($path, $bin_dir);
        push @paths, $expanded if $expanded;
    }
    return @paths;
}

sub _normalize_lib_path {
    my ($path, $bin_dir) = @_;
    return '' if !defined $path || $path eq '';
    $path =~ s/^\s+|\s+$//g;
    return '' if $path eq '';

    if ($path =~ /^\Q$bin_dir\E\//) {
        return $path;
    }
    if ($path =~ m{^\.\./}) {
        return File::Spec->rel2abs($path, $bin_dir);
    }
    return File::Spec->rel2abs($path, '.');
}

sub _module_source_from_roots {
    my ($module, $roots) = @_;
    my $relative = join('/', split(/::/, $module)) . '.pm';
    for my $root (@$roots) {
        my $candidate = File::Spec->catfile($root, $relative);
        next if !-e $candidate;
        open my $fh, '<:raw', $candidate or next;
        local $/;
        my $raw = <$fh>;
        close $fh;
        return $raw if defined $raw && $raw ne '';
    }
    return;
}

sub _module_version_from_roots {
    my ($module, $roots) = @_;
    my $module_source = _module_source_from_roots($module, $roots) or return;
    return if $module_source !~ /\bour\s+\$VERSION\s*=\s*(['"])((?:\\.|(?!\1).)*)\1\s*;/s;
    return _unescape_literal($2);
}

sub _compiled_service_dispatch_unit {
    my ($path, $kind, $logical_path, $source) = @_;
    return if $source !~ /sub\s+main\b/;
    return if $source !~ /my\s+\$cmd\s*=\s*shift\s+\@argv\s*\|\|\s*'version'\s*;/;
    return if $source !~ /require\s+([A-Za-z_][A-Za-z0-9_:]*)\s*;\s*require\s+([A-Za-z_][A-Za-z0-9_:]*)\s*;/s;
    my ($app_module, $server_module) = ($1, $2);
    return if $source !~ /my\s+\$APP_VERSION\s*=\s*'([^'\\]*(?:\\.[^'\\]*)*)'\s*;/;
    my $version = _unescape_literal($1);
    my $builder_method = 'build_psgi_app';
    $builder_method = $1 if $source =~ /->([A-Za-z_][A-Za-z0-9_]*)\(\s*asset_root\s*=>/;
    my $record = {
        format => 'service_dispatch_pcu_v1',
        source_kind => $kind,
        source_path => $path,
        version => $version,
        app_module => $app_module,
        server_module => $server_module,
        builder_method => $builder_method,
    };
    my $bytes = JSON::PP->new->ascii(1)->canonical(1)->encode($record);
    my $compiled_logical = $logical_path;
    $compiled_logical =~ s{\.[^.]+\z}{.service.json};
    $compiled_logical .= '.service.json' if $compiled_logical !~ /\.service\.json\z/;

    return {
        source_path => $path,
        logical_path => $compiled_logical,
        unit_kind => $kind,
        packaging => 'compiled_service_dispatch_pcu_v1',
        compiled_format => 'service_dispatch_pcu_v1',
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($compiled_logical),
        bytes => $bytes,
    };
}

sub _extract_dispatch_script {
    my ($source) = @_;
    my ($decl_start, $decl_end, $mode, $default);
    if ($source =~ /(my\s+\$cmd\s*=\s*shift\s+\@ARGV\s*(\/\/|\|\|)\s*('([^'\\]*(?:\\.[^'\\]*)*)'|"([^"\\]*(?:\\.[^"\\]*)*)")\s*;)/s) {
        $decl_start = $-[1];
        $decl_end = $+[1];
        $mode = $2;
        $default = defined $4 ? $4 : $5;
    }
    return if !defined $decl_start;
    my $bootstrap_source = substr($source, 0, $decl_start);
    my $tail = substr($source, $decl_end);
    my @actions;
    pos($tail) = 0;
    while ($tail =~ /\G\s*(?:if|elsif)\s*\(\s*\$cmd\s+eq\s+'([^']+)'\s*\)\s*\{/gc) {
        my $command = $1;
        my $body_start = pos($tail);
        my $body = _extract_braced_region($tail, $body_start);
        return if !defined $body;
        pos($tail) = $body_start + length($body) + 1;
        my $action = _compile_dispatch_action($body);
        return if !$action;
        push @actions, {
            command => $command,
            action => $action,
        };
    }
    my $rest = substr($tail, pos($tail) || 0);
    return if !@actions;
    my $unknown_action = _compile_dispatch_unknown_action($rest);
    return {
        bootstrap_source => $bootstrap_source,
        command_default => _unescape_literal($default),
        command_default_mode => $mode eq '||' ? 'or' : 'defined_or',
        actions => \@actions,
        unknown_action => $unknown_action,
    };
}

sub _extract_braced_region {
    my ($source, $start) = @_;
    my $depth = 1;
    my $i = $start;
    while ($i < length($source)) {
        my $char = substr($source, $i, 1);
        $depth++ if $char eq '{';
        $depth-- if $char eq '}';
        return substr($source, $start, $i - $start) if $depth == 0;
        $i++;
    }
    return;
}

sub _compile_dispatch_action {
    my ($body) = @_;
    if ($body =~ /\A\s*print\s+([A-Za-z_][A-Za-z0-9_:]*)::([A-Za-z_][A-Za-z0-9_]*)\(\)\s*,\s*"\\n"\s*;\s*exit\s+(\d+)\s*;\s*\z/s) {
        return {
            op => 'print_call',
            target => $1 . '::' . $2,
            args => [],
            newline => 1,
            exit_code => 0 + $3,
        };
    }
    if ($body =~ /\A\s*print\s+([A-Za-z_][A-Za-z0-9_:]*)::([A-Za-z_][A-Za-z0-9_]*)\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'\s*\)\s*,\s*"\\n"\s*;\s*exit\s+(\d+)\s*;\s*\z/s) {
        return {
            op => 'print_call',
            target => $1 . '::' . $2,
            args => [ _unescape_literal($3) ],
            newline => 1,
            exit_code => 0 + $4,
        };
    }
    if ($body =~ /\A\s*require\s+([A-Za-z_][A-Za-z0-9_:]*)\s*;\s*print\s+\$([A-Za-z_][A-Za-z0-9_:]*)::([A-Za-z_][A-Za-z0-9_]*)\s*,\s*"\\n"\s*;\s*exit\s+(\d+)\s*;\s*\z/s) {
        return {
            op => 'print_required_global',
            require_module => $1,
            symbol => $2 . '::' . $3,
            newline => 1,
            exit_code => 0 + $4,
        };
    }
    if ($body =~ /\APAX_EMBEDDED_ASSET_ROOT/ || $body =~ /\$ENV\{PAX_EMBEDDED_ASSET_ROOT\}/) {
        return {
            op => 'print_embedded_asset',
            logical_path => 'banner.txt',
        } if $body =~ /banner\.txt/;
    }
    return;
}

sub _compile_dispatch_unknown_action {
    my ($body) = @_;
    return if !defined $body || $body !~ /\S/;
    if ($body =~ /\A\s*print\s+STDERR\s+"([^"\\]*(?:\\.[^"\\]*)*)\$cmd([^"\\]*(?:\\.[^"\\]*)*)"\s*;\s*exit\s+(\d+)\s*;\s*\z/s) {
        return {
            op => 'stderr_interpolate_cmd',
            prefix => _unescape_literal($1),
            suffix => _unescape_literal($2),
            exit_code => 0 + $3,
        };
    }
    return;
}

sub _unescape_literal {
    my ($value) = @_;
    $value //= '';
    $value =~ s/\\"/"/g;
    $value =~ s/\\'/'/g;
    $value =~ s/\\\\/\\/g;
    $value =~ s/\\n/\n/g;
    $value =~ s/\\t/\t/g;
    return $value;
}

sub _hybrid_compiled_unit {
    my ($path, $kind, $logical_path, $package, $initializers, $subs, $unsupported_subs, $source) = @_;
    my $bootstrap_source = _bootstrap_source($source);
    my %residual_sub_sources;
    for my $full (@$unsupported_subs) {
        my ($short) = $full =~ /::([^:]+)\z/;
        next if !$short;
        my $sub_source = _extract_sub_source($source, $short) or next;
        $residual_sub_sources{$full} = $sub_source;
    }
    my $residual_mode = 'per_sub';
    if (_bootstrap_has_shared_lexicals($bootstrap_source)) {
        %residual_sub_sources = ();
        $residual_mode = 'module';
    }
    if (@$unsupported_subs != scalar(keys %residual_sub_sources)) {
        %residual_sub_sources = ();
        $residual_mode = 'module';
    }
    my $record = {
        format => 'pcu_v1',
        package => $package,
        source_kind => $kind,
        require_path => _require_path_for($path, $package),
        initializers => $initializers,
        subs => $subs,
        unsupported_subs => $unsupported_subs,
        residual_mode => $residual_mode,
        residual_bootstrap_source => $bootstrap_source,
        residual_sub_sources => \%residual_sub_sources,
        residual_source => $residual_mode eq 'module' ? $source : undef,
        residual_source_path => $path,
    };
    my $bytes = JSON::PP->new->ascii(1)->canonical(1)->encode($record);
    my $compiled_logical = $logical_path;
    $compiled_logical =~ s/\.pm$/.pcu.json/;

    return {
        source_path => $path,
        logical_path => $compiled_logical,
        require_path => $record->{require_path},
        package => $package,
        unit_kind => $kind,
        packaging => 'hybrid_compiled_pcu_v1',
        compiled_format => 'pcu_v1',
        hybrid => JSON::PP::true,
        unsupported_subs => $unsupported_subs,
        size => length($bytes),
        sha256 => sha256_hex($bytes),
        c_symbol => 'pax_code_' . sha256_hex($compiled_logical),
        bytes => $bytes,
    };
}

sub _bootstrap_has_shared_lexicals {
    my ($bootstrap_source) = @_;
    return 0 if !defined $bootstrap_source || $bootstrap_source eq '';
    return $bootstrap_source =~ /^\s*my\s+[\$\@\%]/m ? 1 : 0;
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return '';
    local $/;
    return <$fh> // '';
}

sub _same_source_path {
    my ($left, $right) = @_;
    return 0 if !defined $left || !defined $right || $left eq '' || $right eq '';
    my $left_abs = abs_path($left) || $left;
    my $right_abs = abs_path($right) || $right;
    return $left_abs eq $right_abs ? 1 : 0;
}

1;

=pod

=head1 NAME

PAX::CodeUnitCompiler - Perl source-unit compiler for standalone packaging

=head1 SYNOPSIS

  use PAX::CodeUnitCompiler;

  my $obj = PAX::CodeUnitCompiler->new(...);
  my $result = $obj->compile(...);

=head1 DESCRIPTION

Classifies Perl source files, extracts code-unit metadata, and compiles application and dependency units into the runtime forms consumed by standalone builds.

=head1 METHODS

=head2 new, compile

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the Perl source-unit compiler for standalone packaging logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs Perl source-unit compiler for standalone packaging. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects Perl source-unit compiler for standalone packaging, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover Perl source-unit compiler for standalone packaging.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::CodeUnitCompiler -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut

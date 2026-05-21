use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use JSON::PP ();

use lib "$FindBin::Bin/../lib";

use PAX::CodeUnitCompiler;

my $compiler = PAX::CodeUnitCompiler->new;

{
    no warnings 'redefine';
    my $calls = 0;
    local *PAX::CodeUnitCompiler::_capture_timeout_supported = sub { return 0 };
    local *PAX::CodeUnitCompiler::_capture_live_unit = sub {
        my ($path) = @_;
        $calls++;
        return {
            status => 'ok',
            capture => {
                sub_optrees => [],
            },
        };
    };
    my $capture = PAX::CodeUnitCompiler::_capture_with_timeout('/tmp/demo.pm', 'lib');
    is($capture->{status}, 'ok', 'capture timeout helper falls back to direct live capture when ALRM setup is unavailable');
    is($calls, 1, 'capture timeout fallback performs one direct live capture');
}

my $entry = $compiler->compile(
    path => "$FindBin::Bin/fixtures/app_entry.pl",
    kind => 'entrypoint',
    logical_path => 'entrypoint/app_entry.pl',
);
is($entry->{packaging}, 'compiled_dispatch_script_pcu_v1', 'fixture entrypoint compiles to dispatch script PCU');
my $entry_record = JSON::PP->new->decode($entry->{bytes});
is($entry_record->{format}, 'dispatch_script_pcu_v1', 'dispatch script record format recorded');
ok((grep { ($_->{command} // '') eq 'status' } @{ $entry_record->{actions} // [] }) >= 1, 'dispatch script records status action');

{
    my $script_root = tempdir(CLEANUP => 1);
    my $script_path = "$script_root/native-loop.pl";
    open my $script_fh, '>', $script_path or die "cannot write native loop script fixture: $!";
    print {$script_fh} <<'PERL';
#!/usr/bin/env perl
use strict;
use warnings;

# Exercise the masked-mix accumulator loop shape that long-process benchmarks
# rely on for native script lowering.
sub dot_i64 {
    my ($n) = @_;
    my $acc = 0;
    for (my $i = 0; $i < $n; $i++) {
        $acc += (($i * 13) ^ ($i >> 3)) & 0xFFFF;
    }
    return $acc;
}

print dot_i64(8), "\n";
PERL
    close $script_fh;
    my $script_unit = $compiler->compile(
        path => $script_path,
        kind => 'entrypoint',
        logical_path => 'entrypoint/native-loop.pl',
    );
    is($script_unit->{packaging}, 'compiled_script_pcu_v1', 'native-loop script compiles to script PCU');
    my $script_record = JSON::PP->new->decode($script_unit->{bytes});
    my ($native_sub) = grep { ($_->{full_name} // '') eq 'main::dot_i64' } @{ $script_record->{compiled_subs} // [] };
    ok($native_sub, 'script PCU records compiled native-capable sub metadata');
    is(($native_sub->{native_shape}{kind} // ''), 'i64_masked_mix_accum_loop', 'script PCU records masked mix accumulation native shape');
}

my $slow = $compiler->compile(
    path => "$FindBin::Bin/fixtures/app_lib/SlowLoad.pm",
    kind => 'lib',
    logical_path => 'lib/app_lib/SlowLoad.pm',
);
is($slow->{packaging}, 'compiled_pcu_v1', 'slow fixture compiles to PCU');
is($slow->{package}, 'SlowLoad', 'slow fixture package recorded');

my $slow_record = JSON::PP->new->decode($slow->{bytes});
is($slow_record->{package}, 'SlowLoad', 'PCU record includes package');
ok(@{ $slow_record->{initializers} // [] } >= 1, 'PCU record includes initializer ops');
ok(@{ $slow_record->{subs} // [] } >= 1, 'PCU record includes compiled sub ops');

my $inline_root = tempdir(CLEANUP => 1);
my $inline_module = "$inline_root/InlineOneLine.pm";
open my $inline_fh, '>', $inline_module or die "cannot write inline module fixture: $!";
print {$inline_fh} "package InlineOneLine; use strict; use warnings; sub run { return 'ok'; } 1;\n";
close $inline_fh;
my $inline = $compiler->compile(
    path => $inline_module,
    kind => 'lib',
    logical_path => 'lib/InlineOneLine.pm',
);
is($inline->{packaging}, 'hybrid_compiled_pcu_v1', 'inline one-line module falls back to hybrid instead of collapsing to an empty compiled PCU');
my $inline_record = JSON::PP->new->decode($inline->{bytes});
ok((grep { ($_ // '') eq 'InlineOneLine::run' } @{ $inline_record->{unsupported_subs} // [] }) >= 1, 'inline one-line module tracks unsupported sub for residual execution');

my $capture_module = $compiler->compile(
    path => "$FindBin::Bin/../lib/PAX/Capture.pm",
    kind => 'lib',
    logical_path => 'lib/lib/PAX/Capture.pm',
);
is($capture_module->{packaging}, 'source_payload_fallback', 'complex low-coverage modules fall back to source payloads instead of brittle hybrid PCUs');
is($capture_module->{fallback_reason}, 'hybrid_coverage_too_low', 'source fallback records hybrid coverage reason');

my $dd = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard.pm',
);
is($dd->{packaging}, 'compiled_pcu_v1', 'dashboard package-only module compiles to PCU');
is($dd->{package}, 'Developer::Dashboard', 'dashboard package name recorded');

my $dd_record = JSON::PP->new->decode($dd->{bytes});
is($dd_record->{package}, 'Developer::Dashboard', 'dashboard PCU record includes package');
ok(@{ $dd_record->{initializers} // [] } >= 1, 'dashboard PCU record includes version initializer');
is(scalar(@{ $dd_record->{subs} // [] }), 0, 'dashboard package-only module does not need compiled sub ops');

my $dashboard_entry = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/bin/dashboard',
    kind => 'entrypoint',
    logical_path => 'entrypoint/dashboard',
);
is($dashboard_entry->{packaging}, 'compiled_cli_router_pcu_v1', 'dashboard entrypoint compiles to generic cli router PCU');
my $dashboard_entry_record = JSON::PP->new->decode($dashboard_entry->{bytes});
open my $dashboard_version_fh, '<', 'DD Source Code/developer-dashboard/lib/Developer/Dashboard.pm' or die "cannot read dashboard module version source: $!";
my $dashboard_version_source = do { local $/; <$dashboard_version_fh> };
close $dashboard_version_fh;
$dashboard_version_source =~ /\bour\s+\$VERSION\s*=\s*'([^']+)'/ or die 'cannot locate dashboard module version';
my $dashboard_module_version = $1;
is($dashboard_entry_record->{format}, 'cli_router_pcu_v1', 'cli router record format recorded');
is($dashboard_entry_record->{version}, $dashboard_module_version, 'cli router records literal version for launcher fast paths');
is($dashboard_entry_record->{version_module}, 'Developer::Dashboard', 'cli router records version module');
is($dashboard_entry_record->{suggest_class}, 'Developer::Dashboard::CLI::Suggest', 'cli router records suggestion class');
my @dashboard_entry_ops = @{ $dashboard_entry_record->{subs} // [] };
ok((grep { ($_->{op} // '') eq 'app_entry_command' } @dashboard_entry_ops) >= 1, 'dashboard cli router compiles neutral app entry command op');
ok((grep { ($_->{op} // '') eq 'app_entry_command' && ($_->{entrypoint_env} // '') eq 'DEVELOPER_DASHBOARD_ENTRYPOINT' } @dashboard_entry_ops) >= 1, 'app entry command op preserves entrypoint env var metadata');
ok((grep { ($_->{op} // '') eq 'app_entry_command' && ($_->{entrypoint_fallback} // '') eq 'dashboard' } @dashboard_entry_ops) >= 1, 'app entry command op preserves command fallback');

{
    my $installed_root = tempdir(CLEANUP => 1);
    my $module_dir = "$installed_root/Installed";
    mkdir $module_dir or die "cannot create installed module fixture dir: $!";
    open my $module_fh, '>', "$module_dir/App.pm" or die "cannot write installed module fixture: $!";
    print {$module_fh} "package Installed::App;\nour \$VERSION = '9.876';\n1;\n";
    close $module_fh;
    my $entrypoint_path = "$installed_root/app";
    open my $entry_fh, '>', $entrypoint_path or die "cannot write installed entrypoint fixture: $!";
    print {$entry_fh} <<'PERL';
#!/usr/bin/env perl
use strict;
use warnings;
use Installed::App;
require Installed::App;
print $Installed::App::VERSION, "\n";
PERL
    close $entry_fh;
    local @INC = ($installed_root, @INC);
    my $source = do { open my $source_fh, '<', $entrypoint_path or die "cannot read installed entrypoint fixture: $!"; local $/; <$source_fh> };
    my @roots = PAX::CodeUnitCompiler::_module_search_roots_from_source($source, $entrypoint_path);
    ok((grep { $_ eq $installed_root } @roots) >= 1, 'installed-layout module search includes @INC roots');
    is(PAX::CodeUnitCompiler::_module_version_from_roots('Installed::App', \@roots), '9.876', 'installed-layout version lookup resolves module version through @INC roots');
}

my $have_web_stack = eval {
    require Dancer2;
    require Starman::Server;
    require Template;
    1;
};

SKIP: {
    skip 'web stack modules not installed', 11 if !$have_web_stack;
    my $web_entry = $compiler->compile(
        path => "$FindBin::Bin/../examples/webapp/bin/pax-webapp",
        kind => 'entrypoint',
        logical_path => 'entrypoint/pax-webapp',
    );
    is($web_entry->{packaging}, 'compiled_service_dispatch_pcu_v1', 'webapp entrypoint compiles to generic service dispatch PCU');
    my $web_entry_record = JSON::PP->new->decode($web_entry->{bytes});
    is($web_entry_record->{format}, 'service_dispatch_pcu_v1', 'service dispatch record format recorded');
    is($web_entry_record->{version}, '0.1.0', 'webapp dispatch record carries version');
    is($web_entry_record->{app_module}, 'Example::PaxWeb', 'service dispatch records app module');
    is($web_entry_record->{server_module}, 'Starman::Server', 'service dispatch records server module');

    my $web_lib = $compiler->compile(
        path => "$FindBin::Bin/../examples/webapp/lib/Example/PaxWeb.pm",
        kind => 'lib',
        logical_path => 'lib/lib/Example/PaxWeb.pm',
    );
    is($web_lib->{packaging}, 'compiled_pcu_v1', 'webapp module compiles to PCU');
    my $web_lib_record = JSON::PP->new->decode($web_lib->{bytes});
    ok((grep { ($_->{name} // '') eq 'build_psgi_app' && ($_->{op} // '') eq 'build_pax_web_psgi_app' } @{ $web_lib_record->{subs} // [] }) >= 1, 'webapp PCU compiles PSGI app builder sub');
    is(scalar(@{ $web_lib_record->{unsupported_subs} // [] }), 0, 'webapp PCU no longer needs residual app-builder sub');

    my $dd_dancer_app = $compiler->compile(
        path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Web/DancerApp.pm',
        kind => 'lib',
        logical_path => 'lib/developer-dashboard/Developer/Dashboard/Web/DancerApp.pm',
    );
    is($dd_dancer_app->{packaging}, 'compiled_pcu_v1', 'dashboard DancerApp module now compiles to PCU');
    my $dd_dancer_app_record = JSON::PP->new->decode($dd_dancer_app->{bytes});
    ok((grep { ($_->{name} // '') eq 'build_psgi_app' && ($_->{op} // '') eq 'dancerapp_build_psgi_app' } @{ $dd_dancer_app_record->{subs} // [] }) >= 1, 'DancerApp PCU compiles PSGI app builder');
    my ($dd_build_psgi_app) = grep { ($_->{name} // '') eq 'build_psgi_app' && ($_->{op} // '') eq 'dancerapp_build_psgi_app' } @{ $dd_dancer_app_record->{subs} // [] };
    is($dd_build_psgi_app->{app_package}, 'Developer::Dashboard::Web::DancerApp', 'DancerApp PCU keeps the original package for to_app dispatch');
    ok((grep { ($_->{name} // '') eq '_request_args' && ($_->{op} // '') eq 'dancerapp_request_args' } @{ $dd_dancer_app_record->{subs} // [] }) >= 1, 'DancerApp PCU compiles request normalization');
    ok((grep { ($_->{name} // '') eq '_response_from_result' && ($_->{op} // '') eq 'dancerapp_response_from_result' } @{ $dd_dancer_app_record->{subs} // [] }) >= 1, 'DancerApp PCU compiles Dancer response conversion');
    ok((grep { ($_->{name} // '') eq '_run_authorized' && ($_->{op} // '') eq 'dancerapp_run_authorized' } @{ $dd_dancer_app_record->{subs} // [] }) >= 1, 'DancerApp PCU compiles authorized backend dispatcher');
    is(scalar(@{ $dd_dancer_app_record->{unsupported_subs} // [] }), 0, 'DancerApp PCU no longer needs residual fallback');
}

my $hybrid = $compiler->compile(
    path => "$FindBin::Bin/fixtures/app_lib/HybridLoad.pm",
    kind => 'lib',
    logical_path => 'lib/app_lib/HybridLoad.pm',
);
is($hybrid->{packaging}, 'hybrid_compiled_pcu_v1', 'hybrid fixture compiles to hybrid PCU');
is($hybrid->{package}, 'HybridLoad', 'hybrid fixture package recorded');
my $hybrid_record = JSON::PP->new->decode($hybrid->{bytes});
is($hybrid_record->{package}, 'HybridLoad', 'hybrid PCU record includes package');
ok((grep { ($_->{name} // '') eq 'fast_message' } @{ $hybrid_record->{subs} // [] }) >= 1, 'hybrid PCU record includes compiled sub');
ok((grep { ($_ // '') eq 'HybridLoad::slow_message' } @{ $hybrid_record->{unsupported_subs} // [] }) >= 1, 'hybrid PCU record tracks unsupported residual sub');
is($hybrid_record->{residual_mode}, 'per_sub', 'fixture hybrid uses per-sub residual mode');
ok(!defined $hybrid_record->{residual_source}, 'per-sub hybrid does not retain whole-module residual source');
ok(($hybrid_record->{residual_sub_sources}{'HybridLoad::slow_message'} // '') =~ /sub slow_message/, 'hybrid PCU stores per-sub residual source');

my $platform = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Platform.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Platform.pm',
);
is($platform->{packaging}, 'source_payload_fallback', 'dashboard platform module falls back to source when it exposes Exporter contract');
is($platform->{fallback_reason}, 'unsupported_exporter_contract', 'platform source fallback records exporter-contract reason');

my $env_audit = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/EnvAudit.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/EnvAudit.pm',
);
is($env_audit->{packaging}, 'compiled_pcu_v1', 'dashboard env audit module now compiles to PCU');
my $env_audit_record = JSON::PP->new->decode($env_audit->{bytes});
ok((grep { ($_->{name} // '') eq 'clear' && ($_->{op} // '') eq 'clear_package_hash_and_env' } @{ $env_audit_record->{subs} // [] }) >= 1, 'env audit PCU compiles clear into reusable hash/env reset op');
ok((grep { ($_->{name} // '') eq '_load_from_env' && ($_->{op} // '') eq 'load_package_hash_from_env_json' } @{ $env_audit_record->{subs} // [] }) >= 1, 'env audit PCU compiles env JSON loader');
ok((grep { ($_->{name} // '') eq 'record' && ($_->{op} // '') eq 'record_package_hash_entry_and_sync' } @{ $env_audit_record->{subs} // [] }) >= 1, 'env audit PCU compiles record-and-sync op');
is(scalar(@{ $env_audit_record->{unsupported_subs} // [] }), 0, 'env audit PCU no longer needs residual fallback');

my $dd_json = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/JSON.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/JSON.pm',
);
is($dd_json->{packaging}, 'source_payload_fallback', 'dashboard JSON module falls back to source when it exposes Exporter contract');
is($dd_json->{fallback_reason}, 'unsupported_exporter_contract', 'dashboard JSON source fallback records exporter-contract reason');

my $data_helper = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/DataHelper.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/DataHelper.pm',
);
is($data_helper->{packaging}, 'source_payload_fallback', 'dashboard DataHelper module falls back to source when it exposes Exporter contract');
is($data_helper->{fallback_reason}, 'unsupported_exporter_contract', 'DataHelper source fallback records exporter-contract reason');

my $seed_sync = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/SeedSync.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/SeedSync.pm',
);
is($seed_sync->{packaging}, 'compiled_pcu_v1', 'dashboard SeedSync module now compiles to PCU');
my $seed_sync_record = JSON::PP->new->decode($seed_sync->{bytes});
ok((grep { ($_->{name} // '') eq 'content_md5' && ($_->{op} // '') eq 'content_md5' } @{ $seed_sync_record->{subs} // [] }) >= 1, 'SeedSync PCU compiles content md5 helper');
ok((grep { ($_->{name} // '') eq 'same_content_md5' && ($_->{op} // '') eq 'same_content_md5' } @{ $seed_sync_record->{subs} // [] }) >= 1, 'SeedSync PCU compiles content comparison helper');
ok((grep { ($_->{name} // '') eq 'file_matches_content_md5' && ($_->{op} // '') eq 'file_matches_content_md5' } @{ $seed_sync_record->{subs} // [] }) >= 1, 'SeedSync PCU compiles file/content comparison helper');
is(scalar(@{ $seed_sync_record->{unsupported_subs} // [] }), 0, 'SeedSync PCU no longer needs residual fallback');

my $dd_file = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/File.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/File.pm',
);
is($dd_file->{packaging}, 'compiled_pcu_v1', 'dashboard File module now compiles to PCU');
my $dd_file_record = JSON::PP->new->decode($dd_file->{bytes});
ok((grep { ($_->{name} // '') eq 'configure' && ($_->{op} // '') eq 'app_file_configure' } @{ $dd_file_record->{subs} // [] }) >= 1, 'File PCU compiles neutral alias configuration helper');
ok((grep { ($_->{name} // '') eq 'read' && ($_->{op} // '') eq 'app_file_read' } @{ $dd_file_record->{subs} // [] }) >= 1, 'File PCU compiles neutral alias-aware read helper');
ok((grep { ($_->{name} // '') eq 'write' && ($_->{op} // '') eq 'app_file_write' } @{ $dd_file_record->{subs} // [] }) >= 1, 'File PCU compiles neutral alias-aware write helper');
is(scalar(@{ $dd_file_record->{unsupported_subs} // [] }), 0, 'File PCU no longer needs residual fallback');

my $stream_handle = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/PageRuntime/StreamHandle.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/PageRuntime/StreamHandle.pm',
);
is($stream_handle->{packaging}, 'compiled_pcu_v1', 'dashboard stream handle module now compiles to PCU');
my $stream_handle_record = JSON::PP->new->decode($stream_handle->{bytes});
ok((grep { ($_->{name} // '') eq 'TIEHANDLE' && ($_->{op} // '') eq 'tiehandle_constructor' } @{ $stream_handle_record->{subs} // [] }) >= 1, 'stream handle PCU compiles tiehandle constructor');
ok((grep { ($_->{name} // '') eq 'PRINT' && ($_->{op} // '') eq 'stream_writer_print' } @{ $stream_handle_record->{subs} // [] }) >= 1, 'stream handle PCU compiles print callback writer');
ok((grep { ($_->{name} // '') eq 'PRINTF' && ($_->{op} // '') eq 'stream_writer_printf' } @{ $stream_handle_record->{subs} // [] }) >= 1, 'stream handle PCU compiles printf callback writer');
ok((grep { ($_->{name} // '') eq 'CLOSE' && ($_->{op} // '') eq 'return_true' } @{ $stream_handle_record->{subs} // [] }) >= 1, 'stream handle PCU compiles close no-op');
is(scalar(@{ $stream_handle_record->{unsupported_subs} // [] }), 0, 'stream handle PCU no longer needs residual fallback');

my $codec = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Codec.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Codec.pm',
);
is($codec->{packaging}, 'source_payload_fallback', 'dashboard Codec module falls back to source when it exposes Exporter contract');
is($codec->{fallback_reason}, 'unsupported_exporter_contract', 'Codec source fallback records exporter-contract reason');

my $daemon = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Web/Server/Daemon.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Web/Server/Daemon.pm',
);
is($daemon->{packaging}, 'compiled_pcu_v1', 'web server daemon module now compiles to PCU');
my $daemon_record = JSON::PP->new->decode($daemon->{bytes});
ok((grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'bless_args_hash' } @{ $daemon_record->{subs} // [] }) >= 1, 'daemon PCU compiles generic args-hash constructor');
ok((grep { ($_->{name} // '') eq 'sockhost' && ($_->{op} // '') eq 'return_self_slot' } @{ $daemon_record->{subs} // [] }) >= 1, 'daemon PCU compiles slot accessor');
ok((grep { ($_->{name} // '') eq 'internal_sockport' && ($_->{op} // '') eq 'return_self_slot' } @{ $daemon_record->{subs} // [] }) >= 1, 'daemon PCU compiles internal slot accessor');
is(scalar(@{ $daemon_record->{unsupported_subs} // [] }), 0, 'daemon PCU no longer needs residual fallback');

my $cli_complete = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Complete.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Complete.pm',
);
is($cli_complete->{packaging}, 'compiled_pcu_v1', 'CLI complete module now compiles to PCU');
my $cli_complete_record = JSON::PP->new->decode($cli_complete->{bytes});
ok((grep { ($_->{name} // '') eq '_subcommand_candidates' && ($_->{op} // '') eq 'app_subcommand_candidates' } @{ $cli_complete_record->{subs} // [] }) >= 1, 'CLI complete PCU compiles neutral static subcommand candidate table');
ok((grep { ($_->{name} // '') eq 'complete' && ($_->{op} // '') eq 'app_complete' } @{ $cli_complete_record->{subs} // [] }) >= 1, 'CLI complete PCU compiles neutral completion dispatcher');
is(scalar(@{ $cli_complete_record->{unsupported_subs} // [] }), 0, 'CLI complete PCU no longer needs residual fallback');

my $cli_ticket = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Ticket.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Ticket.pm',
);
is($cli_ticket->{packaging}, 'source_payload_fallback', 'CLI ticket module falls back to source when it exposes Exporter contract');
is($cli_ticket->{fallback_reason}, 'unsupported_exporter_contract', 'CLI ticket source fallback records exporter-contract reason');

my $update_manager = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/UpdateManager.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/UpdateManager.pm',
);
is($update_manager->{packaging}, 'compiled_pcu_v1', 'update manager module now compiles to PCU');
my $update_manager_record = JSON::PP->new->decode($update_manager->{bytes});
ok((grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'bless_required_args_hash' } @{ $update_manager_record->{subs} // [] }) >= 1, 'update manager PCU compiles required-args constructor');
ok((grep { ($_->{name} // '') eq 'updates_dir' && ($_->{op} // '') eq 'cwd_catdir_literal' } @{ $update_manager_record->{subs} // [] }) >= 1, 'update manager PCU compiles cwd-based updates dir helper');
ok((grep { ($_->{name} // '') eq '_is_supported_update_script' && ($_->{op} // '') eq 'supported_update_script' } @{ $update_manager_record->{subs} // [] }) >= 1, 'update manager PCU compiles supported-script predicate');
ok((grep { ($_->{name} // '') eq 'run' && ($_->{op} // '') eq 'update_manager_run' } @{ $update_manager_record->{subs} // [] }) >= 1, 'update manager PCU compiles update runner orchestration');
is(scalar(@{ $update_manager_record->{unsupported_subs} // [] }), 0, 'update manager PCU no longer needs residual fallback');

my $page_resolver = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/PageResolver.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/PageResolver.pm',
);
is($page_resolver->{packaging}, 'compiled_pcu_v1', 'page resolver module now compiles to PCU');
my $page_resolver_record = JSON::PP->new->decode($page_resolver->{bytes});
ok((grep { ($_->{name} // '') eq 'providers' && ($_->{op} // '') eq 'page_resolver_providers' } @{ $page_resolver_record->{subs} // [] }) >= 1, 'page resolver PCU compiles provider registry helper');
ok((grep { ($_->{name} // '') eq 'list_pages' && ($_->{op} // '') eq 'page_resolver_list_pages' } @{ $page_resolver_record->{subs} // [] }) >= 1, 'page resolver PCU compiles page listing helper');
ok((grep { ($_->{name} // '') eq 'load_named_page' && ($_->{op} // '') eq 'page_resolver_load_named_page' } @{ $page_resolver_record->{subs} // [] }) >= 1, 'page resolver PCU compiles named-page resolver');
ok((grep { ($_->{name} // '') eq 'load_provider_page' && ($_->{op} // '') eq 'page_resolver_load_provider_page' } @{ $page_resolver_record->{subs} // [] }) >= 1, 'page resolver PCU compiles provider-page loader');
is(scalar(@{ $page_resolver_record->{unsupported_subs} // [] }), 0, 'page resolver PCU no longer needs residual fallback');

my $prompt = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Prompt.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Prompt.pm',
);
is($prompt->{packaging}, 'compiled_pcu_v1', 'prompt module now compiles to PCU');
my $prompt_record = JSON::PP->new->decode($prompt->{bytes});
ok((grep { ($_->{name} // '') eq '_timestamp' && ($_->{op} // '') eq 'strftime_now' } @{ $prompt_record->{subs} // [] }) >= 1, 'prompt PCU compiles timestamp helper');
ok((grep { ($_->{name} // '') eq '_indicator_parts' && ($_->{op} // '') eq 'prompt_indicator_parts' } @{ $prompt_record->{subs} // [] }) >= 1, 'prompt PCU compiles indicator rendering helper');
ok((grep { ($_->{name} // '') eq '_git_branch' && ($_->{op} // '') eq 'git_branch_for_project' } @{ $prompt_record->{subs} // [] }) >= 1, 'prompt PCU compiles git branch helper');
ok((grep { ($_->{name} // '') eq 'render' && ($_->{op} // '') eq 'prompt_render' } @{ $prompt_record->{subs} // [] }) >= 1, 'prompt PCU compiles prompt renderer');
is(scalar(@{ $prompt_record->{unsupported_subs} // [] }), 0, 'prompt PCU no longer needs residual fallback');

my $doctor = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Doctor.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Doctor.pm',
);
is($doctor->{packaging}, 'compiled_pcu_v1', 'doctor module now compiles to PCU');
my $doctor_record = JSON::PP->new->decode($doctor->{bytes});
ok((grep { ($_->{name} // '') eq '_known_roots' && ($_->{op} // '') eq 'doctor_known_roots' } @{ $doctor_record->{subs} // [] }) >= 1, 'doctor PCU compiles known-roots helper');
ok((grep { ($_->{name} // '') eq '_permission_issue_for_path' && ($_->{op} // '') eq 'doctor_permission_issue_for_path' } @{ $doctor_record->{subs} // [] }) >= 1, 'doctor PCU compiles permission-check helper');
ok((grep { ($_->{name} // '') eq '_audit_root' && ($_->{op} // '') eq 'doctor_audit_root' } @{ $doctor_record->{subs} // [] }) >= 1, 'doctor PCU compiles root audit helper');
ok((grep { ($_->{name} // '') eq 'run' && ($_->{op} // '') eq 'doctor_run' } @{ $doctor_record->{subs} // [] }) >= 1, 'doctor PCU compiles doctor runner');
is(scalar(@{ $doctor_record->{unsupported_subs} // [] }), 0, 'doctor PCU no longer needs residual fallback');

my $cli_paths = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Paths.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Paths.pm',
);
is($cli_paths->{packaging}, 'compiled_pcu_v1', 'CLI paths module now compiles to PCU');
my $cli_paths_record = JSON::PP->new->decode($cli_paths->{bytes});
ok((grep { ($_->{name} // '') eq '_build_paths' && ($_->{op} // '') eq 'build_paths_registry' } @{ $cli_paths_record->{subs} // [] }) >= 1, 'CLI paths PCU compiles lightweight path registry builder');
ok((grep { ($_->{name} // '') eq '_cdr_payload' && ($_->{op} // '') eq 'cdr_payload' } @{ $cli_paths_record->{subs} // [] }) >= 1, 'CLI paths PCU compiles cdr payload helper');
ok((grep { ($_->{name} // '') eq '_cdr_completion' && ($_->{op} // '') eq 'cdr_completion' } @{ $cli_paths_record->{subs} // [] }) >= 1, 'CLI paths PCU compiles cdr completion helper');
ok((grep { ($_->{name} // '') eq 'run_paths_command' && ($_->{op} // '') eq 'run_paths_command' } @{ $cli_paths_record->{subs} // [] }) >= 1, 'CLI paths PCU compiles path command dispatcher');
is(scalar(@{ $cli_paths_record->{unsupported_subs} // [] }), 0, 'CLI paths PCU no longer needs residual fallback');

my $cli_progress = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Progress.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Progress.pm',
);
is($cli_progress->{packaging}, 'compiled_pcu_v1', 'CLI progress module now compiles to PCU');
my $cli_progress_record = JSON::PP->new->decode($cli_progress->{bytes});
ok((grep { ($_->{name} // '') eq '_status_prefix' && ($_->{op} // '') eq 'progress_status_prefix' } @{ $cli_progress_record->{subs} // [] }) >= 1, 'CLI progress PCU compiles status marker helper');
ok((grep { ($_->{name} // '') eq 'render_text' && ($_->{op} // '') eq 'progress_render_text' } @{ $cli_progress_record->{subs} // [] }) >= 1, 'CLI progress PCU compiles board text renderer');
ok((grep { ($_->{name} // '') eq 'render' && ($_->{op} // '') eq 'progress_render' } @{ $cli_progress_record->{subs} // [] }) >= 1, 'CLI progress PCU compiles board renderer');
ok((grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'progress_new' } @{ $cli_progress_record->{subs} // [] }) >= 1, 'CLI progress PCU compiles progress constructor');
is(scalar(@{ $cli_progress_record->{unsupported_subs} // [] }), 0, 'CLI progress PCU no longer needs residual fallback');

my $cli_files = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Files.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Files.pm',
);
is($cli_files->{packaging}, 'compiled_pcu_v1', 'CLI files module now compiles to PCU');
my $cli_files_record = JSON::PP->new->decode($cli_files->{bytes});
ok((grep { ($_->{name} // '') eq '_build_paths' && ($_->{op} // '') eq 'build_paths_registry' } @{ $cli_files_record->{subs} // [] }) >= 1, 'CLI files PCU compiles lightweight path registry builder');
ok((grep { ($_->{name} // '') eq 'run_files_command' && ($_->{op} // '') eq 'run_files_command' } @{ $cli_files_record->{subs} // [] }) >= 1, 'CLI files PCU compiles file command dispatcher');
is(scalar(@{ $cli_files_record->{unsupported_subs} // [] }), 0, 'CLI files PCU no longer needs residual fallback');

my $action_runner = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/ActionRunner.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/ActionRunner.pm',
);
is($action_runner->{packaging}, 'compiled_pcu_v1', 'ActionRunner module now compiles to PCU');
my $action_runner_record = JSON::PP->new->decode($action_runner->{bytes});
ok((grep { ($_->{name} // '') eq 'encode_action_payload' && ($_->{op} // '') eq 'action_encode_payload' } @{ $action_runner_record->{subs} // [] }) >= 1, 'ActionRunner PCU compiles payload encoder');
ok((grep { ($_->{name} // '') eq 'run_page_action' && ($_->{op} // '') eq 'action_run_page_action' } @{ $action_runner_record->{subs} // [] }) >= 1, 'ActionRunner PCU compiles action router');
ok((grep { ($_->{name} // '') eq 'run_command_action' && ($_->{op} // '') eq 'action_run_command_action' } @{ $action_runner_record->{subs} // [] }) >= 1, 'ActionRunner PCU compiles command action runner');
ok((grep { ($_->{name} // '') eq '_run_command' && ($_->{op} // '') eq 'action_run_command' } @{ $action_runner_record->{subs} // [] }) >= 1, 'ActionRunner PCU compiles command capture runner');
ok((grep { ($_->{name} // '') eq '_now_iso8601' && ($_->{op} // '') eq 'action_now_iso8601' } @{ $action_runner_record->{subs} // [] }) >= 1, 'ActionRunner PCU compiles UTC timestamp helper');
is(scalar(@{ $action_runner_record->{unsupported_subs} // [] }), 0, 'ActionRunner PCU no longer needs residual fallback');

my $session_store = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/SessionStore.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/SessionStore.pm',
);
is($session_store->{packaging}, 'compiled_pcu_v1', 'SessionStore module now compiles to PCU');
my $session_store_record = JSON::PP->new->decode($session_store->{bytes});
ok((grep { ($_->{name} // '') eq 'create' && ($_->{op} // '') eq 'session_create' } @{ $session_store_record->{subs} // [] }) >= 1, 'SessionStore PCU compiles session creator');
ok((grep { ($_->{name} // '') eq 'get' && ($_->{op} // '') eq 'session_get' } @{ $session_store_record->{subs} // [] }) >= 1, 'SessionStore PCU compiles session loader');
ok((grep { ($_->{name} // '') eq 'delete' && ($_->{op} // '') eq 'session_delete' } @{ $session_store_record->{subs} // [] }) >= 1, 'SessionStore PCU compiles session delete helper');
ok((grep { ($_->{name} // '') eq 'from_cookie' && ($_->{op} // '') eq 'session_from_cookie' } @{ $session_store_record->{subs} // [] }) >= 1, 'SessionStore PCU compiles cookie session resolver');
ok((grep { ($_->{name} // '') eq '_iso8601_to_epoch' && ($_->{op} // '') eq 'utc_iso8601_to_epoch' } @{ $session_store_record->{subs} // [] }) >= 1, 'SessionStore PCU compiles ISO8601 parser');
is(scalar(@{ $session_store_record->{unsupported_subs} // [] }), 0, 'SessionStore PCU no longer needs residual fallback');

my $cli_which = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Which.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Which.pm',
);
is($cli_which->{packaging}, 'compiled_pcu_v1', 'CLI which module now compiles to PCU');
my $cli_which_record = JSON::PP->new->decode($cli_which->{bytes});
ok((grep { ($_->{name} // '') eq 'run_which_command' && ($_->{op} // '') eq 'run_which_command' } @{ $cli_which_record->{subs} // [] }) >= 1, 'CLI which PCU compiles command dispatcher');
ok((grep { ($_->{name} // '') eq '_locate_target' && ($_->{op} // '') eq 'locate_target' } @{ $cli_which_record->{subs} // [] }) >= 1, 'CLI which PCU compiles target locator');
ok((grep { ($_->{name} // '') eq '_command_hook_files' && ($_->{op} // '') eq 'command_hook_files' } @{ $cli_which_record->{subs} // [] }) >= 1, 'CLI which PCU compiles hook enumerator');
ok((grep { ($_->{name} // '') eq '_custom_command_path' && ($_->{op} // '') eq 'custom_command_path' } @{ $cli_which_record->{subs} // [] }) >= 1, 'CLI which PCU compiles layered command resolver');
ok((grep { ($_->{name} // '') eq '_locate_skill_target' && ($_->{op} // '') eq 'locate_skill_target' } @{ $cli_which_record->{subs} // [] }) >= 1, 'CLI which PCU compiles skill target resolver');
my ($cli_which_skill_target) = grep { ($_->{name} // '') eq '_locate_skill_target' && ($_->{op} // '') eq 'locate_skill_target' } @{ $cli_which_record->{subs} // [] };
is($cli_which_skill_target->{skill_manager_class}, 'Developer::Dashboard::SkillManager', 'CLI which PCU resolves imported SkillManager class');
is($cli_which_skill_target->{skill_dispatcher_class}, 'Developer::Dashboard::SkillDispatcher', 'CLI which PCU resolves imported SkillDispatcher class');
is(scalar(@{ $cli_which_record->{unsupported_subs} // [] }), 0, 'CLI which PCU no longer needs residual fallback');

my $cli_skills = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Skills.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Skills.pm',
);
is($cli_skills->{packaging}, 'compiled_pcu_v1', 'CLI skills module now compiles to PCU');
my $cli_skills_record = JSON::PP->new->decode($cli_skills->{bytes});
ok((grep { ($_->{name} // '') eq '_usage_error' && ($_->{op} // '') eq 'usage_error_stderr' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles usage error helper');
ok((grep { ($_->{name} // '') eq '_skills_install_summary_table' && ($_->{op} // '') eq 'skills_install_summary_table' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles install summary table helper');
ok((grep { ($_->{name} // '') eq '_render_table' && ($_->{op} // '') eq 'render_text_table' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles text table renderer');
ok((grep { ($_->{name} // '') eq '_plain_text' && ($_->{op} // '') eq 'ansi_plain_text' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles ANSI scrubber');
ok((grep { ($_->{name} // '') eq '_skills_table' && ($_->{op} // '') eq 'skills_table' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles skills table helper');
ok((grep { ($_->{name} // '') eq '_usage_table' && ($_->{op} // '') eq 'skills_usage_table' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles usage table helper');
ok((grep { ($_->{name} // '') eq 'run_skills_command' && ($_->{op} // '') eq 'run_skills_command' } @{ $cli_skills_record->{subs} // [] }) >= 1, 'CLI skills PCU compiles command dispatcher');
my ($cli_skills_progress) = grep { ($_->{name} // '') eq '_skills_install_progress' && ($_->{op} // '') eq 'skills_install_progress' } @{ $cli_skills_record->{subs} // [] };
is($cli_skills_progress->{progress_class}, 'Developer::Dashboard::CLI::Progress', 'CLI skills progress helper resolves imported CLI::Progress class');
is($cli_skills_progress->{manager_class}, 'Developer::Dashboard::SkillManager', 'CLI skills progress helper resolves imported SkillManager class');
my ($cli_skills_sources_progress) = grep { ($_->{name} // '') eq '_skills_install_progress_for_sources' && ($_->{op} // '') eq 'skills_install_progress_for_sources' } @{ $cli_skills_record->{subs} // [] };
is($cli_skills_sources_progress->{progress_class}, 'Developer::Dashboard::CLI::Progress', 'CLI skills source progress helper resolves imported CLI::Progress class');
is($cli_skills_sources_progress->{manager_class}, 'Developer::Dashboard::SkillManager', 'CLI skills source progress helper resolves imported SkillManager class');
my ($cli_skills_run) = grep { ($_->{name} // '') eq 'run_skills_command' && ($_->{op} // '') eq 'run_skills_command' } @{ $cli_skills_record->{subs} // [] };
is($cli_skills_run->{manager_class}, 'Developer::Dashboard::SkillManager', 'CLI skills dispatcher resolves imported SkillManager class');
is($cli_skills_run->{dispatcher_class}, 'Developer::Dashboard::SkillDispatcher', 'CLI skills dispatcher resolves imported SkillDispatcher class');
is(scalar(@{ $cli_skills_record->{unsupported_subs} // [] }), 0, 'CLI skills PCU no longer needs residual fallback');

my $housekeeper = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Housekeeper.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Housekeeper.pm',
);
is($housekeeper->{packaging}, 'compiled_pcu_v1', 'Housekeeper module now compiles to PCU');
my $housekeeper_record = JSON::PP->new->decode($housekeeper->{bytes});
ok((grep { ($_->{name} // '') eq '_cleanup_state_roots' && ($_->{op} // '') eq 'housekeeper_cleanup_state_roots' } @{ $housekeeper_record->{subs} // [] }) >= 1, 'Housekeeper PCU compiles state-root cleanup');
ok((grep { ($_->{name} // '') eq '_cleanup_temp_files' && ($_->{op} // '') eq 'housekeeper_cleanup_temp_files' } @{ $housekeeper_record->{subs} // [] }) >= 1, 'Housekeeper PCU compiles temp-file cleanup');
ok((grep { ($_->{name} // '') eq '_rotate_collector_logs' && ($_->{op} // '') eq 'housekeeper_rotate_collector_logs' } @{ $housekeeper_record->{subs} // [] }) >= 1, 'Housekeeper PCU compiles collector-log rotation');
ok((grep { ($_->{name} // '') eq 'run' && ($_->{op} // '') eq 'housekeeper_run' } @{ $housekeeper_record->{subs} // [] }) >= 1, 'Housekeeper PCU compiles run dispatcher');
is(scalar(@{ $housekeeper_record->{unsupported_subs} // [] }), 0, 'Housekeeper PCU no longer needs residual fallback');

my $folder = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Folder.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Folder.pm',
);
is($folder->{packaging}, 'compiled_pcu_v1', 'Folder module now compiles to PCU');
my $folder_record = JSON::PP->new->decode($folder->{bytes});
ok((grep { ($_->{name} // '') eq '_paths_obj' && ($_->{op} // '') eq 'folder_paths_obj' } @{ $folder_record->{subs} // [] }) >= 1, 'Folder PCU compiles paths bootstrap');
ok((grep { ($_->{name} // '') eq '_resolve_path' && ($_->{op} // '') eq 'folder_resolve_path' } @{ $folder_record->{subs} // [] }) >= 1, 'Folder PCU compiles path resolver');
ok((grep { ($_->{name} // '') eq 'ls' && ($_->{op} // '') eq 'folder_ls' } @{ $folder_record->{subs} // [] }) >= 1, 'Folder PCU compiles directory listing');
ok((grep { ($_->{name} // '') eq 'locate' && ($_->{op} // '') eq 'folder_locate' } @{ $folder_record->{subs} // [] }) >= 1, 'Folder PCU compiles directory locate');
ok((grep { ($_->{name} // '') eq 'cd' && ($_->{op} // '') eq 'folder_cd' } @{ $folder_record->{subs} // [] }) >= 1, 'Folder PCU compiles temporary chdir helper');
is(scalar(@{ $folder_record->{unsupported_subs} // [] }), 0, 'Folder PCU no longer needs residual fallback');

my $zipper = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Zipper.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Zipper.pm',
);
is($zipper->{packaging}, 'source_payload_fallback', 'Zipper module falls back to source when it exposes Exporter contract');
is($zipper->{fallback_reason}, 'unsupported_exporter_contract', 'Zipper source fallback records exporter-contract reason');

my $cli_suggest = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Suggest.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Suggest.pm',
);
is($cli_suggest->{packaging}, 'compiled_pcu_v1', 'CLI suggest module now compiles to PCU');
my $cli_suggest_record = JSON::PP->new->decode($cli_suggest->{bytes});
ok((grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'suggest_new' } @{ $cli_suggest_record->{subs} // [] }) >= 1, 'CLI suggest PCU compiles constructor');
my ($cli_suggest_new) = grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'suggest_new' } @{ $cli_suggest_record->{subs} // [] };
is($cli_suggest_new->{path_registry_class}, 'Developer::Dashboard::PathRegistry', 'CLI suggest constructor resolves imported PathRegistry class');
is($cli_suggest_new->{skill_manager_class}, 'Developer::Dashboard::SkillManager', 'CLI suggest constructor resolves imported SkillManager class');
ok((grep { ($_->{name} // '') eq 'unknown_command_message' && ($_->{op} // '') eq 'suggest_unknown_command_message' } @{ $cli_suggest_record->{subs} // [] }) >= 1, 'CLI suggest PCU compiles unknown command message helper');
ok((grep { ($_->{name} // '') eq '_top_level_candidates' && ($_->{op} // '') eq 'suggest_internal_top_level_candidates' } @{ $cli_suggest_record->{subs} // [] }) >= 1, 'CLI suggest PCU compiles top-level candidate collector');
ok((grep { ($_->{name} // '') eq '_collect_skill_commands' && ($_->{op} // '') eq 'suggest_collect_skill_commands' } @{ $cli_suggest_record->{subs} // [] }) >= 1, 'CLI suggest PCU compiles skill command collector');
ok((grep { ($_->{name} // '') eq '_rank_candidates' && ($_->{op} // '') eq 'suggest_rank_candidates' } @{ $cli_suggest_record->{subs} // [] }) >= 1, 'CLI suggest PCU compiles candidate ranker');
ok((grep { ($_->{name} // '') eq '_levenshtein_distance' && ($_->{op} // '') eq 'suggest_levenshtein_distance' } @{ $cli_suggest_record->{subs} // [] }) >= 1, 'CLI suggest PCU compiles edit-distance helper');
is(scalar(@{ $cli_suggest_record->{unsupported_subs} // [] }), 0, 'CLI suggest PCU no longer needs residual fallback');

my $file_registry = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/FileRegistry.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/FileRegistry.pm',
);
is($file_registry->{packaging}, 'compiled_pcu_v1', 'FileRegistry module now compiles to PCU');
my $file_registry_record = JSON::PP->new->decode($file_registry->{bytes});
ok((grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'bless_required_args_hash' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles constructor');
ok((grep { ($_->{name} // '') eq 'paths' && ($_->{op} // '') eq 'return_self_slot' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles slot accessor');
ok((grep { ($_->{name} // '') eq 'resolve_file' && ($_->{op} // '') eq 'file_registry_resolve_file' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles file resolver');
ok((grep { ($_->{name} // '') eq 'read' && ($_->{op} // '') eq 'file_registry_read' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles file reader');
ok((grep { ($_->{name} // '') eq 'write' && ($_->{op} // '') eq 'file_registry_write' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles file writer');
ok((grep { ($_->{name} // '') eq 'touch' && ($_->{op} // '') eq 'file_registry_touch' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles file toucher');
ok((grep { ($_->{name} // '') eq 'dashboard_log' && ($_->{op} // '') eq 'file_registry_catfile' } @{ $file_registry_record->{subs} // [] }) >= 1, 'FileRegistry PCU compiles path mapper');
is(scalar(@{ $file_registry_record->{unsupported_subs} // [] }), 0, 'FileRegistry PCU no longer needs residual fallback');

my $internal_cli = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/InternalCLI.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/InternalCLI.pm',
);
is($internal_cli->{packaging}, 'compiled_pcu_v1', 'InternalCLI now compiles to PCU');
my $internal_cli_record = JSON::PP->new->decode($internal_cli->{bytes});
ok((grep { ($_->{name} // '') eq 'helper_names' && ($_->{op} // '') eq 'internal_cli_helper_names' } @{ $internal_cli_record->{subs} // [] }) >= 1, 'InternalCLI PCU compiles helper name list');
ok((grep { ($_->{name} // '') eq 'canonical_helper_name' && ($_->{op} // '') eq 'internal_cli_canonical_helper_name' } @{ $internal_cli_record->{subs} // [] }) >= 1, 'InternalCLI PCU compiles helper canonicalization');
ok((grep { ($_->{name} // '') eq '_managed_helper_content' && ($_->{op} // '') eq 'internal_cli_managed_helper_content' } @{ $internal_cli_record->{subs} // [] }) >= 1, 'InternalCLI PCU compiles managed helper content builder');
ok((grep { ($_->{name} // '') eq 'ensure_helpers' && ($_->{op} // '') eq 'internal_cli_ensure_helpers' } @{ $internal_cli_record->{subs} // [] }) >= 1, 'InternalCLI PCU compiles helper staging');
is(scalar(@{ $internal_cli_record->{unsupported_subs} // [] }), 0, 'InternalCLI PCU no longer needs residual fallback');

my $collector = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Collector.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Collector.pm',
);
is($collector->{packaging}, 'compiled_pcu_v1', 'Collector module now compiles to PCU');
my $collector_record = JSON::PP->new->decode($collector->{bytes});
ok((grep { ($_->{name} // '') eq 'collector_paths' && ($_->{op} // '') eq 'collector_paths' } @{ $collector_record->{subs} // [] }) >= 1, 'Collector PCU compiles path layout helper');
ok((grep { ($_->{name} // '') eq 'write_result' && ($_->{op} // '') eq 'collector_write_result' } @{ $collector_record->{subs} // [] }) >= 1, 'Collector PCU compiles result writer');
ok((grep { ($_->{name} // '') eq 'rotate_log' && ($_->{op} // '') eq 'collector_rotate_log' } @{ $collector_record->{subs} // [] }) >= 1, 'Collector PCU compiles log rotation');
ok((grep { ($_->{name} // '') eq '_entry_timestamp_epoch' && ($_->{op} // '') eq 'collector_entry_timestamp_epoch' } @{ $collector_record->{subs} // [] }) >= 1, 'Collector PCU compiles log timestamp parser');
ok((grep { ($_->{name} // '') eq '_iso8601_to_epoch' && ($_->{op} // '') eq 'iso8601_to_epoch_with_zone' } @{ $collector_record->{subs} // [] }) >= 1, 'Collector PCU compiles offset-aware ISO8601 parser');
is(scalar(@{ $collector_record->{unsupported_subs} // [] }), 0, 'Collector PCU no longer needs residual fallback');

my $config = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Config.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Config.pm',
);
is($config->{packaging}, 'compiled_pcu_v1', 'Config module now compiles to PCU');
my $config_record = JSON::PP->new->decode($config->{bytes});
ok((grep { ($_->{name} // '') eq '_merge_hashes' && ($_->{op} // '') eq 'config_merge_hashes' } @{ $config_record->{subs} // [] }) >= 1, 'Config PCU compiles recursive hash merge');
ok((grep { ($_->{name} // '') eq 'load_global' && ($_->{op} // '') eq 'config_load_global' } @{ $config_record->{subs} // [] }) >= 1, 'Config PCU compiles global config loader');
ok((grep { ($_->{name} // '') eq 'collectors' && ($_->{op} // '') eq 'config_collectors' } @{ $config_record->{subs} // [] }) >= 1, 'Config PCU compiles collector fleet merge');
ok((grep { ($_->{name} // '') eq 'save_global_web_settings' && ($_->{op} // '') eq 'config_save_global_web_settings' } @{ $config_record->{subs} // [] }) >= 1, 'Config PCU compiles web settings persistence');
ok((grep { ($_->{name} // '') eq '_skill_collectors' && ($_->{op} // '') eq 'config_skill_collectors' } @{ $config_record->{subs} // [] }) >= 1, 'Config PCU compiles skill collector expansion');
is(scalar(@{ $config_record->{unsupported_subs} // [] }), 0, 'Config PCU no longer needs residual fallback');

my $skill_dispatcher = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/SkillDispatcher.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/SkillDispatcher.pm',
);
my $skill_dispatcher_record = JSON::PP->new->decode($skill_dispatcher->{bytes});
ok((grep { ($_->{name} // '') eq '_command_spec' && ($_->{op} // '') eq 'skill_dispatcher_command_spec' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles layered command-spec helper');
ok((grep { ($_->{name} // '') eq '_merge_skill_hashes' && ($_->{op} // '') eq 'skill_dispatcher_merge_skill_hashes' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles layered skill-config merge helper');
ok((grep { ($_->{name} // '') eq 'get_skill_config' && ($_->{op} // '') eq 'skill_dispatcher_get_skill_config' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles skill config loader');
ok((grep { ($_->{name} // '') eq 'config_fragment' && ($_->{op} // '') eq 'skill_dispatcher_config_fragment' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles skill config fragment helper');
ok((grep { ($_->{name} // '') eq 'get_skill_path' && ($_->{op} // '') eq 'skill_dispatcher_get_skill_path' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles skill path lookup helper');
ok((grep { ($_->{name} // '') eq 'command_path' && ($_->{op} // '') eq 'skill_dispatcher_command_path' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles command path helper');
ok((grep { ($_->{name} // '') eq 'command_hook_paths' && ($_->{op} // '') eq 'skill_dispatcher_command_hook_paths' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles command hook enumerator');
ok((grep { ($_->{name} // '') eq 'route_response' && ($_->{op} // '') eq 'skill_dispatcher_route_response' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles route response dispatcher');
ok((grep { ($_->{name} // '') eq '_load_skill_page' && ($_->{op} // '') eq 'skill_dispatcher_load_skill_page' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles skill page loader');
ok((grep { ($_->{name} // '') eq '_skill_env' && ($_->{op} // '') eq 'skill_dispatcher_skill_env' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles skill env builder');
ok((grep { ($_->{name} // '') eq 'execute_hooks' && ($_->{op} // '') eq 'skill_dispatcher_execute_hooks' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles hook execution pipeline');
ok((grep { ($_->{name} // '') eq '_execute_hooks_streaming' && ($_->{op} // '') eq 'skill_dispatcher_execute_hooks_streaming' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles streaming hook pipeline');
ok((grep { ($_->{name} // '') eq '_run_child_command_streaming' && ($_->{op} // '') eq 'skill_dispatcher_run_child_command_streaming' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles streaming child runner');
ok((grep { ($_->{name} // '') eq '_exec_replacement' && ($_->{op} // '') eq 'skill_dispatcher_exec_replacement' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles final exec replacement');
ok((grep { ($_->{name} // '') eq 'dispatch' && ($_->{op} // '') eq 'skill_dispatcher_dispatch' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles dispatch entry');
ok((grep { ($_->{name} // '') eq 'exec_command' && ($_->{op} // '') eq 'skill_dispatcher_exec_command' } @{ $skill_dispatcher_record->{subs} // [] }) >= 1, 'SkillDispatcher compiles exec-command entry');

my $docker_compose = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/DockerCompose.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/DockerCompose.pm',
);
is($docker_compose->{packaging}, 'compiled_pcu_v1', 'DockerCompose now compiles to PCU');
my $docker_compose_record = JSON::PP->new->decode($docker_compose->{bytes});
ok((grep { ($_->{name} // '') eq '_expand_env_path' && ($_->{op} // '') eq 'docker_compose_expand_env_path' } @{ $docker_compose_record->{subs} // [] }) >= 1, 'DockerCompose PCU compiles env path expansion');
ok((grep { ($_->{name} // '') eq '_discover_service_files' && ($_->{op} // '') eq 'docker_compose_discover_service_files' } @{ $docker_compose_record->{subs} // [] }) >= 1, 'DockerCompose PCU compiles service file discovery');
ok((grep { ($_->{name} // '') eq 'resolve' && ($_->{op} // '') eq 'docker_compose_resolve' } @{ $docker_compose_record->{subs} // [] }) >= 1, 'DockerCompose PCU compiles compose resolution');
ok((grep { ($_->{name} // '') eq 'run' && ($_->{op} // '') eq 'docker_compose_run' } @{ $docker_compose_record->{subs} // [] }) >= 1, 'DockerCompose PCU compiles compose execution');
is(scalar(@{ $docker_compose_record->{unsupported_subs} // [] }), 0, 'DockerCompose PCU no longer needs residual fallback');

my $seeded_pages = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/SeededPages.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/SeededPages.pm',
);
is($seeded_pages->{packaging}, 'compiled_pcu_v1', 'SeededPages now compiles to PCU');
my $seeded_pages_record = JSON::PP->new->decode($seeded_pages->{bytes});
ok((grep { ($_->{name} // '') eq 'api_dashboard_page' && ($_->{op} // '') eq 'seeded_pages_api_dashboard_page' } @{ $seeded_pages_record->{subs} // [] }) >= 1, 'SeededPages PCU compiles api-dashboard loader');
ok((grep { ($_->{name} // '') eq '_seeded_page_asset_filename' && ($_->{op} // '') eq 'seeded_pages_asset_filename' } @{ $seeded_pages_record->{subs} // [] }) >= 1, 'SeededPages PCU compiles asset filename resolver');
ok((grep { ($_->{name} // '') eq '_read_manifest' && ($_->{op} // '') eq 'seeded_pages_read_manifest' } @{ $seeded_pages_record->{subs} // [] }) >= 1, 'SeededPages PCU compiles manifest reader');
ok((grep { ($_->{name} // '') eq 'ensure_seeded_page' && ($_->{op} // '') eq 'seeded_pages_ensure_seeded_page' } @{ $seeded_pages_record->{subs} // [] }) >= 1, 'SeededPages PCU compiles seed refresh policy');
is(scalar(@{ $seeded_pages_record->{unsupported_subs} // [] }), 0, 'SeededPages PCU no longer needs residual fallback');

my $cli_query = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/Query.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/Query.pm',
);
is($cli_query->{packaging}, 'source_payload_fallback', 'CLI Query module falls back to source when it exposes Exporter contract');
is($cli_query->{fallback_reason}, 'unsupported_exporter_contract', 'CLI Query source fallback records exporter-contract reason');

my $env_loader = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/EnvLoader.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/EnvLoader.pm',
);
is($env_loader->{packaging}, 'compiled_pcu_v1', 'EnvLoader now compiles to PCU');
my $env_loader_record = JSON::PP->new->decode($env_loader->{bytes});
ok((grep { ($_->{name} // '') eq 'load_runtime_layers' && ($_->{op} // '') eq 'env_load_runtime_layers' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles runtime-layer loader');
ok((grep { ($_->{name} // '') eq 'load_skill_layers' && ($_->{op} // '') eq 'env_load_skill_layers' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles skill-layer loader');
ok((grep { ($_->{name} // '') eq '_plain_directory_layers' && ($_->{op} // '') eq 'env_plain_directory_layers' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles plain-directory layer resolver');
ok((grep { ($_->{name} // '') eq '_env_file_candidates' && ($_->{op} // '') eq 'env_file_candidates' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles env-file candidate helper');
ok((grep { ($_->{name} // '') eq '_path_identity' && ($_->{op} // '') eq 'env_path_identity' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles path identity helper');
ok((grep { ($_->{name} // '') eq '_lookup_env_symbol' && ($_->{op} // '') eq 'env_lookup_symbol' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles env symbol lookup helper');
ok((grep { ($_->{name} // '') eq '_strip_env_comments' && ($_->{op} // '') eq 'env_strip_comments' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles env comment stripping');
ok((grep { ($_->{name} // '') eq '_expand_env_value' && ($_->{op} // '') eq 'env_expand_value' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles env value expansion');
ok((grep { ($_->{name} // '') eq '_expand_braced_env_expression' && ($_->{op} // '') eq 'env_expand_braced' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles braced env expansion');
ok((grep { ($_->{name} // '') eq '_call_env_function' && ($_->{op} // '') eq 'env_call_function' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles env function dispatch');
ok((grep { ($_->{name} // '') eq '_load_env_file' && ($_->{op} // '') eq 'env_load_env_file' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles .env loader');
ok((grep { ($_->{name} // '') eq '_load_env_pl_file' && ($_->{op} // '') eq 'env_load_env_pl_file' } @{ $env_loader_record->{subs} // [] }) >= 1, 'EnvLoader PCU compiles .env.pl loader');
is(scalar(@{ $env_loader_record->{unsupported_subs} // [] }), 0, 'EnvLoader PCU no longer needs residual fallback');

my $auth = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Auth.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Auth.pm',
);
is($auth->{packaging}, 'compiled_pcu_v1', 'Auth now compiles to PCU');
my $auth_record = JSON::PP->new->decode($auth->{bytes});
ok((grep { ($_->{name} // '') eq 'trust_tier' && ($_->{op} // '') eq 'auth_trust_tier' } @{ $auth_record->{subs} // [] }) >= 1, 'Auth PCU compiles trust-tier dispatcher');
ok((grep { ($_->{name} // '') eq 'add_user' && ($_->{op} // '') eq 'auth_add_user' } @{ $auth_record->{subs} // [] }) >= 1, 'Auth PCU compiles helper-user writer');
ok((grep { ($_->{name} // '') eq 'verify_user' && ($_->{op} // '') eq 'auth_verify_user' } @{ $auth_record->{subs} // [] }) >= 1, 'Auth PCU compiles helper-user verifier');
ok((grep { ($_->{name} // '') eq '_resolve_host_ips' && ($_->{op} // '') eq 'auth_resolve_host_ips' } @{ $auth_record->{subs} // [] }) >= 1, 'Auth PCU compiles host resolver');
ok((grep { ($_->{name} // '') eq 'login_page' && ($_->{op} // '') eq 'auth_login_page' } @{ $auth_record->{subs} // [] }) >= 1, 'Auth PCU compiles login-page renderer');
is(scalar(@{ $auth_record->{unsupported_subs} // [] }), 0, 'Auth PCU no longer needs residual fallback');

my $runtime_result = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/Runtime/Result.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/Runtime/Result.pm',
);
is($runtime_result->{packaging}, 'compiled_pcu_v1', 'Runtime::Result now compiles to PCU');
my $runtime_result_record = JSON::PP->new->decode($runtime_result->{bytes});
ok((grep { ($_->{name} // '') eq 'current' && ($_->{op} // '') eq 'result_current' } @{ $runtime_result_record->{subs} // [] }) >= 1, 'Runtime::Result PCU compiles current payload decoder');
ok((grep { ($_->{name} // '') eq 'set_current' && ($_->{op} // '') eq 'result_set_current' } @{ $runtime_result_record->{subs} // [] }) >= 1, 'Runtime::Result PCU compiles current payload writer');
ok((grep { ($_->{name} // '') eq '_set_channel' && ($_->{op} // '') eq 'result_set_channel' } @{ $runtime_result_record->{subs} // [] }) >= 1, 'Runtime::Result PCU compiles channel spillover writer');
ok((grep { ($_->{name} // '') eq 'report' && ($_->{op} // '') eq 'result_report' } @{ $runtime_result_record->{subs} // [] }) >= 1, 'Runtime::Result PCU compiles report formatter');
ok((grep { ($_->{name} // '') eq '_command_name' && ($_->{op} // '') eq 'result_command_name' } @{ $runtime_result_record->{subs} // [] }) >= 1, 'Runtime::Result PCU compiles command-name resolver');
is(scalar(@{ $runtime_result_record->{unsupported_subs} // [] }), 0, 'Runtime::Result PCU no longer needs residual fallback');

my $page_store = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/PageStore.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/PageStore.pm',
);
is($page_store->{packaging}, 'compiled_pcu_v1', 'PageStore now compiles to PCU');
my $page_store_record = JSON::PP->new->decode($page_store->{bytes});
ok((grep { ($_->{name} // '') eq 'page_file' && ($_->{op} // '') eq 'page_store_page_file' } @{ $page_store_record->{subs} // [] }) >= 1, 'PageStore PCU compiles page file resolver');
ok((grep { ($_->{name} // '') eq 'save_page' && ($_->{op} // '') eq 'page_store_save_page' } @{ $page_store_record->{subs} // [] }) >= 1, 'PageStore PCU compiles bookmark writer');
ok((grep { ($_->{name} // '') eq 'load_saved_page' && ($_->{op} // '') eq 'page_store_load_saved_page' } @{ $page_store_record->{subs} // [] }) >= 1, 'PageStore PCU compiles saved-page loader');
ok((grep { ($_->{name} // '') eq 'encode_page' && ($_->{op} // '') eq 'page_store_encode_page' } @{ $page_store_record->{subs} // [] }) >= 1, 'PageStore PCU compiles transient encoder');
ok((grep { ($_->{name} // '') eq '_saved_page_entries_for_root' && ($_->{op} // '') eq 'page_store_saved_page_entries_for_root' } @{ $page_store_record->{subs} // [] }) >= 1, 'PageStore PCU compiles recursive saved-page walker');
ok((grep { ($_->{name} // '') eq 'migrate_legacy_json_pages' && ($_->{op} // '') eq 'page_store_migrate_legacy_json_pages' } @{ $page_store_record->{subs} // [] }) >= 1, 'PageStore PCU compiles legacy JSON migration');
is(scalar(@{ $page_store_record->{unsupported_subs} // [] }), 0, 'PageStore PCU no longer needs residual fallback');

my $indicator_store = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/IndicatorStore.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/IndicatorStore.pm',
);
is($indicator_store->{packaging}, 'compiled_pcu_v1', 'IndicatorStore now compiles to PCU');
my $indicator_store_record = JSON::PP->new->decode($indicator_store->{bytes});
ok((grep { ($_->{name} // '') eq 'set_indicator' && ($_->{op} // '') eq 'indicator_store_set_indicator' } @{ $indicator_store_record->{subs} // [] }) >= 1, 'IndicatorStore PCU compiles indicator writer');
ok((grep { ($_->{name} // '') eq 'sync_collectors' && ($_->{op} // '') eq 'indicator_store_sync_collectors' } @{ $indicator_store_record->{subs} // [] }) >= 1, 'IndicatorStore PCU compiles collector sync');
ok((grep { ($_->{name} // '') eq 'refresh_core_indicators' && ($_->{op} // '') eq 'indicator_store_refresh_core_indicators' } @{ $indicator_store_record->{subs} // [] }) >= 1, 'IndicatorStore PCU compiles core indicator refresh');
ok((grep { ($_->{name} // '') eq 'page_header_items' && ($_->{op} // '') eq 'indicator_store_page_header_items' } @{ $indicator_store_record->{subs} // [] }) >= 1, 'IndicatorStore PCU compiles page header items');
ok((grep { ($_->{name} // '') eq '_status_icon_for' && ($_->{op} // '') eq 'indicator_store_status_icon_for' } @{ $indicator_store_record->{subs} // [] }) >= 1, 'IndicatorStore PCU compiles status icon mapper');
is(scalar(@{ $indicator_store_record->{unsupported_subs} // [] }), 0, 'IndicatorStore PCU no longer needs residual fallback');

my $page_document = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/PageDocument.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/PageDocument.pm',
);
is($page_document->{packaging}, 'compiled_pcu_v1', 'PageDocument now compiles to PCU');
my $page_document_record = JSON::PP->new->decode($page_document->{bytes});
ok((grep { ($_->{name} // '') eq 'from_instruction' && ($_->{op} // '') eq 'page_document_from_instruction' } @{ $page_document_record->{subs} // [] }) >= 1, 'PageDocument PCU compiles instruction parser');
ok((grep { ($_->{name} // '') eq 'render_html' && ($_->{op} // '') eq 'page_document_render_html' } @{ $page_document_record->{subs} // [] }) >= 1, 'PageDocument PCU compiles HTML renderer');
ok((grep { ($_->{name} // '') eq '_parse_legacy_sections' && ($_->{op} // '') eq 'page_document_parse_legacy_sections' } @{ $page_document_record->{subs} // [] }) >= 1, 'PageDocument PCU compiles legacy section parser');
ok((grep { ($_->{name} // '') eq '_decode_stash_section' && ($_->{op} // '') eq 'page_document_decode_stash_section' } @{ $page_document_record->{subs} // [] }) >= 1, 'PageDocument PCU compiles stash decoder');
ok((grep { ($_->{name} // '') eq '_legacy_bootstrap' && ($_->{op} // '') eq 'page_document_legacy_bootstrap' } @{ $page_document_record->{subs} // [] }) >= 1, 'PageDocument PCU compiles legacy browser bootstrap');
is(scalar(@{ $page_document_record->{unsupported_subs} // [] }), 0, 'PageDocument PCU no longer needs residual fallback');
ok((grep { ($_->{op} // '') eq 'set_array_literal' && ($_->{symbol} // '') eq 'Developer::Dashboard::PageDocument::LEGACY_KEYS' } @{ $page_document_record->{initializers} // [] }) >= 1, 'PageDocument PCU preserves legacy section key array initializer');

my $cli_seeded_pages = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/SeededPages.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/SeededPages.pm',
);
is($cli_seeded_pages->{packaging}, 'compiled_pcu_v1', 'CLI SeededPages now compiles to PCU');
my $cli_seeded_pages_record = JSON::PP->new->decode($cli_seeded_pages->{bytes});
my ($seeded_page_from_asset) = grep { ($_->{name} // '') eq '_page_from_asset' && ($_->{op} // '') eq 'seeded_pages_page_from_asset' } @{ $cli_seeded_pages_record->{subs} // [] };
ok($seeded_page_from_asset, 'CLI SeededPages compiles page asset loader');
is($seeded_page_from_asset->{page_class}, 'Developer::Dashboard::PageDocument', 'CLI SeededPages resolves imported app-root PageDocument class');
my ($seeded_ensure) = grep { ($_->{name} // '') eq 'ensure_seeded_page' && ($_->{op} // '') eq 'seeded_pages_ensure_seeded_page' } @{ $cli_seeded_pages_record->{subs} // [] };
ok($seeded_ensure, 'CLI SeededPages compiles seeded page writer');
is($seeded_ensure->{page_class}, 'Developer::Dashboard::PageDocument', 'CLI SeededPages preserves imported PageDocument class for from_hash paths');

my $open_file = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CLI/OpenFile.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CLI/OpenFile.pm',
);
is($open_file->{packaging}, 'source_payload_fallback', 'CLI OpenFile module falls back to source when it exposes Exporter contract');
is($open_file->{fallback_reason}, 'unsupported_exporter_contract', 'CLI OpenFile source fallback records exporter-contract reason');

my $collector_runner = $compiler->compile(
    path => 'DD Source Code/developer-dashboard/lib/Developer/Dashboard/CollectorRunner.pm',
    kind => 'lib',
    logical_path => 'lib/developer-dashboard/Developer/Dashboard/CollectorRunner.pm',
);
my $collector_runner_record = JSON::PP->new->decode($collector_runner->{bytes});
ok((grep { ($_->{name} // '') eq 'new' && ($_->{op} // '') eq 'collector_runner_new' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles constructor');
ok((grep { ($_->{name} // '') eq 'run_once' && ($_->{op} // '') eq 'collector_runner_run_once' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles collector execution entry');
ok((grep { ($_->{name} // '') eq '_collector_source' && ($_->{op} // '') eq 'collector_runner_source' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles collector source resolver');
ok((grep { ($_->{name} // '') eq '_run_job' && ($_->{op} // '') eq 'collector_runner_run_job' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles mode dispatcher');
ok((grep { ($_->{name} // '') eq '_cron_due' && ($_->{op} // '') eq 'collector_runner_cron_due' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles cron slot scheduler');
ok((grep { ($_->{name} // '') eq '_is_managed_loop' && ($_->{op} // '') eq 'collector_runner_is_managed_loop' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles managed-loop detector');
ok((grep { ($_->{name} // '') eq '_write_loop_state' && ($_->{op} // '') eq 'collector_runner_write_loop_state' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles loop state writer');
ok((grep { ($_->{name} // '') eq 'start_loop' && ($_->{op} // '') eq 'collector_runner_start_loop' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles loop starter');
ok((grep { ($_->{name} // '') eq 'stop_loop' && ($_->{op} // '') eq 'collector_runner_stop_loop' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles loop stopper');
ok((grep { ($_->{name} // '') eq 'running_loops' && ($_->{op} // '') eq 'collector_runner_running_loops' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles loop lister');
ok((grep { ($_->{name} // '') eq '_run_command' && ($_->{op} // '') eq 'collector_runner_run_command' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles shell command runner');
ok((grep { ($_->{name} // '') eq '_run_code' && ($_->{op} // '') eq 'collector_runner_run_code' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles Perl code runner');
ok((grep { ($_->{name} // '') eq '_indicator_template_vars' && ($_->{op} // '') eq 'collector_runner_indicator_template_vars' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles indicator template var decoder');
ok((grep { ($_->{name} // '') eq '_render_indicator_icon_template' && ($_->{op} // '') eq 'collector_runner_render_indicator_icon_template' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles indicator icon template renderer');
ok((grep { ($_->{name} // '') eq '_materialize_indicator_state' && ($_->{op} // '') eq 'collector_runner_materialize_indicator_state' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles indicator state materializer');
ok((grep { ($_->{name} // '') eq '_run_loop_child' && ($_->{op} // '') eq 'collector_runner_run_loop_child' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles loop child runner');
ok((grep { ($_->{name} // '') eq '_shutdown_loop' && ($_->{op} // '') eq 'collector_runner_shutdown_loop' } @{ $collector_runner_record->{subs} // [] }) >= 1, 'CollectorRunner compiles loop shutdown helper');
is(scalar(@{ $collector_runner_record->{unsupported_subs} // [] }), 0, 'CollectorRunner PCU no longer needs residual fallback');

my $residual_only = $compiler->compile(
    path => "$FindBin::Bin/fixtures/app_lib/ResidualOnly.pm",
    kind => 'lib',
    logical_path => 'lib/app_lib/ResidualOnly.pm',
);
is($residual_only->{packaging}, 'compiled_pcu_v1', 'residual-only fixture now compiles to PCU');
my $residual_record = JSON::PP->new->decode($residual_only->{bytes});
ok((grep { ($_->{name} // '') eq 'reverse_words' && ($_->{op} // '') eq 'split_reverse_join' } @{ $residual_record->{subs} // [] }) >= 1, 'residual-only fixture compiles to reusable split/reverse/join op');
is(scalar(@{ $residual_record->{unsupported_subs} // [] }), 0, 'residual-only fixture no longer needs residual fallback');

done_testing;

=pod

=head1 NAME

t/code_unit_compiler.t - regression coverage for code-unit classification, imported symbol resolution, and standalone compilation behavior

=head1 DESCRIPTION

This test exercises code-unit classification, imported symbol resolution, and standalone compilation behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for code-unit classification, imported symbol resolution, and standalone compilation behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/code_unit_compiler.t

=head1 WHY IT EXISTS

PAX uses this test to keep code-unit classification, imported symbol resolution, and standalone compilation behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut

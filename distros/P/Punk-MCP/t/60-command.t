#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use FindBin;
use Cwd ();

use Punk::Command ();
use Punk::Command::Mcp ();

my $DATA = File::Spec->catdir($FindBin::Bin, 'data');
my $cwd = Cwd::getcwd();

# Run `punk @args` in this process, catching what it prints.
sub punk {
    my (@args) = @_;
    my ($out, $err) = ('', '');
    my $code;
    {
        local *STDOUT; local *STDERR;
        open STDOUT, '>', \$out or die $!;
        open STDERR, '>', \$err or die $!;
        $code = Punk::Command->main(@args);
    }
    chdir $cwd;
    return ($code, $out, $err);
}

my ($code, $out) = punk('help', 'mcp');
is($code, 0, 'punk help mcp');
like($out, qr/Newline-delimited JSON-RPC on stdin and stdout/, 'says what it is');
like($out, qr/--token/, 'and lists --token');
like($out, qr/--env/, 'and --env');

($code, $out) = punk('help');
like($out, qr/mcp\s+serve the application's MCP endpoint over stdio/,
    'the command list has mcp, with its abstract');

my $err;
($code, undef, $err) = punk('mcp', '--dir', File::Spec->catdir($DATA, 'plain-app'));
is($code, 2, 'an application without the plugin: exit 2');
like($err, qr/PlainApp does not use plugin 'MCP'/, 'naming the application');

($code, undef, $err) = punk('mcp', '--dir', File::Spec->catdir($DATA, 'nowhere'));
is($code, 1, 'no application at all: exit 1');

# ---- the doctor row ---------------------------------------------------------------

my ($row) = grep { $_->[0] eq 'Punk::MCP' } @Punk::Command::DOCTOR;
ok($row, 'a doctor row is registered');
my ($ok, $detail) = $row->[1]->();
ok($ok, 'it is a healthy row');
like($detail, qr/^\/mcp: 0 tools|no application here uses it/,
    'before the app is loaded it says nothing uses it, or lists what does');

{
    local @ARGV;
    my $info = Punk::Command->load_app(dir => File::Spec->catdir($DATA, 'stdio-app'));
    chdir $cwd;
    ok($info->{class}, 'the stdio app loads');
}
(undef, $detail) = $row->[1]->();
like($detail, qr{/mcp: 5 tools, 1 resources, 0 prompts, stateless, oauth off},
    'and then describes it: path, counts, sessions, oauth');

done_testing;

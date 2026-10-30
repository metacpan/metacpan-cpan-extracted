#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Punk::Plugin::MCP ();

# BOOT resolves both C ABIs or refuses to load. Grows into the option checks in 04.

my $v = Punk::Plugin::MCP::_abi_versions();
cmp_ok($v->{frj}, '>=', 1, 'BOOT resolved the File::Raw::JSON table');
cmp_ok($v->{jsf}, '>=', 1, 'BOOT resolved the JSON::Schema::Fast table');

# Load the plugin in a fresh perl with @INC rigged, and report what the load
# said. A child, because BOOT runs once per process.
sub load_with {
    my ($rig) = @_;
    my $code = $rig . 'eval { require Punk::Plugin::MCP; 1 } '
             . 'and print "loaded\n"; print $@;';
    my @inc = map { "-I$_" } grep { !ref } @INC;
    open my $fh, '-|', $^X, @inc, '-e', $code or die "cannot run $^X: $!";
    local $/;
    my $out = <$fh>;
    close $fh;
    return $out;
}

# A provider that will not load at all.
my $missing = q{
    unshift @INC, sub {
        die "rigged: no File::Raw::JSON\n" if $_[1] eq 'File/Raw/JSON.pm';
        return;
    };
};
like(load_with($missing),
    qr/^Punk::MCP needs File::Raw::JSON 0\.08 or later for its C ABI 1, and File::Raw::JSON is unusable \(version none\): rigged: no File::Raw::JSON/,
    'a provider that will not load stops the plugin loading, naming it');

# A provider that loads but is too old to carry the table.
my $old = q{
    unshift @INC, sub {
        return unless $_[1] eq 'JSON/Schema/Fast.pm';
        my $src = "package JSON::Schema::Fast; our \$VERSION = '0.01'; 1;\n";
        open my $fh, '<', \$src;
        return $fh;
    };
};
like(load_with($old),
    qr/^Punk::MCP needs JSON::Schema::Fast 0\.10 or later for its C ABI 1, and JSON::Schema::Fast is unusable \(version 0\.01\): Undefined subroutine &JSON::Schema::Fast::_abi_ptr/,
    'a provider with no _abi_ptr stops the plugin loading, naming its version');

like(load_with(''), qr/^loaded$/, 'and the control, unrigged, loads');


# ---- the options ------------------------------------------------------------------

my $n = 0;
# A fresh application class, the plugin registered on it with %opts. Returns
# the stored options, or dies with what register said.
sub opts {
    my ($opts) = @_;
    my $pkg = 'T01::App' . ++$n;
    eval "package $pkg; use Punk; our \$VERSION = '2.5'; 1" or die $@;
    $pkg->punk_app->plugin('MCP' => $opts);
    return Punk::Plugin::MCP->state_for($pkg)->{opts};
}
sub refused {
    my ($opts) = @_;
    eval { opts($opts) };
    return $@;
}

my $o = opts({});
is($o->{path}, '/mcp', 'path defaults to /mcp');
like($o->{name}, qr/^T01::App\d+$/, 'name defaults to the application class');
is($o->{version}, '2.5', "version defaults to the application's VERSION");
is($o->{session}, 0, 'session defaults to 0: stateless (the owner\'s ruling, 23 Oct)');
is($o->{session_ttl}, 3600, 'session_ttl defaults to an hour');
is($o->{max_sessions}, 10000, 'max_sessions defaults to 10000');
is($o->{page_size}, 50, 'page_size defaults to 50');
is($o->{max_body}, 1048576, 'max_body defaults to 1MB');
is($o->{stream}, 'auto', "stream defaults to 'auto'");
is($o->{logging}, 0, 'logging defaults off');
is($o->{stdio_trust}, 0, 'stdio_trust defaults off');
ok(!exists $o->{$_}, "no $_ unless given")
    for qw(title description website icons instructions auth oauth principal
           openapi ops origins timeout);

$o = opts({
    path => '/agents/mcp', name => 'acme', title => 'Acme', version => '1.0',
    description => 'The Acme catalogue.', website => 'https://acme.test',
    icons => [{ src => 'https://acme.test/i.png', mimeType => 'image/png',
                sizes => ['48x48'] }],
    instructions => 'Search first.', auth => sub { return },
    oauth => { issuer => 'https://id.acme.test' }, principal => 'Users#me',
    openapi => 'api', ops => ['listBooks'], session => 0, session_ttl => 60,
    max_sessions => 5, stream => 'json', origins => ['https://acme.test'],
    page_size => 10, max_body => 4096, logging => 1, timeout => 2.5,
    stdio_trust => 1,
});
is($o->{path}, '/agents/mcp', 'path');
is($o->{session}, 0, 'session => 0 is stateless');
is_deeply($o->{openapi}, ['api'], 'a single openapi mount becomes a list');
is($o->{timeout}, 2.5, 'a fractional timeout');
is($o->{stream}, 'json', 'stream');
is($o->{logging}, 1, 'logging');

like(refused({ paht => '/x' }),
    qr/unknown option 'paht' \(known: path, name, title/,
    'an unknown option croaks naming it and the known ones');

for my $case (
    [ path         => 'mcp',            qr/'path' must be a rooted, concrete path/ ],
    [ path         => '/mcp/',          qr/'path' must be a rooted, concrete path/ ],
    [ path         => '/mcp/:id',       qr/'path' must be a rooted, concrete path/ ],
    [ path         => '',               qr/'path' must be a path/ ],
    [ name         => [],               qr/'name' must be a non-empty string/ ],
    [ version      => '',               qr/'version' must be a non-empty string/ ],
    [ title        => {},               qr/'title' must be a non-empty string/ ],
    [ website      => 'acme.test',      qr/'website' must be an http or https URL/ ],
    [ icons        => {},               qr/'icons' must be a list/ ],
    [ icons        => [{ src => 'http://x/i.png' }], qr/an icon src must be an https or data: URI/ ],
    [ icons        => [{ url => 'https://x' }], qr/unknown icon key 'url'/ ],
    [ auth         => \'x',           qr/'auth' must be a guard/ ],
    [ auth         => [],               qr/'auth' must be a guard/ ],
    [ auth         => {},               qr/'auth' must be a guard/ ],
    [ oauth        => 'yes',            qr/'oauth' must be a hash/ ],
    [ principal    => [],               qr/'principal' must be a code ref/ ],
    [ openapi      => {},               qr/'openapi' must be an api mount/ ],
    [ ops          => ['x'],            qr/'ops' needs 'openapi'/ ],
    [ session      => [],               qr/'session' must be 0, or the name/ ],
    [ session_ttl  => 0,                qr/'session_ttl' must be a positive whole number/ ],
    [ session_ttl  => 1.5,              qr/'session_ttl' must be a positive whole number/ ],
    [ max_sessions => 'lots',           qr/'max_sessions' must be a positive whole number/ ],
    [ page_size    => 1001,             qr/'page_size' must be a whole number from 1 to 1000/ ],
    [ max_body     => -1,               qr/'max_body' must be a positive whole number/ ],
    [ stream       => 'sometimes',      qr/'stream' must be 'auto', 'json' or 'always'/ ],
    [ origins      => 'https://a.test', qr/'origins' must be a list/ ],
    [ origins      => ['https://a.test/path'], qr/'origins' holds 'https:\/\/a.test\/path', which is not an origin/ ],
    [ origins      => ['a.test'],       qr/which is not an origin/ ],
    [ timeout      => 0,                qr/'timeout' must be a number of seconds above 0/ ],
    [ timeout      => 'soon',           qr/'timeout' must be a number of seconds above 0/ ],
) {
    my ($k, $v, $want) = @$case;
    my $shown = ref $v ? ref $v : "'$v'";
    like(refused({ $k => $v }), $want, "$k => $shown croaks naming '$k'");
}
like(refused({ ops => ['x'], openapi => 'api', auth => '' }), qr/'auth' must be a guard/,
    'an empty auth string is not a guard');
like(refused('not a hash'), qr/the options must be a hash/, 'options must be a hash');

# punk.yml reaches register through `plugins:`, the same call.
{
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/punk.yml" or die $!;
    print $fh "plugins:\n  MCP:\n    path: /from-yml\n    title: From YAML\n";
    close $fh;
    my $pkg = 'T01::Yml';
    eval "package $pkg; use Punk; config '$dir/punk.yml'; 1" or die $@;
    my $s = Punk::Plugin::MCP->state_for($pkg);
    is($s->{opts}{path}, '/from-yml', 'punk.yml plugins: MCP reaches register');
    is($s->{opts}{title}, 'From YAML', 'with its options');
}

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Config;

# Configuration: layering, the secret resolvers,
# and the promise that $app->config carries no secrets.

plan skip_all => 'YAML::XS required for these tests'
    unless eval { require YAML::XS; 1 };

my $dir = File::Temp->newdir;

sub write_file {
    my ($name, $body) = @_;
    open my $fh, '>', "$dir/$name" or die $!;
    print $fh $body;
    close $fh;
    return "$dir/$name";
}

# ---- layering ---------------------------------------------------------------
{
    write_file('punk.yml', <<'YAML');
app:
  name: base
  workers: 2
views:
  Stencil:
    template_dir: root/templates
list: [1, 2, 3]
YAML
    write_file('punk.production.yml', <<'YAML');
app:
  workers: 8
list: [9]
YAML
    write_file('punk.local.yml', <<'YAML');
app:
  name: local override
YAML

    my $cfg = Punk::Config->load(file => "$dir/punk.yml", env => 'production');
    is($cfg->get('app.workers'), 8, 'the environment layer wins over the base');
    is($cfg->get('app.name'), 'local override', 'the local layer wins over both');
    is($cfg->get('views.Stencil.template_dir'), 'root/templates',
        'untouched keys survive the merge');
    is_deeply($cfg->get('list'), [9],
        'an array in an overlay replaces rather than appends');
    is($cfg->env, 'production', 'the environment is recorded');
    is(scalar @{ $cfg->files }, 3, 'all three layers were read');

    my $dev = Punk::Config->load(file => "$dir/punk.yml", env => 'development');
    is($dev->get('app.workers'), 2,
        'a missing environment layer is simply skipped');
}

# ---- the resolvers -----------------------------------------------------------
{
    my $secret_file = write_file('db_password', "from-a-file\n");
    local $ENV{PUNK_TEST_SECRET} = 'from-the-environment';
    write_file('punk.yml', <<"YAML");
database:
  dsn: dbi:SQLite:dbname=test.db
  password: { \$env: PUNK_TEST_SECRET }
  other:    { \$file: $secret_file }
  computed: { \$exec: [ echo, from-a-command ] }
  plain:    { \$literal: deliberately-inline }
YAML
    my $cfg = Punk::Config->load(file => "$dir/punk.yml", env => 'none');

    is($cfg->secret('database.password'), 'from-the-environment',
        '$env reads the environment');
    is($cfg->secret('database.other'), 'from-a-file',
        '$file reads the file and trims its trailing newline');
    is($cfg->secret('database.computed'), 'from-a-command',
        '$exec takes the command output');
    is($cfg->secret('database.plain'), 'deliberately-inline',
        '$literal passes the value through');

    # the public copy carries none of them
    is($cfg->config->{database}{password}, '[redacted]',
        'the public config redacts a secret');
    is($cfg->config->{database}{other},    '[redacted]', 'every secret');
    is($cfg->config->{database}{dsn}, 'dbi:SQLite:dbname=test.db',
        'ordinary values are untouched');

    # ... and nothing anywhere in it looks like the real thing
    my $dump = do {
        require File::Raw::JSON;
        File::Raw::JSON::file_json_encode($cfg->config);
    };
    unlike($dump, qr/from-the-environment|from-a-file|from-a-command/,
        'a full dump of the public config leaks no secret');

    is_deeply($cfg->secret_paths,
        [ sort qw(database.computed database.other database.password
                  database.plain) ],
        'the resolved secrets are listed');
    ok($cfg->has_secret('database.password'), 'has_secret');
    ok(!$cfg->has_secret('database.dsn'), 'and only for real secrets');

    # get() reaches the resolved value, for the boot consumers
    is($cfg->get('database.password'), 'from-the-environment',
        'get returns the resolved value');
}

# ---- resolver failures are loud ---------------------------------------------
{
    write_file('punk.yml', "token: { \$env: PUNK_DEFINITELY_NOT_SET }\n");
    my $err = '';
    eval { Punk::Config->load(file => "$dir/punk.yml", env => 'none') }
        or $err = $@;
    like($err, qr/PUNK_DEFINITELY_NOT_SET.*not set/,
        'a missing environment variable is fatal, not an empty password');

    write_file('punk.yml', "token: { \$file: /no/such/secret }\n");
    $err = '';
    eval { Punk::Config->load(file => "$dir/punk.yml", env => 'none') }
        or $err = $@;
    like($err, qr/cannot read/, 'an unreadable secret file is fatal');

    write_file('punk.yml', "token: { \$nope: x }\n");
    $err = '';
    eval { Punk::Config->load(file => "$dir/punk.yml", env => 'none') }
        or $err = $@;
    like($err, qr/unknown resolver/, 'an unknown resolver croaks, listing them');
}

# ---- a plaintext value is nobody else's business -----------------------------
#
# There used to be a guardrail here: a plaintext value under a key whose NAME
# looked secret-shaped warned, and `secrets => 'strict'` refused to boot. It
# is gone. Whether a password sits in the file is the decision of whoever
# writes the file, and a warning that fires on a key's name rather than on
# anything it knows is a warning people learn to ignore.
#
# These assert the silence, so reintroducing it fails here rather than in
# somebody's boot log.
{
    unlink "$dir/punk.local.yml" if -e "$dir/punk.local.yml";

    for my $key (qw(password passwd secret token api_key private_key
                    credentials auth)) {
        write_file('punk.yml', "thing:\n  $key: something\n");
        my @warned;
        {
            local $SIG{__WARN__} = sub { push @warned, $_[0] };
            Punk::Config->load(file => "$dir/punk.yml", env => 'none');
        }
        is(scalar @warned, 0, "a plaintext '$key' is loaded without comment");
    }

    write_file('punk.yml', "db:\n  dsn: dbi:Pg:dbname=x;password=oops\n");
    my @warned;
    {
        local $SIG{__WARN__} = sub { push @warned, $_[0] };
        my $c = Punk::Config->load(file => "$dir/punk.yml", env => 'none');
        is($c->get('db.dsn'), 'dbi:Pg:dbname=x;password=oops',
            'and a dsn with the password in it is just a dsn');
    }
    is(scalar @warned, 0, 'no warning for that either');

    # The resolvers are untouched: this is about not second-guessing a
    # plaintext value, not about taking the alternative away.
    local $ENV{PUNK_T_SECRET} = 'from-the-environment';
    write_file('punk.yml', "database:\n  password: { \$env: PUNK_T_SECRET }\n");
    my $cfg = Punk::Config->load(file => "$dir/punk.yml", env => 'none');
    is($cfg->secret('database.password'), 'from-the-environment',
        '$env still resolves');
    is($cfg->config->{database}{password}, '[redacted]',
        'and a resolved secret is still redacted out of the public copy');
}

# ---- config drives the DSL ---------------------------------------------------
{
    mkdir "$dir/templates";
    open my $t, '>', "$dir/templates/hello.tmpl" or die $!;
    print $t '<p>{% msg %}</p>';
    close $t;

    local $ENV{PUNK_TEST_DB_PASSWORD} = 'from-the-env';
    write_file('punk.yml', <<"YAML");
app:
  name: base
views:
  Stencil:
    template_dir: $dir/templates
database:
  dsn: dbi:SQLite:dbname=$dir/app.db
  password: { \$env: PUNK_TEST_DB_PASSWORD }
plugins:
  ConfigTestMark: {}
YAML
    write_file('punk.staging.yml', "app:\n  name: staging\n");
    unlink "$dir/punk.local.yml" if -e "$dir/punk.local.yml";

    package Punk::Plugin::ConfigTestMark;
    our @ISA = ('Punk::Plugin');
    sub register {
        my ($self, $app) = @_;
        $app->helper(config_marked => sub { 'plugin from config' });
    }

    package ConfigDrivenApp;
    use Punk;
    ConfigDrivenApp::config("$dir/punk.yml", env => 'staging');
    get '/' => sub { $_[0]->render('hello', { msg => $_[0]->config_marked }) };

    package main;
    my $app  = ConfigDrivenApp->to_app;
    my $preg = ConfigDrivenApp::punk_app();

    is($preg->config->{app}{name}, 'staging',
        'the environment layer reached $app->config');
    is($preg->config->{database}{password}, '[redacted]',
        '$app->config carries no secret');
    is($preg->secret('database.password'), 'from-the-env',
        '$app->secret reaches the resolved value');

    open my $in, '<', \(my $body = '') or die $!;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/',
                     QUERY_STRING => '', 'psgi.input' => $in });
    is($r->[0], 200, 'the app serves');
    is($r->[2][0], '<p>plugin from config</p>',
        'the view engine and the plugin were both registered from the config');
}

# ---- models: auto-discovery is the default ----------------------------------
{
    mkdir "$dir/lib";
    mkdir "$dir/lib/AutoApp";
    mkdir "$dir/lib/AutoApp/Model";
    for my $m (qw(Alpha Beta)) {
        open my $fh, '>', "$dir/lib/AutoApp/Model/$m.pm" or die $!;
        print $fh "package AutoApp::Model::$m;\n"
                . "use Punk::Model;\ntable '\L$m\E';\n"
                . "field id => { type => 'integer', primary => 1 };\n1;\n";
        close $fh;
    }
    unshift @INC, "$dir/lib";

    package AutoApp;
    use Punk;
    AutoApp::database(dsn => "dbi:SQLite:dbname=$dir/auto.db");

    package main;
    AutoApp->to_app;
    is_deeply([ sort keys %{ AutoApp::punk_app()->{models_compiled} } ],
        [ qw(Alpha Beta) ],
        'every MyApp::Model::* on disk is found and loaded, with no config');

    # models: none turns the scan off
    write_file('punk.yml', "models: none\n");
    package NoAutoApp;
    use Punk;
    NoAutoApp::config("$dir/punk.yml", env => 'none');

    package main;
    {
        no strict 'refs';
        @{'NoAutoApp::Model::Alpha::ISA'} = ();   # keep the namespace clean
    }
    NoAutoApp->to_app;
    ok(!NoAutoApp::punk_app()->{models_compiled},
        "models: none registers nothing");

    is(AutoApp::punk_app()->model_auto, 1, 'auto is on by default');
    NoAutoApp::punk_app()->model_auto(0);
    is(NoAutoApp::punk_app()->model_auto, 0, 'and can be turned off');

    shift @INC;
}

# ---- bad input ---------------------------------------------------------------
{
    my $err = '';
    eval { Punk::Config->load(file => "$dir/nothing-here.yml") } or $err = $@;
    like($err, qr/no config file found/, 'a missing file croaks');

    # Named rather than falling through to "unknown option", because this
    # one used to work and the reader needs to know it was removed rather
    # than mistyped.
    $err = '';
    eval { Punk::Config->load(file => "$dir/punk.yml", secrets => 'strict') }
        or $err = $@;
    like($err, qr/'secrets' option is gone/,
        'the removed option says so by name');
}

# ---- a document is data, and finite -------------------------------------------------
{
    write_file('cycle.yml', "a: &x\n  b: *x\n");
    my $err = '';
    eval { Punk::Config->load(file => "$dir/cycle.yml", env => 'production'); 1 }
        or $err = $@;
    like($err, qr/nested deeper than 64 levels/,
        'an alias cycle is refused rather than walked for ever');

    write_file('blessed.yml', "a: !!perl/hash:Some::Class\n  k: v\n");
    my $cfg = Punk::Config->load(file => "$dir/blessed.yml", env => 'production');
    is(ref $cfg->get('a'), 'HASH', 'a perl object tag loads as a plain hash');
}

done_testing();

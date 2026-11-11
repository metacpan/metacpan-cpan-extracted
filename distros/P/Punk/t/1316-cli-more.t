#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use File::Path ();
use Test::More;
use Punk::Command;

# The CLI past the edges t/1313 covers: the legacy commands list, config
# check resolving literal and file secrets, punk new generating through a kit
# for real (its next steps, a kit that wrote the Sqitch plan itself, a kit
# that does not load), and the generator's credential phrase for every kind
# of security scheme.

plan skip_all => 'Punk::Generate required' unless eval { require Punk::Generate; 1 };
plan skip_all => 'YAML::XS required' unless eval { require YAML::XS; 1 };

my $base = File::Temp::tempdir(CLEANUP => 1);
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub run_punk {
    my (@argv) = @_;
    my ($out, $err) = ('', '');
    open my $ofh, '>', \$out or die $!;
    open my $efh, '>', \$err or die $!;
    local $Punk::Command::OUT = $ofh;
    local $Punk::Command::ERR = $efh;
    my $code = Punk::Command->main(@argv);
    close $ofh; close $efh;
    return ($code, $out, $err);
}

# ---- the legacy commands list ----------------------------------------------------
{
    my @c = Punk::Command::commands();
    ok(scalar(grep { $_ eq 'routes' } @c), 'the legacy commands list names routes');
    ok(scalar(grep { $_ eq 'new' } @c), 'and new');
}

# ---- config check with literal and file secrets ----------------------------------
{
    my $dir = "$base/cfg";
    File::Path::make_path("$dir/config");
    spew("$dir/app.psgi", "package CfgMoreApp;\nuse Punk;\nCfgMoreApp->to_app;\n");
    my $secret = "$base/secret.txt";
    spew($secret, "s3cret\n");
    spew("$dir/config/punk.yml", "host: https://cfg.example\nkey: { \$literal: inline }\ntoken: { \$file: $secret }\n");
    my ($c, $out, $err) = run_punk('config', 'check', '--dir', $dir, '--env', 'test');
    is($c, 0, 'literal and file secrets resolve') or diag "$out$err";
    like($out, qr/^\s+key\s+\$literal: inline value\s*$/m, 'a literal is reported as an inline value');
    like($out, qr/^\s+token\s+\$file: \Q$secret\E\s*$/m, 'a file by its path');
    spew("$dir/config/punk.yml", "token: { \$file: $base/missing.txt }\n");
    ($c, $out) = run_punk('config', 'check', '--dir', $dir, '--env', 'test');
    is($c, 1, 'a file that does not exist fails the check');
    like($out, qr/does not exist/, q{by name});
    like($out, qr/FAILED/, q{and marked});
    SKIP: {
        skip 'root reads anything', 2 if $> == 0;
        chmod 0000, $secret;
        spew("$dir/config/punk.yml", "token: { \$file: $secret }\n");
        ($c, $out) = run_punk('config', 'check', '--dir', $dir, '--env', 'test');
        is($c, 1, 'a file that cannot be read fails the check');
        like($out, qr/is not readable/, q{and says so});
        chmod 0644, $secret;
    }
}

# ---- punk new through a kit, for real ---------------------------------------------
{
    my ($c, $out, $err) = run_punk('new', 'KitApp', '--kit', 'fakekit', '--dir', "$base/KitApp");
    is($c, 0, 'punk new through a kit exits 0') or diag $err;
    my ($where) = $out =~ /^Created KitApp in (\S+)/m;
    ok($where, 'and reports where') or diag $out;
    like($out, qr/the kit said so/, "the kit's next steps are printed");
    ok(-f "$where/KIT.txt", 'the kit wrote its own file') if $where;
}
{
    my ($c, $out, $err) = run_punk('new', 'SqApp', '--kit', 'fakesqitch', '--sqitch', 'sqlite', '--dir', "$base/SqApp");
    is($c, 0, 'a kit that wrote the Sqitch plan exits 0') or diag $err;
    like($out, qr/the kit wrote the Sqitch project; skipping init/, 'and init is skipped');
}
{
    my ($c, undef, $err) = run_punk('new', 'BrApp', '--kit', 'fakebroken', '--dir', "$base/BrApp");
    is($c, 1, 'a kit that does not load exits 1');
    like($err, qr/kit 'fakebroken' failed to load: (?:broken on purpose|Attempt to reload)/, 'with its error');
}

# ---- the credential phrase for every kind of security scheme ------------------------
{
    my @cases = (
        [ 'http digest'   => { type => 'http', scheme => 'digest' }, qr/the Authorization header's credential/ ],
        [ 'oauth2'        => { type => 'oauth2' },                  qr/^the access token$/ ],
        [ 'openIdConnect' => { type => 'openIdConnect' },           qr/^the access token$/ ],
        [ 'mutualTLS'     => { type => 'mutualTLS' },               qr/^the credential$/ ],
    );
    like(Punk::Generate::_credential_of($_->[1]), $_->[2], "the credential phrase for $_->[0]") for @cases;
}

done_testing;

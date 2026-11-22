use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use Mogura::Scanner::Config;

my $cli = abs_path('script/mogura');
my $example = abs_path('lib/Mogura/Scanner/scanner.example.yaml');
local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{XDG_STATE_HOME} = "$ENV{HOME}/state";
chdir $ENV{HOME} or die $!;
subtest 'Help and version' => sub {
    plan skip_all => 'Source CLI uses the ordinary server account' unless $>;
    for my $case (['--version', qr/^Mogura \d/], ['--help', qr/mogura server/]) {
        open my $out, '-|', $cli, $case->[0] or die "Run CLI: $!";
        local $/;
        like(<$out>, $case->[1], "$case->[0] via executable shebang");
        ok(close($out), 'CLI exits successfully');
    }
    ok(!-e $ENV{XDG_STATE_HOME}, 'Help and version leave no application state');
};

subtest 'Scanner configuration' => sub {
    my $class = 'Mogura::Scanner::Config';
    my %connection = (server => 'https://scanner.example', 'token-file' => '/etc/mogura/token');
    my $cfg = $class->from_options(\%connection);
    is_deeply(
        [$cfg->jobs, $cfg->command_timeout, $cfg->upload_timeout, $cfg->exclude_paths],
        [2, 3600, 300, []],
        'CLI alone gets the scanner defaults'
    );

    my $file = "$ENV{HOME}/scanner.yaml";
    open my $out, '>', $file or die $!;
    print {$out} "jobs: 3\n";
    close $out or die $!;
    chmod 0666, $file or die $!;
    eval { $class->from_options({config => $file}) };
    like($@, qr/Root must own|owned by root/, 'Reject an untrusted configuration path');
    eval { $class->from_options({config => 'relative.yaml'}) };
    like($@, qr/relative.yaml.*absolute/, 'Config file must be absolute');

    # Ordinary CPAN tests cannot create root-owned fixtures. Keep the descriptor
    # checks live while isolating only the directory trust check.
    {
        no warnings qw(once redefine);
        local *Mogura::Scanner::Config::trusted_path = sub { };
        eval { $class->from_options({config => $file}) };
        like(
            $@,
            qr/\Q$file\E.*regular file owned by root/,
            'Check ownership and mode on the file itself'
        );
    }

    # Exercise the same parser and option merge on a descriptor supplied by the test.
    no warnings qw(once redefine);
    local *Mogura::Scanner::Config::_open_config = sub {
        open my $fh, '<:raw', $_[0] or die $!;
        return $fh;
    };
    $cfg = $class->from_options(
        {config => $example, jobs => 4, 'exclude-path' => ['/x/', '/x', '/y']});
    is_deeply(
        [$cfg->jobs, $cfg->exclude_paths],
        [4, ['/x', '/y']],
        'CLI replaces YAML settings and normalizes paths'
    );
    is($cfg->upload_timeout, 1800, 'An unspecified option preserves the example upload timeout');
    $cfg = $class->from_options({config => $example});
    is_deeply(
        [$cfg->jobs, $cfg->exclude_paths, $cfg->spool_limit],
        [2, ['/srv/backups', '/var/lib/example/cache'], 8589934592],
        'Read the shipped commented example'
    );

    for my $case (
        ["token: secret", qr/token is an unknown setting/],
        ["jobs: 2\njobs: 3", qr/Duplicate key 'jobs'/],
        ["jobs: true", qr/jobs/],
        ["jobs: '4'", qr/jobs/],
        ["jobs: 65", qr/jobs/],
        ["command_timeout: 0", qr/command_timeout/],
        ["upload_timeout: 2.5", qr/upload_timeout/],
        ["spool_limit: 1000", qr/spool_limit/],
        ["state: relative", qr/state/],
        ["syft: /usr/../tmp/syft", qr/syft/],
        ["server: http://example.org", qr/server/],
        ["exclude_paths: /tmp", qr/exclude_paths/],
        ["exclude_paths: [42]", qr/exclude_paths/],
        ["exclude_paths: &loop [*loop]", qr/cyclic/],
        ["jobs: 2\n---\njobs: 3", qr/single YAML mapping/],
        ["- jobs", qr/single YAML mapping/],
        ["jobs: [", qr/invalid YAML/],
        ["{}", qr/missing server/],
        (
            map { ["exclude_paths: [$_]", qr/exclude_paths/] }
                qw('' tmp / /// /x/./y /x/../y "/x\0y")
        )
        )
    {
        my ($yaml, $error) = @$case;
        open my $fh, '>', $file or die $!;
        print {$fh} "$yaml\n";
        close $fh or die $!;
        eval { $class->from_options({config => $file}) };
        like($@, qr/\Q$file\E: .*?$error/, "Reject $yaml");
    }
};
done_testing;

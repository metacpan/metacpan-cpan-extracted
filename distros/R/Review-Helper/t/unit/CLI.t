# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo/;
use TestCLI qw/cli/;
use Review::Helper::CLI;

my $dir = make_repo();

subtest usage => sub {
    my ($exit, $out, $err) = cli($dir);
    is($exit, 1, 'no arguments fails');
    like($err,                       qr/^Usage: review-helper <command>/,                                                                                                'usage on stderr');
    like(Review::Helper::CLI->usage, qr/Commands: build, close, export, feedback, fill, import, iterate, list, note, prune, published, serve, sheet, skills, version$/m, 'lists every subcommand');
};

subtest file_means_serve => sub {
    require Review::Helper::CLI::Serve;
    my @seen;
    my $mock = mock 'Review::Helper::CLI::Serve' => (override => [run => sub ($class, $settings, @args) { @seen = @args }]);
    my ($exit, $out, $err) = cli($dir, 'review.sqlite');
    is([$exit, \@seen], [0, ['review.sqlite']], 'a file argument means serve');
};

subtest run_command => sub {
    my ($exit, $out, $err) = cli($dir, 'prune', '--bogus');
    is([$exit, $err], [1, "review-helper prune: '--bogus' is not a valid option.\n"], 'invalid option reported with the subcommand');

    ($exit, $out, $err) = cli($dir, 'list', 'extra');
    is([$exit, $err], [1, "review-helper list: Usage: review-helper list\n"], 'subcommand errors reported');

    require Review::Helper::CLI::Close;
    my @seen;
    my $mock = mock 'Review::Helper::CLI::Close' => (override => [run => sub ($class, $settings, @args) { @seen = @args }]);
    ($exit, $out, $err) = cli($dir, 'close', 'a', '--', '--b');
    is([$exit, \@seen], [0, ['a', '--b']], 'positional arguments and those after -- passed in order');

    ($exit, $out, $err) = cli($dir, 'close', 'a', '-', 'b');
    is([$exit, \@seen], [0, ['a', '-', 'b']], "a lone '-' is an argument");
};

subtest decoding => sub {
    require Review::Helper::CLI::Build;
    my ($settings, @seen);
    my $mock = mock 'Review::Helper::CLI::Build' => (override => [run => sub ($class, $s, @args) { ($settings, @seen) = ($s, @args) }]);

    my ($exit, $out, $err) = cli($dir, 'build', '--title', "caf\xc3\xa9", '--path', "\xe2\x9c\x93", '--file', "caf\xc3\xa9.sqlite", "x\xc3\xa9");
    is($exit,                   0,                    'runs') or diag $err;
    is($settings->build->title, "caf\x{e9}",          'option values decoded to characters');
    is($settings->build->path,  ["\x{2713}"],         'list values too');
    is($settings->build->file,  "caf\xc3\xa9.sqlite", '--file stays bytes');
    ok(!utf8::is_utf8($settings->build->file), 'as a byte string');
    is(\@seen, ["x\xc3\xa9"], 'positional arguments stay bytes');

    ($exit, $out, $err) = cli($dir, 'build', '--title', "caf\xe9");
    is([$exit, $err], [1, "review-helper build: The value of --title is not valid UTF-8\n"], 'invalid UTF-8 refused');
};

done_testing;

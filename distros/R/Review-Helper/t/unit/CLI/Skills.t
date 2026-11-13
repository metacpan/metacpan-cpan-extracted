# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use TestCLI qw/cli/;

my $dir = tempdir(CLEANUP => 1);

my ($exit, $out, $err) = cli($dir, 'skills', 'path');
is([$exit, $err], [0, ''], 'path succeeds');
like($out, qr{/skills\n\z}, 'path prints the shipped skills directory');
like($out, qr{\A/},              'as an absolute path');
unlike($out, qr{(?:^|/)\.\.?(?:/|$)}m, 'with no . or .. in it');
chomp $out;
ok(-f "$out/review-build/SKILL.md", 'the directory holds the skills');

for my $args (['install'], ['path', 'extra'], []) {
    ($exit, undef, $err) = cli($dir, 'skills', @$args);
    is([$exit, $err], [1, "review-helper skills: Usage: review-helper skills path\n"], "'skills @$args' fails with usage");
}

done_testing;

use Mojo::Base -strict;
use Test::More;
use Mojo::File qw(path);
use File::Temp qw(tempdir);
use FindBin;

# Add lib directories to @INC so plugins can be found
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Lite;

my $tmp = path(tempdir(CLEANUP => 1))->child('test.log');

# Redirect app log to temp file
app->log->path("$tmp");
app->log->level('debug');

plugin 'Fondation' => {
    dependencies => ['Fondation::LogTest'],
};

my $output = $tmp->slurp;

# Verify contextual log prefix [Fondation::LogTest] appears
like $output, qr/\[Fondation::LogTest\]/, 'contextual log prefix found';

# Verify register() log message
like $output, qr/\[Fondation::LogTest\].*\[register\] log from register works/,
    'log during register() with context prefix';

# Verify finalyze() log message
like $output, qr/\[Fondation::LogTest\].*\[finalyze\] log from finalyze works/,
    'log during finalyze() with context prefix';

# Verify no undef warnings or crashes in the output
unlike $output, qr/Can.t locate object method.*log/i,
    'no "Cant locate object method log" errors';

done_testing;

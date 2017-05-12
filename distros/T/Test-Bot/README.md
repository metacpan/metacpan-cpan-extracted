This is a bot that can be configured to watch for new commits to a
repo, run unit tests for each commit, and notify developers of failed
tests.

Currently it only supports github repos. You must create a
post_receive hook and point it at your bot. This will be automated via
the GitHub API.

At present it only supports notifications via IRC. Plans are to
include email and web page outputs as well.

Unit tests are run via TAP::Harness.


To create your own bot, create a script with the following:

```
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Bot::GitHub;

my $bot = Test::Bot::GitHub->new_with_options(
    source_dir => "$ENV{HOME}/myproject",
    tests_dir => "t",
    notification_modules => [ 'IRC' ],
    port => 4000,
    force => 1,  # overwrite local modifications?
);
$bot->configure_notifications(
    irc_host => 'irc.int80.biz',
    irc_channel => '#int80',
);

$bot->run;
```

If you specify force => 1, a `git clean -df` and `git checkout -f
$commit` will be performed when running tests for a commit. This will
delete untracked (and not ignored) files and changes, so be careful.

If you are interested in using this program and would like to help
develop it further, please let me know via github, email or IRC.


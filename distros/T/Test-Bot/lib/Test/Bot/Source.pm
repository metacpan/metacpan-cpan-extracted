package Test::Bot::Source;

use Any::Moose 'Role';

# start watching source repo for changes
requires 'watch';

# install cron, register post-commit hook, github post-receive hook, etc
requires 'install';

1;

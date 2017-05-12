use strict;
use warnings;
use lib 't';
use SVN::Look;
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 14;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

my $repo   = catfile($t, 'repo');
my $wcfile = catfile($t, 'wc', 'file');

system("echo first >$wcfile");
system("svn add -q --no-auto-props $wcfile");
system("svn ps -q svn:mime-type text/plain $wcfile");
system("svn ci -q -mlog $wcfile");

my $look = SVN::Look->new($repo, -r => 1);

ok(defined $look, 'constructor');

# Grok the author name
ok(my $author = get_author($t), 'grok author');

cmp_ok($look->author(), 'eq', $author, 'author');

cmp_ok($look->log_msg(), 'eq', "log\n", 'log_msg');

cmp_ok(($look->added())[0], 'eq', 'file', 'added');

system("echo second >>$wcfile");
system("svn ci -q -mlog $wcfile");

$look = SVN::Look->new($repo, -r => 2);

cmp_ok($look->diff(), '=~', qr/\+second/, 'diff');

my $ab = catfile($t, 'wc', 'a b.txt');

system("echo space_in_name >\"$ab\"");
system("svn add -q --no-auto-props \"$ab\"");
system("svn ps -q svn:mime-type text/plain \"$ab\"");
system("svn ci -q -mlog \"$ab\"");

# Try without specifying a revision or a transaction
$look = SVN::Look->new($repo);

my $pl = eval { $look->proplist('a b.txt') };

ok(defined $pl, 'can call proplist in a file with spaces in the name');

ok(exists $pl->{'svn:mime-type'}, 'proplist finds the expected property');

is($pl->{'svn:mime-type'}, 'text/plain', 'proplist finds the correct property value');

my $youngest = eval { $look->youngest() };

cmp_ok($youngest, '=~', qr/^\d+$/, 'youngest');

my $uuid = eval { $look->uuid() };

cmp_ok($uuid, '=~', qr/^[0-9a-f-]+$/, 'uuid');

my $lock = eval { $look->lock('file') };

ok(! defined $lock, 'no lock');

system("svn lock -m \"lock comment\" $wcfile");

$lock = eval { $look->lock('file') };

ok(defined $lock && ref $lock eq 'HASH', 'lock');

my @tree = eval { $look->tree('--full-paths') };

is(scalar(@tree), 3, 'tree');

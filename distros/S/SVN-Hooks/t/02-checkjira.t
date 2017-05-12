# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (not can_svn()) {
    plan skip_all => 'Cannot find or use svn commands.';
}
elsif (not eval {require JIRA::REST}) {
    plan skip_all => 'Need JIRA::REST';
}
else {
    plan tests => 16;
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Hooks::CheckJira;
EOS

my $wc   = catfile($t, 'wc');
my $file = catfile($wc, 'file');

work_ok('prepare', <<"EOS");
echo line >$file
svn add -q --no-auto-props $file
svn ci -m"prepare" --force-log $wc
EOS

sub work {
    my ($msg) = @_;
    <<"EOS";
echo line >>$file
svn ci -m"$msg" --force-log $wc
EOS
}

set_conf(<<'EOS');
CHECK_JIRA_CONFIG();
EOS

work_nok('config sans args', 'CHECK_JIRA_CONFIG: requires three, four, or five arguments', work(''));

set_conf(<<'EOS');
CHECK_JIRA_CONFIG('http://jira.atlassian.com/', 'user', 'pass', 'asdf');
EOS

work_nok('invalid fourth arg', 'CHECK_JIRA_CONFIG: fourth argument must be a Regexp', work(''));

set_conf(<<'EOS');
CHECK_JIRA();
EOS

work_nok('accept invalid first arg', 'CHECK_JIRA: first arg must be a qr/Regexp/ or the string \'default\'.', work(''));

set_conf(<<'EOS');
CHECK_JIRA(default => 'invalid');
EOS

work_nok('accept invalid second arg', 'CHECK_JIRA: second argument must be a HASH-ref.', work(''));

set_conf(<<'EOS');
CHECK_JIRA(default => {invalid => 1});
EOS

work_nok('invalid option', 'CHECK_JIRA: unknown option \'invalid\'.', work(''));

set_conf(<<'EOS');
CHECK_JIRA(default => {projects => 1});
EOS

work_nok('invalid projects arg', 'CHECK_JIRA: projects\'s value must be a string matching', work(''));

set_conf(<<'EOS');
CHECK_JIRA(default => {require => undef});
EOS

work_nok('undefined arg', 'CHECK_JIRA: undefined require\'s value', work(''));

set_conf(<<'EOS');
CHECK_JIRA(default => {check_one => 1});
EOS

work_nok('invalid code arg', 'CHECK_JIRA: check_one\'s value must be a CODE-ref', work(''));

set_conf(<<'EOS');
CHECK_JIRA(qr/./ => {});
EOS

work_nok('not configured', 'CHECK_JIRA: plugin not configured. Please, use the CHECK_JIRA_CONFIG directive', work(''));

set_conf(<<'EOS');
CHECK_JIRA_DISABLE;
CHECK_JIRA(qr/./);
EOS

work_ok('disabled', work('no issue'));

################################################
# From now on the checks need a JIRA connection.

SKIP: {
    skip 'online checks are disabled', 5 unless -e 't/online.enabled';

    set_conf(<<'EOS');
CHECK_JIRA_CONFIG('http://no.way.to.get.there', 'user', 'pass');
CHECK_JIRA(qr/./);
EOS

    work_nok('no server', 'Bad hostname', work('[TST-1] no server'));

    my $config = <<'EOS';
CHECK_JIRA_CONFIG('https://jira.atlassian.com/', 'gustavo+jiraclient@gnustavo.com', 'W3PvT&9q0d^HLG0n', qr/^\[([^\]]+)\]/);
EOS

    set_conf($config . <<'EOS');
CHECK_JIRA(qr/asdf/);
EOS

    work_ok('no need to accept', work('ok'));

    set_conf($config . <<'EOS');
sub fix_for {
    my ($version) = @_;
    return sub {
	my ($jira, $issue, $svnlook) = @_;
	die "CHECK_JIRA: missing SVN::Look object" unless ref $svnlook eq 'SVN::Look';
	foreach my $fv (@{$issue->{fields}{fixVersion}}) {
	    return if $version eq $fv->{name};
	}
	die "CHECK_JIRA: issue $issue->{key} not scheduled for version $version.\n";
    }
}

CHECK_JIRA(qr/./, {check_one => fix_for('A version')});
EOS

    work_nok('no keys', 'CHECK_JIRA: you must cite at least one JIRA issue key in the commit message', work('no keys'));

    work_nok('not valid', 'CHECK_JIRA: issue ZYX-1 is not valid:', work('[ZYX-1]'));

    work_nok('check_one', 'CHECK_JIRA: issue TST-55263 not scheduled for version future-version.', work('[TST-55263]'));
}

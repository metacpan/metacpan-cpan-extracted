#!perl

use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 21;
use Padre::Plugin::Git ();

######
# let's check our subs/methods.
######

my @subs
	= qw( clean_dialog commit_message current_files event_on_context_menu git_cmd
	git_cmd_task git_patch github_pull_request load_dialog_output menu_plugins_simple
	on_finish padre_interfaces plugin_about plugin_disable plugin_enable
	plugin_icon plugin_name write_changes);

use_ok('Padre::Plugin::Git', @subs);

foreach my $subs (@subs) {
	can_ok('Padre::Plugin::Git', $subs);
}

######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Git::Output;
$test_object = new_ok('Padre::Plugin::Git::Output');

require Padre::Plugin::Git::FBP::Output;
$test_object = new_ok('Padre::Plugin::Git::FBP::Output');

require Padre::Plugin::Git::Task::Git_cmd;

# $test_object = new_ok('Padre::Plugin::Git::Task::Git_cmd');


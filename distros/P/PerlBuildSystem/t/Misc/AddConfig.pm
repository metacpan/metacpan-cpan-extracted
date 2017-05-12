#!/usr/bin/env perl

# Tests for the AddConfig command, different attributes on
# configuration variables and inheritence of configuration
# variables.

package t::Misc::AddConfig;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Add config');

    $t->build_dir('build_dir');
    $t->target('file.target');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

my $file_pbsfile = <<'_EOF_';
AddConfig('FILE1' => 'file.in');
AddRule '1', [ 'file.target' => 'child'] =>
    'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
AddRule 'child', { NODE_REGEX => 'child',
                   PBSFILE => './child.pl',
		   PACKAGE => 'child' };
_EOF_

sub file_pbsfile_child {
    return 'AddConfig(\'FILE1::' . shift() . <<'_EOF_';
' => 'file2.in');
AddRule 'child', [ 'child' => 'grand_child'] =>
    'cat %FILE1 %DEPENDENCY_LIST > %FILE_TO_BUILD';
AddRule 'grand_child', { NODE_REGEX => 'grand_child',
                         PBSFILE => './grand_child.pl',
			 PACKAGE => 'grand_child' };
_EOF_
}

my $file_pbsfile_grand_child = <<'_EOF_';
AddRule 'grand_child', [ 'grand_child' => undef] =>
    'cat %FILE1 > %FILE_TO_BUILD';
_EOF_

sub add_config : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddConfig('FILE1' => 'file2.in',
	      'FILE2' => 'file3.in');
    AddRule 'add config', [ 'file.target' => 'file.in' ] =>
	'cat %FILE2 %DEPENDENCY_LIST %FILE1 > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');
    $t->write('file3.in', 'file3 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file3 contentsfile contentsfile2 contents');
}

sub add_config_to : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddConfigTo('BuiltIn', 'FILE1' => 'file2.in',
		'FILE2' => 'file3.in');
    AddRule 'add config to', [ 'file.target' => 'file.in' ] =>
	'cat %FILE2 %DEPENDENCY_LIST %FILE1 > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');
    $t->write('file3.in', 'file3 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file3 contentsfile contentsfile2 contents');
}

sub config_local : Test(2) {
    # Write files
    $t->write_pbsfile($file_pbsfile);
    $t->write('child.pl', file_pbsfile_child('LOCAL'));
    $t->write('grand_child.pl', $file_pbsfile_grand_child);
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');
    
    # Build
    $t->build_test;
    $t->test_target_contents('file2 contentsfile contents');
}
    
sub config_override_parent : Test(3) {
    # Write files
    $t->write_pbsfile($file_pbsfile);
    $t->write('child.pl', file_pbsfile_child('OVERRIDE_PARENT'));
    $t->write('grand_child.pl', $file_pbsfile_grand_child);
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');
    
    # Build
    $t->build_test;
    my $stdout = $t->stdout;
    like($stdout, qr|Overriding config|, 'Message about overridden config');
    $t->test_target_contents('file2 contentsfile2 contents');
}

sub config_override_parent_silent_override : Test(3) {
    # Write files
    $t->write_pbsfile($file_pbsfile);
    $t->write('child.pl', file_pbsfile_child('OVERRIDE_PARENT:SILENT_OVERRIDE'));
    $t->write('grand_child.pl', $file_pbsfile_grand_child);
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');
    
    # Build
    $t->build_test;
    my $stdout = $t->stdout;
    unlike($stdout, qr|Overriding config|,
	   'No message about overridden config');
    $t->test_target_contents('file2 contentsfile2 contents');
}

sub config_locked : Test(2) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    AddConfig('FILE1:LOCKED' => 'file.in');
    AddConfig('FILE1' => 'file2.in');
    AddRule '1', [ 'file.target' => undef] =>
        'cat %FILE1 > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');

    # Build
	$t->build_test_fail;
    my $stderr = $t->stderr;
    like($stderr, qr|wants to override locked variable|,
	 'Message about overriding a locked config variable');
}
    
sub config_force : Test(3) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    AddConfig('FILE1:LOCKED' => 'file.in');
    AddConfig('FILE1:FORCE' => 'file2.in');
    AddRule '1', [ 'file.target' => undef] =>
        'cat %FILE1 > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');

    # Build
    $t->build_test;
    my $stdout = $t->stdout;
    like($stdout, qr|Overriding config|,
	 'Message about overriding a config variable');
    $t->test_target_contents('file2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;

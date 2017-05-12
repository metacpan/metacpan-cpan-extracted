#!/usr/bin/env perl

# Tests for different ways to specify dependencies in rules.

package t::Rules::Dependencies;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Dependencies');

    $t->build_dir('build_dir');
    $t->target('file.target');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');

    $t->subdir('subdir');
}

sub relative_absolute_path_basename : Test(2) {
# Create directories
    $t->subdir(['subdir', 'subsubdir'], ['subdir', 'subsubdir2'], 'subdir2');

# Write files
	my $full_path = $t->catfile_pbs($t->here_pbs, 'subdir2', 'file2.in');

    $t->write_pbsfile(<<"_EOF_");
    ExcludeFromDigestGeneration('in-files' => qr/\\.in\$/);
    AddRule 'second', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cp %DEPENDENCY_LIST %FILE_TO_BUILD';
    AddRule 'first', [ 'subdir/file.intermediate' => 'file1.in',
			                                '$full_path',
			                                '[path]/subsubdir/file3.in',
			                                'subsubdir2/asd[basename]4.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file1.in', 'file1 contents');
    $t->write('subdir2/file2.in', 'file2 contents');
    $t->write('subdir/subsubdir/file3.in', 'file3 contents');
    $t->write('subdir/subsubdir2/asdfile4.in', 'file4 contents');

# Build
	$t->build_test;
    $t->test_target_contents('file1 contentsfile2 contentsfile3 contentsfile4 contents');
}

sub globbing : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'globbing', [ '*.target' => '*.in' ] =>
	'cp %DEPENDENCY_LIST %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub depender_sub : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'depender sub',
        sub {
	    my ($file,
		$config,
		$tree,
		$inserted_nodes,
		$depender_definition,
		) = @_;
	    
	    if (! (defined($file) &&
		   defined($config) &&
		   defined($tree) &&
		   defined($inserted_nodes))) {
		return ([0]);
	    }
	    
	    if ($file =~ /(.*).target$/) {
                return ([1, "$1.in"]);
            } else {
                return ([0]);
            }
        } =>
	'cp %DEPENDENCY_LIST %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub dependent_regex : Test(2) {
# Create directory
    $t->subdir('subdir2', 'subdir3');

# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    #ExcludeFromDigestGeneration('node that fails' => qr/\$undefined_variable$/);
    
    AddRule 'second', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cp %DEPENDENCY_LIST %FILE_TO_BUILD';
    AddRule 'dependent regex', [qr/\.intermediate$/ => '$path/$basename$ext.in',
				                       'subdir2/$name.in',
				                       'subdir3/$ext.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.intermediate.in', 'file1 contents');
    $t->write('subdir2/file.intermediate.in', 'file2 contents');
    $t->write('subdir3/.intermediate.in', 'file3 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file1 contentsfile2 contentsfile3 contents');
}

sub dependent_regex_error_in_dependencies : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'second', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cp %DEPENDENCY_LIST %FILE_TO_BUILD';
    AddRule 'dependent regex', [qr/\.intermediate$/ => '$path/$basename$ext.in',
				                       '$undefined_variable'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.intermediate.in', 'file contents');

# Build
	$t->build_test_fail;
    my $stderr = $t->stderr;
    like($stderr, qr|\$undefined_variable' : BUILD_FAILED : No matching rule\.\n|, 'Correct error message in output');
}

sub creator_sub : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'second', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cp %DEPENDENCY_LIST %FILE_TO_BUILD';
    AddRule 'creator sub', [
			    sub {
                                my ($dependent, $target_path) = @_;
				return ($dependent =~ qr|^\./subdir/file.intermediate$| &&
					$target_path =~ qr|^$|);
			    } => 'subdir/$basename.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub dependent_matchers : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    PbsUse('Dependers/Matchers');
    ExcludeFromDigestGeneration('in-files' => qr/\.in2?$/);
    AddRule 'second', [ 'file.target' => 'file1.o',
			                 'file2.o',
			                 'file1.o2',
			                 'file2.o2'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'anymatch', [AnyMatch(qr|file1\.o$|, qr|file2\.o$|) => '$basename.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'andmatch1', [AndMatch(NoMatch(qr|\.o$|, qr|file2\.|), qr|\.o2$|) => '$basename.in2'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'andmatch2', [AndMatch(qr|file2\.|, NoMatch(qr|\.o$|, qr|\.in2$|)) => '$basename.in2'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';

_EOF_
    $t->write('file1.in', 'file1 contents');
    $t->write('file2.in', 'file2 contents');
    $t->write('file1.in2', 'file3 contents');
    $t->write('file2.in2', 'file4 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file1 contentsfile2 contentsfile3 contentsfile4 contents');
}

sub dependencies_sub : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'second', [ 'file.target' => 'file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'dependencies sub', ['file.intermediate' =>
				 'a.in',
				 'b.in',
				 sub {
				     my ($file,
					 $config,
					 $tree,
					 $inserted_nodes,
					 $dependencies,
					 $builder_override) = @_;

				     if (! (defined($file) &&
					    defined($config) &&
					    defined($tree) &&
					    defined($inserted_nodes) &&
					    defined($dependencies) &&
					    !defined($builder_override))) {
					 return ([0]);
				     }

				     shift @$dependencies;
				     my $result;
				     for my $dependency (@$dependencies) {
					 $result .= $dependency;
				     }
				     $result =~ s|\.||g;
				     $result =~ s|/||g;
				     $result =~ s|in||g;
				     return ([1, "$result.in"]);
				 } ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';

_EOF_
    $t->write('ab.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub no_dependencies : Test(4) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'no dependencies', [ 'file.target' => undef ] =>
	'cat file.in > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');

# Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');

    $t->build_test;
    $t->test_target_contents('file contents');
}

sub no_dependencies2 : Test(4) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'no dependencies', [ 'file.target' => undef ] =>
	'cat file.in > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');

# Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');

    $t->build_test;
    $t->test_target_contents('file contents');
}

sub multiple_rules : Test(8) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in2?$/);
    AddRule 'second', [ 'file.target' => 'file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'rule 1', [ '*.intermediate' => '*.in' ] =>
	'echo %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'rule 2', [ '*.intermediate' => '*.in2' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';

_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file.in2', 'file2 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contentsfile2 contents');

# Modify the first file and rebuild
    $t->write('file.in', 'file3 contents');

    $t->build_test;
#~ $t->generate_test_snapshot_and_exit() ;
    $t->test_target_contents('file3 contentsfile2 contents');

# Modify the second file and rebuild
    $t->write('file.in2', 'file4 contents');

    $t->build_test;
    $t->test_target_contents('file3 contentsfile4 contents');

    $t->test_up_to_date;
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;

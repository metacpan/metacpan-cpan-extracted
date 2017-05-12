use strict;
use inc::Module::Install;

name           'Task-RecycleTrash';
all_from       'lib/Task/RecycleTrash.pm';
requires       'File::Remove' => '0.36';
build_requires 'File::Spec'   => '0.80';
build_requires 'Test::More'   => '0.42';

# Handle platform-specific dependencies for File::Remove::trash
if ( $^O eq 'darwin' ) {
	requires 'Mac::Glue'     => 0;
} elsif ( $^O eq 'MSWin32' ) {
	requires 'Win32::FileOp' => 0;
}

WriteAll;

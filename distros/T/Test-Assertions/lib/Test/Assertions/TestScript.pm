package Test::Assertions::TestScript;

use strict;
use Getopt::Long qw(:config pass_through bundling);
use Log::Trace;
use Test::Assertions qw( test );;
use File::Basename;
use vars qw( $VERSION $SAVE_OUTPUT $TRACE $TRACE_DEEP @TRACE_MODULE );

$VERSION = sprintf"%d.%03d", q$Revision: 1.18 $ =~ /: (\d+)\.(\d+)/;

sub import {
	my $package = shift;
	my %options = @_;
	
	if ($0) {
		my $t_directory = dirname ( $0 );
		chdir ( $t_directory ) or die "Could not chdir to unit test directory '$t_directory'\n";
	} else { # this should never happen
		die "Could not find script location\n";
	}
	unshift @INC, "./lib", "../lib";
	
	my $additional_options = $options{options} || {};
	GetOptions(
		't'               => \$TRACE,
		'T'               => \$TRACE_DEEP,
		's'               => \$SAVE_OUTPUT,
		'trace-module=s@' => \@TRACE_MODULE,
		%$additional_options
	);
	
	plan tests => $options{tests};
	
	{
		package main; # Cheating to import into the right place
		import Test::Assertions qw( test );
	}
	
}

INIT {
	package main; # Cheating to import into the right place

	import Log::Trace unless ($Test::Assertions::TestScript::TRACE || $Test::Assertions::TestScript::TRACE_DEEP); # still import the stubs
	import Log::Trace 'print' => { Deep => 0 } if $Test::Assertions::TestScript::TRACE;
	import Log::Trace 'print' => { Deep => 1 } if $Test::Assertions::TestScript::TRACE_DEEP;
	foreach (@Test::Assertions::TestScript::TRACE_MODULE) {
		eval "require $_";
		import Log::Trace print => {Match => $_, Deep => 1};
	}
}

1;

=head1 NAME

Test::Assertions::TestScript - Base for test scripts

=head1 SYNOPSIS

	use Test::Assertions::TestScript;
	use Module::To::Test qw( frobnicate );
	
	ASSERT(frobnicate(),"Frobnicate returns true");

=head1 DESCRIPTION

Test::Assertions::TestScript provides a base for writing test scripts. It performs some
common actions such as setting up the @INC path and parsing command-line options, specifically:

=over

=item *

The lib and t/lib directories are added to @INC.

=item *

The current directory is changed to the directory the script is in.

=item *

Test script command-line options are parsed. (See L<COMMAND-LINE OPTIONS>)

=item *

The test set of functions from Test::Assertions are imported into your test
script.

=back

Test::Assertions::TestScript makes certain assumptions about the filesystem layout of
your project: 

=over 4

=item *

Modules that you are testing are in the lib directory of your project. 

=item *

Test scripts are in the t directory. 

=item *

There may also be a t/lib directory for any modules written for the test process.

=back

Test::Assertions::TestScript should be C<use>d B<before> any modules that you intend to test.

=head1 OPTIONS

Options can be supplied to the import function. These should be placed after
the C<use> or C<import>. For example

	use Test::Assertions::TestScript( tests => 10, options => { 'b', \$opt_b })

The following options are defined:

=over

=item tests

The number of tests to pass to C<plan tests> from Test::Assertions.  For example to tell Test::Assertions::TestScript that the script contains 42 tests:

  use Test::Assertions::TestScript tests => 42;

=item options

A hashref of additional options to capture via Getopt::Long.  The "options" import parameter is passed
verbatim to GetOptions, so something along the following lines is required in order to capture the "-b" command line option:

  use Test::Assertions::TestScript( options => { 'b' => \$opt_b } );

=back

=head1 COMMAND-LINE OPTIONS

A script based on Test::Assertions::TestScript will detect the following
command line options.

=over

=item -t

Shallow tracing. Traces are C<print>ed and AutoImport is turned on.

=item -T

Deep tracing. Traces are C<print>ed and AutoImport is turned on.

=item --trace-module=MODULE

Imports tracing into MODULE specifically. Can be specified multiple times.

=item -s

Save generated output. You will need to write the actual code to do this in
your testscript, but you can inspect $Test::Assertions::TestScript::SAVE_OUTPUT
to see whether this argument was given.

=back

Be aware that all other command line options will be disregarded unless the
C<options> import parameter is used to capture them.

=head1 VERSION

$Revision: 1.18 $

=head1 AUTHOR

Colin Robertson <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005-6. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut

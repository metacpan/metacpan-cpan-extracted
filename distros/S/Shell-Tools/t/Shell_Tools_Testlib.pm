#!perl
package Shell_Tools_Testlib;
use warnings;
use strict;

=head1 Synopsis

Supporting library for Shell::Tools tests.

=head1 Author, Copyright, and License

Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use base 'Exporter';
our @EXPORT = qw/ $AUTHOR_TESTS %HAVE_MODULE $HAVE_ALL_EXTRAS $HAVE_REQUIRED_EXTRAS $EXTRA_MODULE_REPORT /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{SHELL_TOOLS_AUTHOR_TESTS};

my %EXTRA_MODULES = (
	'Try::Tiny'        => { required=>1 },
	'Path::Class'      => { required=>1 },
	'File::pushd'      => { required=>1 },
	'File::Find::Rule' => { required=>1 },
	'IPC::Run3::Shell' => { version=>'0.52' },
);

our %HAVE_MODULE;
our $HAVE_ALL_EXTRAS = 1;
our $HAVE_REQUIRED_EXTRAS = 1;
our $EXTRA_MODULE_REPORT = "--- Extra Module Report ---\n";
for my $mod (sort keys %EXTRA_MODULES) {
	my $have_ver = eval qq{ require $mod; \$mod->VERSION()||"unknown" };  ## no critic (ProhibitStringyEval)
	my $test_ver = $EXTRA_MODULES{$mod}{version} ? eval { $mod->VERSION($EXTRA_MODULES{$mod}{version}); 1 } : 1;
	$HAVE_MODULE{$mod} = $test_ver && $have_ver;
	$HAVE_ALL_EXTRAS = 0 unless $HAVE_MODULE{$mod};
	$HAVE_REQUIRED_EXTRAS = 0 if $EXTRA_MODULES{$mod}{required} && !$HAVE_MODULE{$mod};
	$EXTRA_MODULE_REPORT .= "$mod: "
		.($EXTRA_MODULES{$mod}{required}?"required":"optional")
		.", want ".($EXTRA_MODULES{$mod}{version}||"any version")
		.", have ".($have_ver||"NONE")
		.", ".($HAVE_MODULE{$mod}?"OK":"NOT AVAILABLE")."\n";
}

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	return;
}


1;

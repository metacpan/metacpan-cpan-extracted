# -*- perl -*-
#
# Test::AutoBuild::Stage::Test
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::Stage::Test - Run module test suites

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::Test

=head1 DESCRIPTION

Description

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::Test;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use File::Path;
use File::Temp qw(tempfile tempdir);
use Log::Log4perl;


sub prepare {
    my $self = shift;
    my $runtime = shift;
    my $context = shift;

    my $result = $self->SUPER::prepare($runtime, $context);

    if (!defined $context) {
	foreach my $name ($runtime->sorted_modules()) {
	    my $module = $runtime->module($name);
	    my $subres = Test::AutoBuild::Result->new(name => $name,
						      label => $module->label);
	    $result->add_result($subres);
	    my $key = $self->name . "." . $name;
	    $self->{results}->{$key} = $subres;
	}
    }
    return $result;
}

sub process {
    my $self = shift;
    my $runtime = shift;
    my $module = shift;

    my @ordered_modules = defined $module ? ($module) : $runtime->sorted_modules();

    my $log = Log::Log4perl->get_logger();

    my $dir = tempdir( CLEANUP => 1 );

    foreach my $name (@ordered_modules) {
	my $module = $runtime->module($name);
	my $controlfile = $module->option("test-" . $self->name . "-control-file");
	$controlfile = $self->option("control-file") unless defined $controlfile;
	$controlfile = "autotest.sh" unless defined $controlfile;

	if ($module->build_status() ne 'success' &&
	    $module->build_status() ne 'cached') {
	    $log->info("skipping " . $module->name);
	    next;
	}

	my ($fh, $filename) = tempfile( DIR => $dir );
	$log->debug ("Testing with results in temp dir $dir and filename $filename");

	$runtime->notify("beginTest", $self->name, $name, time);
	my $test_data = $module->option("test_data");
	if (! defined $test_data) {
	    $test_data = {};
	    $module->option("test_data", $test_data);
	}

	$module->test($runtime, $self->name, $controlfile, $filename);

	$test_data->{$self->name}->{"output_xml"} = $filename;
	$runtime->notify("endTest", $self->name, $name, time, $module->test_status($self->name));
    }

    if (!defined $module) {
	foreach my $name ($runtime->sorted_modules()) {
	    my $module = $runtime->module($name);
	    my $key = $self->name . "." . $name;
	    my $subres = $self->{results}->{$key};

	    if (grep { $_ eq $self->name } $module->tests) {
		# XXX build log summary
		#$subres->log($module->test_output_log_summary($self->name));
		$subres->log("");
		$subres->status($module->test_status($self->name));
		$subres->start_time($module->test_start_date($self->name));
		$subres->end_time($module->test_end_date($self->name));
	    }
	}
    }
}

1 # So that the require or use succeeds.

__END__

=pod

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc.

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Build>

=cut

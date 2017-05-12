# -*- perl -*-
#
# Test::AutoBuild::Stage::Build
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

Test::AutoBuild::Stage::Build - The base class for an AutoBuild stage

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::Build


=head1 DESCRIPTION

Description

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::Build;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Log::Log4perl;
use Test::AutoBuild::Result;
use Test::AutoBuild::Lib;

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->option("strict-deps", 1)
	unless defined $self->option("strict-deps");
}

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

    if ($log->is_debug()) {
	$log->debug("Build order: \n" . join ("\n  ", @ordered_modules) . "\nEnd");
    }

    my $failed = 0;
    foreach my $name (@ordered_modules) {
	my $module = $runtime->module($name);
	$runtime->notify("beginBuild", $name, time);

	# We only want to build against the minimal actual dependancies
	# so blow away everything in this module's build root now & let
	# 'build()' install only those deps actually required
	if ($self->option("strict-deps")) {
	    &Test::AutoBuild::Lib::delete_files($runtime->install_root);
	    foreach my $name ($runtime->modules) {
		$runtime->module($name)->is_installed($runtime->install_root, 0);
	    }
	}

	my $controlfile = $module->option("control-file");
	$controlfile = $self->option("control-file") unless defined $controlfile;
	$controlfile = "autobuild.sh" unless defined $controlfile;

	my $timeout = $self->option("build-timeout");
	if (defined $timeout) {
	    $log->debug("timeout set to: $timeout");
	    eval {
		local $SIG{ALRM} = sub { die "timeout" };
		alarm $timeout;
		eval {
		    $module->build($runtime, $controlfile);
		};
		alarm 0;
	    };
	    alarm 0;
	    if ($@) {
		if ($@ =~ /timeout/) {
		    $module->build_status('failed');
		    $log->warn("timed out");
		} else {
		    die $@;
		}
	    }
	} else {
	    $module->build($runtime, $controlfile);
	}

	if ($module->build_status() ne 'success' &&
	    $module->build_status() ne 'cached') {
	    $failed = 1;
	}

	$runtime->notify("endBuild", $name, time, $module->build_status);
	if ($failed && $self->option('abort_on_fail')) {
	    last;
	}
    }
    if ($failed) {
	$self->fail("One or more modules failed during build");
    }

    if (!defined $module) {
	foreach my $name ($runtime->sorted_modules()) {
	    my $module = $runtime->module($name);
	    my $key = $self->name . "." . $name;
	    my $subres = $self->{results}->{$key};

	    # XXX log summary
	    #$subres->log($module->build_output_log_summary);
	    $subres->log("");
	    $subres->status($module->build_status);
	    $subres->start_time($module->build_start_date);
	    $subres->end_time($module->build_end_date);
	}
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc, 2004-2005 Daniel Berrange

=head1 SEE ALSO

L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Runtime>, L<Test::AutoBuild::Stage::Test>,
L<Test::AutoBuild::Module>

=cut

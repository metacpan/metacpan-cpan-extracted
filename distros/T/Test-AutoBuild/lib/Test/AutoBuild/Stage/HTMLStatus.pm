# -*- perl -*-
#
# Test::AutoBuild::Stage::HTMLStatus by Daniel P. Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2005 Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::HTMLStatus - Generate HTML status pages for build cycle

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::HTMLStatus


=head1 DESCRIPTION

This module generates the HTML status pages for displaying the output
of the build cycle.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::HTMLStatus;

use base qw(Test::AutoBuild::Stage::TemplateGenerator);
use warnings;
use strict;
use Log::Log4perl;
use File::Spec::Functions;
use Test::AutoBuild::Lib;

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();

    my @modules;

    foreach my $name (sort { $runtime->module($a)->label cmp $runtime->module($b)->label } $runtime->modules) {
	my $module = $runtime->module($name);
	my @packs = ();
	my $packages = $module->packages();

	foreach my $filename (keys %{$packages}) {
	    (my $fn = $packages->{$filename}->name) =~ s,.*/,,;

	    my $size = $packages->{$filename}->size();

	    my $platform = $packages->{$filename}->platform;
	    $platform = $runtime->host_platform unless $platform;
	    my $p = {
		'filename' => $fn,
		'size' => $size,
		'platform' => $platform,
		'prettysize' => Test::AutoBuild::Lib::pretty_size($size),
		'md5sum' => $packages->{$filename}->md5sum,
		'type' => $packages->{$filename}->type->name,
	    };
	    push @packs, $p;
	}
	@packs = sort { $a->{type} cmp $b->{type} or $a->{filename} cmp $b->{filename} } @packs;

	my $links = $module->links();
	my $artifacts = $module->artifacts();

	my @artifacts;
	foreach my $artifact (@{$artifacts}) {
	    push @artifacts, {
		label => $artifact->{label},
		path => $artifact->{path} ? $artifact->{path} : $artifact->{dst},
	    };
	}

	my @tests;
	foreach my $test ($module->tests) {
	    my $test_start = $module->test_start_date($test);
	    my $test_end = $module->test_end_date($test);

	    my @output_log_stat = stat catfile($runtime->log_root, $module->test_output_log_file($test));
	    my @result_log_stat = stat catfile($runtime->log_root, $module->test_result_log_file($test));

	    my @logs;
	    push @logs, { type => "test_output", file => $module->test_output_log_file($test),
			  size => Test::AutoBuild::Lib::pretty_size($output_log_stat[7]) }
	      if @output_log_stat;
	    push @logs, { type => "test_result", file => $module->test_result_log_file($test),
			  size => Test::AutoBuild::Lib::pretty_size($result_log_stat[7]) }
	      if @result_log_stat;

	    push @tests, {
		name => $test,
		duration => Test::AutoBuild::Lib::pretty_time($test_end - $test_start),
		status => $module->test_status($test),
		logs => \@logs,
	    };
	}

	my @changes;
	$log->debug("Processing changes");
	my $changes = $module->changes;
	if (defined $changes) {
	    foreach my $key (sort { $changes->{$b}->date <=> $changes->{$a}->date } keys %{$changes}) {
		my $change = $changes->{$key};
		$log->debug("Got change $key");
		push @changes, {
		    key => $key,
		    description => $change->description,
		    user => $change->user,
		    date => Test::AutoBuild::Lib::pretty_date($change->date),
		    files => $change->files,
		};
	    }
	}

	my $checkout_start = $module->checkout_start_date;
	my $checkout_end = $module->checkout_end_date;

	my $build_start = $module->build_start_date;
	my $build_end = $module->build_end_date;


	my @checkout_log_stat = stat catfile($runtime->log_root, $module->checkout_output_log_file);
	my @output_log_stat = stat catfile($runtime->log_root, $module->build_output_log_file);
	my @result_log_stat = stat catfile($runtime->log_root, $module->build_result_log_file);

	my @logs;
	push @logs, { type => "checkout", file => $module->checkout_output_log_file,
		      size => Test::AutoBuild::Lib::pretty_size($checkout_log_stat[7]) }
	  if @checkout_log_stat;
	push @logs, { type => "build_output", file => $module->build_output_log_file,
		      size => Test::AutoBuild::Lib::pretty_size($output_log_stat[7]) }
	  if @output_log_stat;
	push @logs, { type => "build_result", file => $module->build_result_log_file,
		      size => Test::AutoBuild::Lib::pretty_size($result_log_stat[7]) }
	  if @result_log_stat;

	my @checkout_lines;
	my @build_lines;
	if ($module->checkout_status eq "failed") {
	    @checkout_lines = Test::AutoBuild::Lib::log_file_lines(catfile($runtime->log_root, $module->checkout_output_log_file), -30);
	}
	if ($module->build_status eq "failed") {
	    @build_lines = Test::AutoBuild::Lib::log_file_lines(catfile($runtime->log_root, $module->build_output_log_file), -30);
	}

	my $mod = {
	    'name' => $name,
	    'label' => $module->label,
	    'status' => $module->status,
	    'groups' => $module->groups,

	    'checkout_status' => $module->checkout_status,
	    'checkout_duration' => Test::AutoBuild::Lib::pretty_time($checkout_end - $checkout_start),
	    'checkout_date' => scalar (Test::AutoBuild::Lib::pretty_date($checkout_start)),
	    'checkout_lines' => \@checkout_lines,

	    'build_status' => $module->build_status,
	    'build_duration' => Test::AutoBuild::Lib::pretty_time($build_end - $build_start),
	    'build_date' => scalar (Test::AutoBuild::Lib::pretty_date($build_start)),
	    'build_lines' => \@build_lines,

	    'logs' => \@logs,

	    'admin_email' => $module->admin_email,
	    'admin_name' => $module->admin_name,
	    'packages' => \@packs,
	    'links' => $links,
	    'artifacts' => \@artifacts,
	    'tests' => \@tests,
	    'changes' => \@changes
	};

	push @modules, $mod;
    }

    my @groups;
    foreach my $name (sort { $runtime->group($a)->label cmp $runtime->group($b)->label } $runtime->groups) {
	my $group = $runtime->group($name);

	my @groupmods = grep { grep { $_ eq $name } @{$_->{groups}} } @modules;
	$log->info("Got $name " . scalar(@groupmods));
	my $entry = {
	    name => $name,
	    label => $group->label,
	    modules => \@groupmods,
	};

	push @groups, $entry;
    }

    my @platforms;
    foreach my $name (sort { $runtime->platform($a)->label cmp $runtime->platform($b)->label } $runtime->platforms) {
	my $platform = $runtime->platform($name);

	my %options;
	foreach ($platform->options) {
	    $options{$_} = $platform->option($_);
	}

	my $entry = {
	    'name' => $name,
	    'label' => $platform->label,
	    'operating_system' => $platform->operating_system,
	    'architecture' => $platform->architecture,
	    'options' => \%options,
	};

	push @platforms, $entry;
    }

    my @repositories;
    foreach my $name (sort { $runtime->repository($a)->label cmp $runtime->repository($b)->label } $runtime->repositories) {
	my $repository = $runtime->repository($name);

	my @repositorymods;
	foreach my $modvars (@modules) {
	    my @paths = $runtime->module($modvars->{name})->paths($repository);
	    if ($#paths > -1) {
		push @repositorymods, $modvars;
	    }
	}

	my $entry = {
	    name => $name,
	    label => $repository->label,
	    modules => \@repositorymods,
	};

	push @repositories, $entry;
    }

    my @package_types;
    foreach my $name (sort { $runtime->package_type($a)->label cmp $runtime->package_type($b)->label } $runtime->package_types) {
	my $package_type = $runtime->package_type($name);

	my $entry = {
	    name => $name,
	    label => $package_type->label,
	};

	push @package_types, $entry;
    }

    my %vars = (
		'modules' => \@modules,
		'groups' => \@groups,
		'platforms' => \@platforms,
		'repositories' => \@repositories,
		'package_types' => \@package_types,
		);

    foreach my $name ($runtime->attributes) {
	$log->debug("Stuffing attribute '$name' into template variables");
	$vars{$name} = $runtime->attribute($name);
    }

    $self->_generate_templates($runtime, \%vars);
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Dennis Gregorovic <dgregorovic@alum.mit.edu>
Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::TemplateGenerator>,
L<Template>,  L<http://template-toolkit.org>

=cut

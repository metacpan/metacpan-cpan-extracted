# -*- perl -*-
#
# Test::AutoBuild::Stage::LogCopier by Daniel P. Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2005 Daniel P. Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::LogCopier - Copy log files to a distribution site.

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::LogCopier

=head1 DESCRIPTION

This module copies the build logs to a directory, typically part
of a Web / FTP root.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::LogCopier;

use base qw(Test::AutoBuild::Stage::Copier);
use warnings;
use strict;
use File::Path;
use File::Spec::Functions;
use Log::Log4perl;


sub handle_directory {
    my $self = shift;
    my $runtime = shift;
    my $directory_name = shift;
    my $directory_attrs = shift;

    my $log = Log::Log4perl->get_logger();

    mkpath([catdir($directory_name, "modules"),
	    catdir($directory_name, "stages")]);


    foreach my $name ($runtime->modules()) {
	if (!exists $directory_attrs->{'module'} || $directory_attrs->{'module'} eq $name) {

	    my $module = $runtime->module($name);
	    my @logs;

	    $self->copy_log($runtime,
			    $directory_name,
			    "modules",
			    $module->checkout_output_log_file);

	    $self->copy_log($runtime,
			    $directory_name,
			    "modules",
			    $module->build_output_log_file);
	    $self->copy_log($runtime,
			    $directory_name,
			    "modules",
			    $module->build_result_log_file);

	    foreach my $test ($runtime->module($name)->tests) {
		$self->copy_log($runtime,
				$directory_name,
				"modules",
				$module->test_output_log_file($test));
		$self->copy_log($runtime,
				$directory_name,
				"modules",
				$module->test_result_log_file($test));
	    }
	}
    }

    my $result = $runtime->attribute("results");
    $self->save_result($directory_name, $result, "");
}

sub save_result {
    my $self = shift;
    my $directory_name = shift;
    my $result = shift;
    my $context = shift;

    my $log = Log::Log4perl->get_logger();

    my $file = ($context ? $context . "-" . $result->name : $result->name);
    my $logfile = File::Spec->catfile($directory_name, "stages", $file . ".log");
    $log->info("writing result log file '$logfile' for stage context $file");
    $self->save_log($logfile,
		    $result->log);

    foreach my $subres ($result->results) {
	$self->save_result($directory_name, $subres, $file);
    }
}

sub copy_log {
    my $self = shift;
    my $runtime = shift;
    my $dir = shift;
    my $type = shift;
    my $log = shift;

    my $dst = catfile($dir, $type, $log);
    my $src = catfile($runtime->log_root, $log);

    if (-f $src) {
	Test::AutoBuild::Lib::copy_files($src, $dst, { link => 1 });
    } else {
	$self->save_log($dst, "no logs available");
    }
}

sub save_log {
    my $self = shift;
    my $file = shift;
    my $log = shift;

    $log = "" unless defined $log;

    open (LOG, ">$file") or die "Could not open $file: $!";
    print LOG $log;
    close LOG;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Dennis Gregorovic <dgregorovic@alum.mit.edu>
Daniel P. Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Daniel P. Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Stage::Copier>

=cut

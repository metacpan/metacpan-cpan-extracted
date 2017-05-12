# -*- perl -*-
#
# Test::AutoBuild::Stage::EmailAlert by Daniel P. Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2006 Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::EmailAlert - Send email alerts with build status

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::EmailAlert


=head1 DESCRIPTION

This module generates email alerts at the end of a build containing
status information. They can be sent on every cycle, or just when
the cycle has a failure.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::EmailAlert;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Net::SMTP;
use IO::Scalar;
use Log::Log4perl;
use POSIX qw(strftime);
use Template;
use Sys::Hostname;
use Test::AutoBuild::Lib;

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();

    my $from = $self->option("from");
    unless (defined $from) {
	my ($name,$passwd,$uid,$gid,
	    $quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid($>);

	my $email = $name . '@' . hostname;

	if ($comment) {
	    $from = $comment . " <" . $email . ">";
	} else {
	    $from = $email;
	}
	$log->debug("No from address set, so using '$from'");
    }

    my $trigger = $self->option("trigger");
    $trigger = "first-fail" unless defined $trigger;

    my $scope = $self->option("scope");
    $scope = "global" unless $scope;
    if ($scope eq "module") {
	$log->info("Sending one mail per module");

	foreach my $name (sort { $a cmp $b } $runtime->modules) {
	    my $module = $runtime->module($name);

	    my $to = $self->option("to");
	    $to = "admin" unless defined $to;
	    my @to;
	    foreach my $addr (split /,/, $to) {
		$addr =~ s/^\s*//g;
		$addr =~ s/\s*$//g;
		if ((lc $addr) eq "admin") {
		    if (defined $module->admin_email) {
			push @to, $module->admin_name . " <" . $module->admin_email . ">";
		    } else {
			push @to, $runtime->admin_name . " <" . $runtime->admin_email . ">";
		    }
		    $log->debug("Resolved module administrator address to '" . $to[$#to] . "'");
		} elsif ((lc $addr) eq "group") {
		    if (defined $module->group_email) {
			push @to, $module->group_name . " <" . $module->group_email . ">";
		    } else {
			push @to, $runtime->group_name . " <" . $runtime->group_email . ">";
		    }
		    $log->debug("Resolved module developer group address to '" . $to[$#to] . "'");
		} else {
		    push @to, $addr;
		}
	    }

	    if ((lc $trigger) eq "always") {
		$log->debug("Sending regardless of status");
		$self->dispatch_message($runtime, $from, \@to, [$name]);
	    } elsif ($module->status eq "failed") {
		if ((lc $trigger) eq "fail") {
		    $log->debug("Sending due to failure");
		    $self->dispatch_message($runtime, $from, \@to, [$name]);
		} else {
		    my $newfail = 0;
		    my $arcman = $runtime->archive_manager;
		    if ($arcman) {
			my $cache = $arcman->get_previous_archive;
			if ($cache) {
			    my $result = $cache->get_data($module->name, "build");
			    if ($result->{status} ne "failed") {
				$log->debug("Previous status was " . $result->{status});
				$newfail = 1;
			    }
			} else {
			    $log->debug("No cache, treating as new failure");
			    $newfail = 1;
			}
		    } else {
			$log->debug("No archive manager, treating as new failure");
			$newfail = 1;
		    }
		    if ($newfail) {
			$log->debug("Sending due to new failure");
			$self->dispatch_message($runtime, $from, \@to, [$name]);
		    } else {
			$log->debug("Not sending because failure was not new");
		    }
		}
	    } else {
		$log->debug("Not sending because no failures occurred");
	    }
	}
    } else {
	$log->info("Sending one mail for entire cycle");

	my $to = $self->option("to");
	$to = "admin" unless defined $to;
	my @to;
	foreach my $addr (split /,/, $to) {
	    $addr =~ s/^\s*//g;
	    $addr =~ s/\s*$//g;
	    if ((lc $addr) eq "admin") {
		push @to, $runtime->admin_name . " <" . $runtime->admin_email . ">";
		$log->debug("Resolved build administrator address to '" . $to[$#to] . "'");
	    } elsif ((lc $addr) eq "group") {
		push @to, $runtime->group_name . " <" . $runtime->group_email . ">";
		$log->debug("Resolved build developer group address to '" . $to[$#to] . "'");
	    } else {
		push @to, $addr;
	    }
	}

	my @modules = $runtime->modules;

	if ((lc $trigger) eq "always") {
	    $log->debug("Sending regardless of status");
	    $self->dispatch_message($runtime, $from, \@to, \@modules);
	} else {
	    my $failed = 0;
	    foreach my $name (@modules) {
		if ($runtime->module($name)->status eq "failed") {
		    $failed = 1;
		}
	    }

	    if ($failed) {
		if ((lc $trigger) eq "fail") {
		    $log->debug("Sending due to failure");
		    $self->dispatch_message($runtime, $from, \@to, \@modules);
		} else {
		    my $newfail = 0;
		    my $arcman = $runtime->archive_manager;
		    if ($arcman) {
			my $cache = $arcman->get_previous_archive;
			if ($cache) {
			    foreach my $name (@modules) {
				if ($runtime->module($name)->status eq "failed") {
				    my $result = $cache->get_data($name, "build");
				    if (!$result->{status} || $result->{status} ne "failed") {
					$log->debug("Previous status was " . $result->{status});
					$newfail = 1;
				    }
				}
			    }
			} else {
			    $log->debug("No cache, treating as new failure");
			    $newfail = 1;
			}
		    } else {
			$log->debug("No archive manager, treating as new failure");
			$newfail = 1;
		    }
		    if ($newfail) {
			$log->debug("Sending due to new failure");
			$self->dispatch_message($runtime, $from, \@to, \@modules);
		    } else {
			$log->debug("Not sending because failure was not new");
		    }
		}
	    } else {
		$log->debug("Not sending because no failures occurred");
	    }
	}
    }
}


sub prepare {
    my $self = shift;
    my $runtime = shift;

    $self->{cycle_start_time} = time;

    $self->SUPER::prepare($runtime);
}

# XXX need to refactor wrt to TemplateGenerator & HTMLStatus classes
sub dispatch_message {
    my $self = shift;
    my $runtime = shift;
    my $from = shift;
    my $to = shift;
    my $modules = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Dispatching messages");

    my $path = $self->option("template-dir");
    my %config = (
		  INCLUDE_PATH => $path
		  );
    my $template = Template->new(\%config);

    my $globalvars = {};
    my $now = time;
    my $then = $self->{cycle_start_time};
    my $cycle_time = $now - $then + 1;

    my $overall_status = 'success';
    foreach my $name ($runtime->modules()) {
	if ($runtime->module($name)->status() eq 'failed') {
	    $overall_status = 'failed';
	}
    }

    $globalvars->{'status'} = $overall_status;

    $globalvars->{'cycle_end_date'} = strftime ("%a %b %e %Y", gmtime $now);
    $globalvars->{'cycle_end_time_utc'} = strftime ("%H:%M:%S", gmtime $now) . " UTC";
    $globalvars->{'cycle_end_time_local'} = strftime ("%H:%M:%S %Z", localtime $now);

    $globalvars->{'cycle_start_date'} = strftime ("%a %b %e %Y", gmtime $then);
    $globalvars->{'cycle_start_time_utc'} = strftime ("%H:%M:%S", gmtime $then) . " UTC";
    $globalvars->{'cycle_start_time_local'} = strftime ("%H:%M:%S %Z", localtime $then);

    $globalvars->{'cycle_duration'} = Test::AutoBuild::Lib::pretty_time($cycle_time);

    $globalvars->{'build_counter'} = $runtime->build_counter;
    $globalvars->{'build_timestamp'} = $runtime->timestamp;
    $globalvars->{'admin_email'} = $runtime->admin_email;
    $globalvars->{'admin_name'} = $runtime->admin_name;
    $globalvars->{'hostname'} = hostname();

    my $smtp_server = $self->option("smtp_server");
    $smtp_server = "localhost" unless defined $smtp_server;

    my @mods;

    # Grab data from modules
    foreach my $name (sort @{$modules}) {
	my $module = $runtime->module($name);

	my $build_start = $module->build_start_date;
	my $build_end = $module->build_end_date;

	my $mod = {
	    'name' => $name,
	    'label' => $module->label,
	    'status' => $module->status,
	    'build_status' => $module->build_status,
	    'build_duration' => Test::AutoBuild::Lib::pretty_time($build_end - $build_start),
	    'build_date' => scalar (Test::AutoBuild::Lib::pretty_date($build_start)),
	    'admin_email' => $module->admin_email,
	    'admin_name' => $module->admin_name,
	};

	push @mods, $mod;
    }

    foreach my $addr (@{$to}) {
	$log->debug("Generating message to '$addr'");
	my %vars = %{$globalvars};
	$vars{'to'} = $addr;
	$vars{'from'} = $from;
	$vars{'modules'} = \@mods;

	my $localvars = $self->option("variables");
	if ($localvars) {
	    foreach my $name (keys %{$localvars}) {
		$vars{$name} = $localvars->{$name};
	    }
	}

	my $body;
	my $template_file = $self->option("template-file") || "email.txt";
	if (!$template->process($template_file, \%vars, IO::Scalar->new(\$body))) {
	    $self->fail($template->error->as_string);
	    $log->warn("Could not format mail body: " . $template->error->as_string);
	    return;
	}

	$self->send_message($smtp_server, $from, $addr, $body);
    }
}

sub send_message {
    my $self = shift;
    my $smtp_server = shift;
    my $from = shift;
    my $to = shift;
    my $body = shift;

    my $log = Log::Log4perl->get_logger();

    my $smtp = Net::SMTP->new($smtp_server);
    die "Couldn't connect to server $smtp_server" unless $smtp;

    $log->info("Sending a message to $to");

    $smtp->mail($from);
    $smtp->to($to);


    $smtp->data();
    $smtp->datasend ($body);
    $smtp->dataend();

    $smtp->quit();
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel P. Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2006 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Net::SMTP>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Runtime>, L<Test::AutoBuild::Module>,
L<Template>, L<http://template-toolkit.org>

=cut

# -*- perl -*-
#
# Test::AutoBuild::Stage::TemplateGenerator by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::TemplateGenerator - Base class for generating file templates

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::TemplateGenerator


=head1 DESCRIPTION

This module provides an abstract base for output modules wishing to
generate HTML using the Template-Toolkit.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::TemplateGenerator;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use File::Spec;
use Log::Log4perl;
use POSIX qw(strftime);
use Sys::Hostname;
use File::Copy qw(copy);
use Template;

sub prepare {
    my $self = shift;
    my $runtime = shift;

    $self->{cycle_start_time} = time;

    $self->SUPER::prepare($runtime);
}

sub _generate_templates {
    my $self = shift;
    my $runtime = shift;
    my $globalvars = shift;

    my $log = Log::Log4perl->get_logger();
    my $files = $self->option("files");
    $files = [ "index.html" ] unless defined $files;
    $files = $self->_expand_templates($files, $runtime);

    my $path = $self->option("template-src-dir");
    my %config = (
		  INCLUDE_PATH => $path,
		  RECURSION => 1,
		  );
    my $template = Template->new(\%config);

    my $overall_status = 'success';
    foreach my $name ($runtime->modules()) {
	if ($runtime->module($name)->status() eq 'failed') {
	    $overall_status = 'failed';
	}
    }

    my $now = time;
    my $then = $self->{cycle_start_time};
    my $cycle_time = $now - $then + 1;

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

    my @failed;
    foreach my $file (@{$files}) {
	my ($src, $dst, $localvars) = @{$file};

	$log->info("Got $src, $dst: " . join (',', map {$_ . "=" . $localvars->{$_}} keys %{$localvars}));

	my $dest = File::Spec->catfile($self->option("template-dest-dir"), $dst);

	if ($src =~ /^.*\.(png|jpeg|jpg|gif)$/) {
	    my $srcpath = File::Spec->catfile($path, $src);
	    copy($srcpath, $dest) or die "cannot copy $srcpath to $dest: $!";
	} else {
	    my $fh = IO::File->new(">$dest")
		or die "cannot  create $dest: $!";

	    my $customvars = $self->option("variables") || {};

	    my %vars;
	    foreach (keys %{$globalvars}) {
		$vars{$_} = $globalvars->{$_};
	    }
	    foreach (keys %{$localvars}) {
		$vars{$_} = $localvars->{$_};
	    }
	    foreach (keys %{$customvars}) {
		$vars{$_} = $customvars->{$_};
	    }

	    if (!$template->process($src, \%vars, $fh)) {
		my $err = $template->error;
		push @failed, "$err";
		$log->warn("$err");
	    }

	    $fh->close;
	}
    }

    if (@failed) {
	$self->fail(join("\n", @failed));
    }
}

sub _expand_templates {
    my $self = shift;
    my $files = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();
    my @in;
    foreach (@{$files}) {
	my ($src, $dst);
	if (ref($_) eq "HASH") {
	    ($src, $dst) = ($_->{src}, $_->{dst});
	} else {
	    $src = $dst = $_;
	}
	$log->info("Adding $src, $dst");
	push @in, [ $src, $dst, { templateSrc => $src, templateDst => $dst } ];
    }
    return Test::AutoBuild::Lib::_expand_standard_macros(\@in, $runtime);
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::HTMLStatus>, L<Template>, L<http://template-toolkit.org>

=cut

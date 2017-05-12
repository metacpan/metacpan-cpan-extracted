# -*- perl -*-
#
# Test::AutoBuild::Lib by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Lib - A library of useful routines

=head1 SYNOPSIS

  use Test::AutoBuild::Lib;

  my \@sorted_modules = Test::AutoBuild::Lib::sort_modules(\@modules);

  my \%packages = Test::AutoBuild::Lib::package_snapshot($package_types);
  my \%newpackages = Test::AutoBuild::Lib::new_packages(\%before, \%after);

  my $string = Test::AutoBuild::Lib::pretty_size($bytes);
  my $string = Test::AutoBuild::Lib::pretty_date($seconds);
  my $string = Test::AutoBuild::Lib::pretty_time($seconds);

=head1 DESCRIPTION

The Test::AutoBuild::Lib module provides a library of routines
that are shared across many different modules.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Lib;

use warnings;
use strict;

use Carp qw(confess);
use File::Copy;
use File::Glob ':glob';
use File::Path;
use File::stat;
use File::Spec::Functions;
use File::ReadBackwards;
use Log::Log4perl;
use POSIX qw(strftime);
use Sys::Hostname;
use Template;
use IO::Scalar;
use Config::Record;
use Test::AutoBuild::Command::Local;

=item my %packages = Test::AutoBuild::Lib::new_packages(\%before, \%after);

Compares the sets of packages defined by the C<before> and C<after>
package snapshots. The returned hash ref will have entries for any
files in C<after>, but not in C<before>, or any files which were
modified between C<before> and C<after> snapshots.

=cut

sub new_packages {
    my $before = shift;
    my $after = shift;

    my $packages = {};
    foreach my $file (keys %{$after}) {
	if (!exists $before->{$file} ||
	    $before->{$file}->last_modified() != $after->{$file}->last_modified()) {
	    $packages->{$file} = $after->{$file};
	}
    }

    return $packages;
}

=item my $string = Test::AutoBuild::Lib::pretty_date($seconds);

Formats the time specified in the C<seconds> parameter to
follow the style "Wed Jan 14 2004 21:45:23 UTC".

=cut

sub pretty_date {
    my $time = shift;

    if (defined $time) {
	return strftime "%a %b %e %Y %H:%M:%S UTC", gmtime($time);
    } else {
	return "";
    }
}

=item my $string = Test::AutoBuild::Lib::pretty_time($seconds);

Formats an interval in seconds for friendly viewing according
to the style "2h 27m 12s" - ie 2 hours, 27 minutes and 12
seconds.

=cut

sub pretty_time {
    my $time = shift;

    if (defined $time) {
	my $time_hours;
	my $time_minutes;
	my $time_seconds;
	{
	    use integer;
	    $time_hours = $time / 3600;
	    $time_minutes = ($time - ($time_hours * 3600)) / 60;
	    $time_seconds = $time - ($time_hours * 3600) - ($time_minutes * 60);
	};

	return sprintf ("%02dh %02dm %02ds",
			$time_hours,
			$time_minutes,
			$time_seconds);
    } else {
	return "";
    }
}

=item my $string = Test::AutoBuild::Lib::pretty_size($bytes);

Formats the size specified in the C<bytes> parameter for
friendly viewing. If the number of bytes is > 1024x1024
then it formats in MB, with 2 decimal places. Else if
the number of bytes is > 1024 it formats in kb with 2
decimal places. Otherwise it just formats as bytes.

=cut

sub pretty_size {
    my $size = shift;

    if ($size > (1024 * 1024)) {
	return sprintf("%.2f MB", ($size / (1024 * 1024)));
    } elsif ($size > 1024) {
	return sprintf("%.2f KB", ($size / 1024));
    } else {
	return $size . " b";
    }
}

=item my $status = Test::AutoBuild::Lib::run($comnand, \%env);

Executes the program specified in the C<command> argument.
The returned value is the output of the commands standard
output stream. Prior to running the command, the environment
variables specified in the C<env> parameter are set. This
environment is modified locally, so the changes are only
in effect for the duration of this method.

=cut

sub run {
    my $command = shift;
    my $env = shift;

    my $log = Log::Log4perl->get_logger();

    local %ENV = %ENV;
    foreach (keys %{$env}) {
	$log->debug("Set env $_ $env->{$_}");
	$ENV{$_} = $env->{$_};
    }

    my $c = Test::AutoBuild::Command::Local->new(cmd => ["/bin/sh", "-c", $command],
						 env => $env);

    my $output = '';
    my $status = $c->run(\$output, \$output);
    die "cannot run /bin/sh -c $command: $status" if $status;
    return $output;
}

sub _copy {
    my $options = shift;
    if (ref($options) ne "HASH") {
	unshift @_, $options;
	$options = undef;
    }

    my $target = pop;
    my @source = @_;
    &copy_files(\@source, $target, $options);
}

sub copy_files {
    my $source = shift;
    my $target = shift;
    my $options = shift;

    my $log = Log::Log4perl->get_logger();

    my $attrs = ['mode','ownership','timestamps','links'];
    $options = {
	"glob" => 1,
	"link" => 0,
	"preserve" => {
	    'mode' => 0,
	    'ownership' => 0,
	    'links' => 1
	    },
	"symbolic-link" => 0,
    } unless defined $options;

    $options->{preserve} = {"all"=>1} unless exists $options->{preserve};

    if ($options->{preserve}->{all}) {
	for (@$attrs) {
	    $options->{preserve}->{$_} = 1;
	}
    }
    my @expanded_sources;
    my @source = ref($source) ? @{$source} : ($source);
    if ($options->{glob}) {
	for (@source) {
	    push @expanded_sources, bsd_glob($_);
	}
    } else {
	@expanded_sources = @source;
    }

    if (@expanded_sources > 1 && ! -d $target) {
	if (-e $target) {
	    die "multiple sources specified but '$target' is not a directory";
	}
	eval {
	    mkpath($target);
	};
	if ($@) {
	    die "could not create directory '$target': $@";
	}
    }
    foreach (@expanded_sources) {
	$_ = File::Spec->canonpath($_);
	my $newfile = -d $target ? File::Spec->catfile($target,(File::Spec->splitpath($_))[-1]) : $target;
	if (-l $_ && $options->{preserve}->{links}) {
	    my $oldfile = readlink;
	    my @dir = File::Spec->splitdir($newfile);
	    pop @dir;
	    my $basedir = File::Spec->catdir(@dir);
	    if (!-d $basedir) {
		eval {
		    $log->debug("Creating base $basedir");
		    mkpath($basedir);
		};
		if ($@) {
		    die "could not create directory '$basedir': $@";
		}
	    }
	    symlink ($oldfile, $newfile) or die "cannot create symlink $newfile";
	    &setStats($newfile, lstat($_));
	} else {
	    if (!-e) {
		confess "cannot stat '$_': No such file or directory";
	    } elsif (-d) {
		$log->debug("copying directory $_");
		my $dir = $_;
		my @dirs = File::Spec->splitdir($dir);
		my $new_target = File::Spec->catdir($target, $dirs[$#dirs]);
		my @files;
		opendir(DIR, $dir) or die("can't opendir $dir: $!");
		push @files, grep { !m/^\.$/ && !m/^\.\.$/ } readdir(DIR);
		closedir DIR;
		foreach (@files) { $_ = File::Spec->catfile($dir, $_) };
		eval {
		    mkpath($new_target);
		};
		if ($@) {
		    die "could not create directory '$new_target': $@";
		}
		my %newoptions = %{$options};
		$newoptions{glob} = 0;
		@files > 0 && _copy (\%newoptions, @files, $new_target);
	    } else {
		my @dir = File::Spec->splitdir($newfile);
		pop @dir;
		my $basedir = File::Spec->catdir(@dir);
		if (!-d $basedir) {
		    eval {
			$log->debug("Creating base $basedir");
			mkpath($basedir);
		    };
		    if ($@) {
			die "could not create directory '$basedir': $@";
		    }
		}

		if (-e $newfile) {
		    $log->debug("unlinking target $newfile which already exists");
		    if ((unlink $newfile) != 1) {
			die "could not unlink target $newfile: $!";
		    }
		}

		if (-f && $options->{'symbolic-link'}){
		    $log->debug("symbolic linking file $_ to $newfile");
		    if (!symlink ($_, $newfile)) {
			die "could not symbolic link to target $newfile: $!";
		    }
		} elsif (-f && $options->{link}){
		    $log->debug("linking file $_ to $newfile");
		    if (!link ($_, $newfile)) {
			# XXX fallback to copy ?
			die "could not hardlink to target $newfile: $!";
		    }
		} else {
		    $log->debug("copying file $_ to $newfile");
		    if (!copy($_, $newfile)) {
		       die "could not copy to target $newfile: $!";
		    }
		    &setStats($newfile, stat($_));
		}
	    }
	}
    }
}

sub setStats {
    my $file = shift;
    my $sb = shift;
    confess "called setStats with an undefined file" unless defined $file;
    confess "called setStats with an undefined sb" unless defined $sb;
    chmod ($sb->mode, $file);
    chown ($sb->uid, $sb->gid, $file);
}

sub delete_files {
    my $dir = shift;

    my $log = Log::Log4perl->get_logger();

    my $glob = catfile($dir, "*");
    $log->info("Removing all files matching '$glob'");

    my @todelete = bsd_glob($glob);
    foreach (@todelete) {
	$log->info("File to remove is '$_'");
    }

    if (@todelete) {
	rmtree(\@todelete, 0, 0);
    }
}

sub _expand_macro {
    my $in = shift;
    my $macro = shift;
    my $name = shift;
    my @values = @_;
    my @out;
    foreach my $entry (@{$in}) {
	my $src = $entry->[0];
	my $dst = $entry->[1];
	if ($dst =~ /$macro/) {
	    foreach my $value (@values) {
		(my $file = $dst) =~ s/$macro/$value/;
		my $vars = {};
		map { $vars->{$_} = $entry->[2]->{$_} } keys %{$entry->[2]};
		$vars->{$name} = $value;
		push @out, [$src, $file, $vars];
	    }
	} else {
	    push @out, $entry;
	}
    }
    return \@out;
}

sub _expand_standard_macros {
    my $in = shift;
    my $runtime = shift;
    my $out = _expand_macro($in, "%m", "module", $runtime->modules);
    $out = _expand_macro($out, "%p", "package_type", $runtime->package_types);
    $out = _expand_macro($out, "%g", "group", $runtime->groups);
    $out = _expand_macro($out, "%r", "repository", $runtime->repositories);
    $out = _expand_macro($out, "%c", "build_counter", $runtime->build_counter);
    $out = _expand_macro($out, "%h", "hostname", hostname());
    return $out;
}

=item ($config, $fh, $error) = Test::AutoBuild::Lib::load_template_config($file, [\%vars])

This method loads the content of the configuration file C<$file>,
passes it through the L<Template> module, and then creates an
instance of the L<Config::Record> module. The second optiona C<%vars>
parameter is a hash reference containing a set of variables which
will be passed through to the templating engine. A 3 element list is
returned, the first element containing the L<Config::Record>
object, the second a scalar containing the post-processed configuration
file, the last containing any error message generated.

=cut

sub load_templated_config {
    my $file = shift;
    my $vars = shift || {};

    return (undef, undef, "file $file does not exist")
	unless -f $file;

    my %template_config = (
			   ABSOLUTE => 1,
			   RELATIVE => 1,
			   );

    my $template = Template->new(\%template_config);
    my $data;
    my $fh = IO::Scalar->new(\$data);

    $template->process($file, $vars, $fh)
	or return (undef, undef, $template->error());

    $fh->setpos(0);
    my $config;
    eval {
	$config = Config::Record->new(file => $fh);
    };
    my $err = $@;
    my @data_file;
    if ($err) {
	my $i = 0;
	foreach (split /\n/, $data) {
	    push @data_file, (sprintf "%4d  %s\n", (++$i), $_);
	}
    }
    return ($config, join("", @data_file), $err);
}


sub log_file_lines {
    my $filename = shift;
    my $limit = shift;

    my $io;
    my $rev = 0;
    if ($limit < 0) {
	$limit = $limit * -1;
	$rev = 1;
	$io = File::ReadBackwards->new($filename) or die "cannot read $filename: $!";
    } else {
	$io = IO::File->new($filename) or die "cannot read $filename: $!";
    }

    my @lines;
    for (my $i = 0 ; !$limit || ($i < $limit) ; $i++) {
	my $line = $io->getline;
	last unless defined $line;
	push @lines, $line;
    }

    @lines = reverse @lines if $rev;

    return @lines;
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>, Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>, L<Template>,
L<Config::Record>

=cut

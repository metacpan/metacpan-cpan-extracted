package Rex::Commands::PerlSync;
$Rex::Commands::PerlSync::VERSION = '0.001';
use v5.12.5;
use warnings;

require Rex::Exporter;
use base qw(Rex::Exporter);
use vars qw(@EXPORT);

use Rex::Commands;
use Rex::Commands::MD5;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Commands::Download;
use Rex::Helper::Path;
use Rex::Helper::Encode;
use Text::Glob 'match_glob';

@EXPORT = qw(sync_up sync_down);
$Text::Glob::strict_wildcard_slash = 0;

sub sync_up
{
	my ($source, $dest, @option) = @_;

	my $options = {};

	if (ref($option[0])) {
		$options = $option[0];
	}
	else {
		$options = {@option};
	}

	# default is, parsing templates (*.tpl) files
	$options->{parse_templates} = TRUE;

	$source = resolv_path($source);
	$dest = resolv_path($dest);

	#
	# 0. normalize local path
	#
	$source = get_file_path($source, caller);

	#
	# first, build excludes list
	#

	my $excludes = $options->{exclude} ||= [];
	$excludes = [$excludes] unless ref($excludes) eq 'ARRAY';

	my @excluded_files = @{$excludes};

	my $check_exclude_file = sub {
		my ($file) = @_;
		$file =~ s{^/}{};

		for my $cmp (@excluded_files) {
			return 1 if match_glob($cmp, $file);
		}

		return 0;
	};

	#
	# second, get all files on source side (minus excludes)
	#
	my @local_files = _get_local_files($source, $check_exclude_file);

	#
	# third, get all files from destination side (minus excludes)
	#

	my @remote_files = _get_remote_files($dest, $check_exclude_file);

	#
	# fourth, get the difference
	#

	my @diff = _diff_files(\@local_files, \@remote_files);

	#
	# fifth, upload the different files
	#

	my @uploaded_files;
	for my $file (@diff) {
		my ($dir) = ($file->{path} =~ m/(.*)\/[^\/]+$/);
		my ($remote_dir) = ($file->{name} =~ m/\/(.*)\/[^\/]+$/);

		my (%dir_stat, %file_stat);
		LOCAL {
			%dir_stat = stat($dir);
			%file_stat = stat($file->{path});
		};

		# check for overwrites
		my %file_perm = (mode => $file_stat{mode});
		if (exists $options->{files} && exists $options->{files}->{mode}) {
			$file_perm{mode} = $options->{files}->{mode};
		}

		if (exists $options->{files} && exists $options->{files}->{owner}) {
			$file_perm{owner} = $options->{files}->{owner};
		}

		if (exists $options->{files} && exists $options->{files}->{group}) {
			$file_perm{group} = $options->{files}->{group};
		}

		my %dir_perm = (mode => $dir_stat{mode});
		if (
			exists $options->{directories}
			&& exists $options->{directories}->{mode}
			)
		{
			$dir_perm{mode} = $options->{directories}->{mode};
		}

		if (
			exists $options->{directories}
			&& exists $options->{directories}->{owner}
			)
		{
			$dir_perm{owner} = $options->{directories}->{owner};
		}

		if (
			exists $options->{directories}
			&& exists $options->{directories}->{group}
			)
		{
			$dir_perm{group} = $options->{directories}->{group};
		}
		## /check for overwrites

		if ($remote_dir) {
			mkdir "$dest/$remote_dir", %dir_perm;
		}

		Rex::Logger::debug(
			"(sync_up) Uploading $file->{path} to $dest/$file->{name}"
		);
		if ($file->{path} =~ m/\.tpl$/ && $options->{parse_templates}) {
			my $file_name = $file->{name};
			$file_name =~ s/\.tpl$//;

			file "$dest/" . $file_name,
				content => template($file->{path}),
				%file_perm;

			push @uploaded_files, "$dest/$file_name";
		}
		else {
			file "$dest/" . $file->{name},
				source => $file->{path},
				%file_perm;

			push @uploaded_files, "$dest/" . $file->{name};
		}
	}

	if (
		exists $options->{on_change}
		&& ref $options->{on_change} eq "CODE"
		&& scalar(@uploaded_files) > 0
		)
	{
		Rex::Logger::debug("Calling on_change hook of sync_up");
		$options->{on_change}->(map { $dest . $_->{name} } @diff);
	}

}

sub sync_down
{
	my ($source, $dest, @option) = @_;

	my $options = {};

	if (ref($option[0])) {
		$options = $option[0];
	}
	else {
		$options = {@option};
	}

	$source = resolv_path($source);
	$dest = resolv_path($dest);

	#
	# first, build excludes list
	#

	my $excludes = $options->{exclude} ||= [];
	$excludes = [$excludes] unless ref($excludes) eq 'ARRAY';

	my @excluded_files = @{$excludes};

	my $check_exclude_file = sub {
		my ($file) = @_;
		$file =~ s{^/}{};

		for my $cmp (@excluded_files) {
			return 1 if match_glob($cmp, $file);
		}

		return 0;
	};

	#
	# second, get all files on dest side (minus excludes)
	#
	my @local_files = _get_local_files($dest, $check_exclude_file);

	#
	# third, get all files from source side (minus excludes)
	#

	my @remote_files = _get_remote_files($source, $check_exclude_file);

	#
	# fourth, get the difference
	#

	my @diff = _diff_files(\@remote_files, \@local_files);

	#
	# fifth, download the different files
	#

	for my $file (@diff) {
		my ($dir) = ($file->{path} =~ m/(.*)\/[^\/]+$/);
		my ($remote_dir) = ($file->{name} =~ m/\/(.*)\/[^\/]+$/);

		my (%dir_stat, %file_stat);
		%dir_stat = stat($dir);
		%file_stat = stat($file->{path});

		LOCAL {
			if ($remote_dir) {
				mkdir "$dest/$remote_dir", mode => $dir_stat{mode};
			}
		};

		Rex::Logger::debug(
			"(sync_down) Downloading $file->{path} to $dest/$file->{name}"
		);
		download($file->{path}, "$dest/$file->{name}");

		LOCAL {
			chmod $file_stat{mode}, "$dest/$file->{name}";
		};
	}

	if (
		exists $options->{on_change}
		&& ref $options->{on_change} eq "CODE"
		&& scalar(@diff) > 0
		)
	{
		Rex::Logger::debug("Calling on_change hook of sync_down");
		if (substr($dest, -1) eq "/") {
			$dest = substr($dest, 0, -1);
		}
		$options->{on_change}->(map { $dest . $_->{name} } @diff);
	}

}

sub _get_local_files
{
	my ($source, $exclude_sub) = @_;

	if (!-d $source) { die("$source : no such directory."); }

	my @dirs = ($source);
	my @local_files;
	LOCAL {
		for my $dir (@dirs) {
			for my $entry (list_files($dir)) {
				next if ($entry eq ".");
				next if ($entry eq "..");

				my $name = "$dir/$entry";
				$name =~ s/^\Q$source\E//;
				next if $exclude_sub->($name);

				if (is_dir("$dir/$entry")) {
					push(@dirs, "$dir/$entry");
					next;
				}
				push(
					@local_files,
					{
						name => $name,
						path => "$dir/$entry",
						md5 => md5("$dir/$entry"),
					}
				);

			}
		}
	};

	return @local_files;
}

sub _get_remote_files
{
	my ($dest, $exclude_sub) = @_;

	if (!is_dir($dest)) { die("$dest : no such directory."); }

	my @remote_dirs = ($dest);
	my @remote_files;

	for my $dir (@remote_dirs) {
		for my $entry (list_files($dir)) {
			next if ($entry eq ".");
			next if ($entry eq "..");

			my $name = "$dir/$entry";
			$name =~ s/^\Q$dest\E//;
			next if $exclude_sub->($name);

			if (is_dir("$dir/$entry")) {
				push(@remote_dirs, "$dir/$entry");
				next;
			}

			push(
				@remote_files,
				{
					name => $name,
					path => "$dir/$entry",
					md5 => md5("$dir/$entry"),
				}
			);
		}
	}

	return @remote_files;
}

sub _diff_files
{
	my ($files1, $files2) = @_;
	my %checksums;
	my @diff;

	for my $file (@{$files2}) {
		$checksums{$file->{name}} = $file->{md5};
	}

	for my $file (@{$files1}) {
		push @diff, $file
			if !$checksums{$file->{name}} || $checksums{$file->{name}} ne $file->{md5};
	}

	return @diff;
}

1;

=head1 NAME

Rex::Commands::PerlSync - Sync directories, better

=head1 DESCRIPTION

This module is a L<Rex> command which synchronizes directories. It is a fork of
L<Rex::Commands::Sync> with the same interface and a couple of improvements:

=over

=item

Files and directories are now excluded before calculating md5 of the directory,
vastly improving the speed if there are a lot of excluded files.

=item

Excludes now work using the exact path rather than file name, making it easier
to exclude files or entire directories.

=back

=head1 SYNOPSIS

 use Rex::Commands::PerlSync;

 task "prepare", "mysystem01", sub {
   # upload directory recursively to remote system.
   sync_up "/local/directory", "/remote/directory";

   sync_up "/local/directory", "/remote/directory", {
     # setting custom file permissions for every file
     files => {
       owner => "foo",
       group => "bar",
       mode  => 600,
     },
     # setting custom directory permissions for every directory
     directories => {
       owner => "foo",
       group => "bar",
       mode  => 700,
     },
     exclude => [ '*.tmp' ],
     parse_templates => TRUE|FALSE,
     on_change => sub {
      my (@files_changed) = @_;
     },
   };

   # download a directory recursively from the remote system to the local machine
   sync_down "/remote/directory", "/local/directory";
 };

=head1 AUTHOR

Original code from L<Rex> - see authors.

Modified by Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


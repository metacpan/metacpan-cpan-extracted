package SVN::Rami;

use 5.10.1;
use strict;
use warnings;

use File::Basename;
use File::Path qw(make_path remove_tree);
#use File::Spec;  # Will use later for Windows file names.
#use Path::Class; # Will use later for Windows file names.

# TODO: clearly define the words "version", "revision", "branch". (Maybe "version" isn't the right word to use.)
# TODO: sanitize version names: they should contain only \w and hyphen.


=head1 NAME

SVN::Rami - Automates merging to multiple branches

=cut

our $VERSION = '0.205';


=head1 SYNOPSIS

Used by the script L<rami|https://metacpan.org/dist/SVN-Rami/view/bin/rami>. This is not (yet) a stand-alone module.

=head1 SUBROUTINES

This module is only intended to be used by the script
L<rami|https://metacpan.org/dist/SVN-Rami/view/bin/rami>.
There are a few publicly available subroutines,
but they are not guaranteed to be compatible between revisions.

=cut

#
# Documentation of public subroutines is provided inline below.
#


#
#Reads a two-column CSV file and converts it to key-value pairs.
#For example, if the file contains one line consisting of "a,b",
#this method returns a mapping of "a" to "b".
#The file is assumed to have no headers.
#
#BUG: the file must be formatted precisely right: even an empty
#line in the middle of the file will result in an incorrect mapping.
#
#TODO: use Text::CSV instead.
#
sub load_csv_as_map {
	my $filename = shift;
	local $/ = undef; # Slurp mode
	open(my $handle, '<', $filename) or die "Could not read $filename\n";
	$_ = <$handle>;
	close $handle;
	my @contents = split( /,|\R/ );
	
	# Hack: the first two items are column headings.
	(undef, undef, my @result) = @contents;
	return @result;
}


#
# This utility function simply dumps data to a file.
# Example: write_file('foo.txt', 'Hello world') creates a file
# named foo.txt whose complete contents are "Hello world".
# Note that you can pass a multi-line string as the second argument.
#
sub write_file {
	my $filename = shift;
	my $contents = shift;
	
	open(my $handle, '>', $filename) or die "Could not write to $filename\n";
	print $handle $contents;
	close $handle;
}

#
# Usage: find_revision($revision, %branch_to_url)
# Queries SVN for information about the revision.
# Returns a hash that maps 'branch' to the branch on which the revision
# was committed (e.g., 6.2) and that maps 'commit_message' to the
# comment the user wrote to explain the commit.
#
sub find_revision {
	my $rev = shift;
	my %branch_to_url = @_;
	foreach my $branch (keys %branch_to_url) {
		my $url = $branch_to_url{$branch};
		$_ = `svn log -c $rev $url`;
		
		# If the revision was NOT on $branch, then the output
		# will be a single line of dashes: ----------
		#
		# But if the revision WAS on $branch, then
		# the output will be something like this:
		# ------------------------------------------------------------------------
		# r84187 | bob.smith | 2023-03-27 10:53:40 -0400 (Mon, 27 Mar 2023) | 4 lines
		# 
		# Fixed memory leak
		# ------------------------------------------------------------------------
		if ( m/^-----+\R*        # match a bunch of dashes followed by a newline.
				^r.*?lines?\R+   # match line: r84187 | badelman | ... | 4 lines
				^(.*?)\R+        # Match the commit message.
				^-------+\R*\Z   # Match a bunch of dashes followed by a newline.
				/msx ) {
			
		#if ( m/^-+\r?\n?.*?lines(\r?\n)+(.*?)\r?\n-+(\r?\n)*$/sx ) {
			return ('branch'=>$branch, 'commit_message'=>$1 );
		}
	}
	
	# Revision not found. Return an empty hash.
	return ();
}


# HACK: define these as essentially global for now.
our $repo = 'default';  # TODO: support more than one repo.
our $rami_home_dir = glob("~/.rami/repo/$repo");  # TODO: use File::HomeDir instead of ~/
our $conf_dir = "$rami_home_dir/conf";
our $temp_dir = "$rami_home_dir/temp";
our $commit_message_file = "$temp_dir/message.txt";
our $path_csv_file = "$conf_dir/paths.csv";    # Not currently used.
our $root_work_dir = "$rami_home_dir/work";    # Holds a subdirectory for each branch.


#=head2 rami_main
#
#The main module. Currently takes one argument,
#which is the SVN revision which shoulde be merged.
#
#=cut

sub rami_main {
	my $source_revision = shift;
	
	my $conf_dir = $SVN::Rami::conf_dir;
	my $commit_message_file = $SVN::Rami::commit_message_file;
	my $path_csv_file = $SVN::Rami::path_csv_file;
	
	#print "### $commit_message_file\n";

	die "Expected directory $conf_dir\n" unless -d $conf_dir;

	# my %branch_to_path_on_filesystem = load_csv_as_map($path_csv_file);

	# We need the list of branches to be in order.
	my @branch_to_url_array = load_csv_as_map("$conf_dir/urls.csv");
	my %branch_to_url = @branch_to_url_array;
	my @branches = grep( !/^http/, @branch_to_url_array);  # HACK: remove URLs, leaving only versions, IN ORDER!
	
	my %branch_to_path_on_filesystem = map { $_ => convert_branches_to_filesystem_paths($_) } @branches;

	my %revision_details = find_revision($source_revision, %branch_to_url);
	if ( ! %revision_details ) {
		die "Unable to find revision $source_revision\n";
	}

	my $source_branch = $revision_details{'branch'};
	# The revision comment. We will later append something like "merge r 123 from 2.2.2"
	my $base_commit_message = $revision_details{'commit_message'};
	$base_commit_message =~ s/(\r\n\R\s)+$//g;   # Remove trailing whitespace/newlines.


	my $found_branch = 0;   # Will be true when we loop to the source branch.
	#my $previous_branch = '';
	foreach my $target_branch (@branches) {
		if ($target_branch eq $source_branch) {
			$found_branch = 1;
			# Perhaps instead of if-else we could use "redo", which is similar to Java's "continue"
		} elsif ( $found_branch ) { # If we found the branch last time...
			print "------------------------ Merging r $source_revision from $source_branch to $target_branch\n";
			my $source_url = $branch_to_url{$source_branch};
			my $working_dir = $branch_to_path_on_filesystem{$target_branch};

			# Get our working directory to the correct revision.
			chdir($working_dir);
			system("svn revert -R ."); # or die "Failed to revert $working_dir";
			system("svn up"); # or die "Failed to update $working_dir";

			# Write the commit message to a file.
			my $commit_message = "$base_commit_message (merge r $source_revision from $source_branch)";
			write_file($commit_message_file, $commit_message);

			my $merge_command = "svn merge --accept postpone -c $source_revision $source_url .";
			print "$merge_command\n";
			my $output_from_merge = `$merge_command`;
			print "$output_from_merge\n";
			if ($output_from_merge =~ /Summary of conflicts/) { # If there were merge conflicts
				print "Failed to merge r $source_revision from $source_branch to $target_branch.\n";
				print "Merge conflicts in $working_dir\n";
				die;
			}

			my $commit_command = "svn commit --file $commit_message_file";
			print "$commit_command\n";
			my $output_from_commit = `$commit_command`;
			my $target_revision;
			print "$output_from_commit\n";
			if ($output_from_commit =~ /Committed revision (\d+)\./) {
				$target_revision = $1;
			} else {
				die "Failed to commit r $source_revision from $source_branch to $target_branch.\n";
			}

			$source_branch = $target_branch;
			$source_revision = $target_revision;
		} else {
			# print "Skipping branch $target_branch because we don't need to merge it.\n";
		}
	}

	if ( ! $found_branch ) {
		die "Unrecognized branch $source_branch\n";
	}
}


=head2 windows_safe_remove_tree

	windows_safe_remove_tree "foo/bar", "c:\\temp"

B<This function is still in beta.> Removes a directory and all its sub-directories.
Same as L<File::Path::remove_tree|https://metacpan.org/pod/File::Path>,
but provides a work-around for a Windows issue involving very long filenames.
Works on all operating systems, not just Windows.


=head3 Statement of the problem

On Windows it is possible to create files that have more than 
L<MAX_PATH|https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file?redirectedfrom=MSDN#maximum-path-length-limitation>=260
characters, but Windows will
L<report errors when you try to delete them|https://appuals.com/fix-source-file-names-are-larger-than-is-supported-by-the-file-system/>.
If you try to delete them manually, you might see this error message:
"The source file names are larger than is supported by the file system".
If you try to delete the files with C<File::Path::remove_tree>,
you might see this error message:
"cannot remove directory for [...]: Directory not empty".

=head3 Existing work-arounds

Besides this function, many work-arounds have been proposed. See:

=over

=item * A L<work-around in Perl|http://stringstream.blogspot.com/2014/11/perl-long-paths-issue-in-windows.html> which uses L<Win32::LongPath|https://metacpan.org/pod/Win32::LongPath>.
(Note that the maintainers of L<File::Path::remove_tree|https://metacpan.org/pod/File::Path>
have L<declined a request to integrate the work-around|https://rt.cpan.org/Public/Bug/Display.html?id=105169>.)

=item * L<Work-arounds on the command-line|https://superuser.com/questions/78434/how-to-delete-directories-with-path-names-too-long-for-normal-delete>

=item * L<Work-arounds in the Windows GUI|https://appuals.com/fix-source-file-names-are-larger-than-is-supported-by-the-file-system/>

=back

=cut

sub windows_safe_remove_tree {
	if ($^O ne 'MSWin32') {
		# Normal case: not Windows
		File::Path::remove_tree @_;
	} else {
		# Windows: do the work-around
		my @filenames = @_;
		for (@filenames) { s#/#\\#g }  # Convert slashes to backslashes, e.g., a/b/c -> a\b\c
		my $windows_filenames = join(' ', @filenames);
		exec("rmdir /Q /S $windows_filenames");
	}
}

#=head2 load_config_from_SVN_url
#
#Secondary function: initializes based on a configuration
#file which is loaded from SVN.
#Takes one argument, which is the name of the config file.
#
#=cut

sub load_config_from_SVN_url {
	my $svn_url = shift;  # URL of our config file in SVN.
	my $rami_home_dir = $SVN::Rami::rami_home_dir;
	my $conf_dir = $SVN::Rami::conf_dir;
	my $temp_dir = $SVN::Rami::temp_dir;
	my $root_work_dir = $SVN::Rami::root_work_dir;

	# TODO: don't wipe out the old configuration until we know that the new configuration exists.
	
	remove_tree $rami_home_dir if -d $rami_home_dir;
	make_path $conf_dir, $temp_dir, $root_work_dir;
	
	my $result_of_export = EXEC("svn export --force $svn_url $conf_dir");
	die "Failed to load configuration from SVN\n" unless ($result_of_export =~ m/Export complete|Exported revision/);

	# Load the branches.
	# This code is COPY-AND-PASTED from rami_main().
	my @branch_to_url_array = load_csv_as_map("$conf_dir/urls.csv");
	my %branch_to_url = @branch_to_url_array;
	my @branches = grep( !/^http/, @branch_to_url_array);  # HACK: remove URLs, leaving only versions, IN ORDER!
	
	# Checkout the branches onto the local filesystem.
	while (my($branch,$url) = each(%branch_to_url)) {
		my $filesystem_path = convert_branches_to_filesystem_paths($branch);
		my $command = "svn checkout $url $filesystem_path";
		print "$command\n";
		system($command);
	}
}

#
# Converts a list of logical branch names to the place on the filesystem where they should be.
#
# Example: convert_branches_to_filesystem_paths('trunk')
# might return '/home/bob/.rami/repo/default/work/bob'
#
# In list context, returns a list.
# In scalar context, returns the first item of the list.
#
sub convert_branches_to_filesystem_paths {
	my $rami_home_dir = $SVN::Rami::rami_home_dir;
	my @result = map { "$rami_home_dir/work/$_" } @_;
	return wantarray ? @result : $result[0];
}

#
# Executes on the command line and returns the output.
# Example: my $list = EXEC('ls');
#
# This is just a wrapper for back-tick, i.e.,
#   my $result = `$command`;
# but it might later allow us to unit-test.
#
sub EXEC {
	my $command = shift;
	# my %args = ...
	print "$command\n";
	my $result = `$command`;
	print "$result\n";
	return $result;
}

=head1 AUTHOR

Dan Richter, C<< <dan.richter at trdpnt.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svn-rami at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Rami>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Rami


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Rami>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/SVN-Rami>

=item * Search CPAN

L<https://metacpan.org/release/SVN-Rami>

=back

=head1 SEE ALSO

L<SVK::Merge|https://metacpan.org/pod/SVK::Merge>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dan Richter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1; # End of SVN::Rami

package SVN::Rami;

use 5.10.1;
use strict;
use warnings;

use File::Basename;
#use File::Spec;  # Will use later for Windows file names.
#use Path::Class; # Will use later for Windows file names.


=head1 NAME

SVN::Rami - Automates merging to multiple branches

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

Should be invoked from the command line:

  perl -e "use SVN::Rami;" -c <version-number>

This is version 0.1, still mainly a proof-of-concept.

=head1 SUBROUTINES/METHODS

=head2 No publicly available subroutines at this time

=cut

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

=head2 function2

=cut

sub function2 {
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

SVK::Merge

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dan Richter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut


shift;   # HACK: currently the first argument is always -c
my $source_revision = shift;
if ( ! $source_revision ) {
	print "Usage: $0 -c <revision_number>\n";
	exit 1;
}


my $commit_message_file = 'c:\dev\430\message.txt';

my $repo = 'default';  # TODO: support more than one repo.
my $rami_home = glob("~/.rami/repo/$repo");  # TODO: use File::HomeDir
my $conf_dir = "$rami_home/conf";

die "Expected directory $conf_dir\n" unless -d $conf_dir;

my %branch_to_path_on_filesystem = load_csv_as_map("$conf_dir/paths.csv");

# We need the list of branches to be in order.
my @branch_to_url_array = load_csv_as_map("$conf_dir/urls.csv");
my %branch_to_url = @branch_to_url_array;
my @branches = grep( !/^http/, @branch_to_url_array);  # HACK: remove URLs, leaving only versions, IN ORDER!

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
		print "Skipping branch $target_branch because we don't need to merge it.\n";
	}
}

if ( ! $found_branch ) {
	die "Unrecognized branch $source_branch\n";
}


1; # End of SVN::Rami

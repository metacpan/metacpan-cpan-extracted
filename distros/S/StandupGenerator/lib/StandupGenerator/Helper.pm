package StandupGenerator::Helper;

use base 'Exporter';

our @EXPORT = qw( 
    find_last_file
    extract_identifiers
);

# Determine last file in a directory after sorting them alphabetically
sub find_last_file {
    my ($path) = @_;
    opendir my $dir, $path;
    my @files = readdir $dir;
    closedir $dir;
    my @sorted = sort @files;
    my $files_length = scalar(@files);
    my $last_file = $sorted[$files_length - 1];

    if (index($last_file, '.txt') == -1) {
        # When no .txt files exist in the directory, assume standups need to be initialized, so set the last file as a dummy
        $last_file = 's0d0.txt';
    }

    return $last_file;
}

# Get sprint and day numbers for a standup given its file name
sub extract_identifiers {
    my ($file) = @_;
    my $file_size = length($file) - 4;
    my $file_d_index = index($file, 'd');
    my $file_sprint = substr($file, 1, $file_d_index - 1);
    my $file_day = substr($file, $file_size - 1, 1);
    
    my %identifiers = (
        sprint => $file_sprint,
        day => $file_day,
    );

    return %identifiers;
}

1;

__END__

=pod

=head1 NAME

StandupGenerator::Helper - provides functions to assist methods in other modules

=head1 DESCRIPTION

The Helper module contains methods not intended for use by the end user. Instead, these methods extracted code blocks that recurred in different top-level methods. The goal was to eliminate redundancy in the rest of the code base.

=head1 METHODS

=head2 C<find_last_file>

This method returns the name of the last file within a given directory, after sorting the files alphabetically. This method will return a string of the name of a I<.txt> file. It will either be the last I<.txt> file within the directory specified by the argument, or it will be I<s0d0.txt> if the directory contained no I<.txt> files. It only takes one parameter:

=over

=item *

C<$path> -- A string containing the full file path for the directory containing the standup files. It should begin with I</Users/>.

=back

Assuming the I<standups> directory contains standup files and that yesterday's standup file was I<s3d07.txt>, then the below command will set C<$last_file> to the string I<s3d07.txt>.

    use StandupGenerator::Helper;
    my $last_file = StandupGenerator::Helper::find_last_file('/Users/johndoe/projects/super-important-project/standups');

=head2 C<extract_identifiers>

This method returns a hash containing the number of the standup's sprint and the last digit of the standup's two-digit day. It only takes one parameter:

=over

=item *

C<$file> -- A string containing the name of the I<.txt> file.

=back

The below command will set C<%ids> to a hash with a I<sprint> key equal to 2 and a I<day> key equal to 7, since only the last digit of the day is stored.

    use StandupGenerator::Helper;
    my %ids = StandupGenerator::Helper::extract_identifiers('s2d07.txt');

=cut
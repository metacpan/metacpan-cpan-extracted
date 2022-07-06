package StandupGenerator::Creator;

use base 'Exporter';
use StandupGenerator::Accessor;
use StandupGenerator::Helper;

our @EXPORT = qw( 
    create_new
);

# Create a new standup file containing contents from the previous day's standup, then open the file for further editing
sub create_new {
    my ($path) = @_;
    my $last_file = StandupGenerator::Helper::find_last_file($path);
    my $last_file_path = "${path}/${last_file}";
    my %last_file_identifiers = StandupGenerator::Helper::extract_identifiers($last_file);
    my $last_file_sprint = $last_file_identifiers{'sprint'};
    my $last_file_day = $last_file_identifiers{'day'};
    my $next_file_sprint;
    my $next_file_day;

    if ($last_file_day == '0') {
        # Yesterday's standup was for day 10 of the last sprint, so today's standup will be for day 1 of the new sprint
        $next_file_day = '01';
        $next_file_sprint = $last_file_sprint + 1;
    } else {
        # Continue incrementing days within the current sprint
        $next_day = $last_file_day + 1;
        $next_file_day = "0${next_day}";
        $next_file_sprint = $last_file_sprint;

        if ($next_file_day == '010') {
            $next_file_day = '10';
        }
    }

    my $next_file = "s${next_file_sprint}d${next_file_day}.txt";
    my $next_file_path = "${path}/${next_file}";

    # Store key data from yesterday's standup
    open my $fh, '<', $last_file_path;
    my $last_file_content = do { local $/; <$fh> };
    close($fh);
    my $file_length = length($last_file_content);
    my $today_index = index($last_file_content, 'TODAY') + 6;
    my $blockers_index = index($last_file_content, 'BLOCKERS') + 9;
    my $today_content;
    my $blockers_content;

    if ($last_file eq "s0d0.txt") {
        # When creating first standup within a directory, give sections empty bullets
        $today_content = "- ";
        $blockers_content = "- ";
    } else {
        # Store yesterday's TODAY and BLOCKERS sections in order to repurpose them for today's standup
        $today_content = substr($last_file_content, $today_index, $blockers_index - $today_index - 11);
        $blockers_content = substr($last_file_content, $blockers_index, $file_length - $blockers_index);
    }

    # Connect gathered pieces to form a single string with all necessary contents
    my $next_file_content = "STANDUP: SPRINT ${next_file_sprint} - DAY ${next_file_day}\n\nYESTERDAY\n${today_content}\n\nTODAY\n${today_content}\n\nBLOCKERS\n${blockers_content}";

    # Create new file
    open my $new_fh, '>', $next_file_path;
    print $new_fh $next_file_content;
    close($new_fh);

    # Open new file
    StandupGenerator::Accessor::open_one($path, $next_file_sprint, $next_file_day);

    return $next_file;
}

1;

__END__

=pod

=head1 NAME

StandupGenerator::Creator - creates a new standup file for user

=head1 DESCRIPTION

The Creator module contains the key method for the entire package, which allows the user to create a new standup file. The new file will appropriately increment based on the existing files within the directory, and it will be created containing data pulled from the previous day's contents, thus giving the user a decent starting place for that day's standup memo.

=head1 METHODS

=head2 C<create_new>

This method lets the user create a new standup file for a given directory. The method will return the name of the newly created file. It will also open the file in the user's default editor (e.g., TextEdit). It only takes one parameter:

=over

=item *

C<$path> -- A string containing the full file path for the directory containing standup files for the current project. It should begin with I</Users/>.

=back

Assuming the I<standups> directory contains standup files and that yesterday's standup file was I<s3d07.txt>, then the below command will create the file I<s3d08.txt> within the same directory and immediately open it. The new file's I<YESTERDAY> section will contain the old file's I<TODAY> section (since yesterday's goals for the day were presumanbly accomplished). The new file's I<TODAY> section will also contain the old file's I<TODAY> (since some of yesterday's goals might not have been accomplished and instead have rolled over into today). The new file's I<BLOCKERS> section will contain the old file's I<BLOCKERS> section (since some of yesterday's blockers may not have been overcome).

    use StandupGenerator::Creator;
    StandupGenerator::Creator::create_new('/Users/johndoe/projects/super-important-project/standups');

=cut
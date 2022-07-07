package StandupGenerator;

use base 'Exporter';
use StandupGenerator::Creator;
use StandupGenerator::Accessor;
use StandupGenerator::Manipulator;

our $VERSION = '0.5';
our @EXPORT = qw( 
    create_standup 
    open_standup 
    view_standups_from_week
    set_aliases
);

# Creates a new standup file when given a directory, with identifiers that increment off of the directory's last file and contents pulled from yesterday's standup file 
sub create_standup {
    my ($path) = @_;
    StandupGenerator::Creator::create_new($path);
}

# Opens an existing standup file when given a directory, a sprint number, and a two-digit string for the day
sub open_standup {
    my ($path, $sprint, $day) = @_;
    StandupGenerator::Accessor::open_one($path, $sprint, $day);
}

# Opens all standup files in a directory from the past week, along with the coming Monday's standup file, if they exist
sub view_standups_from_week {
    my ($path) = @_;
    StandupGenerator::Accessor::open_many($path);
}

# Append some functions to the user's configuration file to make it easier for the user to execute key methods from this package via the CLI, with all functions automatically referencing the correct directory
sub set_aliases {
    my ($path) = @_;
    StandupGenerator::Manipulator::save_script_shortcuts($path);
}

1;

__END__

=pod

=head1 NAME

StandupGenerator - package giving the user a simple way to create and open standup files

=head1 DESCRIPTION

The main module surfaces methods from other modules and repackages them with descriptive names. Instead of forcing a user to implement a nested namespace, the key methods from the package are thus easily accessible at the root.

=head1 METHODS

=head2 C<create_standup>

This method lets the user create a new standup file for a given directory. The method will return the name of the newly created file. It will also open the file in the user's default editor (e.g., TextEdit). It only takes one parameter:

=over

=item *

C<$path> -- A string containing the full file path for the directory containing standup files for the current project. It should begin with I</Users/>.

=back

Assuming your I<standups> directory contains standup files and that yesterday's standup file was I<s3d07.txt>, then executing the below command from the CLI will create the file I<s3d08.txt> within the same directory and immediately open it.

    perl -e 'use StandupGenerator; create_standup("/Users/johndoe/projects/super-important-project/standups")'

=head2 C<open_standup>

This method lets the user open a single standup file stored in a specific directory. If the I<.txt> file exists, then the method will open it in the user's default editor (e.g., TextEdit). It takes three parameters:

=over

=item *

C<$path> -- A string containing the full file path for the directory containing the standup file. It should begin with I</Users/>.

=item *

C<$sprint> -- A number representing the sprint of the standup.

=item *

C<$day> -- A string containing a two-digit representation of the day of the standup. Single digit numbers will begin with I<'0'>.

=back

Executing the below command from the CLI will open the file I<s3d07.txt>, stored within the I<standups> directory within the I<super-important-project> directory.

    perl -e 'use StandupGenerator; open_standup("/Users/johndoe/projects/super-important-project/standups", 3, 07)'

=head2 C<view_standups_from_week>

This method lets the user open a collection of standup files stored in a specific directory. The intent is to open all standups for the past week. It assumes the last standup in the given directory is either a Friday or Monday, and it opens six files as a result (Monday's through Friday's along with the following Monday's). If the path leads to a directory that contains I<.txt> files formatted with the standups naming convention, then the method will open six of those files in the user's default editor (e.g., TextEdit). It only takes one parameter:

=over

=item *

C<$path> -- A string containing the full file path for the directory containing the standup files. It should begin with I</Users/>.

=back

Executing the below command from the CLI will open six files stored within the I<standups> directory within the I<super-important-project> directory.

    perl -e 'use StandupGenerator; view_standups_from_week("/Users/johndoe/projects/super-important-project/standups")'

=head2 C<set_aliases>

This method lets the user easily execute commands from this package via the CLI by editing their configuration file to contain certain shortcuts to key methods. It only takes one parameter:

=over

=item *

C<$path> -- A string containing the full file path for the directory to store standup files. It should begin with I</Users/>. It should only ever contain I<.txt> files in the standup format.

=back

Executing the below command in the CLI will add C<osu>, C<csu>, and C<wsu> shortcuts to the user's configurations. As a result, executing any of those will interact with standup files stored in the I<standups> folder within the larger I<super-important_project> folder.

    perl -e 'use StandupGenerator; set_aliases("/Users/johndoe/projects/super-important-project/standups")'

=cut
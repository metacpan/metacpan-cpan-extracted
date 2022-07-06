package StandupGenerator::Manipulator;

use base 'Exporter';

our @EXPORT = qw( 
    save_script_shortcuts
);

# Updates a user's local zsh or bash config file with functions allowing the user to implement methods from the package via the CLI using far less typing
sub save_script_shortcuts {
    my ($path) = @_;
    my @sections = split('/', $path);
    my $user = $sections[2];
    my $base = "/Users/${user}";
    my $config;
    my $zsh = "${base}/.zshrc";
    my $bash = "${base}/.bashrc";

    if (-e $zsh) {
        # Plan to update user's zsh file if it exists
        $config = $zsh;
    } else {
        # Plan to update user's bash file if user does not use zsh
        $config = $bash;
    }

    open my $fh, '<', $config;
    my $config_content = do { local $/; <$fh> };
    close($fh);

    # Create three functions for creating and opening standup files, then bundle them together into a single string for group insertion
    my $osu = "# Executes open_standup function from standup-generator Perl module\n# Takes three arguments: path to directory housing standups, sprint number, and string of day beginning with 0 (e.g., '04', not 4)\nfunction osu() {\n\tsprint=\$1\n\tday=\$2\n\texport sprint\n\texport day\n\tperl -e 'use StandupGenerator; open_standup(\"${path}\", \$ENV{sprint}, \$ENV{day})'\n}";
    my $csu = "# Executes create_standup function from standup-generator Perl module; it takes no arguments\nfunction csu() {\n\tperl -e 'use StandupGenerator; create_standup(\"${path}\")'\n}";
    my $wsu = "# Executes view_standups_from_week function from standup-generator Perl module; it takes no arguments\nfunction wsu() {\n\tperl -e 'use StandupGenerator; view_standups_from_week(\"${path}\")'\n}";
    my $updated_content = "${config_content}\n\n${osu}\n\n${csu}\n\n${wsu}";

    # Append new shortcuts to the end of existing config file
    open my $new_fh, '>', $config;
    print $new_fh $updated_content;
    close($new_fh);
}

1;

__END__

=pod

=head1 NAME

StandupGenerator::Manipulator - allows user to easily save shortcuts for this package in their configurations

=head1 DESCRIPTION

The Manipulator module contains an auxillary method to make it easy for the user to set up short aliases for the main methods from this package.

=head1 METHODS

=head2 C<save_script_shortcuts>

This method lets the user easily execute commands from this package via the CLI by editing their configuration file to contain certain shortcuts to key methods. It only takes one parameter:

=over

=item *

C<$path> -- A string containing the full file path for the directory to store standup files. It should begin with I</Users/>. It should only ever contain I<.txt> files in the standup format.

=back

Executing the below command in the CLI will add C<osu>, C<csu>, and C<wsu> shortcuts to the user's configurations. As a result, executing any of those will interact with standup files stored in the I<standups> folder within the larger I<super-important_project> folder.

    perl -e 'use StandupGenerator::Manipulator; save_script_shortcuts("/Users/johndoe/projects/super-important-project/standups")'

=cut
package Nuvol::Test;
use Mojo::Base -base, -signatures;

1;

=encoding utf8

=head1 NAME

Nuvol::Test - Test functions

=head1 DESCRIPTION

L<Nuvol::Test> provides functions to simplify module tests. They are split between standard and live
tests.

Live tests will create and remove files with names starting with C<Nuvol Testfile>, a C<Nuvol
Testfolder> and in the latter an unspecified number of files and subfolders. They may delete existing
files with similar names.

Don't run these tests if you don't understand what they are doing.

The tests are skipped if the environment variables for the different services are not set or don't
point to an existing file. The variable names are C<NUVOL_DUMMY_LIVE>, C<NUVOL_OFFICE365_LIVE>.

To create new config files, call L<Nuvol::Connector/new> and L<Nuvol::Connector/authenticate> from
the command line.

    $ export NUVOL_OFFICE365_LIVE=/path/to/config
    $ perl -MNuvol::Connector -E"Nuvol::Connector->new('$NUVOL_OFFICE365_LIVE', 'Office365')->authenticate"

This sets the environment variable for live tests on Office 365 and starts an interactive
authentication that creates the Office 365 config file. Remember that this file contains highly
sensitive information.

=head1 SEE ALSO

L<Nuvol>, L<Nuvol::Test::Connector>, L<Nuvol::Test::ConnectorLive>, L<Nuvol::Test::Drive>,
L<Nuvol::Test::DriveLive>, L<Nuvol::Test::File>, L<Nuvol::Test::FileLive>, L<Nuvol::Test::Folder>,
L<Nuvol::Test::FolderLive>, L<Nuvol::Test::Item>, L<Nuvol::Test::ItemLive>, L<Nuvol::Test::Roles>.

=cut

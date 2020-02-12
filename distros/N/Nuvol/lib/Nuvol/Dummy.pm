package Nuvol::Dummy;
use Mojo::Base -base, -signatures;

1;

=encoding utf8

=head1 NAME

Nuvol::Dummy - Dummy service

=head1 SYNOPSIS

    use Nuvol::Connector;
    my $connector = Nuvol::Connector->new($configfile, 'Dummy');

=head1 DESCRIPTION

L<Nuvol::Dummy> provides modules with internal methods to access a dummy service. It is based on the
local file system and can be used for tests and experiments.

The config file should be located in a separate folder with the following structure:

    dummy folder
    ├── drives
    │   ├── Home       # the main drive
    │   └── Drive 2    # optional second drive
    └── dummy.conf     # config file

It is possible to use it with a temporary folder.

    use Mojo::File;
    use Nuvol::Connector;

    my $tempfolder = Mojo::File::tempdir;
    Mojo::File->new("$tempfolder/drives/Home/")->make_path;

    my $connector = Nuvol::Connector->new("$tempfolder/dummy.conf", 'Dummy');

This will create a connector that has access to a main drive in a temporary folder.

=head1 SEE ALSO

L<Nuvol>, L<Nuvol::Dummy::Connector>, L<Nuvol::Dummy::Drive>, L<Nuvol::Dummy::File>,
L<Nuvol::Dummy::Folder>, L<Nuvol::Dummy::Item>.

=cut

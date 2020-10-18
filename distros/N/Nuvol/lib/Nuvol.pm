package Nuvol;
use Mojo::Base -strict, -signatures;

our $VERSION = '0.03';

# functions

sub autoconnect ($configfile, $service) {
  require Nuvol::Connector;

  if (-f $configfile) {
    return Nuvol::Connector->new($configfile);
  } else {
    return Nuvol::Connector->new($configfile, $service)->authenticate;
  }
}

sub connect ($configfile) {
  require Nuvol::Connector;
  return Nuvol::Connector->new($configfile);
}

1;

=encoding utf8

=head1 NAME

Nuvol - A cloud toolkit

=head1 SYNOPSIS

    use Nuvol;

    # connect to a service
    my $configfile = '/path/to/configfile';
    my $service    = '...';  # one of Dropbox, Office365
    my $connector  = Nuvol::autoconnect($configfile, $service);

    # get main drive
    my $drive = $connector->drive('~');

    # upload a file
    use Mojo::File 'path';
    my $file = $drive->item('/My Text.txt')->copy_from(path 'Text on my PC.txt');

    # copy to another file
    my $file_2 = $file->copy_to('/path/to/Text Copy.txt');

    # download
    my $downloaded = $file_2->copy_to(path 'Downloaded Text.txt');

    # change the text
    $file_2->spurt('This text was changed.');

    # read it
    my $content = $file_2->slurp;

    # and delete the file
    $file_2->remove;

=head1 DESCRIPTION

L<Nuvol> is a toolkit to manipulate files and folders on cloud services. For
the beginning it supports L<Dropbox|Nuvol::Dropbox>, L<Office
365|Nuvol::Office365>, and a L<Dummy service|Nuvol::Dummy>.

    Nuvol
    └── Connector
        ├── Config
        │   └── config file
        └── Drive
            └── Item
                ├── File
                └── Folder

The services are organized in connectors, drives, items, files, and folders. The data needed to
access a service is stored in a config file.

=over 4

=item Connector

The L<Connector|Nuvol::Connector> is responsible for authentication and for the connection to the
cloud service.

=item Config and config file

The config file stores the tokens and other parameters used to establish a connection. Internally is
is represented by a L<Config|Nuvol::Config> object.

B<Warning:> The information in the config file allows full access to your cloud data for anyone who
can read it. It should be stored at a secure place. Services that are no longer used should be
disabled with L<Nuvol::Connector/disconnect>.

=item Drive

A L<Drive|Nuvol::Drive> is an isolated area where your data is stored. You may have a drive for your
personal and another for your business data. Not all cloud providers support different drives.

=item Item

Every object in a drive is an L<Item|Nuvol::Item>. Item is just an abstract type, a real object is
either a L<File|Nuvol::Role::File> or a L<Folder|Nuvol::Role::Folder>.

The syntax for drive items is oriented at L<Mojo::File>, so anyone familiar with this module will
recognize most of the methods.

=back

=head1 FUNCTIONS

None of the functions is exported.

=head2 autoconnect

    use Nuvol;
    $connector = Nuvol::autoconnect($configfile, $service);

Opens a connection using an existing config file, or starts an interactive
authentication process if the file doesn't exist. Returns a
L<Nuvol::Connector>.

=head2 connect

    use Nuvol;
    $connector = Nuvol::connect($configfile);

Opens a connection using an existing config file. Returns a L<Nuvol::Connector>.

=head1 AUTHOR & COPYRIGHT

© 2013–2020 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Drive>, L<Nuvol::Item>, L<Nuvol::Test>.

=cut

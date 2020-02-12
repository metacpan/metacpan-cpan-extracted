package Nuvol;
use Mojo::Base -strict, -signatures;

our $VERSION = '0.01';

# functions

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
    my $connector  = Nuvol::connect($configfile);

    # get main drive
    my $drive = $connector->drive('~');

    # upload a file
    use Mojo::File 'path';
    my $file = $drive->item('My Text.txt')->copy_from(path 'Text on my PC.txt');

    # copy to another file
    my $file_2 = $file->copy_to('path/to/Text Copy.txt');

    # download
    my $downloaded = $file_2->copy_to(path 'Downloaded Text.txt');

=head1 DESCRIPTION

L<Nuvol> is a toolkit to work with cloud resources. For the beginning it supports L<Office
365|Nuvol::Office365> and a L<Dummy service|Nuvol::Dummy> as cloud services and concentrates on files
and folders.

=head1 FUNCTIONS

None of the functions is exported by default.

=head2 connect

    use Nuvol;
    $connector = Nuvol::connect($configfile);

Opens a connection with an existing config file. Returns a L<Nuvol::Connector>.

=head1 AUTHOR & COPYRIGHT

© 2013–2020 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Drive>, L<Nuvol::Item>, L<Nuvol::Test>.

=cut

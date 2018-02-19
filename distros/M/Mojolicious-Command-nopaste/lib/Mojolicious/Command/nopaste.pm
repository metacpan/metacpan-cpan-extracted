package Mojolicious::Command::nopaste;
use Mojo::Base 'Mojolicious::Commands';
use Mojolicious::Command::nopaste::Service;

our $VERSION = '0.12';
$VERSION = eval $VERSION;

has description => "Paste to your favorite pastebin sites.\n";

has message => sub {
  return shift->description . <<EOF;

These services are currently available:
EOF
};

has hint => "\n" . $Mojolicious::Command::nopaste::Service::USAGE . <<EOF;

See '$0 nopaste help SERVICE' for more information on a specific service implementation.
EOF

has namespaces => sub { ['Mojolicious::Command::nopaste::Service'] };

sub help { shift->run(@_) }

1;

=head1 NAME

Mojolicious::Command::nopaste - A clone of App::Nopaste using Mojolicious

=head1 SYNOPSIS

 $ mojo nopaste pastie myfile.pl
 $ cat myfile.pl | mojo nopaste shadowcat
 $ mojo nopaste -p  # contents pulled from clipboard

=head1 DESCRIPTION

This module is a clone of the venerable L<App::Nopaste> using the L<Mojolicious> toolkit.
Nearly all of the functionality is mimicked.
Where possible the command-line system has been replicated, though the mechanism of
choosing the service differs due to the way the L<Mojolicious::Commands> system works.

Files may be passed as arguments, read from STDIN or even read from the clipboard with the
L<Clipboard> module.
For a list of available services run C<mojo help nopaste> or C<mojo nopaste help [SERVICE]>.

=head1 SEE ALSO

=over

=item L<App::Nopaste>

=item L<Mojolicious>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Command-nopaste>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

package Suffit;
use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Suffit - Suffit Library Bundle

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    package MyApp;
    our $VERSION = '0.01';
    use parent 'Suffit';
    sub init { shift->routes->any('/' => {text => 'Hello World!'}) }
    1;

    package main;
    use Mojo::Server;
    Mojo::Server->new->build_app('MyApp', datadir => '/tmp')->start();

    # Now try to run it:
    # perl myapp.pl daemon -l http://*:8080

=head1 DESCRIPTION

Suffit Library Bundle combines multiple complementary libraries into a single
cohesive package, enabling modular, scalable, and efficient development

=head1 EXAMPLE

See F<eg/myapp.pl> file

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acrux>, L<WWW::Suffit>, L<Mojolicious>, L<WWW::Suffit::Server>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

our $VERSION = '1.01';

use parent qw/WWW::Suffit::Server/;

1;

__END__

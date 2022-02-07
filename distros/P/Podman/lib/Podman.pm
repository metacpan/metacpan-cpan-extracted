package Podman;

use strict;
use warnings;
use utf8;

our $VERSION = '20220203.0';

1;

=encoding utf8

=head1 NAME

Podman - Library of bindings to use the RESTful API of L<https://podman.io>.

=head1 SYNOPSIS

    use Podman::Client;
    use Podman::Images;
    use Podman::System;

    my $Client = Podman::Client->new( ConnectionURI => 'http+unix:///run/user/1000/podman/podman.sock' );

    my $System = Podman::System->new( Client => $Client );
    my $Version = $System->Version();
    printf "Release: %s\n", $Version->{'Version'};
    printf "API: %s\n",     $Version->{'APIVersion'};

    for my $Image (@{Podman::Images->List()}) {
        printf "%s\n", $Image->Name;
    }

=head1 DESCRIPTION

L<Podman> is a library of bindings to use the RESTful API of L<Podman>. It is
currently under development and contributors are welcome!

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://github.com/tschaefer/podman-perl>, L<https://docs.podman.io/en/latest/_static/api.html>

=cut

package Mojolicious::Plugin::Prometheus::Shared::FastMmap;
use Mojo::Base 'Mojolicious::Plugin::Prometheus';
use Role::Tiny::With;

our $VERSION = '2.0.0';

with 'Mojolicious::Plugin::Prometheus::Role::SharedFastMmap';
1;
__END__

=for stopwords mmapped

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Prometheus::Shared::FastMmap - Mojolicious Plugin (DEPRECATED)

=head1 DESCRIPTION

This module was made to support preforking servers, but this is not natively in L<Mojolicious::Plugin::Prometheus> and this module has some limitations you are bound to hit.

=head1 AUTHOR

Vidar Tyldum

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Vidar Tyldum

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

=over 2

=item L<Mojolicious::Plugin::Prometheus>

=back

=cut

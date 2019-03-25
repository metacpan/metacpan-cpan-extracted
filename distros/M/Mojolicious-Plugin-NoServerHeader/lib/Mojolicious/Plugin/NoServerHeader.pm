package Mojolicious::Plugin::NoServerHeader;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

sub register {
    $_[1]->hook(after_dispatch => sub {
        $_[0]->res->headers->remove('Server');
    });
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::NoServerHeader - Removes the Server header from every Mojolicious response

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-NoServerHeader"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-NoServerHeader.svg?branch=master"></a>

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'NoServerHeader';

  # Mojolicious
  $app->plugin('NoServerHeader');


=head1 DESCRIPTION

L<Mojolicious::Plugin::NoServerHeader> removes the default Server header, "Mojolicious (Perl)", from every response.
This can be useful for security reasons if there was ever a known exploit for L<Mojolicious>. If you are really concerned about
this, you should also change the default error pages like the L<failraptor|https://mojolicious.org/mojo/failraptor.png>, although
those are probably less obvious than a Server header in every response.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl it.

=head1 SEE ALSO

=cut

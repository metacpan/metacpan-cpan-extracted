package Plack::App::Proxy::Anonymous;

=head1 NAME

Plack::App::Proxy::Anonymous - anonymous proxy requests

=head1 SYNOPSIS

=for markdown ```perl

    # In app.psgi
    use Plack::Builder;
    use Plack::App::Proxy::Anonymous;

    builder {
        enable "Proxy::Requests";
        Plack::App::Proxy::Anonymous->new->to_app;
    };

=for markdown ```

=head1 DESCRIPTION

This module extends L<Plack::App::Proxy>. It doesn't add own headers which
could trace an origin of the request.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0100';

use parent qw(Plack::App::Proxy);

sub build_headers_from_env {
    my ($self, $env, $req) = @_;
    my $headers = $req->headers->clone;
    return +{%$headers};
}

1;

__END__

=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::App::Proxy>, L<Plack::Middleware::Proxy::Connect>.

=head1 BUGS

This module might be incompatible with further versions of
L<Plack::App::Proxy> module.

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Plack-App-Proxy-Anonymous/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Plack-App-Proxy-Anonymous>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2013, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

use strict;
use warnings;
package Plack::Middleware::NoDeflate;
BEGIN {
  $Plack::Middleware::NoDeflate::VERSION = '0.01';
}

use parent qw(Plack::Middleware);

sub call {
    my($self, $env) = @_;
    $env->{HTTP_ACCEPT_ENCODING} = '';
    $self->app->($env);
};

1;

# ABSTRACT: Prevent content from being deflated


__END__
=pod

=head1 NAME

Plack::Middleware::NoDeflate - Prevent content from being deflated

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    enable 'NoDeflate';

=head1 DESCRIPTION

Plack::Middleware::NoDeflate is middleware which prevents content from being
deflated before being served. It sets HTTP_ACCEPT_ENCODING to a blank value,
which means that HTML and text will not be deflated by servers and
applications which respect this environment variable.

=head1 MOTIVATION

L<Plack::Middleware::Debug> does not work with deflated content. In many
cases, you'll be able to fix this by disabling any deflation in the
development process, but that's not always the case. Further, if you're trying
to mangle the response body of a proxied URL with your own middleware, you'll
find yourself with the same problem.

One way to deal with this would be to re-inflate the deflated content
yourself. Another, simpler way, is simply to prevent the content from being
deflated in the first place, which is what this module does.

=head1 SEE ALSO

L<Plack::Middleware::Deflater>

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


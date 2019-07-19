package Plack::Middleware::RemoveRedundantBody;
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util;

our $VERSION = "0.09";

# ABSTRACT: Plack::Middleware which removes body for HTTP response if it's not required

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);

    return $self->response_cb($res, sub {
        my $response = shift;
        return unless @$response == 3;
        return if ( !Plack::Util::status_with_no_entity_body($response->[0]) );
        $response->[2] = [];
        Plack::Util::header_remove($response->[1], "Content-Length");
        return;
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::RemoveRedundantBody - Plack::Middleware which removes body for HTTP response if it's not required

=head1 VERSION

version 0.09

=head1 SYNOPSIS

   use strict;
   use warnings;

   use Plack::Builder;

   my $app = sub { ...  };

   builder {
       enable "RemoveRedundantBody";
       $app;
   };

=head1 DESCRIPTION

This module removes body in HTTP response, if it's not required.

=head1 CONTRIBUTORS

John Napiorkowski <jjn1056@yahoo.com>

Karen Etheridge <ether@cpan.org>

Aristotle Pagaltzis <pagaltzis@gmx.de>

Tomohiro Hosaka <hello@bokut.in>

Robert Rothenberg <rrwo@cpan.org>

=head1 AUTHOR

Upasana <me@upasana.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Upasana.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

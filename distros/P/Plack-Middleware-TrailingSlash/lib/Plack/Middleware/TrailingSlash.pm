package Plack::Middleware::TrailingSlash;

use Moose;
BEGIN {
    $Plack::Middleware::TrailingSlash::AUTHORITY = 'cpan:okko';
}
BEGIN {
    $Plack::Middleware::TrailingSlash::VERSION = '0.001';
}
use namespace::autoclean;
use Plack::Request;
use HTML::Entities;

extends 'Plack::Middleware';

# use Plack::Util::Accessor qw( ignore );
has 'ignore' => (is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    my $p = $req->path_info();

    # Ignore if not GET
    if ($req->method() ne 'GET') {
        return $self->app->($env);
    }

    # Ignore if we are happy with the URL
    if ($p =~ /^.*\/$/                    # Slash at the end OR
        or $p =~ /^.*\/[^\/]+\.[^\/]+$/   # dot in the filename after the last /
        ) {
        return $self->app->($env);
    }

    # Ignore if path is in the ignores list
    if ( defined $self->ignore ) {
        unless ( ref($self->ignore) eq 'ARRAY' ) {
            $self->ignore( [ $self->ignore ] );
        }

        foreach my $ign ( @{$self->ignore} ) {
            if ($p =~ $ign) {
                return $self->app->($env);
            }
        }
    }

    # If we're here the pattern indicates it is a GET request to a directory path and should have a trailing slash.
    my $uri = $req->uri();
    if ($uri =~ /\?/) {
        # with a query string
        $uri =~ s/\?/\/?/;
    } else {
        # without a query string
        $uri .= '/';
    }

    my $res = $req->new_response(301); # new Plack::Response
    $res->headers([
        'Location' => $uri,
        'Content-Type' => 'text/html; charset=UTF-8',
        'Cache-Control' => 'must-revalidate, max-age=3600'
    ]);

    my $uhe = encode_entities($uri);
    $res->body(
        '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN"><html><head><title>301 Moved Permanently</title></head>'
        .'<body><h1>Moved Permanently</h1><p>The document has moved <a href="'.$uhe.'">here</a>.</p></body></html>'
    );

    return $res->finalize;
};

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::TrailingSlash - Append a trailing slash to GET requests whenever it is missing

=head1 SYNOPSIS

  builder {
    enable 'TrailingSlash';
  };

=head1 DESCRIPTION

Redirect to a path containing the trailing slash if the path looks like a directory

The Catalyst Perl MVC framework matches the requested URL to an action
both with and without the trailing slash. For example both /company/contact and
/company/contact/ go to the same action and same template.

This module redirects the requests without the trailing slash (ie. /company/contact)
to the same URL with the trailing slash added (ie. /company/contact/).

Redirects are done permanently to avoid duplicate content in search indexes, but is
given a max age of 3600 to prevent browsers from caching the redirect indefinitely.

=head1 PARAMETERS

=over 1

=item ignore

A string or an array reference with a list of paths to ignore the trailingslash
handling.

  builder {
    enable 'TrailingSlash', ignore => [qr/^\/foobar\//];
  };

  builder {
    enable 'TrailingSlash', ignore => [ qr/^\/foobar\//, qr/^\/lolcat\// ];
  };

=back

=head1 SEE ALSO

L<Plack::Middleware>
L<Plack::Middleware::TrailingSlashKiller>

=head1 AUTHORS

Oskari Ojala E<lt>oskari.ojala@frantic.comE<gt>
Josep Roca

=head1 COPYRIGHT

Copyright 2013-2015 - Oskari Ojala

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

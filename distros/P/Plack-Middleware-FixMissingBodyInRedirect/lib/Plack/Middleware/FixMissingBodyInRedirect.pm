package Plack::Middleware::FixMissingBodyInRedirect;
use strict;
use warnings;
use parent qw( Plack::Middleware );

use Plack::Util;
use HTML::Entities;
use Scalar::Util qw(blessed);
# ABSTRACT: Plack::Middleware which sets body for redirect response, if it's not already set

our $VERSION = '0.12';

sub call {
    my $self = shift;

    return $self->response_cb($self->app->(@_), sub {
        my $res = shift;
        return unless $res->[0] >= 300 && $res->[0] < 400;
        my $headers = Plack::Util::headers($res->[1]); # first index contains HTTP header
        if( $headers->exists('Location') ) {
            my $location = $headers->get("Location");
            # checking if body (which is at index 2) is set or not
            if (@$res == 3 && !_is_body_set($res->[2])) {
                my $body = $self->_default_html_body($location);
                $res->[2] = [$body];
                my $content_length = Plack::Util::content_length([$body]);
                $headers->set('Content-Length' => $content_length);
                $headers->set('Content-Type' => 'text/html; charset=utf-8');
                return;
            }
            elsif (@$res == 2 || blessed($res->[2])) {
                if(! $headers->exists('Content-Type')) {
                    $headers->set('Content-Type' => 'text/html; charset=utf-8')
                }
                my $done;
                return sub {
                    my $chunk = shift;
                    return $chunk if $done;
                    if (!defined $chunk) {
                        $done = 1;
                        return $self->_default_html_body($location);
                    }
                    elsif (length $chunk) {
                        $done = 1;
                    }
                    return $chunk;
                };
            }
        }
    });
}

sub _default_html_body {
  my ($self_or_class, $location) = @_;
  my $encoded_location = encode_entities($location);
  return <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <title>Moved</title>
    </head>
    <body>
   <p>This item has moved <a href="$encoded_location">here</a>.</p>
</body>
</html>
EOF
}

sub _is_body_set {
    my $body = shift;
    if (ref $body eq 'ARRAY') {
        return grep { defined && length } @$body;
    }
    elsif (Plack::Util::is_real_fh($body) && -f $body && -z _) {
        return 0;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::FixMissingBodyInRedirect - Plack::Middleware which sets body for redirect response, if it's not already set

=head1 VERSION

version 0.12

=head1 SYNOPSIS

   use strict;
   use warnings;

   use Plack::Builder;

   my $app = sub { ...  };

   builder {
       enable "FixMissingBodyInRedirect";
       $app;
   };

=head1 DESCRIPTION

This module sets body in redirect response, if it's not already set.

=head1 CONTRIBUTORS

John Napiorkowski <jjn1056@yahoo.com>

Graham Knop <haarg@haarg.org>

n0body, Mark Ellis <m@rkellis.com>

ether, Karen Etheridge <ether@cpan.org>

=head1 AUTHOR

Upasana <me@upasana.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Upasana.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

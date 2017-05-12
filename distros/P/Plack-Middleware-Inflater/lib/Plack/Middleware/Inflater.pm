package Plack::Middleware::Inflater;
$Plack::Middleware::Inflater::VERSION = '0.001';
# ABSTRACT: Inflate gzipped PSGI requests

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use base 'Plack::Middleware';
use Plack::Util;
use Plack::Util::Accessor qw/content_encoding/;
use IO::Uncompress::Gunzip qw/gunzip/;
use IO::Scalar;

sub prepare_app {
    my $self = shift;
    unless ($self->content_encoding) {
        $self->content_encoding([qw/gzip/]);
    }
}

sub modify_request_maybe {
    my ($self, $env) = @_;

    return if $env->{'plack.skip-inflater'};

    my $content_encoding = $env->{HTTP_CONTENT_ENCODING} or return;

    # this thing stolen from Plack::Middleware::Deflater
    $content_encoding =~ s/(;.*)$//;
    if (my $match_cts = $self->content_encoding) {
        my $match=0;
        for my $match_ct ( @{$match_cts} ) {
            if ($content_encoding eq $match_ct) {
                $match++;
                last;
            }
        }
        return unless $match;
    }

    # if we're here it's one of the values of Content-Type that we
    # want to inflate as gzip

    if ($env->{'psgi.input'}) {
        my $inflated = '';
        gunzip $env->{'psgi.input'}, \$inflated;
        $env->{'psgi.input'} = IO::Scalar->new(\$inflated);
        my $content_length = do {
            use bytes;
            length $inflated };
        $env->{CONTENT_LENGTH} = $content_length;
    }
}

sub call {
    my ($self, $env) = @_;
    $self->modify_request_maybe($env);
    return $self->app->($env);
}

1;


=pod

=head1 NAME

Plack::Middleware::Inflater - Inflate gzipped PSGI requests

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Plack::Builder;
  builder {
      enable 'Inflater', content_encoding => [qw/gzip deflate/];
      sub {
          my $request = Plack::Request->new(shift);
          my $response = $request->new_response(
              200,
              ['X-Request-Content-Length', $request->header('Content-Length'),
               'X-Request-Content', $request->content],
              'OK');
          return $response->finalize;
      };
  };

=head1 DESCRIPTION

This PSGI middleware inflates incoming gzipped requests before they
hit your PSGI app.  This only happens whenever the request's
C<Content-Encoding> header is one of the values specified in the
C<content_encoding> attribute, which defaults to C<['gzip']>.

This lets you send compressed requests, like this:

  curl --header 'Content-Encoding: gzip' --data-binary @foobar.gz http://...

=head1 SEE ALSO

L<Plack>

=head1 AUTHOR

Fabrice Gabolde <fgabolde@weborama.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

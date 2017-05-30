package Plack::Middleware::Signposting::JSON;

use strict;
use warnings;

use parent 'Plack::Middleware';
use JSON qw(decode_json);
use Plack::Request;
use Plack::Util::Accessor qw(fix);
use Catmandu;
use Catmandu::Fix;

our $VERSION = '0.02';

sub call {
    my ($self, $env) = @_;

    my $request = Plack::Request->new($env);
    my $res = $self->app->($env);

    # only get/head requests
    return $res unless $request->method =~ m{^get|head$}i;

    # see http://search.cpan.org/~miyagawa/Plack-1.0044/lib/Plack/Middleware.pm#RESPONSE_CALLBACK
    return $self->response_cb($res, sub {
        my $res = shift;

        my $content_type = Plack::Util::header_get($res->[1], 'Content-Type') || '';
        # only json responses
        return unless $content_type =~ m{^application/json}i;
        # ignore streaming response for now
        return unless ref $res->[2] eq 'ARRAY';

        my $body = join('', @{$res->[2]});
        my $data = decode_json($body);

        if (ref $data && ref $data eq 'ARRAY') {
            $data = $data->[0];
        }

        # harcoded fix file
        my $fix = $self->fix ? $self->fix : 'nothing()';
        my $fixer = Catmandu::Fix->new(fixes => [$fix]);
        $fixer->fix($data);

        # add information to the 'Link' header
        if ($data->{signs}) {
            Plack::Util::header_push(
                $res->[1],
                'Link' => $self->_to_link_format( @{$data->{signs}} )
            );
        }
    });
}

# produces the link format
sub _to_link_format {
    my ($self, @signs) = @_;

    my $body = join(", ", map {
        my ($uri, $relation, $type) = @$_;
        my $link_text = qq|<$uri>; rel="$relation"|;
        $link_text .= qq|; type="$type"| if $type;
        $link_text;
    } @signs);

    $body;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Signposting::JSON - A Signposting implementation from JSON content

=begin markdown

[![Build Status](https://travis-ci.org/LibreCat/Plack-Middleware-Signposting.svg?branch=master)](https://travis-ci.org/LibreCat/Plack-Middleware-Signposting)
[![Coverage Status](https://coveralls.io/repos/github/LibreCat/Plack-Middleware-Signposting/badge.svg?branch=master)](https://coveralls.io/github/LibreCat/Plack-Middleware-Signposting?branch=master)

=end markdown


=head1 SYNOPSIS

    builder {
       enable "Plack::Middleware::Signposting::JSON";

       sub {200, ['Content-Type' => 'text/plain'], ['hello world']};
    };

=head1 DESCRIPTION

Plack::Middleware::Signposting::JSON is a base class for Signposting(https://signposting.org) protocol.

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

Vitali Peil, C<< <vitali.peil at uni-bielefeld.de> >>

=head1 COPYRIGHT

Copyright 2017 - Vitali Peil

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

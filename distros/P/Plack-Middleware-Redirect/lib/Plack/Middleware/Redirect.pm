package Plack::Middleware::Redirect;
use 5.008001;
use strict;
use warnings;
use Carp qw/croak/;

use parent 'Plack::Middleware';

our $VERSION = "0.01";

use Plack::Util::Accessor qw/url_patterns/;

my $BODY = {
    301 => "Moved Permanently",
    302 => "Found"
};

sub prepare_app {
    my $self = shift;
    my $url_patterns = $self->url_patterns;

    for (my $i = 0; $i < scalar(@$url_patterns); $i += 2) {
        my ($from, $to) = _fetch_url_pattern($url_patterns, $i);
        
        my $type = ref $from;
        if ($type ne 'Regexp' && $type ne "") {
            croak "$from is invalid parameter";
        }
        if ($type ne 'Regexp') {
            $url_patterns->[$i] = qr/$from/;
        }
    }

}

sub call {
    my ($self, $env) = @_;

    my $url_patterns = $self->url_patterns;

    my $path = $env->{PATH_INFO};
    my $body = "";

    for ( my $i = 0; $i < scalar(@$url_patterns); $i += 2 ) {
        my ($from, $to) = _fetch_url_pattern($url_patterns, $i);

        next unless $path =~ m#$from#;
        
        my $type = ref $to;

        if ($type ne 'ARRAY') {
            my $to = [$to, 301];
        }

        my ($to_path, $status_code) = @$to;
        $type = ref $to_path;
        if ($type eq 'CODE') {
            $path = &$to_path($env, $from);
        }
        else {
            $path =~ s#$from#"\"$to_path\""#iee;
        }
        my $query = $env->{QUERY_STRING};
        if ($query) {
            $path .= $path =~ /\?/
                ? '&' . $query
                : '?' . $query;
        }
        my $body = $BODY->{$status_code} || "";
        return [$status_code, ['Location' => $path], [$body] ];
    }

    return $self->app->($env);
}


sub _fetch_url_pattern {
    my ($url_patterns, $i) = @_;
    return ($url_patterns->[$i], $url_patterns->[$i+1]);
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Redirect - A simple redirector

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Redirect', url_patterns => [
            '/from/oldpath' => '/to/newpath',
            '/from/oldpath' => ['/to/newpath', 301],
            '/from/oldpath' => [sub {
                my ($env, $regex) = @_;
                my $path  = $env->{PATH_INFO};
                $path =~ m|$regex|;
                $path = join ("_", split("", $1)) if $1;
                my $newpath = "/"
                }, 302],
            '/foo/(.+)' => '/another/$1'
        ];
    };

=head1 DESCRIPTION

A plack middleware that redirects.


=head1 REPOSITORY

Plack::Middleware::Redirect is hosted on github: L<https://github.com/okazu-dm/p5-plack-middleware-redirect/tree/master/lib/Plack/Middleware>


=head1 LICENSE

Copyright (C) okazu-dm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

okazu-dm E<lt>uhavetwocows@gmail.comE<gt>

=cut


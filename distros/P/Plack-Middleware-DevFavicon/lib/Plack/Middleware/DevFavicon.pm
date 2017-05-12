package Plack::Middleware::DevFavicon;
use 5.008_001;
use strict;
use warnings;

our $VERSION = "0.02";

use parent qw(Plack::Middleware);

use Plack::Util;
use Imager;

sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    if ($env->{PATH_INFO} =~ m{ /favicon\. (?:ico|png) $}xms) {
        return $self->dev_favicon($res);
    }

    return $res;
}

sub dev_favicon {
    my($self, $res) = @_;

    my $data = '';
    Plack::Util::foreach($res->[2], sub {
        my($buf) = @_;
        $data .= $buf;
    });

    my $type = Plack::Util::header_get($res->[1], 'content-type') =~ /png/ ? 'png' : 'ico';

    my $img = Imager->new(data => $data, type => $type) or die Imager->errstr;
    $img = $img->convert(preset => 'gray') or die Imager->errstr;

    my $out;
    $img->write(data => \$out, type => $type);

    return [$res->[0], $res->[1], [$out]];
}

1;
__END__

=encoding utf-8

=for stopwords env favicon

=head1 NAME

Plack::Middleware::DevFavicon - Shows gray favicon for development env

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $ENV{PLACK_ENV} eq 'development' } 'DevFavicon';
        ...;
    };

=head1 DESCRIPTION

Plack::Middleware::DevFavicon shows gray favicon for a specific environment
in order to distinguish the production environment.

=head1 LICENSE

Copyright (C) Fuji, Goro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fuji, Goro E<lt>gfuji@cpan.orgE<gt>

=cut


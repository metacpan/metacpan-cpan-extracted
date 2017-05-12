package Plack::Middleware::AddDefaultCharset;

use strict;
use warnings;
use 5.008_001;

use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(charset);

our $VERSION = '0.02';

sub call {
    my ($self, $env) = @_;
    $self->response_cb(
        $self->app->($env),
        sub {
            my $res = shift;
            my $headers = $res->[1];
            for (my $i = 0; $i < @$headers; $i += 2) {
                if (lc($headers->[$i]) eq 'content-type') {
                    my $cur_type = $headers->[$i + 1];
                    if ($cur_type =~ m{^text/(html|plain)}
                            && $cur_type !~ /;\s*charset=/) {
                        $headers->[$i + 1] =
                            "$cur_type; charset=" . $self->charset;
                    }
                    last;
                }
            }
        },
    );
}

1;
__END__

=head1 NAME

Plack::Middleware::AddDefaultCharset - a port of Apache2's AddDefaultCharset

=head1 SYNOPSIS

use Plack::Builder;

builder {
    enable 'AddDefaultCharset', charset => $charset_to_add;
    $app;
}

=head1 DESCRIPTION

Plack::Middleware::AddDefaultCharset is a port of the AddDefaultCharset configuration directive of the Apache HTTP server.

=head1 AUTHOR

Kazuho Oku E<lt>kazuhooku {at} gmail.comE<gt>

=head1 SEE ALSO

L<http://httpd.apache.org/docs/2.2/ja/mod/core.html#adddefaultcharset>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

package Plack::Middleware::Matomo;

our $VERSION = '0.01';

use strict;
use warnings;
use AnyEvent::HTTP;
use POSIX qw(strftime);
use Plack::Request;
use Plack::Util::Accessor
    qw(base_url id_site time_format oai_identifier_format view_paths download_paths);
use URI;

use parent 'Plack::Middleware';

sub call {
    my ($self, $env) = @_;

    my $request = Plack::Request->new($env);
    my $res     = $self->app->($env);

    # only get requests
    return $res unless $request->method =~ m{^get$}i;

    my ($action, $id);
    my $view_paths     = $self->view_paths;
    my $download_paths = $self->download_paths;

    foreach my $p (@$view_paths) {
        if ($request->path =~ /$p/) {
            $id     = $1;
            $action = "view";
            last;
        }
    }
    foreach my $p (@$download_paths) {
        if ($request->path =~ /$p/) {
            $id     = $1;
            $action = "download";
            last;
        }
    }

    return $res unless $action;

    my $time_format = $self->time_format // '%Y-%m-%dT%H:%M:%SZ';
    my $now         = strftime($time_format, gmtime(time));
    my $ip          = $self->_anonymize_ip($request->address);
    my $oai_id      = sprintf($self->oai_identifier_format, $id);
    my $cvar        = '{"1":["oaipmhID","' . $oai_id . '"]}';

    my $event = {
        rec       => 1,
        idSite    => $self->id_site,
        visitIP   => $ip,
        action    => $action,
        url       => $request->request_uri,
        timestamp => $now,
        agent     => $request->user_agent // '',
        referer   => $request->referer // '',
        cvar      => $cvar,
    };

    $self->_push_to_openaire($event);

    return $res;
}

sub _anonymize_ip {
    my ($self, $ip) = @_;

    $ip =~ s/\.\d+?$/\.0/;

    return $ip;
}

sub _push_to_openaire {
    my ($self, $event) = @_;

    my $uri = URI->new($self->base_url);
    $uri->query_form($event);

    http_head $uri->as_string, sub {return;};
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Matomo - a middleware to track usage information with Matomo

=head1 SYNOPSIS

    builder {
        enable "Plack::Middleware::Matomo",
            id_site => "my-service",
            base_url => "https://somewhere.eu/matomo",
            auth_token => "secr3t",
            view_paths => ['record/(\w+)/*'],
            download_paths => ['download/(\w+)/*'],
            oai_identifier_format => 'oai:test.server.org:%s',
            ;
        $app;
    }

=head1 CONFIGURATION

=over

=item id_site

Required. The ID of the repository.

=item base_url

Required. The URL of the Matomo endpoint.

=item auth_token

Required. The authorization token.

=item view_paths, download_paths

One of these is required. Provide an array ref of regexes to match.

=item oai_identifier_format

Required. The format of the OAI identifier format of the repository.

=back

=head1 DESCRIPTION

tbd.

=head1 AUTHOR

Vitali Peil E<lt>vitali.peil at uni-bielefeld.deE<gt>

=head1 COPYRIGHT

Copyright 2019- Vitali Peil

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Middleware>, L<Plack::Builder>

=cut

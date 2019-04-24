package Plack::Middleware::Matomo;

our $VERSION = '0.04';

use strict;
use warnings;
use AnyEvent::HTTP;
use Log::Any qw($log);
use Plack::Request;
use Plack::Util::Accessor
    qw(apiv base_url idsite token_auth time_format oai_identifier_format view_paths download_paths);
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

    $log->info("Entering Matomo middleware at " . $request->path);

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
    $log->info("Action: $action");

    my $time_format = $self->time_format // '%Y-%m-%dT%H:%M:%SZ';
    my $ip          = $self->_anonymize_ip($request->address);
    my $oai_id      = sprintf($self->oai_identifier_format, $id);
    my $cvar        = '{"1":["oaipmhID","' . $oai_id . '"]}';

    my $rand = int(rand(10000));

    my $event = {
        _id         => $request->session // '',
        action_name => $action,
        apiv        => $self->apiv // 1,
        cvar        => $cvar,
        idsite      => $self->idsite,
        rand        => $rand,
        rec         => 1,
        token_auth  => $self->token_auth,
        ua          => $request->user_agent // 'Mozilla',
        url         => $request->uri,
        urlref      => $request->referer // '',
        visitIP     => $ip,
    };

    if ($action eq 'download') {
        $event->{download} = $request->uri;
    }

    $self->_push_to_matomo($event);

    return $res;
}

sub _anonymize_ip {
    my ($self, $ip) = @_;

    $ip =~ s/\.\d+?$/\.0/;

    return $ip;
}

sub _push_to_matomo {
    my ($self, $event) = @_;

    my $uri = URI->new($self->base_url);
    $uri->query_form($event);

    $log->debug("URL: " . $uri->as_string);

    http_head $uri->as_string, sub {
        my ($body, $hdr) = @_;

       if ($hdr->{Status} =~ /^2/) {
          # ok
       } else {
          $log->error("Could not reach analytics endpoint: $hdr->{Status} $hdr->{Reason} for " . $uri->as_string);
       }
   };
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
            base_url => "https://analytics.openaire.eu/piwik.php",
            token_auth => "secr3t",
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

Following the spec from L<https://developer.matomo.org/api-reference/tracking-api>.

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

package Plack::App::FakeModPerl1;
{
  $Plack::App::FakeModPerl1::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeModPerl1::VERSION = '0.0.5';
# ABSTRACT: Mimic Apache's mod_perl1
use 5.10.1;
use Moose;

use Carp;
use HTTP::Status qw(:constants :is status_message);

use Package::DeprecationManager -deprecations => {
    'Plack::App::FakeModPerl1::send_http_header'    => '0.0.1',
};


use Plack::App::FakeModPerl1::Dispatcher;
use Plack::App::FakeModPerl1::Server;
use Plack::Util;

no Moose;

sub handle_psgi {
    my $env         = shift;
    my $config_file = shift;
    my $plack = Plack::App::FakeModPerl1->new( env => $env );
    my $session = $env->{'psgix.session'};

    # derive where to dispatch to based on <Location>s in apache config
    my $dispatcher = Plack::App::FakeModPerl1::Dispatcher->new(
        debug               => $ENV{PLACK_DEBUG} // 0,
        config_file_name    => $config_file,
    );
    $dispatcher->dispatch_for( $plack );

    # let Plack::Response do its thing
    return $plack->finalize;
}

sub new {
    my ( $class, %p ) = @_;

    # 'require' rather than 'use' so that non-plebgui doesn't freak out
    require Plack::Request;
    my $request = Plack::Request->new( $p{env} );
    my $response = $request->new_response(HTTP_OK);

    bless {
        %p,
        pnotes      => {},
        request     => $request,
        response    => $response,
        server      => Plack::App::FakeModPerl1::Server->new( env => $p{env} ),
        headers_out => Plack::Util::headers( [] ), # use Plack::Util to manage response headers
        body        => [],
        sendfile    => undef,
    }, $class;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $what = $AUTOLOAD;
    $what =~ s/.*:://;
    carp "!!plack->$what(@_)" unless $what eq 'DESTROY';
}

# Emulate/delegate/fake Apache::* subs
sub         uri { shift->{request}->request_uri(@_) }
sub       param { shift->{request}->param(@_) }
sub      params { shift->{request}->params(@_) }
sub  headers_in { shift->{request}->headers(@_) }
sub headers_out { shift->{headers_out} }
sub    protocol { shift->{request}->protocol(@_) }
sub      pnotes { shift->{pnotes} }
sub      status { shift->{response}->status(@_) }
sub    sendfile { $_[0]->{sendfile} = $_[1] }
sub      server { shift->{server} }
sub      method { shift->{request}->method }
sub      upload { shift->{request}->upload(@_) }
sub  dir_config { shift->{server}->dir_config(@_) }
sub status_line { }
sub   auth_type { } # should we support this?
sub     handler {'perl-script'} # or not..?

# in Apache1/MP1 you'll see people doing something like:
#    $r->send_http_header( 'text/html' );
# Whilst horrible it was 'valid', and we can support this by setting the
# content type header for them
#
# to be safe we should probably only do this if we have one argument passed
sub send_http_header {
    deprecated( 'use ->content_type(..) instead' );
    my $self = shift;

    if (1 == scalar @_) {
        return $self->content_type( $_[0] );
    }
}

sub parsed_uri {
    my $self = shift;
    require URI::URL;
    return URI::URL->new(
          $self->{env}{'psgi.url_scheme'}
        . q{://}
        . ($self->{env}{HTTP_HOST} || $self->{env}{SERVER_NAME} || '')
        . $self->{env}{REQUEST_URI}
    );
}

sub content_type {
    my ( $self, $ct ) = @_;
    $self->{headers_out}->set( 'Content-Type' => $ct );
}

# TODO: I suppose this should do some sort of IO::Handle thing
sub print {
    my $self = shift;
    push @{ $self->{body} }, @_;
}

sub finalize {
    my $self        = shift;
    my $response    = $self->{response};

    if ( $self->{sendfile} && open my $fh, '<', $self->{sendfile} ) {
        $response->body($fh);
    }
    elsif (@{$self->{body}}) {
        $response->body( $self->{body} );
    }
    else {
        if ($response->status == HTTP_OK) {
            $response->status(HTTP_NOT_FOUND);
        }
    }

    # if we don't have a content-type default to text/html
    # - this magically makes Plack::Middleware::Debug work with XT!
    # we only want to add the content type if we're a 200 status
    # (for example, setting it for a 302 stuffs up the redirect)
    if(not $response->header('content-type')) {
        $response->headers([ 'Content-Type' => 'text/html' ])
            if ($response->status == HTTP_OK);
    }

    $response->headers( $self->{headers_out}->headers )
        if @{ $self->{headers_out}->headers };
    return $response->finalize;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeModPerl1 - Mimic Apache's mod_perl1

=head1 VERSION

version 0.0.5

BORROWED HEAVILY FROM

L<https://github.com/pdonelan/webgui/blob/plebgui/lib/WebGUI/Session/Plack.pm>

=head2 handle_psgi

=head2 new

=head2 uri

=head2 param

=head2 params

=head2 headers_in

=head2 headers_out

=head2 protocol

=head2 pnotes

=head2 status

=head2 sendfile

=head2 server

=head2 method

=head2 upload

=head2 dir_config

=head2 status_line

=head2 auth_type

=head2 handler

=head2 send_http_header

=head2 parsed_uri

=head2 content_type

=head2 print

=head2 finalize

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

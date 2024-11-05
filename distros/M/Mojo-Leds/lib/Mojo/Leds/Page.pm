package Mojo::Leds::Page;
$Mojo::Leds::Page::VERSION = '1.18';
use 5.014;    # because s///r usage
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(class_to_path);

sub route {
    my $s = shift;
    my $respond_to_opt = shift || {};

    my $format = $s->accepts;
    $format = $format->[0] || 'html' if ( ref($format) eq 'ARRAY' );
    $format =~ s/^(.*?)\.//;    # replace xxxx.js -> js;
    if ( $s->match->path_for->{path} =~ /\.(\w+)$/ ) {

        # force format to file extension
        $format = $1 if ( $format eq 'html' || $format eq 'htm' );
    }
    $s->stash( 'format', $format );

    $s->respond_to(
        html => sub { $s->render_pm },
        json => sub { $s->render( json => $s->render_json ) },
        css  => sub { $s->render_static_file },
        js   => sub { $s->render_static_file },
        any  => { text => '', status => 204 },
        %$respond_to_opt,
    );

}

sub render_pm {
    my $s           = shift;
    my $render_html = $s->render_html;

    # if undef we suppose that &render_html do the render job by itself
    return unless $render_html;
    $s->render_maybe(%$render_html) or $s->reply->not_found;
}

sub render_html {
    my $c = shift;

    # needed for recursive calls (html -> json as an example)
    my $query = $c->req->params->to_hash;
    while ( my ( $k, $v ) = each %$query ) {
        $c->stash( $k => $v );
    }
    return { template => class_to_path( ref($c) ) =~ s/\.pm//r };
}

sub render_json {
    my $c = shift;
    return {};
}

sub render_static_file {
    my $c = shift;

    # optional sub-folder for templates inside app home
    my $dRoot = $c->app->config->{docs_root} || '';

    # indipendently from url, it consider the requested file local to the ctl
    my $ctl_path
        = $c->app->home->rel_file( $dRoot . '/' . class_to_path($c) );

    my $fn = $c->tx->req->url->path->parts->[-1];    # the requested file name
    my $filepath = $ctl_path->dirname()->child($fn);    # filesystem file path
    return $c->reply->not_found unless ( -e $filepath );  # file doen't exists

    my %opt = (
        content_disposition => 'inline',
        filepath            => $filepath,
        format              => $filepath =~ s/(.*^?)\.//r
    );
    $c->render_file(%opt);
}

1;

=pod

=head1 NAME

Mojo::Leds::Page - Controller for handling page routes

=head1 VERSION

version 1.18

=head1 SYNOPSIS

  use Mojo::Leds::Page;

=head1 DESCRIPTION

This module provides a controller for handling different formats of page routes in a Mojolicious application.

=head2 METHODS

=head3 route

  $s->route($respond_to_opt);

This method handles routing for different formats (html, json, css, js) based on the request. It sets the appropriate format in the stash and responds accordingly.

=over 4

=item *

C<$respond_to_opt> - Optional hash reference for additional respond_to options.

=back

=encoding UTF-8

=head1 NAME

Mojo::Leds::Page - Controller for handling page routes

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Controller for handling page routes



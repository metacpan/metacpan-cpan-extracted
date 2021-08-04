package Mojo::Leds::Page;
$Mojo::Leds::Page::VERSION = '1.04';
use 5.014;    # because s///r usage
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(class_to_path);

sub route {
    my $s = shift;

    my $format = $s->accepts;
    $s->app->types->type(
        js   => 'application/javascript',
        css  => 'text/css',
        xls  => 'application/vnd.ms-excel',
        text => 'text/plain',
        txt  => 'text/plain',
    );
    $format = $format->[0] || 'html' if ( ref($format) eq 'ARRAY' );
    if ( $s->match->path_for->{path} =~ /\.(\w+)$/ ) {

        # forzo il formato dell'estensione del file richiesto
        $format = $1 if ( $format eq 'html' || $format eq 'htm' );
    }

    # occhio che respond_to non va bene perche' sembra chiamare
    # comunque tutte le funzioni
    for ($format) {
        if    (/^html?/) { my $r = $s->render_html; $s->render(%$r) if ($r) }
        elsif ( $_ eq 'txt' ) {
            my $r = $s->render_html;
            $s->render(%$r) if ($r);
        }
        elsif ( $_ eq 'json' ) { $s->render( json => $s->render_json ) }
        elsif ( $_ eq 'text' ) { $s->render( text => $s->render_text ) }

        # match xxx.model.js ad esempio
        elsif (/^(\w+\.)?js$/)  { $s->render_static_file }
        elsif (/^(\w+\.)?css$/) { $s->render_static_file }
        else                    { $s->render( { text => '', status => 204 } ) }
    }
}

sub render_html {
    my $c = shift;

    # per uso in successive chiamate (html -> json ad esempio)
    my $query = $c->req->params->to_hash;
    $c->session->{query} = $query;
    while ( my ( $k, $v ) = each %$query ) {
        $c->stash( $k => $v );
    }
    return { template => class_to_path( ref($c) ) =~ s/\.pm//r };
}

sub render_json {
    my $c = shift;
    return {};
}

sub render_text {
    my $c = shift;

    my $json  = $c->render_json;    # default try to get json data from page
    my $data0 = $json->{data0};     # json => {"data0": [...]}
    my $str   = '';
    my $fmt   = '%24s | ';

    # title
    my $rowd = $data0->[0];
    foreach my $key ( keys %$rowd ) {
        if ( length($key) > 24 ) {
            $key = substr( $key, 0, 21 ) . '...';
        }
        $str .= sprintf( $fmt, $key );
    }
    $str .= "\n";

    foreach my $rowd (@$data0) {
        foreach my $val ( values %$rowd ) {
            if ( length($val) > 24 ) {
                $val = substr( $val, 0, 21 ) . '...';
            }
            $str .= sprintf( $fmt, $val );
        }
        $str .= "\n";
    }

    return $str;
}

sub render_static_file {
    my $c = shift;

    # optional sub-folder for templates inside app home
    my $dRoot = $c->app->config->{docs_root} || '';

    # indipendently from url, it consider the requested file local to the ctl
    my $ctl_path = $c->app->home->rel_file( $dRoot . '/' . class_to_path($c) );

    my $fn = $c->tx->req->url->path->parts->[-1];    # the requested file name
    my $filepath = $ctl_path->dirname()->child($fn);    # filesystem file path
    return $c->reply->not_found unless ( -e $filepath );    # file doen't exists

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

Mojo::Leds::Page - Standard page controller for Mojo::Leds

=head1 VERSION

version 1.04

=head1 SYNOPSIS

=head1 DESCRIPTION

=encoding UTF-8

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Standard page controller for Mojo::Leds


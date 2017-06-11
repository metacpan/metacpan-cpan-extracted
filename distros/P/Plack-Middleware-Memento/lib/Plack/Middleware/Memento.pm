package Plack::Middleware::Memento;

use strict;
use warnings;

our $VERSION = '0.0102';

use Plack::Request;
use Plack::Util;
use DateTime;
use DateTime::Format::HTTP;
use parent 'Plack::Middleware';
use namespace::clean;

sub timegate_path {
    $_[0]->{timegate_path} ||= '/timegate';
}

sub timemap_path {
    $_[0]->{timemap_path} ||= '/timemap';
}

sub _handler_options {
    my ($self) = @_;
    $self->{_handler_options} ||= do {
        my $options = {};
        for my $key (keys %$self) {
            next
                if $key
                =~ /(?:^_)|(?:^(?:handler|timegate_path|timemap_path)$)/;
            $options->{$key} = $self->{$key};
        }
        $options;
    };
}

sub _handler {
    my ($self) = @_;
    $self->{_handler} ||= do {
        my $class = Plack::Util::load_class($self->{handler},
            'Plack::Middleware::Memento::Handler');
        $class->new($self->_handler_options);
    };
}

sub call {
    my ($self, $env) = @_;
    return $self->app->($env) unless $env->{REQUEST_METHOD} =~ /GET|HEAD/;
    $self->_handle_timegate_request($env)
        || $self->_handle_timemap_request($env)
        || $self->_wrap_request($env);
}

sub _wrap_request {
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    my $req = Plack::Request->new($env);
    if (my ($uri_r, $dt) = $self->_handler->wrap_memento_request($req)) {
        my @links = (
            $self->_original_link($uri_r),
            $self->_timegate_link($req->base, $uri_r),
            $self->_timemap_link($req->base, $uri_r, 'timemap'),
        );
        Plack::Util::header_set($res->[1], 'Memento-Datetime',
            DateTime::Format::HTTP->format_datetime($dt));
        Plack::Util::header_push($res->[1], 'Link', join(",", @links));
    }
    if ($self->_handler->wrap_original_resource_request($req)) {
        Plack::Util::header_push($res->[1], 'Link',
            $self->_timegate_link($req->base, $req->uri->as_string));
    }
    $res;
}

sub _handle_timegate_request {
    my ($self, $env) = @_;

    my $prefix = $self->timegate_path;
    my $uri_r  = $env->{PATH_INFO};
    $uri_r =~ s|^${prefix}/|| or return;

    my $req = Plack::Request->new($env);

    my $mementos = $self->_handler->get_all_mementos($uri_r, $req)
        || return $self->_not_found;

    $mementos = [sort {DateTime->compare($a->[1], $b->[1])} @$mementos];

    my $closest_mem;

    if (defined(my $date = $req->header('Accept-Datetime'))) {
        my $dt = eval {DateTime::Format::HTTP->parse_datetime($date)}
            or return $self->_bad_request;

        my ($closest) = sort {$a->[1] <=> $b->[1]} map {
            my $diff = abs($_->[1]->epoch - $dt->epoch);
            [$_, $diff];
        } @$mementos;

        $closest_mem = $closest->[0];
    }
    else {
        $closest_mem = $mementos->[-1];
    }

    my @links = (
        $self->_original_link($uri_r),
        $self->_timemap_link($req->base, $uri_r, 'timemap', $mementos),
    );

    if (@$mementos == 1) {
        push @links, $self->_memento_link($closest_mem, 'first last memento');
    }
    elsif ($closest_mem->[0] eq $mementos->[0]->[0]) {
        push @links, $self->_memento_link($closest_mem,    'first memento');
        push @links, $self->_memento_link($mementos->[-1], 'last memento');
    }
    elsif ($closest_mem->[0] eq $mementos->[-1]->[0]) {
        push @links, $self->_memento_link($mementos->[0], 'first memento');
        push @links, $self->_memento_link($closest_mem,   'last memento');
    }
    else {
        push @links, $self->_memento_link($mementos->[0],  'first memento');
        push @links, $self->_memento_link($closest_mem,    'memento');
        push @links, $self->_memento_link($mementos->[-1], 'last memento');
    }

    [
        302,
        [
            'Vary'         => 'accept-datetime',
            'Location'     => $closest_mem->[0],
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Link'         => join(",", @links),
        ],
        [],
    ];
}

sub _handle_timemap_request {
    my ($self, $env) = @_;

    my $prefix = $self->timemap_path;
    my $uri_r  = $env->{PATH_INFO};
    $uri_r =~ s|^${prefix}/|| or return;

    my $req = Plack::Request->new($env);

    my $mementos = $self->_handler->get_all_mementos($uri_r, $req)
        || return $self->_not_found;

    $mementos = [sort {DateTime->compare($a->[1], $b->[1])} @$mementos];

    my @links = (
        $self->_original_link($uri_r),
        $self->_timemap_link($req->base, $uri_r, 'self', $mementos),
        $self->_timegate_link($req->base, $uri_r),
    );

    if (@$mementos == 1) {
        push @links,
            $self->_memento_link($mementos->[0], 'first last memento');
    }
    else {
        if (my $first_mem = shift @$mementos) {
            push @links, $self->_memento_link($first_mem, 'first memento');
        }
        if (my $last_mem = pop @$mementos) {
            push @links, $self->_memento_link($last_mem, 'last memento');
        }
        push @links, map {$self->_memento_link($_, 'memento')} @$mementos;
    }

    [
        200,
        ['Content-Type' => 'application/link-format',],
        [join(",\n", @links),],
    ];
}

sub _not_found {
    my ($self) = @_;
    [404, ['Content-Type' => 'text/plain; charset=UTF-8'], []];
}

sub _bad_request {
    my ($self) = @_;
    [400, ['Content-Type' => 'text/plain; charset=UTF-8'], []];
}

sub _original_link {
    my ($self, $uri_r) = @_;
    qq|<$uri_r>; rel="original"|;
}

sub _timemap_link {
    my ($self, $base_url, $uri_r, $rel, $mementos) = @_;
    $base_url->path(join('/', $self->timemap_path, $uri_r));
    my $uri_t = $base_url->canonical->as_string;
    my $link  = qq|<$uri_t>; rel="$rel"; type="application/link-format"|;
    if ($mementos) {
        my $from
            = DateTime::Format::HTTP->format_datetime($mementos->[0]->[1]);
        my $until
            = DateTime::Format::HTTP->format_datetime($mementos->[-1]->[1]);
        $link .= qq|; from="$from"; until="$until"|;
    }
    $link;
}

sub _timegate_link {
    my ($self, $base_url, $uri_r) = @_;
    $base_url->path(join('/', $self->timegate_path, $uri_r));
    my $uri_g = $base_url->canonical->as_string;
    qq|<$uri_g>; rel="timegate"|;
}

sub _memento_link {
    my ($self, $mem, $rel) = @_;
    my $uri_m    = $mem->[0];
    my $datetime = DateTime::Format::HTTP->format_datetime($mem->[1]);
    qq|<$uri_m>; rel="$rel"; datetime="$datetime"|;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Memento - Enable the Memento protocol

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::App::Catmandu::Bag;

    builder {
        enable 'Memento', handler => 'Catmandu::Bag', store => 'authority', bag => 'person';
        Plack::App::Catmandu::Bag->new(
            store => 'authority',
            bag => 'person',
        )->to_app;
    };

=head1 DESCRIPTION

This is an early minimal release, documentation and tests are lacking.

=head1 AUTHOR

Nicolas Steenlant E<lt>nicolas.steenlant@ugent.beE<gt>

=head1 COPYRIGHT

Copyright 2017- Nicolas Steenlant

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

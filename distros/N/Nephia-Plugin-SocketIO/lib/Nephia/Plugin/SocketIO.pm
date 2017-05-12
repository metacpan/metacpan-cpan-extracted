package Nephia::Plugin::SocketIO;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use PocketIO;
use Plack::Builder;
use HTML::Escape ();
use Sub::Recursive;
use Nephia::Plugin::SocketIO::Assets;

our $VERSION = "0.01";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->app->builder_chain->append('SocketIO' => $class->can('_wrap_app'));
    return $self;
}

sub exports { qw/socketio/ }

sub socketio {
    my ($self, $context) = @_;
    return sub ($&) {
        my ($event, $code) = @_;
        $self->app->{events}{$event} = sub {
            my ($socket, $var) = @_;
            $code->($socket, _escape_html_recursive($var)); ### avoid XSS by _escape_html_recursive
        };
    };
}

sub _wrap_app {
    my ($app, $coderef) = @_;
    builder {
        mount '/socket.io.js' => sub {
            [200, ['Content-Type' => 'text/javascript'], [Nephia::Plugin::SocketIO::Assets->get('socket.io.js')]];
        };
        mount '/socket.io' => PocketIO->new(handler => sub {
            my $socket = shift;
            for my $event (keys %{$app->{events}}) {
                $socket->on($event => $app->{events}{$event});
            }
            $socket->send({buffer => []});
        });
        mount '/' => builder {
            enable 'SimpleContentFilter', filter => sub{
                s|(</body>)|$1\n<script type="text/javascript" src="/socket.io.js"></script>|i;
            };
            $coderef;
        };
    };
}

sub _escape_html_recursive {
    my $v = shift;
    return unless $v;
    my $work = recursive {
        my $val = shift;
        ref($val) eq 'ARRAY' ? [map {$REC->($_)} @$val] :
        ref($val) eq 'HASH'  ? +{map {($_, $REC->($val->{$_}))} keys %$val} :
        HTML::Escape::escape_html($val) ;
    };
    $work->($v);
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::SocketIO - Nephia plugin socketio support

=head1 SYNOPSIS

    use Nephia plugins => [
        'SocketIO',
        ...
    ];
    
    app {
        socketio 'your_event' => sub {
            my $socket = shift; ### PocketIO::Socket object
            $socket->emit('some_event' => 'some_data');
        };
    };


=head1 DESCRIPTION

Nephia::Plugin::SocketIO is a plugin for Nephia. It provides SocketIO messaging feature.

=head1 DSL

=head2 socketio

    my $coderef = sub {
        my $socket = shift; # PocketIO::Socket object
        ...
    };
    socketio $str => $coderef;

Specifier DSL for SocketIO messaging.

$str is event name, and $coderef is event logic.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut


package Mojo::WebSocket::PubSub::Shell;
$Mojo::WebSocket::PubSub::Shell::VERSION = '0.06';
use Mojo::Base 'Term::Shell';
use Regexp::Pattern;
use Mojo::WebSocket::PubSub;
use Term::ANSIColor;

use Time::HiRes qw(tv_interval gettimeofday);

has prompt_line => colored( "pubsub", "cyan" );
has ps          => undef;
has state       => 0b00;

sub prompt_str { shift->prompt_line . '> ' }

sub init {
    my $s = shift;
    $s->{API}{check_idle} = 10;
    say "";
    say "Welcome to Mojo::WebSocket::PubSub shell";
    say "Connect to a Mojo::WebSocket::PubSub server with: "
      . colored( "connect [url]", "bright_white" );
    say "Type "
      . colored( "help", "bright_white" )
      . " for a list of commands.";
    say "";
}

sub idle {
    my $s = shift;
    if ( defined $s->ps ) {
        $s->ps->keepalive;
    }
}

# connect <url>
sub run_connect {
    my $s   = shift;
    my $url = shift // '';
    state $cb;
    return $s->_error('Not a valid url.') unless $url =~ re("URI::http");
    $s->ps( new Mojo::WebSocket::PubSub( url => $url, auto_keepalive => 0 ) );
    $cb = $s->ps->on( 'connected' => sub { $s->connected( $_[1] ) } )
      unless $cb;
    $s->ps->connect;
}

sub smry_connect { "Connect to a PubSub WebSocket" }

sub help_connect {
    qq{
        Connect to a PubSub WebSocket.
            USAGE:   connect <url>
            EXAMPLE: connect http://127.0.0.1:9096
    } =~ s/^\s{8}//gmr;
}

sub connected {
    my $s = shift;
    $s->prompt_line( colored( "pubsub/c", "cyan" ) );
    $s->state(0b01);
    $s->_reply( "WebSocket connected to " . shift );
}

sub term_msg {
    my $s   = shift;
    my $msg = shift;
}

# listen <channel_name>
sub run_listen {
    my $s  = shift;
    my $ch = shift;
    state $cb;
    return $s->_error('Invalid channel.')              unless $ch;
    return $s->_error('Not connected to a WebSocket.') unless ($s->state & 1);
    $s->ps->listen($ch);
    $cb = $s->ps->on( 'notify' => sub { $s->received_notify( $_[1] ) } )
      unless $cb;
    $s->prompt_line( colored( "pubsub/l:$ch", "cyan" ) );
    $s->state(0b11);

}

sub smry_listen { "Listen to a pubsub channel" }

sub help_listen {
    qq{
        Listen to a pubsub channel
            USAGE:   listen <channel_name>
            EXAMPLE: listen foo
    } =~ s/^\s{8}//gmr;
}

# ping
sub run_ping {
    state $cb;
    my $s = shift;
    return $s->_error('Not connected to a WebSocket.') unless ($s->state & 1);
    $cb = $s->ps->on( 'pong' => sub { shift; $s->pong(@_) } )
      unless $cb;
    $s->ps->ping;
}

sub smry_ping { "Ping a pubsub channel" }

sub help_ping {
    qq{
        Ping a pubsub channel. Return client to server time (C2S), server to cliente time (S2C) and total time in milliseconds
            USAGE:   ping
            EXAMPLE: ping
    } =~ s/^\s{8}//gmr;
}

sub pong {
    my $s   = shift;
    my $req = shift;
    my $cte = [gettimeofday];
    $s->_reply( "C2S: "
          . ( tv_interval $req->{cts}, $req->{sts} ) * 1000
          . " - S2C: "
          . ( tv_interval $req->{sts}, $cte ) * 1000
          . " - Total time: "
          . ( tv_interval $req->{cts}, $cte ) * 1000
          . ' ms' );
}

sub run_publish {
    my $s   = shift;
    my $msg = shift;
    return $s->_error('Not connected to a WebSocket.') unless ($s->state & 1);
    return $s->_error('Not connected to channel.') unless ($s->state & 0b10);
    $s->ps->publish($msg);
    $s->_reply("Message sent");
}

sub _reply {
    my $s = shift;
    my $msg = shift;
    my $color = shift || 'green';
    print colored( $msg, $color ) . "\n";
}

sub _error {
    my $s = shift;
    $s->_reply( shift . " See help for command syntax.", 'red' );
}

sub received_notify {
    my $s   = shift;
    my $msg = shift;
    $s->_reply("\nReceived broadcast msg:", 'yellow');
    $s->_reply("$msg", 'bright_white');
}

1;

=pod

=head1 NAME

Mojo::WebSocket::PubSub::Shell - A shell interface to Mojolicious:WebSocket::PubSub service

=for html <p>
    <a href="https://github.com/emilianobruni/mojo-websocket-pubsub/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/mojo-websocket-pubsub/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/mojo-websocket-pubsub">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/mojo-websocket-pubsub">
</p>

=head1 VERSION

version 0.06

=head1 SYNOPSIS

Create a script like this and execute

  #!/usr/bin/env perl
..
  use Mojo::WebSocket::PubSub::Shell;

  Mojo::WebSocket::PubSub::Shell->new->cmdloop;

a shall will open. Type C<help> for a list of commands.

=head1 DESCRIPTION

A shell interface to Mojolicious:WebSocket::PubSub service

=encoding UTF-8

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojo::WebSocket::PubSub

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A shell interface to Mojolicious:WebSocket::PubSub service


package Redis::Client::Role::URP;
$Redis::Client::Role::URP::VERSION = '0.015';
# ABSTRACT: Role for the Redis Unified Request Protocol

use Moose::Role;
use Carp 'croak';

our @CARP_NOT = ( 'Redis::Client' );     # report errors from the right place

my $CRLF = "\x0D\x0A";

has '_sock'        => ( is => 'rw', isa => 'IO::Socket', init_arg => undef, lazy_build => 1, 
                        predicate => '_have_sock', clearer => '_clear_sock' );

requires 'host';
requires 'port';

sub _build__sock { 
    my $self = shift;

    my $sock = IO::Socket::INET->new( 
        PeerAddr    => $self->host,
        PeerPort    => $self->port,
        Proto       => 'tcp',
    ) or die sprintf q{Can't connect to Redis host at %s:%s: %s}, $self->host, $self->port, $@;

    return $sock;
}

sub send_command { 
    my $self = shift;
    my ( $cmd, @args ) = @_;

    my $sock = $self->_sock;
    my @cmd = ();
    ($cmd =~ /\s/) ? (@cmd = split(/\s/, $cmd)) : (@cmd = ($cmd));
    my $cmd_block = $self->_build_urp( @cmd, @args );

    $sock->send( $cmd_block );

    return $self->_get_response;
}

# build a command string using the binary-safe Unified Request Protocol
sub _build_urp { 
    my $self = shift;
    my @items = @_;

    my $length = @_;

    my $block = sprintf '*%s%s', $length, $CRLF;

    foreach my $line( @items ) { 
        $block .= sprintf '$%s%s', length $line, $CRLF;
        $block .= $line . $CRLF;
    }

    return $block;
}

sub _get_response { 
    my $self = shift;
    my $sock = $self->_sock;

    # the first byte tells us what to expect
    my %msg_types = ( '+'   => '_read_single_line',
                      '-'   => '_read_single_line',
                      ':'   => '_read_single_line',
                      '$'   => '_read_bulk_reply',
                      '*'   => '_read_multi_bulk_reply' );

    my $buf;
    $sock->read( $buf, 1 );
    die "Can't read from socket" unless $buf;
    die "Can't understand Redis message type [$buf]" unless exists $msg_types{$buf};

    my $meth = $msg_types{$buf};

    if ( $buf eq '-' ) { 
        # A Redis error. Get the error message and throw it.
        my $err = $self->$meth;
        $err =~ s/ERR\s/Redis: /;

        # Reconnect to server so next command does not fail
        $self->_sock( $self->_build__sock );

        croak $err;
    }

    # otherwise get the response and return it normally.
    return $self->$meth;
}

sub _read_multi_bulk_reply { 
    my $self = shift;
    my $sock = $self->_sock;

    local $/ = $CRLF;

    my $parts = readline $sock;
    chomp $parts;

    return if $parts == 0;      # null response

    my @results;
    foreach my $part ( 1 .. $parts ) { 
        # better hope we don't see a multi-bulk inside a multi-bulk!
        push @results, $self->_get_response;
    }

    return @results;
}

sub _read_bulk_reply { 
    my $self = shift;
    my $sock = $self->_sock;

    local $/ = $CRLF;

    my $length = readline $sock;
    chomp $length;

    return undef if $length == -1;    # null response

    my $buf;
    $sock->read( $buf, $length );

    # throw out the terminating CRLF
    readline $sock;

    return $buf;
}

sub _read_single_line { 
    my $self = shift;
    my $sock = $self->_sock;

    local $/ = $CRLF;

    my $val = readline $sock;
    chomp $val;

    return $val;
}


1;

__END__

=pod

=head1 NAME

Redis::Client::Role::URP - Role for the Redis Unified Request Protocol

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Moose;

    has host => ( ... )
    has port => ( ... )

    with 'Redis::Client::Role::URP';

=head1 DESCRIPTION

This role implements the L<Unified Request Protocol|http://redis.io/topics/protocol> used by 
Redis 2.0 and above.

=head1 METHODS

=head2 send_command

Sends a command to Redis using the URP and returns the response. Takes the name of
the command and a list of arguments. 

    $self->send_command( 'DEL', 'key1', 'key2', 'key3' );

=encoding utf8

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

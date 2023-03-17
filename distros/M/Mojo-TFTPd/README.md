# NAME

Mojo::TFTPd - Trivial File Transfer Protocol daemon

# VERSION

0.04

# SYNOPSIS

    use Mojo::TFTPd;
    my $tftpd = Mojo::TFTPd->new;

    $tftpd->on(error => sub ($tftpd, $error) { warn "TFTPd: $error\n" });

    $tftpd->on(rrq => sub ($tftpd, $connection) {
      open my $FH, '<', $connection->file;
      $connection->filehandle($FH);
      $connection->filesize(-s $connection->file);
    });

    $tftpd->on(wrq => sub ($tftpd, $connection) {
      open my $FH, '>', '/dev/null';
      $connection->filehandle($FH);
    });

    $tftpd->on(finish => sub ($tftpd, $connection, $error) {
      warn "Connection: $error\n" if $error;
    });

    $tftpd->start;
    $tftpd->ioloop->start unless $tftpd->ioloop->is_running;

# DESCRIPTION

This module implements a server for the
[Trivial File Transfer Protocol](http://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol).

From Wikipedia:

    Trivial File Transfer Protocol (TFTP) is a file transfer protocol notable
    for its simplicity. It is generally used for automated transfer of
    configuration or boot files between machines in a local environment.

The connection which is referred to in this document is an instance of
[Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection).

# EVENTS

## error

    $tftpd->on(error => sub ($tftpd, $str) { ... });

This event is emitted when something goes wrong: Fail to ["listen"](#listen) to socket,
read from socket or other internal errors.

## finish

    $tftpd->on(finish => sub ($tftpd, $connection, $error) { ... });

This event is emitted when the [Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection) finish, either
successfully or due to an error. `$error` will be an empty string on success.

## rrq

    $tftpd->on(rrq => sub ($tftpd, $connection) { ... });

This event is emitted when a new read request arrives from a client. The
callback should set ["filehandle" in Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection#filehandle) or the connection
will be dropped.
["filehandle" in Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection#filehandle) can also be a [Mojo::Asset](https://metacpan.org/pod/Mojo%3A%3AAsset) reference.

## wrq

    $tftpd->on(wrq => sub ($tftpd, $connection) { ... });

This event is emitted when a new write request arrives from a client. The
callback should set ["filehandle" in Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection#filehandle) or the connection
will be dropped.
["filehandle" in Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection#filehandle) can also be a [Mojo::Asset](https://metacpan.org/pod/Mojo%3A%3AAsset) reference.

# ATTRIBUTES

## connection\_class

    $str = $tftpd->connection_class;
    $tftpd = $tftpd->connection_class($str);

Used to set a custom connection class. Defaults to [Mojo::TFTPd::Connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection).

## inactive\_timeout

    $num = $tftpd->inactive_timeout;
    $tftpd = $tftpd->inactive_timeout(15);

How long a [connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection) can stay idle before
being dropped. Default is 15 seconds.

## ioloop

    $loop = $tftpd->ioloop;
    $tftpd = $tftpd->ioloop(Mojo::IOLoop->new);

Holds an instance of [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop).

## listen

    $str = $tftpd->listen;
    $tftpd = $tftpd->listen('127.0.0.1:69');
    $tftpd = $tftpd->listen('tftp://*:69');

The bind address for this server.

## max\_connections

    $int = $tftpd->max_connections;
    $tftpd = $tftpd->max_connections(1000);

How many concurrent connections this server can handle. Default to 1000.

## retransmit

    $int = $tftpd->retransmit;
    $tftpd = $tftpd->retransmit(1);

How many times the server should try to retransmit the last packet on timeout before
dropping the [connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection). Default is 0 (disable retransmits)

## retransmit\_timeout

    $num = $tftpd->retransmit_timeout;
    $tftpd = $tftpd->retransmit_timeout(2);

How long a [connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection) can stay idle before last packet
being retransmitted. Default is 2 seconds.

## retries

    $int = $tftpd->retries;
    $tftpd = $tftpd->retries(1);

How many times the server should try to send ACK or DATA to the client before
dropping the [connection](https://metacpan.org/pod/Mojo%3A%3ATFTPd%3A%3AConnection).

# METHODS

## start

    $tftpd = $tftpd->start;

Starts listening to the address and port set in ["Listen"](#listen). The ["error"](#error)
event will be emitted if the server fail to start.

# AUTHOR

Svetoslav Naydenov - `harryl@cpan.org`

Jan Henning Thorsen - `jhthorsen@cpan.org`

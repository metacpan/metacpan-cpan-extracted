package Pgtools;
use 5.021001;
use strict;
use warnings;

our $VERSION = "0.009";

1;
__END__

=encoding utf-8

=head1 NAME

Pgtools - It's a yet another command-line tool for PostgreSQL operation. 

=head1 SYNOPSIS

=head2 pg_kill
    $ pg_kill -kill -print -mq "like\s'\%.*\%'" "192.168.32.12,5432,postgres,,dvdrental"
    -------------------------------
    Killed-pid: 11590
    At        : 2016/03/21 01:32:29
    Query     : SELECT * FROM actor WHERE last_name like '%a%';
    Killed matched queries!


=head2 pg_config_diff
    $ pg_config_diff  "192.168.33.21,5432,postgres,," "192.168.33.22,,,," "192.168.33.23,5432,postgres,,dvdrental"
    <Setting Name>           192.168.33.21           192.168.33.22           192.168.33.23
    --------------------------------------------------------------------------------------------
    max_connections          50                      100                     100
    shared_buffers           32768                   16384                   65536
    tcp_keepalives_idle      8000                    7200                    10000
    tcp_keepalives_interval  75                      75                      10
    wal_buffers              1024                    512                     2048


=head2 pg_fingerprint
    $ pg_fingerprint queries_file
    SELECT * FROM user WHERE id = ?;
    SELECT * FROM user2 WHERE id = ? LIMIT ?;
    SELECT * FROM user2 WHERE point = ?;
    SELECT * FROM user2 WHERE expression IS ?;



=head1 DESCRIPTION

Pgtools is composed of 3 commands which is pg_kill, pg_config_diff, pg_fingerprint.

- pg_kill shows the specified queries during execution by regular expression and other options. And also kill these specifid queries by -kill option.
- pg_config_diff command needs more than 2 argument which is string to specify the PostgreSQL databases.
- pg_fingerprint command converts the values into a placeholders.

=head1 LICENSE

    Copyright (C) Otsuka Tomoaki.

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself.

=head1 AUTHOR

Otsuka Tomoaki E<lt>otsuka.t.2013@gmail.comE<gt>

=cut


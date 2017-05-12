# NAME

Pgtools - It's a yet another command-line tool for PostgreSQL operation. 

# SYNOPSIS

## pg\_kill
    $ pg\_kill -kill -print -mq "like\\s'\\%.\*\\%'" "192.168.32.12,5432,postgres,,dvdrental"
    -------------------------------
    Killed-pid: 11590
    At        : 2016/03/21 01:32:29
    Query     : SELECT \* FROM actor WHERE last\_name like '%a%';
    Killed matched queries!

## pg\_config\_diff
    $ pg\_config\_diff  "192.168.33.21,5432,postgres,," "192.168.33.22,,,," "192.168.33.23,5432,postgres,,dvdrental"
    <Setting Name>           192.168.33.21           192.168.33.22           192.168.33.23
    --------------------------------------------------------------------------------------------
    max\_connections          50                      100                     100
    shared\_buffers           32768                   16384                   65536
    tcp\_keepalives\_idle      8000                    7200                    10000
    tcp\_keepalives\_interval  75                      75                      10
    wal\_buffers              1024                    512                     2048

## pg\_fingerprint
    $ pg\_fingerprint queries\_file
    SELECT \* FROM user WHERE id = ?;
    SELECT \* FROM user2 WHERE id = ? LIMIT ?;
    SELECT \* FROM user2 WHERE point = ?;
    SELECT \* FROM user2 WHERE expression IS ?;

# DESCRIPTION

Pgtools is composed of 3 commands which is pg\_kill, pg\_config\_diff, pg\_fingerprint.

\- pg\_kill shows the specified queries during execution by regular expression and other options. And also kill these specifid queries by -kill option.
\- pg\_config\_diff command needs more than 2 argument which is string to specify the PostgreSQL databases.
\- pg\_fingerprint command converts the values into a placeholders.

# LICENSE

    Copyright (C) Otsuka Tomoaki.

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself.

# AUTHOR

Otsuka Tomoaki <otsuka.t.2013@gmail.com>

package Redis::Term;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.12';

1;
__END__

=head1 NAME

Redis::Term - Redis Client Terminal

=head1 SYNOPSIS

  [chengang@local]# redist -h127.0.0.1 -P6379 -ppasswd
  Welcome to the Redis Terminal.  Commands end with ENTER.
  Your Redis connection name is 1393840471
  Connected to: 127.0.0.1:6379
  Redis version: 2.8.6-standalone

  Copyright (c) 2014-2015, Chen Gang. This is free software.

  Type 'help' for help.

  redis> info
  +--------------------------------+------------------------------------------+
  | Variable_name                  | Value                                    |
  +--------------------------------+------------------------------------------+
  | redis_build_id                 | cce2568a7c149200                         |
  | total_connections_received     | 3                                        |
  | used_memory_lua                | 33792                                    |
  | used_memory_rss                | 1568768                                  |
  | redis_git_dirty                | 0                                        |
  | loading                        | 0                                        |
  | redis_mode                     | standalone                               |
  | latest_fork_usec               | 0                                        |
  | repl_backlog_first_byte_offset | 0                                        |
  | sync_partial_ok                | 0                                        |
  | master_repl_offset             | 0                                        |
  | mem_allocator                  | libc                                     |
  | uptime_in_days                 | 0                                        |
  | gcc_version                    | 4.2.1                                    |
  | aof_rewrite_scheduled          | 0                                        |
  .
  .
  .


=head1 DESCRIPTION

Small redis client in perl.

Execute 'redist', then input any redis command you want.


=head1 ARGV

-h Redis server IP or HOSTNAME, default 127.0.0.1

-P Redis server port, default 6379

-p password if have any


=head1 INSTALL

Recommended to install using cpanm, like this.

  curl -L -k http://cpanmin.us | perl - -n Redis::Term


=head1 EXPORT

Nothing will be exported.


=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut


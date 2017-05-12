package Mojar::Mysql;
use Mojo::Base -strict;

our $VERSION = 2.132;

1;
__END__

=head1 NAME

Mojar::Mysql - Suite of MySQL integration tools.

=head1 DESCRIPTION

=over 4

=item L<Mojar::Mysql::Connector>

Subclass of L<DBI> providing sensible defaults, easy management of parameters,
richer connectors, connection cacheing, and convenience methods.

=item L<Mojar::Mysql::Replication>

Class for monitoring and managing repliation threads.

  $repl->start_sql;
  say 'Lag: ', $repl->sql_lag;

=item L<Mojar::Mysql::Util>

Collection of utility functions.

=back

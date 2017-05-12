#!/usr/bin/perl
use strict;
use warnings;

use RocksDB;

RocksDB::LDBTool->new->run;

__END__

=head1 NAME

ldb.pl - multiple data access and database admin commands

=head1 SYNOPSIS

  $ ldb.pl --db=/path/to/rocks.db put a1 b1

  $ ldb.pl --db=/path/to/rocks.db get a1

=head1 DESCRIPTION

The ldb.pl command line tools is a interface to rocksdb::LDBTool.

=head1 SEE ALSO

L<RocksDB::LDBTool> L<https://github.com/facebook/rocksdb/wiki/Ldb-Tool>

=cut

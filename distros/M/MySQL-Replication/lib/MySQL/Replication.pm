package MySQL::Replication;

use strict;
use warnings;

use version;
our $VERSION = qv( '0.0.2' );

1;

__END__

=head1 NAME

MySQL::Replication - Decentralised, peer-to-peer, multi-master MySQL replication

=head1 DESCRIPTION

=head2 What is MySQL::Replication

MySQL::Replication is a replacement for MySQL's built-in replication. The
reason for this module is that there are a number of issues with MySQL's
built-in replication:

=over

=item *

Multi-Master Replication

By design, MySQL can only replicate from a single master. There are some
approaches to achieving multi-master replication, but they have problems:

=over

=item *

Ring Topologies Are Fragile

Multi-master replication is possible by using a ring topology:

  +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com |
  +-----------------+       +-----------------+
           ^                         |
           |                         |
           |                         v
  +-----------------+       +-----------------+
  | db4.example.com | <---- | db3.example.com |
  +-----------------+       +-----------------+

Each master replicates its queries to the connected slave. The way this
achieves multi-master replication is that along with locally generated
queries, incoming replicated queries are also replicated out to the connected
slave e.g:

=over

=item *

db1 replicates its queries to db2

=item *

db2 replicates its queries to db3 (including queries from db1)

=item *

db3 replicates its queries to db4 (including queries from db1 and db2)

=item *

db4 replicates its queries to db1 (including queries from db1, db2 and db3)

=back

Queries replicate all the way around the ring until a master sees an incoming
query that was generated locally. These are discarded to prevent queries
infinitely replicating around the ring.

The problem with ring topologies is that if a master dies, queries don't
progress around the ring and so replication lag builds:

  +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com |
  +-----------------+       +-----------------+
                                     |
                                     |
                                     v
                            +-----------------+
                            | db3.example.com |
                            +-----------------+

We can fix a broken ring by bypassing the dead master:

  +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com |
  +-----------------+       +-----------------+
           ^                         |
           |                         |
           |                         v
           |                +-----------------+
           +--------------- | db3.example.com |
                            +-----------------+

The problem here is that if there are queries still replicating around the
ring from the dead master, the queries will not be filtered out and so an
infinite replication loop occurs.

Since MySQL::Replication clients do not binlog incoming queries, there is no
risk of serving non-locally generated queries and thus no risk of infinite
replication loops.

=item *

Time Slicing Wastes Time

Multi-master replication is possible by time slicing:

  @t1:
  +-----------------+       +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com |       | db3.example.com |
  +-----------------+       +-----------------+       +-----------------+

  @t2:
  +-----------------+       +-----------------+       +-----------------+
  | db1.example.com |       | db2.example.com | <---- | db3.example.com |
  +-----------------+       +-----------------+       +-----------------+

  @t3:
  +-----------------+       +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com |       | db3.example.com |
  +-----------------+       +-----------------+       +-----------------+

A timer is used to stop replicating from the currently connected master and to
switch to another e.g.:

=over

=item *

the timer is started

=item *

db2 replicates from db1 for a timeslice

=item *

the timer fires

=item *

db2 stops replicating from db1

=item *

db2 is reconfigured to replicate from db3

=item *

the timer is started

=item *

db2 replicates from db3 for a timeslice

=back

The problem with time slicing is that time is wasted:

=over

=item *

The slave does no work when the currently connected master doesn't have
anything to replicate

=item *

Replication latency builds up on the blocked masters while they wait for their
share of the timer i.e. given C<N> masters with a timeslice of C<t> seconds
each, the slave will be at least C<(N-1) * t> seconds behind each master.

=back

Since MySQL::Replication achieves multi-master replication by running multiple
instances of the client in parallel, there is no time slicing via a timer and
thus no time wasted by time slicing.

=back

=item *

Queries May Get Replayed After A Server Crash

A slave's master position is recorded in the C<relay-log.info> file however
writes to the InnoDB tablespace and C<relay-log.info> are not atomically
synced to disk. If a slave dies and comes back online, files may be in an
inconsistent state. If the InnoDB tablespace was flushed to disk before the
crash but C<relay-log.info> wasn't, the slave will restart replication from a
stale position and so will replay queries.

A workaround can be found at L<http://bugs.mysql.com/bug.php?id=40337> but note:

  "Although such solution has been proposed to reduce the probability of
  corrupted files due to a slave-crash, the performance penalty introduced by
  it has made the approach impractical for highly intensive workloads."

MySQL::Replication clients store their server positions inside the InnoDB
tablespace (i.e. the C<Replication.SourcePosition> table by default). Since
updates are done within the same transaction as replicated queries are
executed in, writes are atomic. If a slave dies and comes back online, we will
still be in a consistent state since either the transaction was committed or
it will be rolled back.

=item *

Moving Slaves To Different Masters Is Hard

A slave's master position is relative to the directly connected master's
binlogs. Given a multi-layer replication topology e.g. a tree topology, a
slave's master position is still relative to the directly connected master's
binlogs and not relative to the root master's binlogs. If a master in a middle
layer dies, moving its slaves to a different master is non-trivial since they
will all need their master positions translated to the new master's binlogs.

MySQL::Replication always deals with canonical binlog positions. In a
multi-layer replication topology e.g. a tree topology, positions are always
relative to the root server's binlogs. If a relay in a middle layer dies,
moving its clients to a different relay is a simple configuration item change
since no translation is needed.

=back

=head2 How Does MySQL::Replication Work

A MySQL::Replication replication topology is made up of:

=over

=item *

MySQL::Replication servers

Servers provide an API to retrieve queries from its local binlogs. A client
can request queries from arbitrary binlogs and file positions.

=item *

MySQL::Replication clients

Clients retrieve queries from a server and applies them to the local database.

=item *

MySQL::Replication relays

Relays provide a transparent caching query proxy for clients to connect to.
Relays are useful for reducing data transfers between multiple data centers
and reducing load on the servers. 

=back

=head3 MySQL::Replication Servers

A MySQL master runs a MySQL::Replication server, which serves queries from
its local binlogs e.g.: 

  db1.example.com:~$ MySQLReplicationServer.pl --binlog db1:/var/lib/mysql/binlogs/mysql-bin.index

The server running on C<db1.example.com> will serve queries from the binlogs
listed in C<mysql-bin.index>.

See L<MySQLReplicationServer.pl> for more information on servers.

=head3 MySQL::Replication Clients

A MySQL slave runs the MySQL::Replication client e.g.:

  db2.example.com:~$ MySQLReplicationClient.pl --srchost db1.example.com --srcbinlog db1

The client running on C<db2.example.com> will:

=over

=item *

Get the server position for C<db1.example.com> from the local database

=item *

Connect to the server running on C<db1.example.com>

=item *

Request queries, starting from its server position

=item *

Read the query response from the server

=item *

Execute the query on the local database

=item *

Update the server position in the local database

=item *

Wait for the next query response

=back

  +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com |
  +-----------------+       +-----------------+

To replicate from multiple masters, run multiple instances of the client e.g.:

  db2.example.com:~$ MySQLReplicationClient.pl --srchost db1.example.com --srcbinlog db1
  db2.example.com:~$ MySQLReplicationClient.pl --srchost db3.example.com --srcbinlog db3

  +-----------------+       +-----------------+       +-----------------+
  | db1.example.com | ----> | db2.example.com | <---- | db3.example.com |
  +-----------------+       +-----------------+       +-----------------+

Note that there is no restriction on where the client and server run. e.g.
having all databases replication to and from each other is possible:

  +-----------------+       +-----------------+       +-----------------+
  | db1.example.com | <---> | db2.example.com | <---> | db3.example.com |
  +-----------------+       +-----------------+       +-----------------+
           ^                                                   ^
           |                                                   |
           +---------------------------------------------------+

See L<MySQLReplicationClient.pl> for more information on clients.

=head3 MySQL::Replication Relays

A MySQL::Replication relay acts as a proxy cache. In a multi-layer replication
topology, middle layers run a MySQL::Replication relay e.g.:

  relay.example.com:~$ MySQLReplicationRelay.pl

The relay running on C<relay.example.com> will:

=over

=item *

Accept requests from connecting clients

=item *

If the relay can fulfill the request from its cache, it will serve them to the
client

=item *

If the relay cannot fulfill the request from its cache, it will:

=over

=item *

Connect directly to the server, or if specified, the next relay

=item *

Relay the request to the next layer

=item *

Read the query response

=item *

Cache the query response for future requests

=item *

Send the query response to the client

=item *

Wait for the next query response

=back

=back

  +-----------------+       +-------------------+       +-----------------+
  | db1.example.com | ----> | relay.example.com | ----> | db2.example.com |
  +-----------------+       +-------------------+       +-----------------+

By using relays:

=over

=item *

Bandwidth is saved since multiple clients in one data center need only connect
to the local relay, while the relay goes over the WAN to fulfill requests

=item *

Load is saved on the server since the number of connecting clients is reduced

=back

Note that there is no restriction on the number of layers of relays e.g. a
tree of relays is possible:

  +-----------------+
  | db2.example.com | <---------------+
  +-----------------+                 |
                                      |
  +-----------------+       +--------------------+       
  | db3.example.com | <---- | relay2.example.com | <----------------+ 
  +-----------------+       +--------------------+                  | 
                                                                    |
                                                         +--------------------+       +-----------------+
                                                         | relay1.example.com | <---- | db1.example.com |
                                                         +--------------------+       +-----------------+
                                                                    |
  +-----------------+       +--------------------+                  |
  | db4.example.com | <---- | relay3.example.com | <----------------+ 
  +-----------------+       +--------------------+       
                                      |
  +-----------------+                 |
  | db5.example.com | <---------------+
  +-----------------+ 

See L<MySQLReplicationRelay.pl> for more information on relays.

=head2 FAQs

=head3 What Happens If There Is A Race Condition On A Record

e.g. An insert to the C<users> table occurs on two seperate databases at the
same time for the C<username> 'alfie'. The problem here is that C<username> is
the primary key. Since the inserts happened at the same time, both inserts
succeeded. It is only when they replicate will a primary key constraint fail. 
If this happens, replication will stop and manual intervention is necessary.

The only way to prevent this is to avoid the race in the first place:

=over

=item *

Use an external arbiter to protect access to shared resources

e.g. before inserting into the C<users> table, each program performing the
insert contacts the arbiter and request the inserting of 'alfie'. The first
request is granted the insert while the others fail.

=item *

Shard your data so that race conditions cannot occur

e.g. the C<users> table is sharded based on the first letter of the usename.
Inserts for 'alfie' only happen on the database with write access to the 'a'
records.

=item *

Don't use C<AUTO_INCREMENT> keys, use UUIDs instead

Not useful in the C<users> example, but for tables where C<AUTO_INCREMENT> ids
are used, switch to UUIDs to avoid clashes.

=back

=head1 BUGS

=over

=item *

The relay is still in development and have not been released yet

=item *

Communication over the wire is in plain text. Only use MySQL::Replication over
a secure channel (e.g. stunnel, IPSec etc)

=item *

Row-based replication is not supported yet

=item *

LOAD DATA events are not supported yet

=item *

Filtering on queries, tables and schemas are not supported yet

=back

=head1 SEE ALSO

=over

=item *

L<MySQLReplicationClient.pl>

=item *

L<MySQLReplicationServer.pl>

=item *

L<MySQLReplicationRelay.pl>

=item *

L<https://github.com/alfie/MySQL--Replication>

=back

=head1 AUTHOR

Alfie John, C<alfiej@opera.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Opera Software Australia Pty. Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the copyright holder nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

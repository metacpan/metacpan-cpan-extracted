## Net::Z3950::SimpleServer - Simple Perl API for building Z39.50 servers.

The SimpleServer module is a tool for constructing Z39.50 "Information
Retrieval" servers in Perl. The module is easy to use, but it does
help to have an understanding of the Z39.50 query structure and the
construction of structured retrieval records.

Z39.50 is a network protocol for searching remote databases and
retrieving the results in the form of structured "records". It is
widely used in libraries around the world, as well as in the US
Federal Government. In addition, it is generally useful whenever you
wish to integrate a number of different database systems around a
shared, abstract data model.

The model of the module is simple: It implements a "generic" Z39.50
server, which invokes callback functions supplied by you to search for
content in your database. You can use any tools available in Perl to
supply the content, including modules like DBI and WWW::Search.

The server will take care of managing the network connections for you,
and it will spawn a new process (or thread, in some environments)
whenever a new connection is received.

### AUTHORS

 Anders Sønderberg <sondberg@indexdata.dk>

 Sebastian Hammer <quinn@indexdata.com>

 Mike Taylor <mike@indexdata.com>

 Adam Dickmeiss <adam@indexdata.com>

### COPYRIGHT AND LICENCE

See file LICENSE


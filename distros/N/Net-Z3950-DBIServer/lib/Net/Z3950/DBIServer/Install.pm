# $Header: /home/mike/cvs/mike/zSQLgate/lib/Net/Z3950/DBIServer/Install.pm,v 1.9 2005-04-20 09:56:24 mike Exp $

package Net::Z3950::DBIServer::Install;
use strict;


=head1 NAME

Net::Z3950::DBIServer::Install - The zSQLgate Installation Guide


=head1 SYNOPSIS

Before you can install C<zSQLgate>, you need to have already installed
both its front end, which speaks Z39.50, and its back end, which is a
relational database.  The front end is Index Data's
C<Net::Z3950::SimpleServer> module, which itself depends on their YAZ
toolkit.  The back end is Perl's DBI (DataBase Independent) module,
together with the driver for some particular RDBMS, plus the RDBMS
itself.


=head1 DESCRIPTION

C<zSQLgate>
provides an Z39.50 interface to your relational databases.
That is, it provides a generic gateway between the Z39.50 Information
Retrieval protocol and pretty much any relational database you
care to mention.

In order to provide a gateway between those two things, it needs those
two things to be there.  That means that there are quite a lot of
prerequisites, since both the Z39.50 front end and the relational
database back end are pretty complex systems.  And of course, you'll
need Perl itself - the language in which C<zSQLgate> is written.

This may appear a daunting list, but take heart!  You probably have
most of these things already.  It's pretty much impossible to buy a
Real Computer without Perl these days, for example.  And you probably
already have the database system that you want to build a gateway for
(otherwise why do you want a gateway to it?)

The following sections deal in some detail with the various things
that need to be installed.  The order they're listed in works fine:
you can just follow the list if you like.  But you don't need to
adhere to its exact order.  Here are the actual dependencies:

=over 4

=item *

C<zSQLgate> depends on SimpleServer and DBI configured with an
appropriate driver.

=item *

C<SimpleServer> depends on Perl and the YAZ toolkit.

=item *

The DBI driver depends on Perl, DBI and the relevant RDBMS.

=item *

DBI itself depends only on Perl.

=back

Basically, if you start with Perl, the database system and the YAZ
toolkit, none of which have any prerequisites, you should be OK.


=head1 THINGS TO INSTALL

=head2 Install Perl.

Building and installing Perl, if you don't already have it, it an
art-form in itself.  Reams have been written about the process, but
fortunately you should never have to read any of it, since pretty much
every Real Computer these days comes with Perl already installed - if
only because it's widely used behind the scenes for system
administration tasks.

To see if you have Perl, go to the shell prompt and type

	$ perl -e 'print 2+2'

If you get C<4>, you're OK, and can skip to the next section.  If you
get C<command not found>, you may not have Perl (or it may not be in
your path).  If you get C<5>, you've got real problems :-)

If you're running any kind of Unix (including Linux), then the odds
are good that your operating system's install media have a ready-to-go
Perl package that you can breathe into life.  If you're running on
Windows, then the best way to get Perl installed is to install Linux
and then ...  No, wait!  I promised myself not to get bogged down in
operating system evangelism :-) You should be able to get pre-built
Win32 binaries at http://www.cpan.org/ - the Comprehensive Perl
Archive Network.


=head2 Install an RDBMS.

If you already have the database that you want to build a Z39.50
gateway to, then you no doubt also have the RDBMS (relational database
management system) software that controls it; so you're OK.

If you're building a system from scratch, then you'll need to install
the database software.  That can be anything from a trivial to a
wizardly process.  At the simplest end of the scale, I did the bulk of
the C<zSQLgate> development work using a PostgreSQL database which I
installed from packages on my Red Hat 7.1 CD-ROM.  It went like this:

	# mount /mnt/cdrom
	# rpm -Uhv /mnt/cdrom/RedHat/RPMS/postgresql-7.0.3-8.i386.rpm
	# rpm -Uhv /mnt/cdrom/RedHat/RPMS/postgresql-server-7.0.3-8.i386.rpm 
	# rpm -Uhv /mnt/cdrom/RedHat/RPMS/postgresql-devel-7.0.3-8.i386.rpm 

(You need the core package for the client libraries; the server
package so you can run the server (duh!); and the the development
package so that you can build C<DBD::Pg> against its header files
later.)

Then I created the actual database:

	$ mkdir -p /usr/local/postgres/data
	$ initdb --pglib=/usr/lib/pgsql --pgdata=/usr/local/postgres/data
	$ postmaster -D /usr/local/postgres/data

More recently, I have been working with MySQL running on Debian
GNU/Linux, which I installed like this:

	# apt-get install mysql-client
	# apt-get install mysql-common
	# apt-get install mysql-server

But - this goes without saying, I am sure - these are just examples of
how two particular RDBMSs can be installed.  They are all very
different from each other.

Which RDBMS should you choose?  That's a whole subject in itself.  The
C<DBI::FAQ> document (section 3.7, I<What database do you recommend me
using?>) speaks highly of mSQL and MySQL (both of which used to be
free, and the latter of which still is) and Oracle and
Informix (both not at all free!).  To this list, I would add
PostgreSQL (also free, which helps, and it's part of recent Red Hat
distributions, hence my very easy installation).  Others say great
things about Sybase, or IBM's DB2; and at the other end of the scale,
there's a Perl module (C<DBD::CSV>) that presents an RDBMS-like
interface to boring old CVS files - that is, text files in which each
line is a record, with the fields separated by commas.

A few URLs:

=over 4

=item *

mSQL
at
http://www.hughes.com.au/products/msql/

=item *

MySQL
at
http://www.mysql.com/

=item *

Oracle
at
http://www.oracle.com/

=item *

Informix
at
http://www.informix.com/

=item *

PostgreSQL
at
http://www.postgresql.org/

=item *

Sybase
at
http://www.sybase.com/

=item *

DB2
at
http://www-3.ibm.com/software/data/db2/

=item *

C<DBD::CSV>
at
http://www.cpan.org/authors/id/J/JW/JWIED/

=back

Basically, this is a Holy War subject.  Use what works for you.  If
you really have no preference, then get one of the free ones: they're
good.


=head2 Install the DBI module.

Ah, now this is much easier.  C<DBI> is Perl's DataBase Independent
interface, which presents a uniform interface to pretty much any RDBMS
(and which is responsible for C<zSQLgate>'s multilinguality.)  In
principle, it's similar to ODBC, although it's very different in the
details.

C<DBI> is a refreshingly straightforward module to build and install,
using the standard sequence of commands:

	$ gunzip < DBI-1.20.tar.gz | tar xf -
	$ cd DBI-1.20
	$ perl Makefile.PL
	$ make
	$ make test
	$ su
	# make install

(You can find the C<DBI> module, like all respectable Perl modules, on
CPAN.  Versions 1.20 and 1.32 are known to work with zSQLgate, but all
more recent version will work fine, too, and there is no reason to
think that older versions won't.)


=head2 Install the DBI driver for the RDBMS of your choice.

C<DBI> provides the uniform front end to any RDBMS, but to make it
work, you need a I<driver> for for the specific RDBMS you want to use.
The drivers are found in modules with names of the form
C<DBD::>I<something> where I<something> is related to the name of the
RDBMS.  For example, the driver for PostgreSQL is called C<DBD::Pg>
and the driver for MySQL is called C<DBD::mysql>.
If you poke around on CPAN, you'll be able to find drivers for most of
the well-known RDBMSs, including all those discussed above.

Once you've fetched your driver (from CPAN, natch), you can unpack it
and build it just as you did with DBI itself: C<perl Makefile.PL>,
C<make>, C<make test> and then - as root - C<make install>.

Most DBI drivers need to be told at build time where the RDBMS is
installed.  Usually, the C<perl Makefile.PL> stage will complain if
you've not done this, or if you've got it wrong.  For example, in
order to build the PostgreSQL driver, I had to set two environment
variables specifying where the PostgreSQL libraries and header files
were:

	$ POSTGRES_LIB=/usr/lib  # location of libpq.so
	$ POSTGRES_INCLUDE=/usr/include/pgsql
	$ export POSTGRES_LIB POSTGRES_INCLUDE

But again, you'll have to do something different if you're using a
different RDBMS.  Consult your C<DBI> driver's documentation for
details.

Increasingly these days Linux distributions include pre-built packages
for the more commonly used DBD drivers.  For example, I installed the
MySQL driver on my Debian box like this:

	# apt-get install mysql-server libdbd-mysql-perl

=head2 Install the YAZ toolkit.

YAZ is written in C.  You'll need to download it from
http://www.indexdata.com/yaz/ and unpack it, then just:

	$ ./configure
	$ make
	$ su
	# make install

Yes, it's that easy.  No, nothing can go wrong.  Not only is YAZ
robust, efficient, battle tested and elegant code, it's also a cinch
to build.  Go, Index Data!


=head2 Install the Net::Z3950::SimpleServer module.

Penultimate lap.  You need the SimpleServer module on which
C<zSQLgate> is built: go to http://www.indexdata.com/simpleserver/ and
download it.  Unpack the archive, and do the usual Perl thing: C<perl
Makefile.PL>, C<make>, C<make test> and then, as root, C<make
install>.


=head2 Install zSQLgate itself.

You've surely got the hang of this by now?  :-)  Unpack the archive,
then C<perl Makefile.PL>, C<make> ...  Ah, you can figure the rest
out.  (OK, for those of a nervous disposition, the sequence ends:
C<make test> and then, as root, C<make install>)

Congratulations.  You're done!


=head2 ### Install XSLT support - see http://sql.z3950.org/xslt/


=head1 TROUBLESHOOTING

Here are a few of the thing that might go wrong:


=head2 No C Compiler

When you come to build C<DBI>, a C<DBI> driver, YAZ or the
SimpleServer module, you may find that the C<make> phase fails, saying
something like:

	make: cc: Command not found

This means you don't have a C compiler installed (or its not in your
path).  Go to your operating system's install media and remedy this
deficiency.  If the CD-ROM doesn't have a C compiler on it, then you
have problems: this used to happen a lot years ago - it was called
``unbundling'' - but it's thankfully very rare now except on Microsoft
operating systems.  If that's your problem, then your best best is
probably just to upgrade to a Real Computer.  Oops, sorry, it just
slipped out.


=head2 Missing DBI Driver

When you come to actually run C<zSQLgate>, you may find that it starts
correctly but dies when a client connects to it, saying something
like:

	install_driver(CSV) failed: Can't locate DBD/CSV.pm in @INC
	Perhaps the DBD::CSV perl module hasn't been fully installed,
	or perhaps the capitalisation of 'CSV' isn't right.
	Available drivers: ExampleP, Pg, Proxy.

Actually, this message is pretty clear: it's telling you that you've
not installed the driver that C<zSQLgate>'s configuration file wants
to use.  You'll need to go back to CPAN and find, download, unpack,
build and install the relevant driver.

(Why does this message only appear when a client connects?  Because
C<DBI> loads its drivers at run-time - in fact, at the point where it
tries to connect to the RDBMS - rather than when the Perl program is
compiled.  Which is, of course, because it can't tell in advance what
drivers you're going to want to use.)


=head1 HELP!

If all this just seems too much, or if you're really stuck,
installation consultancy is available from the author.  Email me.


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Thursday 7th March 2002.

=cut

1;

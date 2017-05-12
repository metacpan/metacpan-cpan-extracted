package Net::DNS::Dynamic::Proxyserver;

our $VERSION = '1.2';

use strict;
use warnings;

use Perl6::Junction qw( all any none one );

use Net::DNS;
use Net::DNS::Nameserver;

use POSIX qw( strftime );
use Carp;

use Moose;
use Moose::Util::TypeConstraints;

=head1 NAME

Net::DNS::Dynamic::Proxyserver - A dynamic DNS proxy-server

=head1 DESCRIPTION

This proxy-server is able to resolve incoming DNS queries by asking the /etc/hosts file
and/or a SQL database. You could run it as a simple proxy-server which just loops
through the DNS question/answer to other nameservers. However, it could also be
used to build your own dynamic DNS service, share one /etc/hosts file with all PC's in
your local network or to deliver different answers for hosts at different locations.

For example, if you have a home or office server behind NAT with port-forwarding and
want to connect to this server always with the same hostname based on your notebooks
location, you could run this dns-proxy to answer to your servers hostname with it's
internal RFC1918 IP when you are at home or in the office. When you're at a different
location and use an external nameserver, the hostname of your server will be resolved
with the "external" IP address (of your router).

If you like to build your own dynamic DNS service, you need to write your dynamic IP
addresses into a SQL databases and let your DNS proxy-server answer queries from it.

=head1 SYNOPSIS

 my $proxy = Net::DNS::Dynamic::Proxyserver->new(

     debug => 1,

     host => '*',
     port => 53,

     uid => 65534,
     gid => 65534,
     
     nameservers      => [ '127.0.0.1', '192.168.1.110' ],
     nameservers_port => 53,

     ask_etc_hosts => { ttl => 3600 },

     ask_sql => {
	 
         ttl => 60, 

         dsn => 'DBI:mysql:database=my_database;host=localhost;port=3306',
         user => 'my_user',
         pass => 'my_password',

         statement => "SELECT ip FROM hosts WHERE hostname='{qname}' AND type='{qtype}'"
     },
 );

 $proxy->run();

=head1 WORKFLOW

At startup, the file /etc/resolv.conf will be read and parsed. All defined nameservers will
be used to proxy through queries that can not be answered locally. If you define the 'ask_etc_hosts'
argument, then also the file /etc/hosts will be read at startup and will be used as the first
resource to answer DNS questions. If you make changes to /etc/hosts, you can send a kernel
signal HUP to your script, which will trigger a re-read of this file at run-time. The hosts-file
will only answer queries for type 'A' (name to IP) and 'PTR' (IP to name).

If you specify the 'ask_sql' argument, the SQL database will be asked in second order, right
after a look into the hosts file. The SQL statement will be parsed for every query with the
given query name and type. Your statement should return the IP address as the first column
in the result-set. Right now, only "forward lookups" are supported (PTR records can not
be resolved yet because we'd need a second, different SQL statement for that).

Then, if the query could not be answered from the hosts-file and/or the database, the question
will be handed over to the nameserves from your /etc/resolv.conf and the answer will be looped
trough to the caller.

=head1 Arguments to new()

The following options may be passed over when creating a new object:

=head2 debug Int

When the debug option is set to 1 or higher (1-3), this module will print out some
helpful debug informations to STDOUT. If you like, redirect the output to a
log-file, like so

./my-dns-proxy.pl >>/var/log/my_dns_proxy.log

A debug value of 1 prints out some basic action logging. A value of 2 and
higher turns on nameserver verbosity, a value of 3 and higher turns on resolver
debug output.

=head2 host String

You can specify the IP address to bind to with this option. If not defined, the
server binds to all interfaces.

Examples:

 my $proxy = Net::DNS::Dynamic::Proxyserver->new( host => '127.0.0.1' );

 my $proxy = Net::DNS::Dynamic::Proxyserver->new( host => '192.168.1.1' );

 my $proxy = Net::DNS::Dynamic::Proxyserver->new( host => '*' );

=head2 port Int

The tcp & udp port to run the DNS server under. Default is port 53, which means
that you need to start your script as user root (all ports below 1000 need root
rights).

  my $proxy = Net::DNS::Dynamic::Proxyserver->new( port => 5353 );

=head2 uid Int

The user id to switch to, after the socket has been created. Could be set to
the uid of 'nobody' (65534 on some systems).

  my $proxy = Net::DNS::Dynamic::Proxyserver->new( uid => 65534 );

=head2 gid Int

The group id to switch to, after the socket has been created. Could be set to
the gid of 'nogroup' (65534 on some systems).

  my $proxy = Net::DNS::Dynamic::Proxyserver->new( gid => 65534 );

=head2 nameservers ArrayRef

This argument allows to defined one or more nameservers to forward any DNS question
which can not be locally answered. Must be an Arrayref of IP addresses.

If you do not specify nameservers this way, the file /etc/resolv.conf will be read
instead and any nameserver defined there will be used.

 my $proxy = Net::DNS::Dynamic::Proxyserver->new( nameservers => [ '127.0.0.1', '192.168.1.110' ] );

=head2 nameservers_port Int

Specify the port of the remote nameservers. By default, this is set to 53 (the standard port),
but you can ovewrite it if you run a nameserver on a different port. This port will be used
for every nameserver - due to a limitation of Net::DNS::Resolver which cant deal with ports
for each individual nameserver.

 my $proxy = Net::DNS::Dynamic::Proxyserver->new( nameservers_port => 5353 );

=head2 ask_etc_hosts HashRef

If you'd like to anwer DNS queries from entries in your /etc/hosts file, then
define this argument like so:

 my $proxy = Net::DNS::Dynamic::Proxyserver->new( ask_etc_hosts => { ttl => 3600 } );

The only argument that can be passed to 'ask_etc_hosts' is the TTL (time to life) for
the response.

If 'ask_etc_hosts' is not defined, no queries to /etc/hosts will be made.

If you make changes to your /etc/hosts file, you can send your script a
signal HUP and it will re-read the file on the fly.

=head2 ask_sql HashRef

If you'd like to answer DNS queries from entries in your SQL database, then define
this argument like so:

  my $proxy = Net::DNS::Dynamic::Proxyserver->new( ask_sql => {
  	
  	ttl => 60, 
	dsn => 'DBI:mysql:database=db_name;host=localhost;port=3306',
	user => 'my_user',
	pass => 'my_password',
	statement => "SELECT ip FROM hosts WHERE hostname='{qname}' AND type='{qtype}'"
  } );

The 'ttl' specifies the TTL (time to life) for the DNS response. Setting this to a
low value will tell the client to ask you again after the TTL time has passed by;
which also means some higher load for your dns-proxy-server.

The 'dsn' is the 'data source name' for the DBI module. This information is used
to connect to your SQL database. You can use every flavour of SQL database that
is supported by DBI and a DBD::* module, like MySQL, PostgreSQL, SQLite, Oracle, etc...
Please have a look at the manual page of DBI and DBD::* to see how a dsn looks like
and which options it could contain.

The 'user' and 'pass' is the username and password for the connection to the database. If
you use SQLite, just leave the values empty (user => '', pass => ''). Also make sure, the
SQLite database file can be accessed (read/write) with the defined uid/gid!

The 'statement' is a SELECT statement, which must return the IP address for the
given query name (qname) and query type (qtype, like 'A' or 'MX'). The placeholders
{qname} and {qtype} will be replaced by the actual query name and type. Your statement
must return the IP address as the first column in the result.

If 'ask_sql' is not defined, no queries to a database will be made.

=cut

subtype 'Net.DNS.Dynamic.Proxyserver.ValidSQLArguments'
	=> as 'HashRef'
	=> where { $_->{dsn} && $_->{user} && $_->{pass} && $_->{statement} }
	=> message { "Mandatory elements missing in argument 'ask_sql': dsn, user, pass, statement" };

has debug			=> ( is => 'ro', isa => 'Int', required => 0, default => 0 );
has host			=> ( is => 'ro', isa => 'Str', required => 0, default => '*' );
has port			=> ( is => 'ro', isa => 'Int', required => 0, default => 53 );
has uid				=> ( is => 'ro', isa => 'Int', required => 0 );
has gid				=> ( is => 'ro', isa => 'Int', required => 0 );
has ask_etc_hosts	=> ( is => 'ro', isa => 'HashRef', required => 0 );
has ask_sql			=> ( is => 'ro', isa => 'Net.DNS.Dynamic.Proxyserver.ValidSQLArguments', required => 0 );

has addrs			=> ( is => 'rw', isa => 'HashRef', init_arg => undef );
has forwarders	 	=> ( is => 'rw', isa => 'ArrayRef', required => 0, init_arg => 'nameservers' );
has forwarders_port => ( is => 'ro', isa => 'Int', required => 0, init_arg => 'nameservers_port' );
has dbh				=> ( is => 'rw', isa => 'Object', init_arg => undef );

has nameserver		=> ( is => 'rw', isa => 'Net::DNS::Nameserver', init_arg => undef );
has resolver		=> ( is => 'rw', isa => 'Net::DNS::Resolver', init_arg => undef );

sub BUILD {
	my ( $self ) = shift;

	# initialize signal handlers
	#
	$SIG{KILL}	= sub { $self->signal_handler(@_) };
	$SIG{QUIT}	= sub { $self->signal_handler(@_) };
	$SIG{TERM}	= sub { $self->signal_handler(@_) };
	$SIG{INT}	= sub { $self->signal_handler(@_) };
	$SIG{HUP}	= sub { $self->read_config() };

	# slurp in /etc/hosts and /etc/resolv.conf
	#
	$self->read_config();

	# initialize nameserver object
	#
	my $ns = Net::DNS::Nameserver->new(

		LocalAddr		=> $self->host,
		LocalPort		=> $self->port,
		ReplyHandler	=> sub { $self->reply_handler(@_); },
		Verbose			=> ($self->debug > 1 ? 1 : 0)
	);

	$self->nameserver( $ns );

	# initialize resolver object
	#
	my $res = Net::DNS::Resolver->new(

		nameservers => [ @{$self->forwarders} ],
		port		=> $self->forwarders_port || 53,
		recurse     => 1,
		debug       => ($self->debug > 2 ? 1 : 0),
	);

	$self->resolver( $res );

	# change the effective user id and group id
	#
	$> = $self->uid if $self->uid;
	$) = $self->gid if $self->gid;
}

sub run {
	my ( $self ) = shift;
	
	$self->log("listening for DNS queries on address " . $self->host . " and port " . $self->port, 1);

	$self->log("Try a DNS query to your server: dig @" . ($self->host eq '*' ? '127.0.0.1' : $self->host ) . " -p " . $self->port . " -q hostname.domain.com");

	$self->nameserver->main_loop;
}

sub reply_handler {
	my ($self, $qname, $qclass, $qtype, $peerhost,$query,$conn) = @_;

	my ($rcode, @ans, @auth, @add);

	$self->log("received query from $peerhost: qtype '$qtype', qname '$qname'");

	# see if we can answer the question from /etc/hosts
	#
	if ($self->ask_etc_hosts && ($qtype eq 'A' || $qtype eq 'PTR')) {
	
		if (my $ip = $self->query_etc_hosts( $qname, $qtype )) {

			$self->log("[/etc/hosts] resolved $qname to $ip NOERROR");

			my ($ttl, $rdata) = (($self->ask_etc_hosts->{ttl} ? $self->ask_etc_hosts->{ttl} : 3600), $ip );
        
			push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");

			$rcode = "NOERROR";
			
			return ($rcode, \@ans, \@auth, \@add, { aa => 1, ra => 1 });
		}
	}

	# see if we can answer the question from the SQL database
	#
	if ($self->ask_sql) {
	
		if (my $ip = $self->query_sql( $qname, $qtype )) {
		
			$self->log("[SQL] resolved $qname to $ip NOERROR");

			my ($ttl, $rdata) = (($self->ask_sql->{ttl} ? $self->ask_sql->{ttl} : 3600), $ip );
        
			push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");

			$rcode = "NOERROR";
			
			return ($rcode, \@ans, \@auth, \@add, { aa => 1, ra => 1 });
		}
	}
	
	# forward to remote nameserver and loop through the result
	# 
	my $answer = $self->resolver->send($qname, $qtype, $qclass);

	if ($answer) {

       	$rcode = $answer->header->rcode;
       	@ans   = $answer->answer;
       	@auth  = $answer->authority;
       	@add   = $answer->additional;
    
		$self->log("[proxy] response from remote resolver: $qname $rcode");

		return ($rcode, \@ans, \@auth, \@add);
	}
	else {

		$self->log("[proxy] can not resolve $qtype $qname - no answer from remote resolver. Sending NXDOMAIN response.");

		$rcode = "NXDOMAIN";

		return ($rcode, \@ans, \@auth, \@add, { aa => 1, ra => 1 });
	}
}

sub log {
	my ( $self, $msg, $force_flag ) = @_;
	
	print "[" . strftime('%Y-%m-%d %H:%M:%S', localtime(time)) . "] " . $msg . "\n" if $self->debug || $force_flag;
}

sub read_config {
	my ( $self ) = shift;

	$self->forwarders([ $self->parse_resolv_conf() ]);		# /etc/resolv.conf
	$self->addrs({ $self->parse_etc_hosts() });				# /etc/hosts
}

sub signal_handler {
	my ( $self, $signal ) = @_;

	$self->log("shutting down because of signal $signal");

	$self->dbh->disconnect() if $self->dbh;

	exit;
}

sub query_etc_hosts {
	my ( $self, $qname, $qtype ) = @_;
	
	return $self->search_ip_by_hostname( $qname ) if $qtype eq 'A';
	return $self->search_hostname_by_ip( $qname ) if $qtype eq 'PTR';
}

sub search_ip_by_hostname {
	my ( $self, $hostname ) = @_;

	foreach my $ip (keys %{$self->addrs}) {
		
		if ( any(@{$self->addrs->{$ip}}) eq $hostname ) {
			
			return $ip;
		}
	}

	return;
}

sub search_hostname_by_ip {
	my ( $self, $ip ) = @_;

	$ip = $self->get_in_addr_arpa( $ip ) || return;

	return $self->addrs->{$ip}->[0] if $self->addrs->{$ip};

	return;
}

sub get_in_addr_arpa {
	my ( $self, $ptr ) = @_;

	# convert ipv4 -> 10.1.168.192.in-addr.arpa -> 192.168.1.10
	#
	my ($reverse_ip) = ($ptr =~ m!^([\d\.]+)\.in-addr\.arpa$!);

	return unless $reverse_ip;

	my @octets = reverse split(/\./, $reverse_ip);

	return join('.', @octets);
}

sub parse_etc_hosts {
	my ( $self ) = shift;

	return unless $self->ask_etc_hosts;

	$self->log('reading /etc/hosts file');

	my %addrs;
	my %names;

	open(HOSTS, "/etc/hosts") or croak "cant open /etc/hosts file: $!";

	while (<HOSTS>) {
		
		next if /^\s*#/;	# skip comments
		next if /^$/; 		# skip empty lines
		s/\s*#.*$//;		# delete in-line comments and preceding whitespace

	    my ($ip, @names) = split;

		next unless $ip =~ /^[\d\.]+$/;		# skip ipv6 adresses

	    push @{$addrs{$ip}}, @names;

	    foreach (@names) {

		    croak "The hostname $_ has been defined for more then one IP address!\n" if exists $names{$_};

		    $names{$_} = $ip;
	    }
	}

	close(HOSTS);

	return %addrs;
}

sub parse_resolv_conf {
	my ( $self ) = shift;
	
	return @{$self->forwarders} if $self->forwarders;

	$self->log('reading /etc/resolv.conf file');

	my @dns_servers;
	
	open (RESOLV, "/etc/resolv.conf") || croak "cant open /etc/resolv.conf file: $!";
	
	while (<RESOLV>) {
		
		if (/^nameserver\s+([\d\.]+)/) {
			
			push @dns_servers, $1;
		}
	}

	close (RESOLV);
	
	croak "you have not specified a nameserver in /etc/resolv.conf!" unless @dns_servers;
	
	return @dns_servers;
}

sub query_sql {
	my ( $self, $qname, $qtype ) = @_;

	use DBI;
	
	my $args = $self->ask_sql;

	# see if we have an open database handle already, which we can re-use
	#
	unless ($self->dbh && $self->dbh->ping()) {
	
		# connect
		#
		my $dbh = DBI->connect( $args->{dsn}, $args->{user}, $args->{pass} ) || croak "can not connect to database $args->{dsn} $!";

		$self->dbh( $dbh );
	}
	
	$qname = $self->get_in_addr_arpa( $qname ) if $qtype eq 'PTR';

	# parse the statement variables
	#
	$qname =~ s!'!!g;
	$qtype =~ s!'!!g;
	
	my $statement = $args->{statement};
	
	$statement =~ s!{qname}!$qname!g;
	$statement =~ s!{qtype}!$qtype!g;

	my $sth = $self->dbh->prepare( $statement );

	$sth->execute();

	# we expect exact one column to come back from the SQL statement - the IP address of the given hostname and query type
	#
	my $result = $sth->fetchrow_arrayref();
	
	return $result->[0];
}

=head1 AUTHOR

Marc Sebastian Jakobs <maja@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marc Sebastian Jakobs

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


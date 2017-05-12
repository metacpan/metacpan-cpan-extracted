package Squid::Guard;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.15';

use Carp;
use DB_File;
use Fcntl;
use Squid::Guard::Request;

=head1 NAME

Squid::Guard - Redirector for the Squid web proxy

=head1 SYNOPSYS

    use Squid::Guard;

    my $sg = Squid::Guard->new();

    $sg->redir("http://proxy/cgi-bin/deny.pl";);

    $sg->checkf(\&check);

    $sg->run;

=head1 DESCRIPTION

Squid::Guard is a module for creating a simple yet flexible
redirector for the Squid web cache engine.
This module was inspired by squidGuard, a popular squid redirector
written in C, but aims to be more flexible and in some ways simpler
to use.
I was happy with squidGuard and used it for years. But I needed
certain extra features like the ability to differentiate
between users based on some external program output, group
belongings etc.
squidGuard did not support this, so Squid::Guard was born.


=head2 Squid::Guard->new( opt => val, ...)

API call to create a new server.  Does not actually start running anything until you call C<-E<gt>run()>.

=cut

sub new {
	my $class = shift;
	my %opts = @_;

	my $self  = {};

	$self->{dbdir}          = undef;
	$self->{forcedbupdate}  = 0;
	$self->{checkf}         = undef;
	$self->{concurrency}    = 0;
	$self->{categ}          = {};
	$self->{redir}          = ();
	$self->{strictauth}     = 0;
	$self->{verbose}        = 0;
	$self->{debug}          = 0;
	$self->{oneshot}        = 0;

	for( keys %opts ) {
		$self->{$_} = $opts{$_};
	}

	bless($self, $class);
	return $self;
}


=head2 $sg->redir()

Get/set the redir page.
The following macros are supported:

=over

=item %u	the requested url

=item %p	the path and the optional query string of %u, but note for convenience without the leading "/"

=item %a	the client IP address 

=item %n	the client FQDN

=item %i	the user name, if available

=item %t	the C<checkf> function result (see)

=item %%	the % sign

=back

If set to the special value C<CHECKF>, then the return value of the checkf function, if true, is used directly as the redirection url

=cut

sub redir {
	my $self = shift;
	if (@_) { $self->{redir} = shift }
	return $self->{redir};
}


=head2 $sg->checkf()

Sets the check callback function, which is called upn each request received.
The check function receives as arguments the current C<Squid::Guard> object, and a L<Squid::Guard::Request> object on which the user can perform tests.
A false return value means no redirection is to be proformed. A true return value means that the request is to be redirected to what was declared with C<redir()>.

=cut

sub checkf {
	my $self = shift;
	my $funcref = shift;
	$self->{checkf} = $funcref;
}


=head2 $sg->concurrency()

Enables the concurrency protocol. For now, the implementation is rather poor: the ID is simply read and echoed to squid.
See url_rewrite_concurrency in squid.conf

=cut

sub concurrency {
	my $self = shift;
	my $num = shift;
	$self->{concurrency} = $num;
}


my $cachettl = 0;
my $cachepurgelastrun = 0;
my %cacheh;	# this contains the real cache items
my @cachea;	# this contains the cache keys with the time they where written in the cache.

=head2 $sg->cache()

Enables caching in expensive subs which involve spawning external processes. At the moment, caching is implemented in C<checkinwbgroup()> (which calls wbinfo 3 times) and in C<checkingroup()> (which can be expensive in some nss configurations).
An argument must be suplied, representing the time to live of cached items, in seconds.
The time to live, as the whole cached objects, are shared among all the objects belonging to this class. No problem since usually only one object is in use.

=cut

sub cache {
	my $self = shift;
	my $ttl = shift;
	$cachettl = $ttl;
}


sub _cachepurge() {
	my $time = time();
	return if $cachepurgelastrun == $time;	# do not purge too often
	$cachepurgelastrun = $time;

        my $t = $time - $cachettl;

	return unless @cachea;			# try to avoid looping through if unnecessary
	return if $cachea[0]->[0] > $t;

	my $ndel = 0;
        LOOP: foreach my $p ( @cachea ) {
                last LOOP if $p->[0] > $t;

                my $k = $p->[1];
                delete( $cacheh{$k} ) if defined( $cacheh{$k} ) && $cacheh{$k}->[0] <= $t;

		$ndel++;
        }
	
	$ndel and splice(@cachea, 0, $ndel);
}


sub _cachewr($$) {
        my ($k, $v) = @_;
	defined($v) or $v = "";	# be sure not to cache undef values since _cacherd returns undef when the value is not in the cache

        my $t = time;

        my @arr = ( $t, $v );
        $cacheh{$k} = \@arr;

        my @arra = ($t, $k);
        push @cachea, \@arra;
}


sub _cacherd($) {
        my ($k) = @_;
	# Purge the cache when reading from it. This also ensures that the remaining cache record are in their ttl. This could be done in other occasions too
	_cachepurge();
        return defined($cacheh{$k}) ? $cacheh{$k}->[1] : undef;
}


=head2 $sg->verbose()

Get/set verbosity. Currently only one level of verbosity is supported

=cut

sub verbose {
	my $self = shift;
	if (@_) { $self->{verbose} = shift }
	return $self->{verbose};
}


=head2 $sg->debug()

Emit debug info

=cut

sub debug {
	my $self = shift;
	if (@_) { $self->{debug} = shift }
	$self->{debug} and $self->{verbose} = $self->{debug};
	return $self->{debug};
}


=head2 $sg->oneshot()

Executes only a single iteration then exits (can be used when debugging)

=cut

sub oneshot {
	my $self = shift;
	if (@_) { $self->{oneshot} = shift }
	return $self->{oneshot};
}


=head2 $sg->handle($req)

Handles a request, returning the empty string or the redirected url.
The request can be either a string in the format passed to the redirector by squid, or a Squid::Guard::Request object.
This sub is usually called internally by run() to handle a request, but can be called directly too.

=cut

sub handle {
	my $self = shift;

	return "" unless $self->{checkf};

	my $arg = shift;
	my $req = ref($arg) ? $arg : Squid::Guard::Request->new($arg);

	my $redir = "";

	my $res = $self->{checkf}->( $self, $req );
	if( $res ) {
		if( $self->{redir} eq 'CHECKF' ) {
			$redir = $res;
		} else {
			$redir = $self->{redir} || croak "A request was submitted, but redir url is not defined";
			$redir =~ s/(?<!%)%a/$req->addr/ge;
			$redir =~ s/(?<!%)%n/$req->fqdn or "unknown"/ge;
			my $i = $req->ident || "unknown";
			$i =~ s/([^-._A-Za-z0-9])/sprintf("%%%02X", ord($1))/eg;
			$redir =~ s/(?<!%)%i/$i/g;
			#$redir =~ s/(?<!%)%s//;	# Contrary to squidGuard, it does not mean anything to us
			$redir =~ s/(?<!%)%u/$req->url/ge;
			my $pq = $req->path_query;
			$pq =~ s-^/--o;
			$redir =~ s/(?<!%)%p/$pq/g;
			my $r = $res;
			$r =~ s/([^-._A-Za-z0-9])/sprintf("%%%02X", ord($1))/eg;
			$redir =~ s/(?<!%)%t/$r/g;
			$redir =~ s/%%/%/;

# Redirections seem not to be understood when the request was for HTTPS.
# Info taken from http://www.mail-archive.com/squid-users@squid-cache.org/msg58422.html :
# Squid is a little awkward:
# the URL returned by squidguard must have the protocol as the original URL.
# So for a URL with HTTPS protocol, squidguard must return a URL that uses the HTTPS protocol.
# This is really not nice but the workaround is to use a 302 redirection:
#   redirect        302:http://www.internal-server.com/blocked.html

# another one on the issue: http://www.techienuggets.com/Comments?tx=114527
# Blocking/filtering SSL pages with SquidGuard do not work very well. You
# need to use Squid acls for that, or wrap up SquidGuard as an external
# acl instead of url rewriter..
#
# The reason is that
# a) Most browsers will not accept a browser redirect in response to
# CONNECT.
#
# b) You can't rewrite a CONNECT request into a http:// requrest.
#
# c) Most browsers will be quite upset if you rewrite the CONNECT to a
# different host than requested.
#
# meaning that there is not much you actually can do with CONNECT requests
# in SquidGuard that won't make browsers upset.

# So let's redirect.
# Maybe we should check if $url begins with http:// .

			if( $req->method eq 'CONNECT' ) {
				$redir = "302:$redir";
			}
		}
	}

	return $redir;
}


=head2 $sg->run()

Starts handling the requests, reading them from <STDIN> one per line in the format used by Squid to talk to the url_rewrite_program

=cut

sub run {
        my $self = shift;

	$self->{redir} || croak "Can not run when redir url is not defined";

	$|=1;   # force a flush after every print on STDOUT

	while (<STDIN>) {

		chomp;
		$self->{verbose} and print STDERR "Examining $_\n";

		my $ret = "";
		if( $self->{concurrency} ) {
			s/^(\d+\s+)//o;
			$ret = $1;
		}

		my $redir = $self->handle($_);

		if( $redir ) {
			$self->{verbose} and print STDERR "Returning $redir\n";
			$ret .= $redir;
		}

		print "$ret\n";

		last if $self->{oneshot};
	}
}


=head2 Black/white-list support

Squid::Guard provides support for using precompiled black or white lists, in a way similar to what squidGuard does. These lists are organized in categories. Each category has its own path (a directory) where three files can reside. These files are named domains, urls and expressions. There's no need for all three to be there, and in most situations only the domains and urls files are used. These files list domains, urls and/or (regular) expressions which describe if a request belong to the category. You can decide, in the checkf function, to allow or to redirect a request belonging to a certain category.
Similarly to what squidGuard does, the domains and urls files have to be compiled in .db form prior to be used. This makes it possible to run huge domains and urls lists, with acceptable performance.
You can find precompiled lists on the net, or create your own.
Beginning with version 0.13, there is EXPERIMENTAL support for the userdomains file. This file lists domains associated with users. The request will be checked against the domains only if the request has the associated identity corresponding to the user. The file is made of lines in the format C<user|domain>. At the moment, the file is entirely read in memory and no corresponding .db is generated/needed. The userdomain feature is EXPERIMENTAL and subject to change.

=head2 $sg->dbdir()

Get/set dbdir parameter, i.e. the directory where category subdirs are found. .db files generated from domains and urls files will reside here too.

=cut

sub dbdir {
	my $self = shift;
	if (@_) { $self->{dbdir} = shift }
	return $self->{dbdir};
}


=head2 $sg->addcateg( name => path, ... )

Adds one or more categories.
C<path> is the directory, relative to dbdir, containing the C<domains>, C<urls>, C<expressions> and C<userdomains> files.

=cut

sub addcateg {
	my $self = shift;
	my %h = ( @_ );
	foreach my $cat (keys %h) {
		$self->{categ}->{$cat}->{loc} = $h{$cat};

		my $l = $self->{dbdir} . '/' . $self->{categ}->{$cat}->{loc};
		#print STDERR "$l\n";

		my $domsrc = "${l}/domains";
		my $domdb = "${domsrc}.db";
		if( -f $domsrc ) {
			# tie .db for reading
			my %h;
			my $X = tie (%h, 'DB_File', $domdb, O_RDONLY, 0644, $DB_BTREE) || croak ("Cannot open $domdb: $!");
			$self->{categ}->{$cat}->{d} = \%h;
			$self->{categ}->{$cat}->{dX} = $X;
		}

		my $urlsrc = "${l}/urls";
		my $urldb = "${urlsrc}.db";
		if( -f $urlsrc ) {
			# tie .db for reading
			my %h;
			my $X = tie (%h, 'DB_File', $urldb, O_RDONLY, 0644, $DB_BTREE) || croak ("Cannot open $urldb: $!");
			$self->{categ}->{$cat}->{u} = \%h;
			$self->{categ}->{$cat}->{uX} = $X;
		}

		my $e = "$l/expressions";
		if( -f $e ) {
			my @a;
			open( E, "< $e" ) or croak "Cannot open $e: $!";
			while( <E> ) {
				chomp;
				s/#.*//o;
				next if /^\s*$/o;
				push @a, qr/$_/i;	# array of regexps. Can't use 'o' regexp option, since I would put in the array always the same regexp (the first one). But it seems that with qr, 'o' is obsolete.
			}
			close E;
			$self->{categ}->{$cat}->{e} = \@a;
		}

		my $ud = "$l/userdomains";
		if( -f $ud ) {
			my $hr = {};
			open( UD, "< $ud" ) or croak "Cannot open $ud: $!";
			while( <UD> ) {
				chomp;
				s/#.*//o;
				next unless /^\s*([^\|]+)\|(.*\S)/o;
				$hr->{$1}->{$2} = 1;
			}
			close UD;
			$self->{categ}->{$cat}->{ud} = $hr;
		}
	}
	return 1;
}


=head2 $sg->mkdb( name => path, ... )

Creates/updates the .db files for the categories.
Will search in C<path> for the potential presence of the C<domains> and C<urls> plaintext files.
According to the value of the C<forcedbupdate> flag (see), will create or update the .db file from them.

=cut

sub mkdb {
	my $self = shift;
	my %h = ( @_ );
	foreach my $cat (keys %h) {
		$self->{categ}->{$cat}->{loc} = $h{$cat};

		my $l = $self->{dbdir} . '/' . $self->{categ}->{$cat}->{loc};
		#print STDERR "$l\n";

		my $domsrc = "${l}/domains";
		my $domdb = "${domsrc}.db";
		if( -f $domsrc ) {
			# update .db, if needed
			if( $self->{forcedbupdate} || (stat($domsrc))[9] > ( (stat($domdb))[9] || 0 ) ) {
				$self->{verbose} and print STDERR "Making $domdb\n";
				my %h;
				my $X = tie (%h, 'DB_File', $domdb, O_CREAT|O_TRUNC|O_RDWR, 0644, $DB_BTREE) || croak ("Cannot create $domdb: $!");
				open( F, "< $domsrc") or croak "Cannot open $domsrc";
				while( <F> ) {
					chomp;
					s/#.*//o;
					next if /^\s*$/o;
					$h{lc($_)} = undef;
				}
				close F;
				undef $X;
				untie %h;
			} else {
				$self->{verbose} and print STDERR "$domdb more recent than $domsrc, skipped\n";
			}
		}

		my $urlsrc = "${l}/urls";
		my $urldb = "${urlsrc}.db";
		if( -f $urlsrc ) {
			# update .db, if needed
			if( $self->{forcedbupdate} || (stat($urlsrc))[9] > ( (stat($urldb))[9] || 0 ) ) {
				$self->{verbose} and print STDERR "Making $urldb\n";
				my %h;
				my $X = tie (%h, 'DB_File', $urldb, O_CREAT|O_TRUNC|O_RDWR, 0644, $DB_BTREE) || croak ("Cannot create $urldb: $!");
				open( F, "< $urlsrc") or croak "Cannot open $urlsrc";
				while( <F> ) {
					chomp;
					s/#.*//o;
					next if /^\s*$/o;
					$h{lc($_)} = undef;
				}
				close F;
				undef $X;
				untie %h;
			} else {
				$self->{verbose} and print STDERR "$urldb more recent than $urlsrc, skipped\n";
			}
		}
	}
	return 1;
}


=head2 $sg->forcedbupdate()

Controls whether mkdb should forcibly update the .db files.
If set to a false value (which is the default), existing .db files are refreshed only if older than the respective plaintext file.
If set to a true value, .db files are always (re)created.

=cut

sub forcedbupdate {
	my $self = shift;
	if (@_) { $self->{forcedbupdate} = shift }
	return $self->{forcedbupdate};
}


#=head2 $sg->getcateg()
#
#Gets the defined categories
#
#=cut
#
#sub getcateg {
#	my $self = shift;
#	my %h;
#	for( keys %{$self->{categ}} ) {
#		$h{$_} = $self->{categ}->{$_}->{loc};
#	}
#	return %h;
#}


# =head2 $sg->_domains()
# 
# Finds the super-domains where the given domain is nested.
# This is a helper sub for C<checkincateg>
# 
# =cut

sub _domains($) {
	my $host = shift;
	return () unless $host;
	# www . iotti . biz
	#  0      1      2
	my @a = split(/\./, $host);
	my $num = $#a;
	my @b;
	for( 0 .. $num ) {
		my $j = $num - $_;
		push @b, join(".", @a[$j .. $num]);
	}
	return @b;
}


# =head2 $sg->_uris()
# 
# Finds the uris containing the given uri.
# This is a helper sub for C<checkincateg>
# 
# =cut

sub _uris($) {
	my $uri = shift;
	return () unless $uri;
	# www.iotti.biz / dir1 / dir2 / dir3 / file
	#       0          1      2      3      4
	my @a = split(/\//, $uri);
	my $num = $#a;
	my @b;
	for( 0 .. $num ) {
		my $sub_uri = join("/", @a[0 .. $_]);
		push @b, $sub_uri;
		push @b, $sub_uri . '/' if $_ < $num;	# check www.iotti.biz/dir/ too (with the trailing slashe) since some publicly-available lists carry urls with trailing slashes
	}
	return @b;
}


=head2 $sg->checkincateg($req, $categ, ... )

Checks if a request is in one category or more

=cut

sub checkincateg($$@) {
	my ( $self, $req, @categs ) = @_;

	foreach my $categ (@categs) {
		my $catref = $self->{categ};
		defined( $catref->{$categ} ) or croak "The requested category $categ does not exist";

		#print STDERR "s $req->scheme h $req->host p $req->path\n";
		if( defined( $catref->{$categ}->{d} ) ) {
			$self->{debug} and print STDERR " Check " . $req->host . " in $categ domains\n";
			my $ref = $catref->{$categ}->{d};
			foreach( _domains($req->host) ) {
				$self->{debug} and print STDERR "  Check $_\n";
				if(exists($ref->{$_})) {
					$self->{debug} and print STDERR "   FOUND\n";
					return $categ;
				}
			}
		}
		if( defined( $catref->{$categ}->{u} ) ) {
			# in url checking, we test the authority part + the optional path part + the optional query part
			my $what = $req->authority_path_query;
			$self->{debug} and print STDERR " Check $what in $categ urls\n";
			my $ref = $catref->{$categ}->{u};
			foreach( _uris($what) ) {
				$self->{debug} and print STDERR "  Check $_\n";
				if(exists($ref->{$_})) {
					$self->{debug} and print STDERR "   FOUND\n";
					return $categ;
				}
			}
		}
		if( defined( $catref->{$categ}->{e} ) ) {
			my $what = $req->url;
			$self->{debug} and print STDERR " Check $what in $categ expressions\n";
			my $ref = $catref->{$categ}->{e};
			foreach( @$ref ) {
				$self->{debug} and print STDERR "  Check $_\n";
				if( $what =~ /$_/i ) {	# Can't use 'o' regexp option, since I would compare always the same regexp.
					$self->{debug} and print STDERR "   FOUND\n";
					return $categ;
				}
			}
		}
		if( $req->ident and defined( $catref->{$categ}->{ud}->{$req->ident} ) ) {
			$self->{debug} and print STDERR " Check " . $req->host . " in $categ userdomains for user " . $req->ident . "\n";
			my $hr = $catref->{$categ}->{ud}->{$req->ident};
			# TODO: optimization: precompile _domains($req->host) only once for domains and userdomains
			foreach( _domains($req->host) ) {
				$self->{debug} and print STDERR "  Check $_\n";
				if($hr->{$_}) {
					$self->{debug} and print STDERR "   FOUND\n";
					return $categ;
				}
			}
		}
	}

	return '';
}


# Gets a passwd row, making use of the cache if enabled.

sub _getpwnamcache($) {
	my $nam = shift;
	my $k = "PWNAM: $nam";

	if( $cachettl ) {
		my $v = _cacherd( $k );
		defined($v) and return split( /:/, $v );
	}

	my @a = getpwnam($nam);

	if( $cachettl ) {
		_cachewr( $k, join( ':', @a ) );
	}

	return @a;
}


sub _getgrnamcache($) {
	my $nam = shift;
	my $k = "GRNAM: $nam";

	if( $cachettl ) {
		my $v = _cacherd( $k );
		defined($v) and return split( /:/, $v );
	}

	my @a = getgrnam($nam);

	if( $cachettl ) {
		_cachewr( $k, join( ':', @a ) );
	}

	return @a;
}


# Runs a command, making use of the cache if enabled.

sub _runcache($) {
	my $cmd = shift;
	my $k = "RUN: $cmd";

	my $v;
	if( $cachettl ) {
		$v = _cacherd( $k );
		defined($v) and return $v;
	}

	$v = `$cmd`;

	if( $cachettl ) {
		_cachewr( $k, $v );
	}

	return $v;
}


=head2 Other help subs that can be used in the checkf function


=head2 $sg->checkingroup($user, $group, ... )

Checks if a user is in a UNIX grop

=cut

sub checkingroup($$@) {
	my ( $self, $user, @groups ) = @_;

	return 0 unless $user;

	my @pwent = _getpwnamcache($user);
	if( ! @pwent ) {
		print STDERR "Can not find user $user\n";
		return '';
	}

	my $uid      = $pwent[2];
	my $uprimgid = $pwent[3];
	if( ! defined $uid || ! defined $uprimgid ) {
		print STDERR "Can not find uid and gid corresponding to $user\n";
		return '';
	}

	foreach my $group (@groups) {
		my @grent = _getgrnamcache($group);
		if( ! @grent ) {
			print STDERR "Can not find group $group\n";
			next;
		}

		my $gid = $grent[2];
		if( ! defined $gid ) {
			print STDERR "Can not find gid corresponding to $group\n";
			next;
		}

		if( $uprimgid == $gid ) {
			$self->{debug} and print STDERR "FOUND $user has primary group $group\n";
			return $group;
		}

		my @membri = split(/\s+/, $grent[3]);
		$self->{debug} and print STDERR "Group $group contains:\n" . join("\n", @membri) . "\n";
		for(@membri) {
			my @pwent2 = _getpwnamcache($_);
			my $uid2 = $pwent2[2];
			if( ! defined $uid2 ) {
				print STDERR "Can not find uid corresponding to $_\n";
				next;
			}
			if( $uid2 == $uid ) {
				$self->{debug} and print STDERR "FOUND $user is in $group\n";
				return $group;
			}
		}
	}

	return '';
}


=head2 $sg->checkinwbgroup($user, $group, ...)

Checks if a user is in a WinBind grop

=cut

sub checkinwbgroup($$@) {
	my ( $self, $user, @groups ) = @_;

	return '' unless $user;

	my $userSID = _runcache("wbinfo -n '$user'");
	if( $? ) {
		print STDERR "Can not find user $user in winbind\n";
		return '';
	}
	$userSID =~ s/\s.*//o;
	chomp $userSID;
	$self->{debug} and print STDERR "Found user $user with SID $userSID\n";

	my %groupsSIDs;
	foreach my $group (@groups) {
		my $groupSID = _runcache("wbinfo -n '$group'");
		if( $? ) {
			print STDERR "Can not find group $group in winbind\n";
			return '';
		}
		$groupSID =~ s/\s.*//o;
		chomp $groupSID;
		$self->{debug} and print STDERR "Found group $group with SID $groupSID\n";
		$groupsSIDs{$groupSID} = $group;
	}

	my @userInSIDs = _runcache("wbinfo --user-domgroups '$userSID'");
	if( $? ) {
		print STDERR "Can not find the SIDs of the groups of $user - $userSID\n";
		return '';
	}
	$self->{debug} and print STDERR "$user is in the following groups:\n @userInSIDs";

	foreach ( @userInSIDs ) {
		chomp;
		if ( $groupsSIDs{$_} ) {
			$self->{debug} and print STDERR "   FOUND\n";
			return $groupsSIDs{$_};
		}
	}

	return '';
}


=head2 $sg->checkinaddr($req)

Checks if a request is for an explicit IP address

=cut

sub checkinaddr($$) {
        my ( $self, $req ) = @_;
	# TODO: Maybe the test should be more accurate and more general
	return 1 if $req->host =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/o;
	return 0;
}


1;

__END__

=head1 AUTHOR

Luigi Iotti, E<lt>luigi@iotti.bizE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Luigi Iotti

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

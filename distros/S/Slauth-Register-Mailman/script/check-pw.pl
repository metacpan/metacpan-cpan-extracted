#!/usr/bin/suidperl

use strict;
our ( $debug, $list_domain, $email, $pw, $list_domain_ut, $email_ut, $pw_ut,
	$dir, @lists, $list, %list_info, $pw_match, @subs, %names,
	$auth_req );

# make tainted environment happy
#delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
%ENV = ();
$ENV{PATH} = "/bin:/usr/bin";
#$debug = 1;

# set autoflush on STDOUT
$| = 1;

#
# function defintions
#

# return successful run (search completed, result may be failure or success)
sub success
{
	print "status: success\n";
	foreach ( @_ ) {
		print "$_\n";
	}
	exit 0;
}

# return fatal error
sub fail
{
	my $text = shift;
	print "status: failure\n";
	print "$text\n";
	exit 1;
}

# extract parameters for requested address from list configuration
sub read_list
{
	my $list = shift;

	open ( dumpdb_pipe, "$dir/bin/dumpdb --pickle $dir/lists/$list/config.pck |" )
		or fail "couldn't read list info for $list: $!";
	my $dumpdb = join ( '', <dumpdb_pipe> );
	close dumpdb_pipe
		or fail "couldn't close list info for $list: $!";

	my ( %result );
	if ( $dumpdb =~ /'accept_these_nonmembers': \[([^\]]+)\],/so ) {
		my $accept_these_nonmembers = $1;
		if ( $accept_these_nonmembers =~ /'$email_ut'/ ) {
			$result{accept_these_nonmembers} = 1;
		}
	}
	if ( $dumpdb =~ /'members': \{([^\}]+)\},/so ) {
		my $members = $1;
		if ( $members =~ /'$email_ut': ([0-9]+)/ ) {
			$result{member} = $1;
		}
	}
	if ( $dumpdb =~ /'passwords': \{([^\}]+)\},/so ) {
		my $passwords = $1;
		if ( $passwords =~ /'$email_ut': '([^']+)'/ ) {
			$result{password} = $1;
		}
	}
	if ( $dumpdb =~ /'user_options': \{([^\}]+)\},/so ) {
		my $user_options = $1;
		if ( $user_options =~ /'$email_ut': ([0-9]+)/ ) {
			$result{user_options} = $1;
		}
	}
	if ( $dumpdb =~ /'usernames': \{([^\}]+)\},/so ) {
		my $usernames = $1;
		if ( $usernames =~ /'$email_ut': u'([^']+)'/ ) {
			$result{usernames} = $1;
		}
	}

	return \%result;
}

#
# main
#

# check if setgid is needed
if ( $( != $) ) {
	$( = $);
}

# read parameters from STDIN (usually a pipe except for debugging)
$list_domain = <STDIN>;
$email = <STDIN>;
$pw = <STDIN>;
close STDIN;

# chomp newlines
chomp $list_domain;
$debug and print STDERR "list_domain = $list_domain\n";
chomp $email;
$debug and print STDERR "email = $email\n";
chomp $pw;
$debug and print STDERR "pw = $pw\n";

# force $list_domain and $email to lower case
$list_domain = lc($list_domain);
$email = lc($email);

# fixup domain name - remove www prefix if present
$list_domain =~ s/^www\.//;

# untaint inputs
if ( $list_domain =~ /^([a-z0-9_.-]+)$/ ) {
	$list_domain_ut = $1;
	$debug and print STDERR "list_domain_ut = $list_domain_ut\n";
}
if ( $email =~ /^([a-z0-9_.+=$&*\/-]+\@[a-z0-9_.-]+)$/ ) {
	$email_ut = $1;
	$debug and print STDERR "email_ut = $email_ut\n";
}
if ( $pw =~ /^(\S+)$/ ) {
	$pw_ut = $1;
	$debug and print STDERR "pw_ut = $pw_ut\n";
}

# check if we're doing an authenticated query
$auth_req = 1;  # default
if ( $pw eq "***unauthenticated query***" ) {
	$auth_req = 0;
}

# locate Mailman directory for this domain
$dir = "/home/mailman/$list_domain_ut";
( -d $dir ) or fail ( "lists not found for domain" );

# get list of mailman lists
opendir(DIR, "$dir/lists" ) || fail ( "can't opendir $dir/lists: $!" );
@lists = grep { ! /^\./ and -d "$dir/lists/$_" } readdir(DIR);
closedir DIR;

# loop through the lists collecting info
$pw_match = 0;
foreach $list ( @lists ) {
	my $list_res;
	( $list =~ /^(\S+)$/ ) or next;
	$list_res = read_list( $1 );
	if ( defined $list_res ) {
		$list_info{$list} = $list_res;
		if ( $list_info{$list}{password} eq $pw_ut ) {
			 $pw_match = 1;
		}
		if ( defined $list_info{$list}{member}) {
			push @subs, $list;
		}
		#if ( defined $list_info{$list}{accept_these_nonmembers}) {
		#	push @subs, $list;
		#}
		if ( defined $list_info{$list}{username}) {
			if ( length($list_info{$list}{username}) > 0 ) {
				$names{$list_info{$list}{username}} = 1;
			}
		}
	}
}

$debug and print STDERR "auth_req=$auth_req pw_match = $pw_match\n";
if ( $auth_req and !$pw_match ) {
	success ( "search-status: failure" );
}

my @name_headers;
foreach ( sort keys( %names )) {
	push @name_headers, "name: $_";
}
success ( "search-status: ".($auth_req ? "" : "unauthenticated " )."success",
	"subscriptions: ".join( " ", @subs ),
	@name_headers
);

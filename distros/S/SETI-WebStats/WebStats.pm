# $Id: WebStats.pm,v 1.9 2003/10/10 01:57:57 vek Exp $

package SETI::WebStats;

use Carp qw(croak);
use LWP::UserAgent;
use XML::Simple;
use strict;
use vars qw($VERSION);

$VERSION = '1.03';

use constant USERURL =>
	"http://setiathome.ssl.berkeley.edu/fcgi-bin/fcgi?cmd=user_xml&email=%s";

use constant GROUPURL =>
	"http://setiathome.ssl.berkeley.edu/fcgi-bin/fcgi?cmd=team_lookup_xml&name=%s";

sub new {
	my ($class, $emailAddr) = @_;
	my $self = {};
	$self->{version} = $VERSION;
	bless $self, $class;
	# still allowing emailAddr in constructor for
	# backwards compatability...
	if ($emailAddr) {
		return $self->fetchUserStats($emailAddr);
	}
	return $self;
}

###############################################################################
# Public methods 
###############################################################################

sub fetchUserStats {
	my ($self, $emailAddr) = @_;
	if (! $emailAddr) {
		croak("You must specify an email address");
		return 0;
	}
	my $url = sprintf(USERURL, $emailAddr);
	$self->_mode('user');
	return $self->_fetch($url);
}

sub fetchGroupStats {
	my ($self, $groupName) = @_;
	if (! $groupName) {
		croak("You must specify a group name");
		return 0;
	}
	my $url = sprintf(GROUPURL, $groupName);
	$self->_mode('group');
	return $self->_fetch($url);
}

# userinfo methods

sub userInfo {
	my $self = shift;
	return $self->{data}->{userinfo};
}

sub userTime {
	my $self = shift;
	return $self->{data}->{userinfo}->{usertime};
}

sub aveCpu {
	my $self = shift;
	return $self->{data}->{userinfo}->{avecpu};
}

sub numResults {
	my $self = shift;
	return $self->{data}->{userinfo}->{numresults};
}

sub regDate {
	my $self = shift;
	return $self->{data}->{userinfo}->{regdate};
}

sub profileURL {
	my $self = shift;
	if ($self->{data}->{userinfo}->{userprofile}) {
		return $self->{data}->{userinfo}->{userprofile}->{a}->{href};
	} else {
		return "No URL";
	}
}

sub resultsPerDay {
	my $self = shift;
	return $self->{data}->{userinfo}->{resultsperday};
}

sub lastResultTime {
	my $self = shift;
	return $self->{data}->{userinfo}->{lastresulttime} || 0;
}

sub cpuTime {
	my $self = shift;
	return $self->{data}->{userinfo}->{cputime};
}

sub name {
	my $self = shift;
	if (ref $self->{data}->{userinfo}->{name}) {
		return $self->{data}->{userinfo}->{name}->{a}->{content};
	} else {
		return $self->{data}->{userinfo}->{name};
	}
}

sub homePage {
	my $self = shift;
	if (ref $self->{data}->{userinfo}->{name}) {
		if ($self->{data}->{userinfo}->{name}->{a}->{href}) {
			return $self->{data}->{userinfo}->{name}->{a}->{href};
		} else {
			return "No Home Page";
		}
	} else {
		return "No Home Page";
	}
}

# rankinfo methods

sub rankInfo {
	my $self = shift;
	return $self->{data}->{rankinfo};
}

sub haveSameRank {
	my $self = shift;
	return $self->{data}->{rankinfo}->{num_samerank};
}

sub totalUsers {
	my $self = shift;
	return $self->{data}->{rankinfo}->{ranktotalusers};
}

sub rankPercent {
	my $self = shift;
	return (100 - $self->{data}->{rankinfo}->{top_rankpct});
}

sub rank {
	my $self = shift;
	return $self->{data}->{rankinfo}->{rank};
}

# groupinfo methods from individual user query...

sub groupInfo {
	my $self = shift;
	return $self->{data}->{groupinfo}->{group} ?
		$self->{data}->{groupinfo}->{group}->{a} :
		undef;
}

sub groupName {
	my $self = shift;
	return $self->{data}->{groupinfo}->{group} ?
		$self->{data}->{groupinfo}->{group}->{a}->{content} :
		undef;
}

sub groupUrl {
	my $self = shift;
	return $self->{data}->{groupinfo}->{group} ?
		$self->{data}->{groupinfo}->{group}->{a}->{href} :
		undef;
}

# group methods (from group query)

sub groupURL {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{url} || undef) :
		undef;
}

sub numGroupResults {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{numresults} || undef) :
		undef;
}

sub numGroupMembers {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{nummembers} || undef) :
		undef;
}

sub totalGroupCPU {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{totalcpu} || undef) :
		undef;
}

sub nameOfGroup {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{name} || undef) :
		undef;
}

sub groupFounderName {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{founder}->{name} || undef) :
		undef;
}

sub groupFounderURL {
	my $self = shift;
	return $self->{groupdata} ?
		($self->{groupdata}->{founder}->{url} || undef) :
		undef;
}

###############################################################################
# Private methods
###############################################################################

sub _fetch {
	my ($self, $URL) = @_;
	my $ua   = LWP::UserAgent->new;
	$ua->agent("SETI::WebStats/$VERSION " . $ua->agent);
	my $req  = HTTP::Request->new('GET', $URL);
	my $resp = $ua->request($req);
	return 0 if (! $resp->is_success);
	if ($resp->content =~ /No user|No such group/) {
		croak($resp->content);
		return 0;
	}
	local ($^W) = 0; # silence XML::SAX::Expat
	if ($self->_mode eq 'user') {
		$self->{data} = XMLin($resp->content);
	} else {
		$self->{groupdata} = XMLin($resp->content);
	}
	local ($^W) = 1;
	return 1;
}

sub _mode {
	my ($self, $mode) = @_;
	if (defined $mode) {
		$self->{mode} = $mode;
		return $self;
	} else {
		return $self->{mode} || undef;
	}
}

1;
__END__

=head1 NAME

SETI::WebStats - Gather SETI@home statistics from the SETI@home web server

=head1 SYNOPSIS

  use SETI::WebStats;

  my $seti = SETI::WebStats->new;

  # get individual user statistics...
  if ($seti->fetchUserStats('foo@bar.org')) {
     print "My rank current rank is " . $seti->rank, "\n";
     print "I have processed " . $seti->numResults . " units.";
  }
  my $cpuTime  = $seti->cpuTime;
  my $userInfo = $seti->userInfo;
  for (keys(%$userInfo)) {
     print $_, "->", $userInfo->{$_}, "\n";
  }

  # get group statistics...
  if ($seti->fetchGroupStats('perlmonks')) {
     print $seti->groupFounderName . " founded the group.\n";
	 print "We have " . $seti->numGroupMembers . "members.\n";
	 print "We've processed " . $seti->numGroupResults . " units.\n";
	 print "For a total group CPU time of " . $seti->totalGroupCPU;
  }
  
=head1 ABSTRACT

A simple Perl interface to SETI@home User & Group statistics.  

=head1 DESCRIPTION

The C<SETI::WebStats> module queries the SETI@home web server to retrieve user and group statistics via XML.  The data availible from the server is the same as that displayed on the C<Individual User Statistics> and C<Group Statistics> web pages.  In order to query the server, you will need a valid SETI@home account (i.e email address) or valid group name.

=head2 Using SETI::WebStats

Load the module as normal.

  use SETI::WebStats

Create a WebStats object.

  my $seti = SETI::WebStats->new;

=head2 Retrieving User Statistics

  $seti->fetchUserStats('foo@bar.org');

The C<fetchUserStats> method takes a mandatory email address as it's only argument.  The SETI@home web server will be queried and the XML output parsed.  Returns 1 on success, 0 on failure.

You can then extract the user stats in one go:

  my $userInfo = $seti->userInfo;

Returns a hash reference:

  $userInfo = {
	usertime       => '3.530 years',
	avecpu         => '15 hr 54 min 36.3 sec',
	numresults     => '670',
	regdate        => 'Fri May 28 20:28:45 1999',
	resultsperday  => '0.51',
	lastresulttime => 'Sat Jun  8 03:47:50 2002',
	cputime        => '     1.217 years',
	name           => 'John Doe'};

Alternatively, instead of calling C<userInfo>, you can extract each user statistic individually:

  my $userTime     = $seti->userTime;
  my $aveCpu       = $seti->aveCpu;
  my $procd        = $seti->numResults;
  my $registerDate = $seti->regDate;
  my $dailyResults = $seti->resultsPerDay;
  my $lastUnit     = $seti->lastResultTime;
  my $cpuTime      = $seti->cpuTime;
  my $accountName  = $seti->name;

You can extract rank stats in one go:

  my $rankInfo = $seti->rankInfo;

Returns a hash reference:

  $rankInfo = {
	num_samerank   => '3',
	ranktotalusers => '4152567',
	top_rankpct    => '0.516',
	rank           => '21410'};

Alternatively, instead of calling C<rankInfo>, you can extract each rank statistic individually:

  my $usersWithSameRank = $seti->haveSameRank;
  my $totalUsers        = $seti->totalUsers;
  my $percentComparedTo = $seti->rankPercent;
  my $rank              = $seti->rank;

=head2 Retrieving Group Statistics

  $seti->fetchGroupStats('some_group_name');

The C<fetchGroupStats> method takes a mandatory group name as it's only argument.  The SETI@home web server will be queried and the XML output parsed.  Returns 1 on success, 0 on failure.

You can then extract each group statistic.

  my $groupName    = $seti->groupName;
  my $groupURL     = $seti->groupURL;
  my $founder      = $seti->groupFounderName;
  my $founderURL   = $seti->groupFounderURL;
  my $groupResults = $seti->numGroupResults;
  my $groupMembers = $seti->numGroupMembers;
  my $groupCPU     = $seti->totalGroupCPU;

=head1 BUGS

None that I'm aware of but be sure to let me know if you find one.

=head1 AUTHOR

Kevin Spencer <vek@perlmonk.org>

=head1 SEE ALSO

L<perl>, L<SETI::Stats>, L<http://setiathome.ssl.berkeley.edu>.

=cut

package Net::PSYC::Storage;
#
# this provides access to information in ~/.psyc files	-lynX
# and PSYC environment variables according to http://psyc.pages.de/storage
#
# ... and maybe one day implements also _request_retrieve and _request_store
# but then i'd have to do the linking as well.. and that doesn't belong here
#
our $VERSION = '0.1';

use strict;
use Carp;
use Net::PSYC;
use base 'Exporter';

our @EXPORT = qw(UNI nick pass);

my $UNL = $ENV{PSYCUNL};
my $UNI = $ENV{PSYC};
my $pass = $ENV{PSYCPASS};
my $nick = undef;

sub path () { "/.psyc/" }

sub readUNI () {
	my $I;
	unless (open($I, $ENV{HOME}.path.'me')) {
		warn "Consider putting your <UNI> into ~/.psyc/me\n...";
		return 0;
	}
	while(<$I>) {
#		last if ($nick, $UNI, $pass) = /^(\S+)\s+(psyc:\S+)\s*(\S*)$/;
		last if ($UNI) = /^(psyc:\S+)$/;
	}
	close $I;
	return $UNI;
}

sub readUNL () {
	my $I;
	unless (open($I, $ENV{HOME}.path.'unl')) {
		warn "Consider putting your <UNL> (containing your dyndns.host) into ~/.psyc/unl\n...";
		return 0;
	}
	while(<$I>) {
#		last if ($nick, $UNI, $pass) = /^(\S+)\s+(psyc:\S+)\s*(\S*)$/;
		last if ($UNL) = /^(psyc:\S+)$/;
	}
	close $I;
	return $UNL;
}

sub readpass {
	my $me = lc(shift);
	my ($I, $UNI);

	return 0 unless ($me);
	unless (open($I, $ENV{HOME}.path.'auth')) {
	    warn "Consider putting '<UNI> <pass>' into ~/.psyc/auth\n...";
	    return 0;
	}
	while(<$I>) {
		($UNI, $pass) = /^(psyc:\S+)\s+(\S+)$/;
		if (lc($UNI) eq $me) {
		    close($I);
		    return $pass;
		}
	}
	close $I;
	return 0;
}

sub UNL () { $UNL || readUNL; }
sub UNI () { $UNI || readUNI; }
sub pass { $pass || readpass($_[0]||$UNI); }
sub nick () {
	return $nick if $nick;
	return $nick if $nick = $ENV{PSYCNICK} || $ENV{NICK};
	if (UNI) {
	    my ($user, $host, $port, $type, $object) = parse_uniform(UNI);
	    return $nick = $user if $user;
	    return $nick = $1 if $object =~ m#~(\S+)/?#;
	}
	return $nick if $nick = $ENV{IRCNICK};
	return $nick if $nick = $ENV{USER}
		     and $nick ne 'root' && $nick ne 'daemon';
	return $nick = $ENV{HOST} || 'someone';
}

1;

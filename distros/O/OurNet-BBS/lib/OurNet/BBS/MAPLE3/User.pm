# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/User.pm $ $Author: clkao $
# $Revision: #6 $ $Change: 4602 $ $DateTime: 2003/03/05 12:55:04 $

package OurNet::BBS::MAPLE3::User;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot id recno _ego _hash/;
use subs qw/writeok readok/;

use OurNet::BBS::Base (
    'UserGroup' => [qw/$packsize $packstring @packlist/],
);

use enum 'BITMASK:PERM_',
    qw/BASIC CHAT PAGE POST VALID MBOX CLOAK XEMPT/,		# Basic
    qw/P9 P10 P11 P12 P13 P14 P15 P16/,				# Special
    qw/DENYPOST DENYCHAT DENYTALK DENYMAIL DENY5 DENY6 DENYLOGIN PURGE/,
    qw/BM SEECLOAK ADMIN3 ADMIN4 ACCOUNTS CHATROOM BOARD/;	# Admin

use constant PERM_SYSOP	     => 0x80000000; # enum bug: will overflow
use constant PERM_DEFAULT    => (PERM_BASIC|PERM_CHAT|PERM_PAGE|PERM_POST);
use constant PERM_ADMIN      => (PERM_BOARD | PERM_ACCOUNTS | PERM_SYSOP);
use constant PERM_ALLBOARD   => (PERM_SYSOP);
use constant PERM_LOGINCLOAK => (PERM_SYSOP | PERM_ACCOUNTS);
use constant PERM_SEEULEVELS => PERM_SYSOP;
use constant PERM_SEEBLEVELS => (PERM_SYSOP | PERM_BM);
use constant PERM_READMAIL   => PERM_BASIC;
use constant PERM_INTERNET   => PERM_VALID;
use constant PERM_FORWARD    => PERM_INTERNET;
use constant GEM_QUIT        => -2;
use constant GEM_VISIT       => -1;
use constant GEM_USER        => 0;
use constant GEM_RECYCLE     => 1;
use constant GEM_MANAGER     => 2;
use constant GEM_SYSOP       => 3;

use constant WRITEOK	=> ' username address realname email ';
use constant READOK	=> ' numlogin numposts justify lastlogin vmail'.
			   ' username userid mailbox ';

sub writeok {
    my ($self, $user, $op, $param) = @_;

    return (
	index(WRITEOK, $param->[0]) > -1
	and ($self->id eq $user->id)
    );
}

sub readok {
    my ($self, $user, $op, $param) = @_;

    return (
	index(READOK, $param->[0]) > -1
	or ($self->id eq $user->id)
    );
}

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

sub refresh_meta {
    my ($self, $key) = @_;
    return if defined $key and exists $self->{_hash}{$key};

    my $path = "$self->{bbsroot}/usr/".
              lc(substr($self->{id}, 0, 1)."/$self->{id}");

    local $/;

    unless (-d $path) {
        mkdir $path or die "cannot mkdir $path\n";

        open(my $USR, ">$path/.ACCT") or die "cannot open: $path/.ACCT";

        $self->{_hash}{userno} = (stat("$self->{bbsroot}/.USR"))[7] / 16 + 1;
        $self->{_hash}{userid} = $self->{id};
        $self->{_hash}{userlevel} = 15;
        $self->{_hash}{ufo} = 15;
        print $USR pack($packstring, @{$self->{_hash}}{@packlist});
        close $USR;

        open($USR, ">>$self->{bbsroot}/.USR") or die "cannot open: $self->{bbsroot}/.USR";
        print $USR substr(pack("LZ13", time(), $self->{id}), 0, 16);
        close $USR;
    }

    if (!defined($key) or $self->contains($key)) {
	open(my $USR, "<$path/.ACCT") or die "cannot: open $path/.ACCT";
	@{$self->{_hash}}{@packlist} = unpack($packstring, <$USR>);
	close $USR;

	no warnings 'numeric';

	$self->{recno} ||= $self->{_hash}{userno} - 1;
	$self->{_hash}{uid} ||= $self->{_hash}{userno};
	$self->{_hash}{name} ||= $self->{id};

	return 1;
    }
    else {
	die "malicious intent stopped cold" if index($key, '..') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
	    "$path/$key";
    }

    return 1;
}

sub refresh_mailbox {
    my $self = shift;
    my $PATH_USR = 'usr'; # XXX: should be in initvars

    return $self->{_hash}{mailbox} ||= $self->module('ArticleGroup')->new({
	basepath	=> "$self->{bbsroot}/$PATH_USR/".
			   lc(substr($self->{id}, 0, 1)),
	board		=> lc($self->{id}),
	idxfile	 	=> '.DIR',
	bm		=> $self->{id},
	readlevel	=> -1,
	postlevel	=> -1,
    });
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;
    $self->refresh_meta($key);

    my $path = "$self->{bbsroot}/usr/".
		lc(substr($self->{id}, 0, 1)."/$self->{id}");

    if ($self->contains($key)) {
	$self->{_hash}{$key} = $value;

	open(my $USR, ">$path/.ACCT");
	print $USR pack($packstring, @{$self->{_hash}}{@packlist});
	close $USR;
    }
    else {
	die "malicious intent stopped cold" if index($key, '..') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
	    "$path/$key" unless $self->{_hash}{$key};

	$self->{_hash}{$key} = $value;
    }
}

1;


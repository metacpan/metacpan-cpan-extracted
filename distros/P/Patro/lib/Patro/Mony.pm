package Patro::Mony;
use strict;
use warnings;

# Repository for functions the Patro distribution
# will assign in the CORE::GLOBAL namespace.

if (defined &CORE::read) {
    *CORE::GLOBAL::read = sub (*\$$;$) {
	$Patro::read_sysread_flag = 'read';
	goto &CORE::read;
    };
    *CORE::GLOBAL::sysread = sub (*\$$;$) {
	$Patro::read_sysread_flag = 'sysread';
	goto &CORE::sysread;
    };
} else {
    $Patro::read_sysread_flag = 'read?';
}

*CORE::GLOBAL::truncate = \&_truncate;
*CORE::GLOBAL::stat = \&_stat;
*CORE::GLOBAL::flock = \&_flock;
*CORE::GLOBAL::fcntl = \&_fcntl;

*CORE::GLOBAL::sysopen = \&_sysopen;
*CORE::GLOBAL::lstat = \&_lstat;

*CORE::GLOBAL::opendir = \&_opendir;
*CORE::GLOBAL::closedir = \&_closedir;
*CORE::GLOBAL::readdir = \&_readdir;
*CORE::GLOBAL::seekdir = \&_seekdir;
*CORE::GLOBAL::telldir = \&_telldir;
*CORE::GLOBAL::rewinddir = \&_rewinddir;
*CORE::GLOBAL::chdir = \&_chdir;

sub _truncate {
    my ($fh,$len) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('TRUNCATE',1,$len);
    } else {
	return CORE::truncate($fh,$len);
    }
}

sub _fcntl {
    my ($fh,$func,$scalar) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('FCNTL',1,$func,$scalar);
    } else {
	return CORE::fcntl($fh,$func,$scalar);
    }
}

sub _stat {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	my $context = defined(wantarray) + wantarray + 0;
	return $fh->_tied->__('STAT',$context);
    } else {
	return CORE::stat $fh;
    }
}

sub _flock {
    my ($fh,$op) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('FLOCK',1,$op);
    } else {
	return CORE::flock($fh,$op);
    }
}

sub _sysopen {
    my ($fh,$fname,$mode,$perm) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('SYSOPEN',1,$fname,$mode,$perm);
    } elsif (defined ($perm)) {
        return CORE::sysopen($fh,$fname,$mode,$perm);
    } else {
        return CORE::sysopen($fh,$fname,$mode);
    }
}

sub _lstat (;*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	my $context = defined(wantarray) + wantarray + 0;
	return $fh->_tied->__('LSTAT',$context);
    }
    return CORE::lstat $fh;
}

sub _opendir (*$) {
    if (CORE::ref($_[0]) eq 'Patro::N5') {
        return $_[0]->_tied->__('OPENDIR',1,$_[1]);
    }
    return CORE::opendir($_[0],$_[1]);
}

sub _closedir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('CLOSEDIR',1);
    }
    return CORE::closedir($fh);
}

sub _readdir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('READDIR',undef);
    }
    return CORE::readdir($fh);
}

sub _seekdir (*$) {
    my ($fh,$pos) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('SEEKDIR',1,$pos);
    }
    return CORE::seekdir($fh,$pos);
}

sub _telldir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('TELLDIR',1);
    }
    return CORE::telldir($fh);
}

sub _rewinddir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('REWINDDIR',1);
    }
    return CORE::rewinddir($fh);
}

sub _chdir (;$) {
    my ($fh) = @_;
    if ($fh && CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('CHDIR',1);
    }
    return CORE::chdir($fh);
}

1;


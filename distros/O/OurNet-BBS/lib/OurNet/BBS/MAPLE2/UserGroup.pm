# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/UserGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE2::UserGroup;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot shmkey maxuser shmid shm mtime _ego _hash _array/;
use OurNet::BBS::ShmScalar;
use OurNet::BBS::Base (
    '$packstring' => 'Z13Z20Z24Z14CISSLLZ16Z8Z50Z50Z39',
    '$namestring' => 'Z13',
    '$packsize'   => 256,
    '$namesize'   => 13,
    '@packlist'   => [
        qw/userid realname username passwd uflag userlevel numlogins 
           numposts firstlogin lastlogin lasthost remoteuser email 
           address justify month day year reserved state/
    ],
    '$PWD'	  => '.PASSWDS',
);

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $flag) = @_;

    unless ($self->{shmid} || !$self->{shmkey}) {
        if ($^O ne 'MSWin32' and
            $self->{shmid} = shmget($self->{shmkey},
				    ($self->{maxuser}) * $namesize + 16, 0)) {
            # print "key: $self->{shmkey}\n";
            # print "maxuser: $self->{maxuser}\n";
            tie $self->{shm}{userlist}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, 0, $namesize, $self->{maxuser} * $namesize, 'Z$namesize';
            tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser} * $namesize,      4, 'L';
            tie $self->{shm}{touchtime}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser} * $namesize +  4, 4, 'L';
            tie $self->{_hash}{number}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser} * $namesize +  8, 4, 'L';
            tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser} * $namesize + 12, 4, 'L';
        }
    }

    my $name;
    if ($self->{shmid}) {
	# shm-based imeplementation
	if ($key and $flag == HASH) {
            # key fetch
            return if $self->{_hash}{$key} or !$self->{maxuser};

            my $buf;
            $name = $key;
            undef $key;

            foreach my $rec (0 .. $self->{maxuser} - 1) {
                shmread($self->{shmid}, $buf, $namesize * $rec, $namesize);

                if ($name eq unpack($namestring, $buf)) {
                    $key = $rec; last;
                }
            }

            $key ||= $self->{maxuser};
        }
        elsif (defined($key) and $flag == ARRAY) {
            shmread($self->{shmid}, $name, $namesize * $key, $namesize);
            $name = unpack($namestring, $name);
            return if $self->{_hash}{$name} == $self->{_array}[$key];
        }
	else {
	    # initialize everything
            my $buf;
            foreach my $rec (0 .. $self->{maxuser} - 1) {
                shmread($self->{shmid}, $buf, $namesize * $rec, $namesize);
		$buf = unpack($namestring, $buf);
		$self->{_hash}{$buf} = $self->{_array}[$rec] = $self->module(
		    'User'
		)->new(
		    $self->{bbsroot},
		    $buf,	# id
		    $rec,	# recno
		);
	    }
	}
    }
    else {
	# XXX: shm-less implementation
	my $file = "$self->{bbsroot}/$PWD";
	open(my $DIR, "<$file")
	    or (warn "can't read DIR file for $file: $!", return);

	if ($key and $flag == HASH) {
	    foreach my $rec (0 .. int((stat($file))[7] / $packsize) - 1) {
		read $DIR, $name, $packsize;
		$name = unpack($namestring, $name);
		next unless $name eq $key;
		$key = $rec; last;
	    }
	}
        elsif (defined($key) and $flag == ARRAY) {
	    seek $DIR, $key * $packsize, 0;
	    read $DIR, $name, $packsize;
            $name = unpack($namestring, $name);
            return if $self->{_hash}{$name} == $self->{_array}[$key];
	}
	else {
	    # initializes everything
	    return if $self->filestamp($file);
	    seek $DIR, 0, 0;

	    foreach $key (0 .. int((stat($file))[7] / $packsize) - 1) {
		read $DIR, $name, $packsize;
		$name = unpack($namestring, $name);

		# return the thing
		$self->{_hash}{$name} = $self->{_array}[$key] = $self->module(
		    'User'
		)->new(
		    $self->{bbsroot},
		    $name,
		    $key,
		);
	    }

	    close $DIR;
	    return 1;
	}
    }

    print "new $name $key\n" if $OurNet::BBS::DEBUG;

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,	# id
        $key,	# recno
    );

    $self->{_hash}{$name} = $self->{_array}[$key] = $obj;

    return 1;
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;

    return 1 if exists ($self->{_hash}{$key});

    if ($self->{shmid}) {
	# shm-based imeplementation
	my $buf;
	foreach my $rec (1 .. $self->{maxuser}) {
	    shmread($self->{shmid}, $buf, $namesize * $rec, $namesize);
	    return 1 if unpack($namestring, $buf) eq $key;
	}
    }
    else {
	# shm-less implementation
	my $file = "$self->{bbsroot}/$PWD";
	return 0 if $self->filestamp($file, 'mtime', 1);
	open(my $DIR, "<$file") or die "can't read PWD file $file: $!";

	my $buf;
	foreach (0 .. int((stat($file))[7] / $packsize)-1) {
	    read $DIR, $buf, $packsize;
	    return 1 if unpack($namestring, $buf) eq $key;
	}

	close $DIR;
    }

    return 0;
}

1;

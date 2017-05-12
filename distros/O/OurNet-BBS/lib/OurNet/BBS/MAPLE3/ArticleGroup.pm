# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 4823 $ $DateTime: 2003/03/19 19:35:32 $

package OurNet::BBS::MAPLE3::ArticleGroup;

use open IN => ':raw', OUT => ':raw';

# hdrfile for the upper level hdr file holding metadata of this level
# idxfile for hdr of the deeper level that this articlegroup is holding.

use strict;
no warnings 'deprecated';
use fields qw/basepath board name dir hdrfile idxfile recno 
	      bm readlevel postlevel mtime btime _ego _hash _array/;
use subs qw/readok writeok/;
use OurNet::BBS::Base (
    '$packstring' => 'LLLZ32Z80Z50Z9Z73',
    '$packsize'   => 256,
    '@packlist'   => [qw/time xmode xid id author nick date title/],
);

use Date::Parse;
use Date::Format;

use constant GEM_FOLDER  => 0x00010000;
use constant GEM_BOARD   => 0x00020000;
use constant GEM_GOPHER  => 0x00040000;
use constant GEM_HTTP    => 0x00080000;
use constant GEM_EXTEND  => 0x80000000;
use constant POST_DELETE => 0x0080;

my %chronos;

sub writeok {
    my ($self, $user, $op, $param) = @_;
    my $id = $user->id;

    # as usual, SYSOP has full access.
    return 1 if $user->has_perm('PERM_SYSOP');

    # store/delete an arbitary article require bm permission in that board
    return 1 if $self->bm =~ /^\b\Q$id\E\b$/ and (
	$user->has_perm('PERM_BM') or $self->readlevel == -1
    );

    # only PUSH allowed now
    return unless $op eq 'PUSH' or ($op eq 'STORE' and $param->[0] eq '');

    # actually you can store your own article, no big deal
    my $value = $param->[-1]; # 0 for PUSH, 1 for STORE
    my $author = $value->{author};
    return if $author and $author ne $id;

    my $header = $value->{header};
    return if $header and $header->{From} !~ /^\Q$id\E\b/;

    return ($author or $header); # at least one of author bits must exist
}

sub readok {
    my ($self, $user) = @_;

    my $readlevel = $self->readlevel;

    return ($user->has_perm('PERM_SYSOP') or $self->bm eq $user->id)
	if $readlevel == -1; # mailbox
    return (!$readlevel or $readlevel & $user->{userlevel});
}

sub stamp {
    my $chrono = shift;
    my $str    = '';

    for (1 .. 7) {
        $str = ((0 .. 9,'A' .. 'V')[$chrono & 31]) . $str;
        $chrono >>= 5;
    }

    return "A$str";
}

sub new_id {
    my $self = shift;
    my ($chrono, $file, $fname);

    $file = "$self->{basepath}/$self->{board}";

    unless (-e "$file/$self->{hdrfile}") {
        open(my $HEADER, ">$file/$self->{hdrfile}")
	    or die "cannot create $file/$self->{hdrfile}";
        close $HEADER;
    }

    no warnings 'uninitialized';

    $chrono = time;
    $chronos{$self->{board}} = $chrono if $chrono > $chronos{$self->{board}};

    while (my $id = stamp($chrono)) {
        $fname = join('/', $file, substr($id, -1), $id);
        last unless -e $fname;

        $chrono = ++$chronos{$self->{board}};
    }

    # make storage subdir if not exist
    my $path = $1 if $fname =~ m|^(.+)/|;
    mkdir $path unless -d $path;

    open(my $BODY, ">$fname") or die "cannot open $fname";
    close $BODY;

    return $chrono;
}

sub refresh_id {
    my ($self, $key) = @_;

    if (defined $self->{idxfile}) {
        my $file = "$self->{basepath}/$self->{board}/$self->{idxfile}";
        $self->filestamp($file, 'btime');
    }

    my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

    local $/ = \$packsize;
    open(my $DIR, "<$file") or die "can't read DIR file $file: $!";

    if (defined $self->{recno} and defined $self->{name}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_hash}}{@packlist} = unpack($packstring, <$DIR>);
        if ($self->{_hash}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{name} and defined $self->{recno}) {
	no warnings 'uninitialized';

	if (defined $self->{name}) { # seek for name
	    $self->{recno} = 0;

	    while (my $data = <$DIR>) {
		@{$self->{_hash}}{@packlist} = unpack($packstring, $data);
		last if ($self->{_hash}{id} eq $self->{name});
		$self->{recno}++;
	    }
	}
	else { # append
	    seek $DIR, 0, 2;
	    $self->{name} = stamp($self->{_hash}{time} = $self->new_id);
	    $self->{idxfile} = substr($self->{name}, -1)."/$self->{name}";
	    $self->{recno} = (stat($DIR))[7] / $packsize; # filesize/packsize
	}

	my @localtime = localtime;

        if ($self->{_hash}{id} ne $self->{name}) {
            $self->{_hash}{id}		= $self->{name};
            $self->{_hash}{xmode}	= GEM_FOLDER;
            $self->{_hash}{date}      ||= sprintf(
		"%02d/%02d/%02d", substr($localtime[5], -2), 
		$localtime[4] + 1, $localtime[3]
	    );
            $self->{_hash}{filemode} = 0;

            open($DIR, "+>>$file")
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
            close $DIR;

            open($DIR, '>' . join(
		'/', $self->{basepath}, $self->{board}, 
		substr($self->{name}, -1), $self->{name}
	    )) or die "can't write BODY file for $self->{board}: $!";
            close $DIR;
        }
    }

    return 1;
}

sub FETCHSIZE {
    my $self = $_[0]->ego;
    my $file = "$self->{basepath}/$self->{board}/$self->{idxfile}";

    return int((stat($file))[7] / $packsize);
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $flag) = @_;

    no warnings 'uninitialized';

    my $file = "$self->{basepath}/$self->{board}/$self->{idxfile}";
    my $name;

    goto &refresh_id if $self->contains($key);
    $self->refresh_id if (!defined($key) and $self->{dir});

    if ($key and $flag == HASH and $self->{dir} and substr($self->{dir}, 0, 1) ne '/') {
	print "Looking at $self->{dir}\n";
	no warnings 'uninitialized';

        # hash key -- no recaching needed
        return if $self->{_hash}{$key};

        my $obj = $self->module(
	    $key =~ /^D\./ ? 'ArticleGroup' : 'Article'
	)->new({
	    basepath	=> $self->{basepath},
	    board	=> $self->{board},
	    name	=> $key,
	    dir		=> "$self->{dir}/$self->{name}",
	    hdrfile	=> '.DIR',
	});

        $self->{_hash}{$key} = $self->{_array}[$obj->recno] = $obj;

        return 1;
    }

    local $/ = \$packsize;
    open(my $DIR, "<$file") or (warn "can't read DIR file for $file: $!", return);
    my $size = int((stat($file))[7] / $packsize);

    if (defined($key) and $flag == ARRAY) {
        # out-of-bound check
        die 'no such article' if $key < 0 or $key >= $size;

        seek $DIR, $packsize * $key, 0;
	return $self->_insert($key, scalar <$DIR>);
    }

    return if $self->filestamp($file);

    # reload the whole articlegroup
    $self->_insert($_, scalar <$DIR>) foreach (0 .. $size - 1);

    return 1;
}

# insert the desires key based on packed data
sub _insert($$) {
    my ($self, $key, $data) = @_;
    my %entry;

    @entry{@packlist} = unpack($packstring, $data);

    my $name = $entry{id};

    return if exists $self->{_hash}{$name}
	 	 and $self->{_hash}{$name} == $self->{_array}[$key];

    no warnings 'uninitialized';
    $self->{_hash}{$name} = $self->{_array}[$key] = (
	$entry{xmode} & POST_DELETE
    ) ? undef : $self->module(
	($entry{xmode} & GEM_FOLDER) ? 'ArticleGroup' : 'Article'
    )->new({
	board		=> $self->{board},
	basepath	=> $self->{basepath},
	name		=> $name,
	hdrfile		=> $self->{idxfile},
	recno		=> $key,
	dir		=> "$self->{dir}/$self->{name}",
	($entry{xmode} & GEM_FOLDER) ? (
	    idxfile	=> substr($entry{id}, -1) . "/$entry{id}"
	) : (),
    });

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    ($self, my $flag) = @{${$self}};

    no warnings 'uninitialized';

    if ($flag == HASH) {
	if ($self->contains($key)) {
	    $self->refresh($key, $flag);
	    $self->{_hash}{$key} = $value;

	    my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

	    open(my $DIR, "+<$file") or die "cannot open $file for writing";
	    seek $DIR, $packsize * $self->{recno}, 0;
	    print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
	    close $DIR;
	    return 1;
	}

	# special case: hash without key becomes PUSH.
	die 'arbitary storage of message-ids condered harmful.' if $key;
	$key = $#{$self->{_array}} + 1;
	$flag = ARRAY;
    }
    elsif (!$self->{_array}) {
    	$self->refresh_meta;
    }

    my $obj;

    if (exists $self->{_array}[$key]) {
	$obj = $self->{_array}[$key];
    }
    else {
	$obj = $self->module('Article', $value)->new({
	    basepath => $self->{basepath},
	    board    => $self->{board},
	    hdrfile  => $self->{idxfile},
	    recno    => $key,
	});
    }

    my $is_group = ref($obj) =~ m|ArticleGroup|;

    if ($is_group) {
	$obj->refresh('id');
    }
    elsif ($value->{header}) {
	# modern style
	@{$value}{qw/author nick/} = ($1, $2)
	    if $value->{header}{From} =~ m/^\s*(.+?)\s*(?:\((.*)\))?$/g;

	@{$value}{qw/author nick/} = ($2, $1)
	    if $value->{header}{From} =~ m/^\s*\"?(.*?)\"?\s*\<(.*)\>$/g;

	$value->{date} = time2str(
	    '%y/%m/%d', str2time($value->{header}{Date})
	) if $value->{header}{Date};

	$value->{title} = $value->{header}{Subject};
    }
    else {
	# traditional style
	$value->{header} = {
	    From    => $value->{author}.
	    (defined $self->{_hash}{nick} 
		? " ($self->{_hash}{nick})" : ''),
	    Subject => $value->{title},
	}
    }

    $value->{board} = $value->{header}{Board} = $self->{board}
	unless $is_group;

    while (my ($k, $v) = each %{$value}) {
	$obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
    };

    $obj->{body}  = $value->{body} if defined $value->{body};

    $self->refresh($key, $flag);
    $self->{mtime} = $obj->{time}; # not mtime, due to chrono-ahead.
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;
    return 1 if exists ($self->{_hash}{$key});

    my $file = "$self->{basepath}/$self->{board}/$self->{name}/.DIR";
    return if $self->filestamp($file, 'mtime', 1);

    open(my $DIR, "<$file") or die "can't read DIR file $file: $!";

    my $board;
    foreach my $key (0 .. int((stat($file))[7] / $packsize) - 1) {
        read $DIR, $board, $packsize;
        return 1 if unpack('x12Z32x212', $board) eq $key;
    }

    close $DIR;
    return;
}

1;

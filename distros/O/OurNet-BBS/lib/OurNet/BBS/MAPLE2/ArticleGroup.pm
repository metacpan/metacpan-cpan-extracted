# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 4823 $ $DateTime: 2003/03/19 19:35:32 $

package OurNet::BBS::MAPLE2::ArticleGroup;

use open IN => ':raw', OUT => ':raw';

use strict;
use warnings;
no warnings 'deprecated';
use fields qw/bbsroot board basepath name dir recno mtime btime/,
           qw/_ego _hash _array/;

use OurNet::BBS::Base (
    '$packstring'    => 'Z33Z1Z14Z6Z73C',
    '$namestring'    => 'Z33',
    '$packsize'      => 128,
    '@packlist'      => [qw/id savemode author date title filemode/],
);

my %chronos;

sub basedir {
    no warnings 'uninitialized';
    return join('/', @{$_[0]}{qw/bbsroot basepath board dir/});
}

sub new_id {
    my $self = shift;
    my ($id, $file);

    my $chrono = time();

    no warnings 'uninitialized';
    
    $chronos{$self->{board}} = $chrono 
        if $chrono > $chronos{$self->{board}};

    while ($id = "D.$chrono.A") {
        $file = join('/', $self->basedir, $id);
        last unless -e $file;
        $chrono = ++$chronos{$self->{board}};
    }

    mkdir join('/', $self->basedir, $self->{name});
    return $id;
}

sub refresh_id {
    my ($self, $key) = @_;

    $self->{name} ||= $self->new_id;

    if (defined $self->{recno}) {
	my $file = join('/', $self->basedir, $self->{name}, '.DIR');
	$self->filestamp($file, 'btime');
    }

    my $file = join('/', $self->basedir, '.DIR');
    local $/ = \$packsize;
    open(my $DIR, "<$file") or die "can't read DIR file for $self->{board}: $!";

    if (defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_hash}}{@packlist} = unpack($packstring, <$DIR>);
        if ($self->{_hash}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;

        while (my $data = <$DIR>) {
            @{$self->{_hash}}{@packlist} = unpack($packstring, $data);
            # print "$self->{_hash}{id} versus $self->{name}\n";
            last if ($self->{_hash}{id} eq $self->{name});
            $self->{recno}++;
        }

	no warnings 'uninitialized';

        if ($self->{_hash}{id} ne $self->{name}) {
            $self->{_hash}{id} = $self->{name};
            $self->{_hash}{author}   ||= 'guest.';
            $self->{_hash}{date}     = sprintf(
		"%2d/%02d", (localtime)[4] + 1, (localtime)[3]
	    );
            $self->{_hash}{title}    = '¡» (untitled)';
            $self->{_hash}{filemode} = 0;

            open($DIR, "+>>$file")
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
            close $DIR;

            mkdir join('/', $self->basedir, $self->{name});
            open($DIR, '>'. join('/', $self->basedir, '.DIR'));
            close $DIR;
        }
    }

    return 1;
}

sub FETCHSIZE {
    my $self = $_[0]->ego;

    no warnings 'uninitialized';
    return int((stat(
	join('/', @{$self}{qw/bbsroot basepath board dir name/}, '.DIR')
    ))[7] / $packsize);
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $flag) = @_;

    no warnings qw/uninitialized numeric/;

    my $file = join('/', $self->basedir, $self->{name}, '.DIR');
    my $name;

    goto &refresh_id if $self->contains($key);
    $self->refresh_id if (!defined($key) and $self->{dir});

    if ($key and $flag == HASH and $self->{dir} and substr($self->{dir}, 0, 1) ne '/') {
        # hash key -- no recaching needed
        return if $self->{_hash}{$key};

        my $obj = $self->module(substr($key, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $key,
                "$self->{dir}/$self->{name}",
            );

        $self->{_hash}{$key} = $self->{_array}[$obj->recno] = $obj;

        return 1;
    }

    open(my $DIR, "<$file")
	or (warn "can't read DIR file for $file: $!", return);

    if (defined($key) and $flag == ARRAY) {
        # out-of-bound check
        return if $key < 0 or $key >= int((stat($file))[7] / $packsize);

        seek $DIR, $packsize * $key, 0;
        read $DIR, $name, $packsize;
        $name = unpack($namestring, $name);

        return if exists $self->{_hash}{$name}
		and $self->{_hash}{$name}== $self->{_array}[$key];

        my $obj = $self->module(substr($name, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $name,
                "$self->{dir}/$self->{name}",
                $key,
            );

        $self->{_hash}{$name} = $self->{_array}[$key] = $obj;

        close $DIR;
        return 1;
    }

    return if $self->filestamp($file);

    seek $DIR, 0, 0;

    foreach my $key (0 .. int((stat($file))[7] / $packsize) - 1) {
        read $DIR, $name, $packsize;
        $name = unpack($namestring, $name);

        # return the thing
        $self->{_hash}{$name} = $self->{_array}[$key] = $self->module(
	    substr($name, 0, 2) eq 'D.' ? 'ArticleGroup' : 'Article'
	)->new(
	    $self->{bbsroot},
	    $self->{board},
	    $self->{basepath},
	    $name,
	    "$self->{dir}/$self->{name}",
	    $key,
	);
    }

    close $DIR;

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

	    my $file = join('/', $self->basedir, '.DIR');

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

    if ($self->{_array}[$key]) {
	$obj = $self->{_array}[$key];
    }
    else {
	$obj = $self->module('Article', $value)->new(
	    $self->{bbsroot},
	    $self->{board},
	    $self->{basepath},
	    undef,
	    "$self->{dir}/$self->{name}",
	    $flag == ARRAY ? $key : undef,
	);
    }

    use Date::Parse;
    use Date::Format;

    if (ref($value) and $value->{header}) {
	@{$value}{qw/author nick/} = ($1, $2)
	    if $value->{header}{From} =~ m/^\s*(.+?)\s*(?:\((.*)\))?$/g;

	@{$value}{qw/author nick/} = ($2, $1)
	    if $value->{header}{From} =~ m/^\s*\"?(.*?)\"?\s*\<(.*)\>$/g;

	$value->{date}  = time2str(
	    '%m/%d', str2time($value->{header}{Date})
	);
	$value->{date}  =~ s/^0/ /; # how crude!
	$value->{title} = $value->{header}{Subject};
    }

    while (my ($k, $v) = each %{$value}) {
	$obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
    };

    $obj->{body} = $value->{body} if ($value->{body});
    $self->refresh($key, $flag);
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;

    return unless defined $self->{name};
    return 1 if exists ($self->{_hash}{$key});

    my $file = join('/', $self->basedir, $self->{name}, '.DIR');
    return 0 if $self->filestamp($file, 'mtime', 1);

    open(my $DIR, "<$file") or die "can't read DIR file $file: $!";

    my $board;

    foreach (0 .. int((stat($file))[7] / $packsize)-1) {
        read $DIR, $board, $packsize;
        return 1 if unpack($namestring, $board) eq $key;
    }

    close $DIR;
    return 0;
}

1;

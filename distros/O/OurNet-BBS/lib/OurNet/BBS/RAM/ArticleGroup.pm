# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::ArticleGroup;

use strict;
no warnings 'deprecated';
use fields qw/dbh board name dir recno mtime btime _ego _hash _array/;

# btime: header, mtime: directory

use OurNet::BBS::Base (
    '@packlist'   => [qw/id author nick date title/],
);

my $chrono = 0;

sub new_id {
    my ($self, $id) = @_;

    # simulate chrono-ahead
    if ($chrono >= time) {
	$id = ++$chrono;
    }
    else {
	$chrono = $id = time;
    }

    # XXX: GENERATE ID
    return $id;
}

sub refresh_id {
    my ($self, $key) = @_;

    $self->{_hash}{id} = $self->{name} ||= $self->new_id;
    return if $self->timestamp(-1, 'btime');

    if (defined $self->{recno}) {
        # XXX: FETCH ONE ARTICLEGROUP-AS-ARTICLE HEADER
        @{$self->{_hash}}{@packlist} = () if 0;

        undef $self->{recno}
            if ($self->{_hash}{id} and 
                $self->{_hash}{id} ne $self->{name});
    }

    unless (defined $self->{recno}) {
        use Date::Parse;
        use Date::Format;

        $self->{_hash}{id}     = $self->{name};
        $self->{_hash}{author} ||= 'guest.';
        $self->{_hash}{date}   ||= time2str(
	    '%y/%m/%d', str2time(scalar localtime)
	);
        $self->{_hash}{title}  ||= '(untitled)';

        # XXX: STORE INTO ARTICLEGROUP-AS-ARTICLE
    }

    return 1;
}

sub refresh_meta {
    my ($self, $key, $flag) = @_;

    if ($self->contains($key)) {
        goto &refresh_id; # metadata refresh
    }
    elsif (!defined($key) and $self->{dir}) {
        $self->refresh_id; # group-as-article refresh
    }

    unless (defined $key) {
	# XXX: GLOBAL FETCH
    }
    elsif ($flag == ARRAY) {
        # XXX: ARRAY FETCH
        my $recno = $key;
        my $obj;

        die "$recno out of range" if $recno < 0; # || $recno >= $max;
        return if $self->{_array}[$recno]; # MUST DELETE THIS LINE

        # TRY GET $key
        $self->{_hash}{$key} = $self->{_array}[$recno] = $obj;
    }
    elsif ($flag == HASH) {
        # XXX: HASH FETCH
        return if !$key or $self->{_hash}{$key};

        my $obj; # TRY GET $obj
        $self->{_hash}{$key} = $obj;
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    ($self, my $flag) = @{${$self}};

    if ($self->contains($key)) {
        $self->refresh($key, $flag);
        $self->{_hash}{$key} = $value;

        # XXX STORE INTO ARTICLEGROUP-AS-ARTICLE
        return $self->timestamp(1, 'btime');
    }

    # special case: hash without key becomes PUSH.
    if ($flag == HASH) {
	die 'arbitary storage of message-ids condered harmful.' if $key;
	$key = $#{$self->{_array}} + 1;
	$flag = ARRAY;
    }

    my $obj;

    if (exists $self->{_array}[$key]) {
	$obj = $self->{_array}[$key];
    }
    else {
	# XXX: DO ACTUAL STORAGE
	$obj = $self->module('Article', $value)->new({
	    dbh   => $self->{dbh},
	    board => $self->{board},
	    dir   => $self->{dir},
	    recno => $key,
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
	no warnings 'uninitialized';

	# traditional style
	$value->{header} = {
	    From    => $value->{author}.
	    (defined $self->{_hash}{nick} 
		? " ($self->{_hash}{nick})" : ''),
	    Subject => $value->{title},
	}
    }

    while (my ($k, $v) = each %{$value}) {
	$obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
    };
    
    # delayed storage of body
    $obj->{body} = $value->{body} if exists $value->{body};
    $self->{_array}[$key] = $self->{_hash}{$obj->name} = $obj;

    # forced conversion for {''} storage
    $self->refresh($key, $flag = ARRAY); 

    $self->timestamp(1);
}

1;

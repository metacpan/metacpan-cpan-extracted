# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/Article.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE3::Article;

use if ($^O eq 'MSWin32'), 'open' => (IN => ':bytes', OUT => ':bytes');
use if $OurNet::BBS::Encoding, 'open' => ":encoding($OurNet::BBS::Encoding)";
use if $OurNet::BBS::Encoding, 'encoding' => 'big5', STDIN => undef, STDOUT => undef;

use strict;
use warnings;
no warnings 'deprecated';
use fields qw/basepath board name dir hdrfile recno mtime btime _ego _hash/;
use subs qw/readok writeok remove/;

use OurNet::BBS::Base (
    'ArticleGroup' => [qw/$packsize $packstring @packlist &new_id/],
    'Board'	   => [qw/&remove_entry/],
);

my %chronos;

sub readok { 1 };

sub writeok {
    my ($self, $user, $op) = @_;

    return if $op eq 'DELETE';

    # STORE
    return (
	$self->{author} eq $user->id 
	or $user->has_perm('PERM_SYSOP')
    );
}

sub basedir {
    my $self = shift;
    return join('/', $self->{basepath}, $self->{board});
}

sub stamp {
    my $chrono = shift;
    my $str = '';

    for (1 .. 7) {
        $str = ((0 .. 9, 'A' .. 'V')[$chrono & 31]) . $str;
        $chrono >>= 5;
    }

    return "A$str";
}

sub _refresh_body {
    my $self = shift;

    $self->refresh_meta unless ($self->{name});

    my $file = "$self->{basepath}/$self->{board}/".
        ($self->{name} =~ /^@/ ? '@' : substr($self->{name}, -1)).
	'/'.$self->{name};

    die "no such file: $file" unless -e $file;

    return if $self->filestamp($file, 'btime')
	      and defined $self->{_hash}{body};

    $self->{_hash}{date} ||= sprintf(
	"%02d/%2d/%02d", 
	substr((localtime)[5], -2), 
	(localtime($self->{btime}))[4] + 1,
	(localtime($self->{btime}))[3],
    );

    $self->_parse_body($file);

    OurNet::BBS::Utils::set_msgid(
	$self->{_hash}{header}
    ) unless $self->{_hash}{header}{'Message-ID'};

    return 1;
}

sub _parse_body {
    my ($self, $file) = @_;

    local $/;
    open(my $DIR, "<$file") or die "can't open DIR file for $self->{board}";
    $self->{_hash}{body} = <$DIR>;

    my ($from, $title, $date);

    if ($self->{_hash}{body} =~ 
        s/^作者: ([^ \(]+)\s?(?:\((.+?)\) )?[^\n]*\n標題: (.*)\n時間: (.+)\n\n//
    ) {
        ($from, $self->{_hash}{nick}, $title, $date) = ($1, $2, $3, $4);
    }
    else {
        $self->refresh_meta;
    }

    $self->{_hash}{header} = {
        From    => ($from || $self->{_hash}{author}) .
                   ($self->{_hash}{nick} ? " ($self->{_hash}{nick})" : ''),
        Subject => $title ||= $self->{_hash}{title},
        Date    => $date  ||= scalar localtime($self->{btime}),
        Board   => $self->{board},
    };
}

sub refresh_body {
    shift->_refresh_body;
}

sub refresh_header {
    shift->_refresh_body;
}

sub refresh_meta {
    my $self = shift;   
    my $cachetime;
    
    $self->{name} = stamp($cachetime = $self->new_id)
	unless (defined $self->{name});

    my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";
    
    return if $self->filestamp($file);

    local $/ = \$packsize;
    open(my $DIR, "<$file") or die "can't read DIR file $file: $!";
    binmode($DIR);

    if (defined $self->{name} and defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_hash}}{@packlist} = unpack($packstring, <$DIR>);

        if ($self->{_hash}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{name} and defined $self->{recno}) {
	no warnings 'uninitialized';

	if (not defined $cachetime) { # seek for name
	    $self->{recno} = 0;

	    while (my $data = <$DIR>) {
		@{$self->{_hash}}{@packlist} = unpack($packstring, $data);
		last if ($self->{_hash}{id} eq $self->{name});
		$self->{recno}++;
	    }
	}
	else { # append
	    seek $DIR, 0, 2;
	    $self->{_hash}{time} = $cachetime;
	    $self->{recno} = (stat($DIR))[7] / $packsize; # filesize/packsize
	}

        if ($self->{_hash}{id} ne $self->{name}) {
	    my @localtime = localtime($cachetime || time);

            $self->{_hash}{id}		= $self->{name};
            $self->{_hash}{filemode}	= 0;
            $self->{_hash}{date}      ||= sprintf(
		"%02d/%02d/%02d", substr($localtime[5], -2), 
		$localtime[4] + 1, $localtime[3]
	    );

	    no warnings qw/uninitialized numeric/;
            open($DIR, "+>>$file")
		or die "can't write DIR file for $self->{board}: $!";
	    binmode($DIR);
            print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
            close $DIR;
	} 
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;
    $self->refresh_meta($key);

    if ($key eq 'body') {
	my $file = "$self->{basepath}/$self->{board}/".
	    substr($self->{name}, -1).'/'.$self->{name};

        unless (-s $file) {
            $value =
		"作者: $self->{_hash}{author} ".
		(defined $self->{_hash}{nick} 
		    ? "($self->{_hash}{nick}) " : '').
		"看板: $self->{board} \n".
		"標題: ".substr($self->{_hash}{title}, 0, 60)."\n".
		"時間: ".localtime($self->{_hash}{time} || time).
		"\n\n".
		$value;
        }

        open(my $BODY, ">$file") or die "cannot open $file";
        print $BODY $value;
        close $BODY;

        $self->{_hash}{$key} = $value;
	$self->filestamp($file, 'btime');
    }
    else {
	no warnings 'uninitialized';

        $self->{_hash}{$key} = $value;

	my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

        open(my $DIR, "+<$file") or die "cannot open $file for writing";
	binmode($DIR);
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
        close $DIR;

	$self->filestamp($file);
    }
}

sub remove {
    my $self = shift->ego;

    $self->remove_entry("$self->{basepath}/$self->{board}/$self->{hdrfile}");
    return unlink "$self->{basepath}/$self->{board}/$self->{name}";
}

1;

# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/Article.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE2::Article;

use if $OurNet::BBS::Encoding, 'open' => ":encoding($OurNet::BBS::Encoding)";
use if $OurNet::BBS::Encoding, 'encoding' => 'big5', STDIN => undef, STDOUT => undef;

use strict;
use warnings;
no warnings 'deprecated';
use fields qw/bbsroot board basepath name dir recno mtime btime _ego _hash/;

use OurNet::BBS::Base (
    'ArticleGroup' => [qw/$packsize $namestring $packstring @packlist/],
    'Board'	   => [qw/&remove_entry/],
    '$HEAD_REGEX'  => qr/作者: ([^ \(]+)\s?(?:\((.+?)\) )?[^\n]*\n標題: (.*)\n時間: (.+)\n\n/,
);

my %chronos;

sub basedir {
    my $self = shift;

    return join('/', $self->{bbsroot}, $self->{basepath},
                     $self->{board}, $self->{dir});
}

sub new_id {
    my $self = shift;
    my ($id, $file);

    $file = $self->basedir;

    unless (-e "$file/.DIR") {
        open(my $DIR, ">$file/.DIR") or die "cannot create $file/.DIR";
        close $DIR;
    }

    my $chrono = time;

    no warnings 'uninitialized';
    $chronos{$self->{board}} = $chrono 
        if $chrono > $chronos{$self->{board}};

    while ($id = "M.$chrono.A") {
        last unless -e "$file/$id";
        $chrono = ++$chronos{$self->{board}};
    }

    open(my $BODY, ">$file/$id") or die "cannot open $file/$id";
    close $BODY;

    $self->{_hash}{time} = $chrono;

    return $id;
}

sub _refresh_body {
    my $self = shift;

    $self->{name} ||= $self->new_id;

    my $file = join('/', $self->basedir, $self->{name});

    return unless -e $file;
    return if $self->filestamp($file, 'btime') and defined $self->{_hash}{body};

    $self->{_hash}{date} ||= 
	sprintf("%2d/%02d", (localtime($self->{btime}))[4] + 1, 
	        (localtime($self->{btime}))[3]);

    local $/;
    open(my $DIR, "<$file") or die "can't open DIR file for $self->{board}";
    $self->{_hash}{body} = <$DIR>;
    close $DIR;

    my ($from, $title, $date);

    if ($self->{_hash}{body} =~ 
	s/$HEAD_REGEX//
    ) {
        ($from, $self->{_hash}{nick}, $title, $date) = ($1, $2, $3, $4);
    }
    else {
        $self->refresh_meta;
    }

    $self->{_hash}{title} =~ s/^◇ //
	if $self->{dir} and $self->{_hash}{title};

    $self->{_hash}{header} = {
        From	=> ($from || $self->{_hash}{author}) .
		   ($self->{_hash}{nick} ? " ($self->{_hash}{nick})" : ''),
        Subject	=> $title ||= $self->{_hash}{title},
        Date 	=> $date  ||= scalar localtime($self->{btime}),
	Board	=> $self->{board},
    };

    OurNet::BBS::Utils::set_msgid($self->{_hash}{header});

    return 1;
}

sub refresh_nick {
    shift->_refresh_body;
}

sub refresh_body {
    shift->_refresh_body;
}

sub refresh_header {
    shift->_refresh_body;
}

sub refresh_meta {
    my $self = shift->ego;

    $self->{name} ||= $self->new_id;

    my $file = join('/', $self->basedir, $self->{name});
    $self->{btime} = (stat($file))[9] if -e $file;

    $file = join('/', $self->basedir, '.DIR');

    return if $self->filestamp($file);

    local $/ = \$packsize;
    open(my $DIR, "<$file") or die "can't read DIR file for $self->{board}: $!";
    binmode($DIR);

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
        if ($self->{_hash}{id} ne $self->{name}) {
            $self->{_hash}{id} = $self->{name};
            $self->{_hash}{author}   ||= '(unknown).';
            $self->{_hash}{date}     = sprintf(
		"%2d/%02d", (localtime)[4] + 1, (localtime)[3]
	    );
            $self->{_hash}{title}    = 
		(substr($self->{basepath}, 0, 4) eq 'man/')
		    ? '◇ (untitled)' : '(untitled)';
            $self->{_hash}{filemode} = 0;
            open($DIR, "+>>$file")
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
            close $DIR;
            # print "Recno: ".$self->{recno}."\n";
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    $self->refresh_meta($key);

    if ($key eq 'body') {
        my $file = join('/', $self->basedir, $self->{name});
        unless (-s $file) {
            $value =
                "作者: ".($self->{_hash}{header}{From} || (
		    $self->{_hash}{author}." ".
		    (defined $self->{_hash}{nick} 
			? "($self->{_hash}{nick})" : "")
		)) . " " .
                "看板: $self->{board} \n".
                "標題: ".substr($self->{_hash}{title}, 0, 60)."\n".
                "時間: ".localtime($self->{_hash}{time} || time).
                "\n\n".
                $value;
        }
        open(my $BODY, ">$file") or die "cannot open $file";
        print $BODY $value;
        close $BODY;
        $self->{btime} = (stat($file))[9];
        $self->{_hash}{$key} = $value;
    }
    else {
        if ($key eq 'title' and
            substr($self->{basepath}, 0, 4) eq 'man/' and
            substr($value, 0, 3) ne '◇ ') {
            $value = "◇ $value";
        }
	elsif ($key eq 'author') {
	    $value =~ s/(?:\.bbs)?\@.*$/./;
	}

        $self->{_hash}{$key} = $value;

        my $file = join('/', $self->basedir, '.DIR');

        open(my $DIR, "+<$file") or die "cannot open $file for writing";
	binmode($DIR);
        # print "seeeking to ".($packsize * $self->{recno});
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
        close $DIR;

	$self->filestamp($file);
    }
}

sub remove {
    my $self = shift;

    $self->remove_entry(join('/', $self->basedir, '.DIR'));
    return unlink join('/', $self->basedir, $self->{name});
}

1;

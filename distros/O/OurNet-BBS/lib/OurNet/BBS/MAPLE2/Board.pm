# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/Board.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE2::Board;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot board shmid shm recno mtime _ego _hash/;

use OurNet::BBS::Base (
    'BoardGroup' => [
        qw/$BRD $PATH_BRD $PATH_GEM $packsize $packstring @packlist/
    ],
);

sub refresh_articles {
    my $self = shift;

    return $self->{_hash}{articles} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot}, $self->{board}, $PATH_BRD
    );
}

sub refresh_archives {
    my $self = shift;

    return $self->{_hash}{archives} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot}, $self->{board}, $PATH_GEM
    );
}

sub post_new_board {};

sub refresh_meta {
    my ($self, $key) = @_;

    die 'cannot parse board' unless $self->{board};

    if ($key and index(
	" forward anonymous permit anonymous access etc_brief ".
	" maillist overrides reject water note friendplan",
	" $key "
    ) > -1) {
	# special-casing MAPLE2 note => notes:
	$key = 'notes' if $key eq 'note' and $PATH_BRD eq 'boards';

        return if exists $self->{_hash}{$key};

        require OurNet::BBS::ScalarFile;
        tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
            "$self->{bbsroot}/$PATH_BRD/$self->{board}/$key";

        return 1;
    }

    my $file = "$self->{bbsroot}/$BRD";
    return if $self->filestamp($file);

    local $/ = \$packsize;
    open(my $DIR, "<$file") or die "can't read $BRD: $!";

    if (defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_hash}}{@packlist} = unpack($packstring, <$DIR>);
        if ($self->{_hash}{id} ne $self->{board}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;

        while (my $data = <$DIR>) {
            @{$self->{_hash}}{@packlist} = unpack($packstring, $data);
            last if ($self->{_hash}{id} eq $self->{board});
            $self->{recno}++;
        }

	no warnings 'uninitialized';

        if ($self->{_hash}{id} ne $self->{board}) {
            $self->{_hash}{id}       = $self->{board};
            $self->{_hash}{bm}       = '';
            $self->{_hash}{date}     = sprintf(
		"%2d/%02d", (localtime)[4] + 1, (localtime)[3]
	    );
            $self->{_hash}{title}    = '(untitled)';

            mkdir "$self->{bbsroot}/$PATH_BRD/$self->{board}";
            open($DIR, ">$self->{bbsroot}/$PATH_BRD/$self->{board}/.DIR");
            close $DIR;

            mkdir "$self->{bbsroot}/$PATH_GEM/$self->{board}";
            open($DIR, ">$self->{bbsroot}/$PATH_GEM/$self->{board}/.DIR");
            close $DIR;

            open($DIR, ">>$file")
		or die "can't write $BRD file for $self->{board}: $!";

	    no warnings 'uninitialized';
            print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
            close $DIR;

	    $self->post_new_board;
        }
    }

    close $DIR;
    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    no warnings 'uninitialized';

    $self->refresh($key);
    $self->{_hash}{$key} = $value;

    return unless $self->contains($key);

    my $file = "$self->{bbsroot}/$BRD";
    open(my $DIR, "+<$file") or die "cannot open $file for writing";
    seek $DIR, $packsize * $self->{recno}, 0;
    print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
    close $DIR;

    $self->filestamp($file);
    $self->shmtouch if exists $self->{shm};
}

sub shmtouch {
    my $self = shift;
    $self->{shm}{touchtime} = time();
}

sub remove {
    my $self = shift->ego;

    $self->remove_entry("$self->{bbsroot}/$BRD");

    OurNet::BBS::Utils::deltree("$self->{bbsroot}/$PATH_BRD/$self->{board}");
    OurNet::BBS::Utils::deltree("$self->{bbsroot}/$PATH_GEM/$self->{board}");

    return 1;
}

sub remove_entry {
    my ($self, $file, $recno) = @_;
    my ($before, $after) = ('', '');

    $self->refresh_meta;

    $recno = $self->{recno} unless defined $recno;

    open(my $DIR, "<$file") or die "cannot open $file for reading";

    if ($recno) {
        # before...
        seek $DIR, 0, 0;
        read($DIR, $before, $packsize * $recno);
    }

    if ($recno < ((stat($file))[7] / $packsize) - 1) {
        seek $DIR, $packsize * ($recno + 1), 0;
        read(
	    $DIR, $after, 
	    $packsize * (
		(stat($file))[7] - (($recno + 1) * $packsize)
	    )
	);
    }

    close $DIR;

    open($DIR, ">$file") or die "cannot open $file for writing";
    print $DIR $before . $after;
    close $DIR;
}

1;

# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/Article.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::Article;

use strict;
no warnings 'deprecated';
use fields qw/dbh board name dir recno mtime btime _ego _hash/;

# btime: file, mtime: index

use OurNet::BBS::Base (
    'ArticleGroup' => [qw/@packlist &new_id/],
);

sub refresh_body {
    my $self = shift;

    $self->{name} ||= $self->new_id();
    return if $self->timestamp(-1, 'btime')
              and defined $self->{_hash}{body};

    # XXX: FETCH BODY
    $self->{_hash}{body} = '' if 0;
    
    return 1;
}

sub refresh_header {
    my $self = shift;

    $self->{name} ||= $self->new_id();
    return if $self->timestamp(-1)
              and defined $self->{_hash}{header};

    $self->refresh_meta();

    # XXX: FETCH HEADER
    my ($from, $date);

    $self->{_hash}{header} = {
        From	=> $from  ||= (
            $self->{_hash}{author} .
            ($self->{_hash}{nick} ? " ($self->{_hash}{nick})" : '')
        ),
        Subject	=> $self->{_hash}{title},
        Date	=> $date ||= scalar localtime($self->{_hash}{id}),
	Board  	=> $self->{board},
    };

    OurNet::BBS::Utils::set_msgid($self->{_hash}{header});
    
    return 1;
}

sub refresh_meta {
    my $self = shift;

    $self->{name} ||= $self->new_id;
    return if $self->timestamp(-1);

    if (defined $self->{recno}) {
        # XXX: FETCH ONE ARTICLE HEADER
        # @{$self->{_hash}}{@packlist} = () if 0;
        undef $self->{recno}
            if ($self->{_hash}{id} and $self->{_hash}{id} ne $self->{name});
    }

    unless (defined $self->{recno}) {
        use Date::Parse;
        use Date::Format;

        $self->{_hash}{id}       = $self->{name};
        $self->{_hash}{author}   ||= 'guest.';
        $self->{_hash}{date}     ||= time2str(
	    '%y/%m/%d', str2time(scalar localtime)
	);
        $self->{_hash}{title}    ||= '(untitled)';

        # XXX: STORE INTO ARTICLE
    }
    else {
        $self->{_hash}{id}       = $self->{name};
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    $self->refresh_meta($key);

    if ($key eq 'body') {
        # XXX: WRITE BODY
        $self->{_hash}{$key} = $value;
        $self->{btime} = 1;
    }
    else {
        $self->{_hash}{$key} = $value;
        $self->{mtime} = 1;
    }

    return 1;
}

sub remove {
    my $self = shift;

    # XXX: DELETE ARTICLE ENTRY
    return 1;
}

1;


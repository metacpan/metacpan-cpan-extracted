# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/NNTP/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::NNTP::ArticleGroup;

# FIXME: use first/last update to determine refresh result

use strict;
no warnings 'deprecated';
use fields qw/nntp board first num last _ego _hash _array/;
use OurNet::BBS::Base;

use Date::Parse;
use Date::Format;

sub refresh_meta {
    my ($self, $key, $flag) = @_;

    @{$self}{qw/num first last/} = $self->{nntp}->group($self->{board})
	unless $self->{board} eq $self->{nntp}->group;

    return unless $flag;

    if ($flag == ARRAY or !defined($key)) {
	die "$key out of range" if defined($key) 
	    and $key < $self->{first} - 1 || $key >= $self->{last};

	my @keys = (
	    defined($key) ? $key : ($self->{first} - 1 .. $self->{last} - 1)
	);

	foreach my $key (@keys) {
	    next if $self->{_array}[$key]; # XXX: blind cache

	    my $msgid = $self->{nntp}->nntpstat($key + 1) or next;

	    $self->{_hash}{$msgid} = $self->{_array}[$key] = 
		$self->module('Article')->new({
		    nntp	=> $self->{nntp},
		    board	=> $self->{board},
		    recno	=> $key + 1,
		});
	}
    }
    elsif ($key) {
        return if $self->{_hash}{$key};

	my $msgid = $self->{nntp}->nntpstat($key)
	    or die "no such article $key";

	$self->{_hash}{$key} = $self->module('Article')->new({
	    nntp	=> $self->{nntp},
	    board	=> $self->{groupname},
	    recno	=> $key,
	});
    }

    return 1;
}

sub FETCHSIZE {
    my $self = $_[0]->ego;

    @{$self}{qw/num first last/} = $self->{nntp}->group($self->{board})
	unless defined($self->{last});

    return $self->{last} + 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    @{$self}{qw/num first last/} = $self->{nntp}->group($self->{board})
	unless $self->{board} eq $self->{nntp}->group;

    my %header = %{$value->{header}} or die "must specify header to post";

    $header{Date} = time2str('%d %b %Y %T %Z', str2time($header{Date}));
    $header{Newsgroups} ||= $self->{board};
    $header{'Message-ID'} =~ s/^([^<].*[^>])$/<$1>/;
    delete $header{Board};

    $self->{nntp}->post(
	(sort { $a cmp $b } map {"$_: $header{$_}\n"} (keys %header)),
	"\n", 
	$value->{body},
    );

    return 1;
}

1;

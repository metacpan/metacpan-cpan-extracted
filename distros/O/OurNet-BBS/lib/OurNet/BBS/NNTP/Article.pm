# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/NNTP/Article.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::NNTP::Article;

use strict;
no warnings 'deprecated';
use fields qw/nntp board recno _ego _hash/;
use OurNet::BBS::Base;

sub refresh_body {
    my $self = shift;
    return if defined $self->{_hash}{body};

    $self->{nntp}->group($self->{board})
	unless $self->{nntp}->group eq $self->{board};

    $self->{_hash}{body} = join('', @{$self->{nntp}->body($self->{recno})});

    return 1;
}

sub refresh_header {
    my $self = shift;
    return if defined $self->{_hash}{head};

    $self->{nntp}->group($self->{board})
	unless $self->{nntp}->group eq $self->{board};

    my $header = join('', @{$self->{nntp}->head($self->{recno})});
    $header =~ s/\n[\t ]+/ /g; # merge continuation lines
    $header = { $header =~ /^([\w-]+):\s*(.+)/mg };
    $header->{'Message-ID'} ||= delete $header->{'Message-Id'}; # XXX kluge

    $self->{_hash}{header} = $header;

    return 1;
}

sub refresh_meta { 1 }

sub STORE {
    die 'no Article STORE yet';
}

1;

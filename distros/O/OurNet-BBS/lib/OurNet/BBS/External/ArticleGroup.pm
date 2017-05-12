# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/External/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 3807 $ $DateTime: 2003/01/24 22:48:36 $

package OurNet::BBS::External::ArticleGroup;

use if $OurNet::BBS::Encoding, 'open' => ":encoding($OurNet::BBS::Encoding)";

use strict;
no warnings 'deprecated';
use fields qw/article_store article_fetch board name dir recno mtime btime _ego _hash _array/;

use Date::Parse;
use Date::Format;

# btime: header, mtime: directory

use OurNet::BBS::Base (
    '@packlist'   => [qw/id author nick date title/],
);

my $chrono = 0;

sub refresh_meta {
    my ($self, $key, $flag) = @_;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    ($self, my $flag) = @{${$self}};

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

    if ($value->{header}) {
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

    $value->{author} =~ s/(?:\.bbs)?(\@[^\@]*)\@.*/$1/;

    my $cmd = $self->{article_store};
    $cmd =~ s/\$\{?header\}?\{(\w+)\=([^\}]+)\}/$value->{header}{$1} = $2/eg;
    $cmd =~ s/\$\{(\w+)\=([^\}]+)\}/$value->{$1} = $2/eg;
    $cmd =~ s/\$\{?header\}?\{(\w+)\}/$value->{header}{$1}/g;
    $cmd =~ s/\$\{?(\w+)\}?/$value->{$1}/g;

    open my $fh, "| $cmd";
    while (my ($k, $v) = each %{$value->{header}}) {
	print $fh "$k: $v\n";
    }
    print $fh "\n$value->{body}";
    close $fh;

    return 1;
}

1;

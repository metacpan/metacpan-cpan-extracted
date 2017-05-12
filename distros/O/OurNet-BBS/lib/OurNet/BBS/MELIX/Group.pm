# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MELIX/Group.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MELIX::Group;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot parent recno group/,
           qw/time xmode xid id author nick date title mtime _ego _hash/;
use OurNet::BBS::Base (
    'GroupGroup'	=> [
	qw/$packstring $packsize @packlist &STORE &_refresh_meta/,
	qw/&GEM_FOLDER &GEM_BOARD &GEM_GOPHER &GEM_HTTP &GEM_EXTEND/,
    ],
    'Board'		=> [qw/&remove_entry/],
);

sub readok { 1 }
sub writeok { 0 }

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $board;

    if (index(' owner title id ', " $key ") > -1) {
	@{$self->{_hash}}{qw/owner title id/}
	    = @{$self}{qw/author title id/};
	return 1;
    }

    return $self->_refresh_meta;
}

sub remove {
    my $self = shift->ego;

    if ($self->{group}) {
	my $file = "$self->{bbsroot}/gem/\@/\@$self->{group}";

	open(my $GROUP, "<$file") or die "cannot open $file for reading";
	local $/ = \$packsize;

	my (%entry, $buf);
        my $recno = 0;

	while (defined($buf = <$GROUP>)) {
	    @entry{@packlist} = unpack($packstring, $buf);
	    $entry{id} =~ s/^@//;
	    last if $entry{id} eq $self->{id};
	    $recno++;
	}

	close $GROUP;
	$self->remove_entry($file, $recno) if ($entry{id} eq $self->{id});

    }

    return unlink "$self->{bbsroot}/gem/\@/\@$self->{group}";
}

1;

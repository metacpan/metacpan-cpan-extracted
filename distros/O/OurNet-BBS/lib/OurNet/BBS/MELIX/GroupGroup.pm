# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MELIX/GroupGroup.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 3972 $ $DateTime: 2003/01/28 11:41:10 $

package OurNet::BBS::MELIX::GroupGroup;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot group mtime _ego _hash/;
use OurNet::BBS::Base (
    '$packstring' => 'LLLZ32Z80Z50Z9Z73',
    '$packsize'   => 256,
    '@packlist'   => [qw/time xmode xid id author nick date title/],
    '$toplevel'	  => 'Class',
);

use constant GEM_FOLDER		=> 0x00010000;
use constant GEM_BOARD		=> 0x00020000;
use constant GEM_GOPHER		=> 0x00040000;
use constant GEM_HTTP		=> 0x00080000;
use constant GEM_EXTEND		=> 0x80000000;

sub readok { 1 }
sub writeok { 0 }

sub toplevel {
    my $self = shift;
    $toplevel = shift if @_;
    return $toplevel;
}

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{group} ||= $toplevel;

    return $self->_refresh_meta;
}

sub _refresh_meta {
    my $self = shift->ego;
    my $file = "$self->{bbsroot}/gem/\@/\@$self->{group}";
    return if $self->filestamp($file);

    %{$self->{_hash}} = ();

    my $GROUP;
    open($GROUP, "<$file") or open ($GROUP, "+>>$file")
        or warn("Cannot read group file $file: $!");

    return if (stat($file))[7] % $packsize;

    local $/ = \$packsize;

    my (%entry, $buf);
    my $recno = 0;

    while (defined($buf = <$GROUP>)) {
	@entry{@packlist} = unpack($packstring, $buf);

	$entry{id} =~ s/^@//;

	if ($entry{xmode} & GEM_BOARD) {
            $self->{_hash}{$entry{id}} = $self->module('Board')->new(
                $self->{bbsroot}, $entry{id},
            ) if -e "$self->{bbsroot}/brd/$entry{id}/.DIR";
	}
	elsif ($entry{xmode} & GEM_FOLDER) {
            $self->{_hash}{$entry{id}} = $self->module('Group')->new({
		bbsroot	=> $self->{bbsroot},
		parent	=> $self->{group},
		recno	=> $recno,
		group	=> $entry{id},
		map { $_ => $entry{$_} } @packlist,
	    }) if -e "$self->{bbsroot}/gem/\@/\@$entry{id}";
	}

	$recno++;
    }

    close $GROUP;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;
    $self->{group} ||= $toplevel;

    # heuristic:
    # - blessed refs are of their own type. 
    # - unblessed hashrefs are groups waiting to be built.
    #  = allows using ->{group} or the key for automatic creations.
    # - non-refs means auto-detection; try board first.

    if (!ref($value)) {
	# deduction time
	$value = (-e "$self->{bbsroot}/brd/$key/.DIR")
		    ? $self->module('Board')->new($self->{bbsroot}, $key)
		    : (-e "$self->{bbsroot}/gem/\@/\@$key")
			? $self->module('Group')->new($self->{bbsroot}, $key)
			: die "doesn't exists such group or board $key: panic!";
    }
    elsif (ref($value) eq 'HASH') {
	# create a new group here. yes. here.
	$key ||= $value->{id}; $value->{id} ||= $key;

	my $file = "$self->{bbsroot}/gem/\@/\@$key";
	unless (-e $file) {
	    open(my $DIR, ">$file") or die "cannot open $file for writing";
	    close $DIR;
	}
    }

    return if exists $self->{_hash}{$key}; # doesn't make sense yet

    my $file = "$self->{bbsroot}/gem/\@/\@$self->{group}";

    die "doesn't exists such group or board $key: panic!"
        unless (-e "$self->{bbsroot}/gem/\@/\@$key" or
                -e "$self->{bbsroot}/brd/$key/.DIR");

    my %entry = (
	xmode	=> ref($value) =~ /Board/ ? GEM_BOARD : GEM_FOLDER,
	'time'	=> scalar CORE::time,
    );

    if ($entry{xmode} eq GEM_BOARD) {
	$entry{author} = $value->{bm};
	$entry{title}  = $value->{title};
	$entry{id}     = $value->{id};
    }
    else {
	$entry{author} = $value->{owner};
	$entry{title}  = $value->{title};
	$entry{id}     = '@'.$value->{id};
    }

    no warnings 'uninitialized';
    open(my $DIR, "+>>$file")
	or die "can't write DIR file for $self->{group}: $!";
    print $DIR pack($packstring, @entry{@packlist});
    close $DIR;

    if (ref($value) eq 'HASH') {
	# promote it to a Group object
	$value = $self->module('Group')->new(
	    @{$self}{qw/bbsroot group/}, ((stat($file))[7] / $packsize) - 1,
	    $value->{id}, @entry{@packlist},
	);
    };

    $self->{_hash}{$key} = $value;
}

1;

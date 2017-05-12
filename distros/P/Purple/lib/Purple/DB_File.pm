package Purple::DB_File;

use strict;
use warnings;

use IO::File;
use DB_File;
use Purple::Sequence;

my $ORIGIN = '0';
my $LOCK_WAIT = 1;
my $LOCK_TRIES = 5;

my $DEFAULT_SEQUENCE        = 'sequence';
my $DEFAULT_SEQUENCE_INDEX  = 'sequence.index';
my $DEFAULT_SEQUENCE_RINDEX = 'sequence.rindex';

sub _New {
    my $class = shift;
    my %p     = @_;
    my $self;

    my $datadir = $p{store};
    $datadir =~ s{$}{/} if $datadir;

    $self->{datafile} = $datadir . $DEFAULT_SEQUENCE;
    $self->{indexfile} = $datadir . $DEFAULT_SEQUENCE_INDEX;
    $self->{revindexfile} = $datadir . $DEFAULT_SEQUENCE_RINDEX;

    bless($self, $class);
    return $self;
}

sub getNext {
    my ($self, $url) = @_;

    $self->_lockFile();
    my $value = $self->_retrieveNextValue();
    $self->_unlockFile();
    # update the NID to URL index
    if ($url) {
        $self->_updateIndex($value, $url);
    }

    return $value;
}

sub getURL {
    my ($self, $nid) = @_;
    my %index;
    my $url;

    $self->_tieIndex(\%index);
    $url = $index{$nid};

    untie %index;

    return $url;
}

sub updateURL {
    my ( $self, $url, @nids ) = @_;
    my ( %index, %revidx, %oldnids );

    $self->_tieIndex( \%index );
    $self->_tieRevIndex( \%revidx );
    my @stored_nids = split( " ", $revidx{$url} );
    foreach my $oldnid (@stored_nids) {
        $oldnids{$oldnid} = 1;
    }
    my @newnids = ();
    for my $new_nid (@nids) {
        delete $oldnids{$new_nid};
        $index{$new_nid} = $url;
        push @newnids, $new_nid;
    }
    for my $old_nid ( keys %oldnids ) {
        delete $index{$old_nid};

        #print STDERR "Delete($url) $old_nid\n";
    }
    my $new_info = join ( " ", @newnids, keys(%oldnids) );
    $revidx{$url} = $new_info;

    untie %revidx;
    untie %index;
}

sub getNIDs {
    my ($self, $url) = @_;

    my %revidx;
    $self->_tieRevIndex(\%revidx);

    my @nids = split(" ", $revidx{$url});
    untie %revidx;
    return @nids;
}

# XXX this is incomplete for this implementation
sub deleteNIDs {
    my ($self, @nids) = @_;
    my %index;
    $self->_tieIndex(\%index);

    foreach my $nid (@nids) {
        delete $index{$nid};
    }

    untie %index;
}

sub _tieIndex {
    my $self = shift;
    my $index = shift;
    my $file = $self->{indexfile};

    ( (-f $file) and tie(%$index, 'DB_File', $file, O_RDWR, 0666, $DB_HASH) )
    or tie(%$index, 'DB_File', $file, O_RDWR|O_CREAT, 0666, $DB_HASH)
    or die "unable to tie " . $file . ' ' . $!;
}

sub _tieRevIndex {
    my $self = shift;
    my $index = shift;
    my $file = $self->{revindexfile};

    ( (-f $file) and tie(%$index, 'DB_File', $file, O_RDWR, 0666, $DB_HASH) )
    or tie(%$index, 'DB_File', $file, O_RDWR|O_CREAT, 0666, $DB_HASH)
    or die "unable to tie " . $file . ' ' . $!;
}

sub _updateIndex {
    my $self = shift;
    my $value = shift;
    my $url = shift;
    my %index;
    my %revindex;

    $self->_tieIndex(\%index);
    $self->_tieRevIndex(\%revindex);
    $index{$value} = $url;
    my $new_info = '';
    $new_info = $revindex{$url} if $revindex{$url};

    $revindex{$url} = join(" ", split(" ", $new_info), $value);
    untie %index;
}


sub _lockFile {
    my $self = shift;
    # use simple directory locks for ease
    my $dir = $self->{datafile} . '.lck';
    my $tries = 0;

    # FIXME: copied from UseMod, relies on errno
    while (mkdir($dir, 0555) == 0) {
        if ($! != 17) {
            die "Unable to create locking directory $dir";
        }
        $tries++;
        if ($tries > $LOCK_TRIES) {
            die "Timeout creating locking directory $dir";
        }
        sleep($LOCK_WAIT);
    }
}
        
sub _unlockFile {
    my $self = shift;
    my $dir = $self->{datafile} . '.lck';
    rmdir($dir) or die "Unable to remove locking directory $dir: $!";
}

sub _getCurrentValue {
    my $self = shift;
    my $file = $self->{datafile};
    my $value;

    if (-f $file) {
        my $fh = new IO::File;
        $fh->open($file) || die "Unable to open $file: $!";
        $value = $fh->getline();
        $fh->close;
    } else {
        $value = $ORIGIN;
    }

    return $value;
}

sub _retrieveNextValue {
    my $self = shift;

    my $newValue
        = Purple::Sequence::increment_nid( $self->_getCurrentValue() );
    $self->_setValue($newValue);
    return $newValue;
}

sub _setValue {
    my $self = shift;
    my $value = shift;

    my $fh = new IO::File;
    if ($fh->open($self->{datafile}, 'w')) {
        print $fh $value;
        $fh->close;
    } else {
        die "unable to write value to " . $self->{datafile} . ": $!";
    }
}

# XXX docs are way out of date

=head1 NAME

Purple::DB_File - DB_File driver for Purple

=head1 SYNOPSIS

DB_File backend for storing and retrieving Purple nids.

    # XXX update this for factory stuff
    use Purple::DB_File;

    my $p = Purple::DB_File->new('purple.db');
    my $nid = $p->getNext('http://i.love.purple/');
    my $url = $p->getURL($nid);  # http://i.love.purple/

=head1 METHODS

=head2 new($db_loc)

Initializes NID database at $db_loc, creating it if it does not
already exist.  Defaults to "purple.db" in the current directory if
$db_loc is not specified.

=head2 getNext($url)

Gets the next available NID, assigning it $url in the database.

=head2 getURL($nid)

Gets the URL associated with NID $nid.

=head2 updateURL($url, @nids)

Updates the NIDs in @nids with the URL $url.

=head2 getNIDs($url)

Gets all NIDs associated with $url.

=head2 deleteNIDs(@nids)

Deletes all NIDs in @nids.

=head1 AUTHORS

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.comE<gt>

Gerry Gleason, E<lt>gerry@geraldgleason.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Based on L<PurpleWiki::Sequence>, which it attempts to replace.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

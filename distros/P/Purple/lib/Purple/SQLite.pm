package Purple::SQLite;

use strict;
use DBI;
use Purple::Sequence;

our $VERSION = '0.9';

my $DEFAULT_DB_LOC = 'purple.db';
# XXX not positive we want url to NOT NULL
# XXX last_nid table is for speed handling
my $CREATE_SQL1 = q{
    CREATE TABLE nids (
        nid TEXT PRIMARY KEY NOT NULL,
        url TEXT NOT NULL,
        created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
        updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
    );
};
my $CREATE_SQL2 = q{
    CREATE TABLE lastnid (
        nid TEXT NOT NULL
    );
};
my $CREATE_SQL3 = q{
    INSERT INTO lastnid (nid) VALUES ('0');
};

sub _New {
    my $class = shift;
    my %p     = @_;
    my $self;

    my $db_loc;
    if ($p{store}) {
        $db_loc = $p{store} . '/' . $DEFAULT_DB_LOC;
    }
    $db_loc ||= $DEFAULT_DB_LOC;

    $self->{db_loc} = $db_loc;

    $self->{dbh} = DBI->connect("dbi:SQLite:$db_loc", undef, undef);
#                                { AutoCommit => 0 });

    # create nids table if it doesn't already exist
    if (!_table_exists($self->{dbh}, 'nids')) {
        $self->{dbh}->do($CREATE_SQL1);
        $self->{dbh}->do($CREATE_SQL2);
        $self->{dbh}->do($CREATE_SQL3);
    }
    bless($self, $class);
}

# XXX retrieving the lastnid is slow
# using max does not work when the nids are mixed numbers and letters
# last_row_id (see DBD::SQLite) was tested as well as the below, 
# neither is great
sub getNext {
    my ($self, $url) = @_;

    $self->{dbh}->do('BEGIN TRANSACTION');
    # get next NID
    my $sth = $self->{dbh}->prepare('SELECT nid FROM lastnid');
    $sth->execute();
    my $currentNid = ($sth->fetchrow_array)[0];
    my $nextNid = Purple::Sequence::increment_nid($currentNid);
    # update NID->URL value
    $self->{dbh}->do("INSERT INTO nids (nid, url) VALUES ('$nextNid', '$url')");
    $self->{dbh}->do("UPDATE lastnid SET nid = '$nextNid'");
    $self->{dbh}->do('COMMIT TRANSACTION');

    return $nextNid;
}

sub getURL {
    my ($self, $nid) = @_;
    my $sth = $self->{dbh}->prepare('SELECT url FROM nids WHERE nid = ?');
    $sth->execute($nid);
    return ($sth->fetchrow_array)[0];
}

sub updateURL {
    my ($self, $url, @nids) = @_;
    my $questionMarks = join(', ', map('?', @nids));

    $self->{dbh}->do(qq{
        UPDATE nids SET url = ?, updated_on = ? WHERE nid IN ($questionMarks)
      }, undef, $url, &_timestamp, @nids);
}

sub getNIDs {
    my ($self, $url) = @_;

    my $sth = $self->{dbh}->prepare('SELECT nid FROM nids WHERE url = ?');
    $sth->execute($url);

    my @nids;
    while (my $nid = $sth->fetchrow_array) {
        push @nids, $nid;
    }
    return @nids;
}

sub deleteNIDs {
    my ($self, @nids) = @_;
    my $questionMarks = join(', ', map('?', @nids));

    $self->{dbh}->do("DELETE FROM nids WHERE nid IN ($questionMarks)", 
                     undef, @nids);
}

### private

sub _timestamp {
    my @timestamp = localtime;
    return sprintf('%d-%02d-%02d %02d:%02d:%02d', $timestamp[5] + 1900,
                   $timestamp[4] + 1, $timestamp[3], $timestamp[2],
                   $timestamp[1], $timestamp[0]);
}

# stolen from
# http://gmax.oltrelinux.com/dbirecipes.html#checking_for_an_existing_table
sub _table_exists {
    my $dbh = shift;
    my $table = shift;
    my @tables = $dbh->tables('','','','TABLE');
    if (@tables) {
        for (@tables) {
            next unless $_;
            return 1 if $_ eq $table
        }
    }
    else {
        eval {
            local $dbh->{PrintError} = 0;
            local $dbh->{RaiseError} = 1;
            $dbh->do(qq{SELECT * FROM $table WHERE 1 = 0 });
        };
        return 1 unless $@;
    }
    return 0;
}

### fini

=head1 NAME

Purple::SQLite - SQLite driver for Purple

=head1 VERSION

Version 0.9

=head1 SYNOPSIS

SQLite backend for storing and retrieving Purple nids.

    use Purple::SQLite;

    my $p = Purple::SQLite->new('purple.db');
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

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Geraldine's and El Sombrero in Seattle for sustaining us
while we coded away.  In particular, Eugene would not have made it had
it not been for that macho margarita.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Purple::SQLite

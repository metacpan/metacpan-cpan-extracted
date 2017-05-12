=head1 NAME

Net::Download::Queue::DBI - Net::Download::Queue::DBI base class

=head1 SYNOPSIS



=cut





package Net::Download::Queue::DBI;
use base 'Class::DBI::SQLite';
#use base 'Class::DBI::mysql';



our $VERSION = 0.01;



use strict;
use File::Basename;





=head1 CLASS METHODS

These must be before the other ones...


=head2 fileDatabase()

Return file name of SQLite database.

=cut
sub fileDatabase {
    return("./download-queue.db");
}





=head2 rebuildDatabase()

Empty and rebuild the SQLite database.

Return 1 on success, else die on errors.

=cut
sub rebuildDatabase {
    my $pkg = shift;

    $pkg->db_Main->disconnect;  #To avoid it being locked when unlinking

    my $fileDatabase = $pkg->fileDatabase;
    unlink($fileDatabase); -f $fileDatabase and die("Could not delete existing database file ($fileDatabase): $!\n");

    return( $pkg->ensureDatabase() );
}





=head2 ensureDatabase()

Rebuild the SQLite database if it's not present.

Return 1 on success, else die on errors.

=cut
sub ensureDatabase {
    my $pkg = shift;
    my $fileDatabase = $pkg->fileDatabase;
    -f $fileDatabase and return(1);

    my $fileSql = dirname(__FILE__) . "/database/sqlite/create.sql";
    -f $fileSql or die("Could not find SQLite create file ($fileSql)\n");

#    warn "dbish\n";
    `dbish "dbi:SQLite:dbname=$fileDatabase" < "$fileSql" 2>&1`;

    return(1);
}





__PACKAGE__->ensureDatabase();   #Must be there before set_db

my $fileDatabase = __PACKAGE__->fileDatabase;
my ($dsn, $username, $password) = ("dbi:SQLite:dbname=$fileDatabase", undef, undef);
#my ($dsn, $username, $password) = ("dbi:mysql:database=app;port=3306", "app", "abc123");
__PACKAGE__->set_db('Main', $dsn, $username, $password, { AutoCommit => 1 } );

#my $dbh = DBI->connect($dsn, $username, $password) or die("Could not connect to db\n");





=head1 METHODS


=head1 CLASS METHODS

=head2 accessor_name

Reformat accessor names. Overridden.

=cut
sub accessor_name { my $pkg = shift;
	my ($column) = @_;

	$column =~ s/ (_+)  (\w) / uc($2) /gex;

	return($column);
}





=head2 search_first

Like search(), but return the first row.

=cut
sub search_first {
    my $pkg = shift;

	my $itRow = $pkg->search(@_);

	return($itRow->next);
}





=head2 oDownloadStatus($name)

Return DownloadStatus object with $name, or die on errors.

=cut
sub oDownloadStatus {
    my $pkg = shift;
    my ($name) = @_;

    my $oStatus = Net::Download::Queue::DownloadStatus->search_first({name => $name}) or die("Could not get status ($name)\n");
    
    return($oStatus);
}





1;





__END__

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-download-queue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Download-Queue>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

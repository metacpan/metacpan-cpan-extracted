package SPOPSx::Ginsu::DBI;

use strict;
use vars qw($VERSION $DSN $USER $PASS);

$VERSION = sprintf "%d.%03d", q$Revision: 1.18 $ =~ /: (\d+)\.(\d+)/;

use base qw( SPOPS::DBI::MySQL SPOPS::DBI );
use SPOPS 0.86;
use SPOPS::DBI;
use SPOPS::DBI::MySQL;

sub dbi_connect {
	my $self = shift;
	$self->set_dbi_connect_args(@_)	if @_;
	return DBI->connect( $self->DBI_DSN, $self->DBI_USER, $self->DBI_PASS, $self->DBI_OPT );
}

sub dbi_disconnect {
	my $self = shift;
	$self->DBH->disconnect;
	$self->set_DBH( undef );
}

sub global_datasource_handle {
	my ($self) = @_;
	my $attempts = 1;
	until ( $self->DBH && $self->DBH->ping ) {
		if (my $dbh = $self->dbi_connect ) {
			$self->set_DBH( $dbh );
		} else {
			$attempts++;
			warn "DBI->connect() attempt " . $attempts . " (pid = $$): $DBI::errstr\n";
			die  "DBI->connect() failed: $DBI::errstr"	if $attempts > 10;
			sleep 1										if $attempts > 5;
		};
	}
	return $self->DBH;
}

sub drop_table {
	my $class = shift;
# This will only work for classes whose config has been processed.
# I.e. it won't work for our ClubMembers type of class which is
# only used to create a 'links_to' table
# 	my $SQL = "DROP TABLE " .  $class->CONFIG->{base_table};

# ... so we have to do it this way instead ...
	my $conf = eval '$' . $class . '::CONF';
	if ($conf) {
		my ($alias) = grep $conf->{$_}->{class} eq $class, keys %$conf;
		my $SQL = "DROP TABLE IF EXISTS " .  $conf->{$alias}->{base_table};
		my $db = $class->global_datasource_handle;
		$db->do($SQL);
	}
	
	return 1;
}

sub create_table {
	my $class = shift;
	my $SQL = eval '$' . $class . '::TABLE_DEF';
	if ($SQL) {
		my $db = $class->global_datasource_handle;
		$db->do($SQL) or die $db->errstr;
	}
}

sub recreate_table {
	my $class = shift;
	$class->drop_table;
	$class->create_table;
}

1;
__END__

=head1 NAME

SPOPSx::Ginsu::DBI - Ginsu datasource base class.

=head1 SYNOPSIS

Assuming the files MyDBI.pm, MyBaseObject.pm, MyObject.pm and
my_dbi_conf.pm from steps 1-4 of SPOPSx::Ginsu POD SYNOPSIS ...

  use my_dbi_conf.pm          # defines package variables for DSN, etc.
  use MyObject;
  
  MyObject->dbi_connect;
  MyObject->dbi_disconnect;

  $dbh = MyObject->global_datasource_handle;
  
  MyObject->drop_table;
  MyObject->create_table;
  MyObject->recreate_table;

=head1 DESCRIPTION

This class inherits from SPOPS::DBI::MySQL and SPOPS::DBI and serves as
a base class for your own datasource class (e.g. t/MyDBI.pm) which is in
turn a base class for all of your Ginsu object classes. The methods
defined here and inherited by all Ginsu objects are for creating,
destroying and returning the database connection, and dropping, creating
and recreating (dropping and creating again) the table corresponding to
the class. All methods are class methods, but can also be called as
object methods.

The database connection parameters DBI_DSN, DBI_USER, DBI_PASS, and
DBI_OPT are held in package variables with the respective names in your
datasource class (e.g. t/MyDBI.pm). Closures of the same names are used
to return their values and a closure, C<set_dbi_connect_args()> is used
to set their values. Another datasource class package variable, DBH,
holds the database handle when connected. This is also accessed and set
through closures named C<DBH()> and C<set_DBH()>, respectively. Please see
t/MyDBI.pm for an example of such

=head1 METHODS

=head2 Public Class Methods

=over 4

=item dbi_connect

 $rc = CLASS->dbi_connect
 $rc = CLASS->dbi_connect( $DBI_DSN, $DBI_USER, $DBI_PASS, $DBI_OPT )

Calls DBI->connect() and passes back the return value. Arguments to
DBI->connect() are found by calling the DBI_DSN, DBI_USER, DBI_PASS and
DBI_OPT methods. If values are passed in for these arguments, they are
first passed to the C<set_dbi_connect_args()> method.

=item dbi_disconnect

 CLASS->dbi_disconnect

Calls disconnect() on the handle retured by the classes C<DBH()> method.
Then sets clears the database handle by passing undef to the
C<set_DBH()> method.

=item global_datasource_handle

 $dbh = CLASS->global_datasource_handle
 $dbh = $object->global_datasource_handle
 
Returns a DBI database handle. If a cached handle is not available, it
calls C<dbi_connect> and caches and returns the handle. Retries 10
times if necessary, before giving up.

=item drop_table

 CLASS->drop_table

Drops the class's base_table from the database.

=item create_table

 CLASS->create_table

Creates the class's table based on the SQL stored in the class's
$TABLE_DEF. We typically use 'CREATE TABLE IF NOT EXISTS'.

=item recreate_table

 CLASS->recreate_table

Does a C<drop_table()> followed by a C<create_table()>.

=back

=head1 BUGS / TODO

=over 4

=item *

Need to refactor some to make it easy to extend to other databases
supported by SPOPS. Probably should use some sort of database
independent keys and database specific substitution as in
SPOPS::Import::DBI::TableTransform.

=back

=head1 CHANGE HISTORY

=over 4

$Log: DBI.pm,v $
Revision 1.18  2004/06/02 15:05:42  ray
Now requires SPOPS-0.86

Revision 1.17  2004/04/23 18:05:30  ray
Updated docs.

Revision 1.16  2004/04/23 16:50:54  ray
Renamed from ESPOPS::DBI and updated docs.


=back

=head1 COPYRIGHT

Copyright (c) 2001-2004 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

SPOPS(3)
SPOPS::DBI(3)
SPOPS::DBI::MySQL(3)
perl(1)

=cut

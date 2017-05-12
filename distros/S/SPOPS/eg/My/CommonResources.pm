package My::CommonResources;

# $Id: CommonResources.pm,v 3.1 2003/07/15 12:19:47 lachoy Exp $

use strict;
use Data::Dumper qw( Dumper );
use DBI;

$My::CommonResources::VERSION = sprintf("%d.%02d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/);

my ( $DB, $USER, $GROUP );

sub set_user {
    my ( $class, $user ) = @_;
    unless ( $class->global_group_current ) {
        $class->set_group( $user->group );
    }
    return $USER = $user;
}

sub set_group {
    my ( $class, $group ) = @_;
    return $GROUP = $group;
}


# You can change who the superuser is by modifying this ID

sub get_superuser_id  { return 1 }
sub get_supergroup_id { return 1 }

sub global_security_object_class { return 'My::Security' }
sub global_user_current          { return $USER }
sub global_group_current         { return $GROUP }

sub global_datasource_handle {
    return $DB if ( $DB );
    $DB = DBI->connect( My::Common->DBI_DSN, My::Common->DBI_USER, My::Common->DBI_PASSWORD,
                        { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    unless ( $DB ) { SPOPS::Exception->throw( "Cannot connect to DB: $DBI::errstr" ) }
    return $DB;
}

1;

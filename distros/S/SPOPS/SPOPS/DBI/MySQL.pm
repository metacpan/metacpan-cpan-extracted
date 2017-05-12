package SPOPS::DBI::MySQL;

# $Id: MySQL.pm,v 3.5 2004/06/02 00:48:22 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory qw( OK NOTIFY );
use SPOPS::Key::DBI::HandleField;

my $log = get_logger();

$SPOPS::DBI::MySQL::VERSION  = sprintf("%d.%02d", q$Revision: 3.5 $ =~ /(\d+)\.(\d+)/);

sub sql_current_date  { return 'NOW()' }

# Backward compatibility (basically) -- you just have to set a true
# value in the config if you have an auto-increment field in the
# table. If so we call the post_fetch_id method from
# SPOPS::Key::DBI::HandleField.

sub post_fetch_id {
    my ( $item, @args ) = @_;
    return undef unless ( $item->CONFIG->{increment_field} );
    $item->CONFIG->{handle_field} ||= 'mysql_insertid';
    $log->is_info &&
        $log->info( "Setting to handle field: $item->CONFIG->{handle_field}" );
    return SPOPS::Key::DBI::HandleField::post_fetch_id( $item, @args );
}


# Code generation behavior -- find defaults if asked

sub behavior_factory {
    my ( $class ) = @_;
    $log->is_info &&
        $log->info( "Installing MySQL default discovery for ($class)" );
    return { manipulate_configuration => \&find_mysql_defaults };
}


sub find_mysql_defaults {
    my ( $class ) = @_;
    my $CONFIG = $class->CONFIG;
    return ( OK, undef ) unless ( $CONFIG->{find_defaults} and $CONFIG->{find_defaults} eq 'yes' );
    my $dbh = $class->global_datasource_handle( $CONFIG->{datasource} );
    unless ( $dbh ) {
      return ( NOTIFY, "Cannot find defaults because no DBI database " .
                       "handle available to class ($class)" );
    }

    my $sql = "DESCRIBE $CONFIG->{base_table}";
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute;
    };
    if ( $@ ) {
      return ( NOTIFY, "Cannot find defaults because there was an error " .
                       "executing ($sql): $@. Class: $class" );
    }
    while ( my $row = $sth->fetchrow_arrayref ) {
        my $default = $row->[4];
        next unless ( $default );
        $CONFIG->{default_values}{ $row->[0] } = $default;
    }
}

1;

__END__

=head1 NAME

SPOPS::DBI::MySQL -- MySQL-specific code for DBI collections

=head1 SYNOPSIS

 myobject => {
   isa             => [ qw( SPOPS::DBI::MySQL SPOPS::DBI ) ],
   increment_field => 1,
 };

=head1 DESCRIPTION

This just implements some MySQL-specific routines so we can abstract
them out.

One of these items is to return the just-inserted ID. Only works for
tables that have at least one auto-increment field:

 CREATE TABLE my_table (
   id  int not null auto_increment,
   ...
 )

You must also specify a true value for the class configuration
variable 'increment_field' to be able to automatically retrieve
auto-increment field values.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Key::HandleField|SPOPS::Key::HandleField>

L<DBD::mysql|DBD::mysql>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

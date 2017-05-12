package SPOPS::Tool::DBI::DiscoverField;

# $Id: DiscoverField.pm,v 3.6 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory qw( ERROR OK NOTIFY );

my $log = get_logger();

$SPOPS::Tool::DBI::DiscoverField::VERSION = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);

sub behavior_factory {
    my ( $class ) = @_;
    $log->is_info &&
        $log->info( "Installing field discovery for ($class)" );
    return { manipulate_configuration => \&discover_fields };
}

sub discover_fields {
    my ( $class ) = @_;
    my $CONFIG = $class->CONFIG;
    return ( OK, undef ) unless ( $CONFIG->{field_discover} eq 'yes' );
    my $dbh = $class->global_datasource_handle( $CONFIG->{datasource} );
    unless ( $dbh ) {
        $CONFIG->{field}      = undef;
        $CONFIG->{field_list} = undef;
        return ( NOTIFY, "Cannot discover fields because no DBI database " .
                         "handle available to class ($class)" );
    }
    my $sql = $class->sql_fetch_types( $CONFIG->{base_table} );
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute;
    };
    if ( $@ ) {
        $CONFIG->{field} = undef;
        return ( NOTIFY, "Cannot discover fields: $@" );
    }
    $CONFIG->{field}     = [ map { lc $_ } @{ $sth->{NAME} } ];
    $CONFIG->{field_raw} = [ @{ $sth->{NAME} } ];
    $log->is_info &&
        $log->info( "Table: ($CONFIG->{base_table}); ",
			          "Fields: (", join( ', ', @{ $CONFIG->{field} } ), ")" );
    return ( OK, undef );
}

1;

__END__

=head1 NAME

SPOPS::Tool::DBI::DiscoverField - SPOPS::ClassFactory rule implementing autofield discovery

=head1 SYNOPSIS

  my $config = {
        myobject => { class          => 'My::Object',
                      isa            => [ 'SPOPS::DBI' ],
                      field          => [], # just for show...
                      rules_from     => [ 'My::DiscoverField' ],
                      field_discover => 'yes',
                      base_table     => 'mydata',
                      ...  },
  };
  my $class_list = SPOPS::Initialize->process({ config => $config });

  # All fields in 'mydata' table now available as object properties

=head1 DESCRIPTION

Simple behavior rule to dynamically find all fields in a particular
database table and set them in our object.

Configuration is easy, just put:

 rules_from => [ 'My::DiscoverField' ],

in your object configuration, or add 'My::DiscoverField' to an
already-existing 'rules_from' list. Then add:

 field_discover => 'yes',

to your object configuration. Initialize the class and everything in
'field' will be overwritten.

=head1 GOTCHAS

These fields are only discovered once, when the class is created. If
you modify the schema of a table (such as with an 'ALTER TABLE'
statement while a process (like a webserver) is running with SPOPS
definitions the field modifications will not be reflected in the
object class definition. (This is actually true of all
L<SPOPS::DBI|SPOPS::DBI> objects, but probably more apt to pop up
here.)

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

package OpenInteract::SQLInstall;

# $Id: SQLInstall.pm,v 1.22 2003/01/07 13:46:54 lachoy Exp $

use strict;
use Class::Date;
use Data::Dumper           qw( Dumper );
use OpenInteract::Package;
use SPOPS::SQLInterface;

@OpenInteract::SQLInstall::ISA      = qw();
$OpenInteract::SQLInstall::VERSION  = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);

use constant DEBUG => 0;


# Ensure that the installer is 'require'd -- put the package dir(s)
# into @INC and read the class name from the package itself.

sub require_package_installer {
    my ( $class, $pkg_info ) = @_;

    # Ensure that the necessary directories from the package are in @INC

    OpenInteract::Package->add_to_inc( $pkg_info );
    my $installer_class = $pkg_info->{sql_installer};
    return undef unless ( $installer_class );

    DEBUG && _w( 1, "Trying to require ($installer_class) from ($class) for ($pkg_info->{name})" );
    eval "require $installer_class";
    die "Cannot include installer ($installer_class) to system. Error: $@\n" if ( $@ );
    return $installer_class;
}


# TODO: This whole status thing sucks. We should create an
# OpenInteract::Manage::Status object that can hold all this crap

# Use this to apply a particular action
#
# Parameters:
#   action:  action you want to do (create_structure|install_data|install_security)
#   db:      DBI database handle (in correct db, RaiseError on)
#   config:  config object/hashref
#   package: package for which you're installing
#   status:  'raw' (get back arrayref of raw status items) (optional)

sub apply {
    my ( $class, $p ) = @_;

    # TODO: we assume the db driver is the one from the 'main'
    # datasource for now -- we'll probably have to revisit this

    my $driver_name = $class->find_database_driver( $p->{config}, 'main' );
    my $action = $p->{action_code};
    unless ( $action ) {
        DEBUG && _w( 1, "Finding coderef for $p->{action}" );
        my $handlers = $class->read_db_handlers( $driver_name );
        $action = $handlers->{ $p->{action} };
    }
    unless ( $action ) {
        my $msg = "$p->{action} for $driver_name: no action taken";
        return ( $p->{status} eq 'raw' )
                 ? [ { ok => 1, msg => $msg } ]
                 : $msg;
    }

    my $status = [];

    # Do this when the first item in the handler definition is the
    # subroutine, next is the hashref of arguments

    if ( ref $action eq 'ARRAY' ) {
        my $routine = shift @{ $action };
        my $extra_args = ( ref $action->[0] eq 'HASH' ) ? $action->[0] : {};
        my $args = { package => $p->{package},
                     db      => $p->{db},
                     config  => $p->{config},
                     %{ $extra_args } };
        $status = $class->$routine( $args );
    }

    # Do this when there is actual code to run

    elsif ( ref $action eq 'CODE' ) {
        $status = $action->( $class, { package => $p->{package},
                                       db      => $p->{db},
                                       config  => $p->{config} });
    }
    else {
        my $msg = 'Action is not of expected type, so nothing run.';
        return ( $p->{status} eq 'raw' )
                 ? [ { ok => 1, msg => $msg } ]
                 : $msg;
    }
    return $status if ( $p->{status} eq 'raw' );
    return $class->format_status( { action      => $p->{action},
                                    driver_name => $driver_name },
                                  $status );
}



# Read in a set of SQL files and execute them, doing necessary
# replacements before doing so; returns an arrayref of status hashrefs

sub create_structure {
    my ( $class, $p ) = @_;
    unless ( ref $p->{table_file_list} eq 'ARRAY' ) {
        return [{ type => 'structure',
                  ok   => 0,
                  msg  => 'No files given from which to read structures!' }];
    }

    my $pkg_info = $p->{package};

    # TODO: we assume the db driver is the one from the 'main'
    # datasource for now -- we'll probably have to revisit this

    my $driver_name = $class->find_database_driver( $p->{config}, 'main' );
    my $struct_dir = join( '/', $pkg_info->{website_dir}, $pkg_info->{package_dir}, 'struct' );
    my @status = ();
    foreach my $table_file ( @{ $p->{table_file_list} } ) {
        my $this_status = { type => 'structure', name => $table_file, ok => 1 };
        my $table_sql = eval { $class->read_file( "$struct_dir/$table_file" ) };
        if ( $@ ) {
            $this_status->{ok} = 0;
            $this_status->{msg} = "Cannot open/read file for table SQL ($struct_dir/$table_file): $@";
            DEBUG && _w( 1, " -- $this_status->{msg}" );
        }
        else {
            $table_sql = $class->sql_modify_increment( $p->{config}, $driver_name, $table_sql );
            $table_sql = $class->sql_modify_increment_type( $p->{config}, $driver_name, $table_sql );
            $table_sql = $class->sql_modify_usertype( $p->{config}, $driver_name, $table_sql );
            $table_sql = $class->sql_modify_grouptype( $p->{config}, $driver_name, $table_sql );
            $table_sql = $class->sql_modify_datetime( $p->{config}, $driver_name, $table_sql );
            eval { $p->{db}->do( $table_sql ) };
            if ( $@ ) {
                $this_status->{ok} = 0;
                $this_status->{msg} = "Cannot execute table SQL\n$table_sql\nError: $@";
                DEBUG && _w( 1, " -- $this_status->{msg}" );
            }
            else {
                $this_status->{msg} = "Created table from ($table_file): ok";
                DEBUG && _w( 1, "Structure (from $table_file) ok!" );
            }
        }
        push @status, $this_status;
    }
    return \@status;
}



# Takes a set of filenames of data and processes each of them; returns
# an arrayref of status hashrefs

sub install_data {
    my ( $class, $p ) = @_;
    unless ( ref $p->{data_file_list} eq 'ARRAY' ) {
        return [ { type => $p->{type},
                   ok   => 0,
                   msg  => 'No files given from which to read data!' } ];
    }

    my $pkg_info = $p->{package};
    my $data_dir = $p->{data_dir} || join( '/', $pkg_info->{website_dir}, $pkg_info->{package_dir}, 'data' );
    my @status = ();
    my %args = ( db => $p->{db}, config => $p->{config} );
    foreach my $data_file ( @{ $p->{data_file_list} } ) {
        my $this_status = { type => $p->{type}, name => $data_file, ok => 1 };
        my $process_status = eval { $class->process_data_file({ %args,
                                                                filename => "$data_dir/$data_file" }) };
        if ( $@ ) {
            $this_status->{ok}  = 0;
            $this_status->{msg} = "Error: $@";
        }
        else {
            $this_status->{msg} = ( $process_status->{msg} )
                                    ? "$process_status->{msg} (from $data_file): ok"
                                    : "Processed data (from $data_file): ok";
        }
        push @status, $this_status;
    }
    return \@status;
}



# Processes a single .dat data file

# TODO: Split out the actual processing so we can feed the data and
# action in and get the same result whether we generate the data
# ourselves or read it from a file

sub process_data_file {
    my ( $class, $p ) = @_;
    unless ( -f $p->{filename} ) {
        die "Cannot process data file without valid filename! ",
            "(Filename given: <$p->{filename}>)\n";
    }
    my $info = $class->read_perl_file( $p->{filename} );
    return {} unless ( ref $info eq 'ARRAY' and ref $info->[0] eq 'HASH' );
    my $action = shift @{ $info };

    # Transform all the data at once

    my $trans_data = $class->transform_data( $action, $info, $p );

    # Something defined in 'sql_type' signifies that we're going to
    # process a given SQL statement for as many data entries as there
    # are

    my ( $process_sql, $save_object );
    if ( my $sql_type = $action->{sql_type} ) {
        DEBUG && _w( 1, "Reading data for prepared SQL statements" );
        my $types = undef;
        foreach my $data ( @{ $trans_data } ) {
            eval {
                if ( $sql_type eq 'insert' ) {
                    SPOPS::SQLInterface->db_insert({
                         db    => $p->{db},
                         table => $action->{sql_table},
                         field => $action->{field_order},
                         value => $data,
                         dbi_type_info => $action->{field_type} });
                    $process_sql++;
                }
                if ( $sql_type eq 'update' ) {
                    SPOPS::SQLInterface->db_update({
                         db    => $p->{db},
                         table => $action->{sql_table},
                         where => $action->{sql_where},
                         value => $data,
                         dbi_type_info => $action->{field_type} });
                    $process_sql++;
                }
                if ( $sql_type eq 'delete' ) {
                    SPOPS::SQLInterface->db_delete({
                         db => $p->{db},
                         table => $action->{sql_table},
                         where => $action->{sql_where},
                         value => $data,
                         dbi_type_info => $action->{field_type} });
                    $process_sql++;
                }
            };
            if ( $@ ) {
                die "Error executing SQL statement type $sql_type\n",
                    "Data: ((", join( ', ', @{ $data } ), "))\nError: $@\n";
            }
        }
    }

    # If a 'spops_class' exists, we want to create an object for each
    # item of data

    elsif ( my $object_class = $action->{spops_class} ) {
        my $website_name = $p->{config}{server_info}{website_name} || $p->{config}{website_name};
        $object_class = $class->sql_class_to_website( $website_name, $object_class );
        DEBUG && _w( 1, "Reading data for class $object_class" );
        my $fields = $action->{field_order};
        my $num_fields = scalar @{ $fields };
        foreach my $data ( @{ $trans_data } ) {
            my $obj = $object_class->new;
            foreach my $i ( 0 .. ( $num_fields - 1 ) ) {
                $obj->{ $fields->[ $i ] } = $data->[ $i ];
            }
            eval { $obj->save({ db            => $p->{db},
                                is_add        => 1,
                                skip_log      => 1,
                                skip_security => 1,
                                skip_cache    => 1,
                                DEBUG         => DEBUG }) };
            if ( $@ ) {
                my $ei = SPOPS::Error->get;
                die "Cannot create SPOPS object!\nBasic: $@\n",
                    "Error: $ei->{system_msg}\n";
            }
            else {
                $save_object++;
            }
        }
    }
    if ( $process_sql ) {
        return { ok => 1, msg => "Processed ($process_sql) SQL statements." };
    }
    elsif ( $save_object ) {
        return { ok => 1, msg => "Created ($save_object) SPOPS objects" };
    }
    return { ok => 1 };
}


# Find the driver to use

sub find_database_driver {
    my ( $class, $config, $connect_key ) = @_;
    my $driver = $config->{db_info}{ $connect_key }{sql_install} ||
                 $config->{db_info}{ $connect_key }{driver_name};
    unless ( $driver ) {
        die "Cannot find database driver given connection key ($connect_key)";
    }
    return $driver;
}


# Get the hash of handlers from an installer class

sub read_db_handlers {
    my ( $class, $driver_name ) = @_;
    no strict 'refs';
    my %handlers = %{ $class . '::HANDLERS' };
    my $db_handlers = {};
    foreach my $action ( keys %handlers ) {
        $db_handlers->{ $action } = $handlers{ $action }{ $driver_name } ||
                                    $handlers{ $action }{'_default_'};
    }
    return $db_handlers;
}


########################################
# DATA TRANSFORMATION
########################################

# Transform all of the data from whatever source

sub transform_data {
    my ( $class, $action, $data_list, $p ) = @_;

    # Setup the field order as a hash for the implementors

    for ( my $i = 0; $i < scalar @{ $action->{field_order} }; $i++ ) {
        $p->{field_order}{ $action->{field_order}->[ $i ] } = $i;
    }

    # If an action specifies to change a field TO a particular website

    if ( ref $action->{transform_class_to_website} eq 'ARRAY' ) {
        $data_list = $class->_transform_class_to_website( $action, $data_list, $p );
    }

    # If an action specifies to change a field FROM a particular website

    if ( ref $action->{transform_class_to_oi} eq 'ARRAY' ) {
        $data_list = $class->_transform_class_to_oi( $action, $data_list, $p );
    }

    # If an action specifies lookup a field in the 'default_objects'
    # server configuration key

    if ( ref $action->{transform_default_to_id} eq 'ARRAY' ) {
        $data_list = $class->_transform_default_to_id( $action, $data_list, $p );
    }

    # If an action specifies set the value of a particular field to a
    # date string representing right now.

    if ( ref $action->{transform_to_now} eq 'ARRAY' ) {
        $data_list = $class->_transform_to_now( $action, $data_list, $p );
    }

    return $data_list;
}



sub _transform_class_to_website {
    my ( $class, $action, $data_list, $p ) = @_;
    my $website_name = $p->{config}{server_info}{website_name} || $p->{config}{website_name};
    foreach my $data ( @{ $data_list } ) {
        foreach my $website_field ( @{ $action->{transform_class_to_website} } ) {
            my $idx = $p->{field_order}{ $website_field };
            $data->[ $idx ] =  $class->sql_class_to_website( $website_name, $data->[ $idx ] );
        }
    }
    return $data_list;
}



sub _transform_class_to_oi {
    my ( $class, $action, $data_list, $p ) = @_;
    my $website_name = $p->{config}{server_info}{website_name} || $p->{config}{website_name};
    foreach my $data ( @{ $data_list } ) {
        foreach my $website_field ( @{ $action->{transform_class_to_oi} } ) {
            my $idx = $p->{field_order}{ $website_field };
            $data->[ $idx ] = $class->sql_class_to_oi( $website_name, $data->[ $idx ] );
        }
    }
    return $data_list;
}


sub _transform_default_to_id {
    my ( $class, $action, $data_list, $p ) = @_;
    my $CONFIG = OpenInteract::Request->instance->CONFIG;
    foreach my $data ( @{ $data_list } ) {
        foreach my $field ( @{ $action->{transform_default_to_id} } ) {
            my $idx = $p->{field_order}{ $field };
            $data->[ $idx ] =  $class->sql_default_to_id( $CONFIG->{default_objects}, $data->[ $idx ] );
        }
    }
    return $data_list;
}


sub _transform_to_now {
    my ( $class, $action, $data_list, $p ) = @_;
    my $now_string = Class::Date->now->strftime( '%Y-%m-%d %H:%M:%S' );
    foreach my $data ( @{ $data_list } ) {
        foreach my $field ( @{ $action->{transform_to_now} } ) {
            my $idx = $p->{field_order}{ $field };
            $data->[ $idx ] = $now_string;
        }
    }
    return $data_list;
}




########################################
# SQL MODIFICATIONS
########################################

sub sql_default_to_id {
    my ( $class, $default, @text ) = @_;
    my @modified = ();
    foreach my $field ( @text ) {
        push @modified, ( $default->{ $field } ) ? $default->{ $field } : $field;
    }
    return wantarray ? @modified : $modified[0];
}


# Translate OpenInteract::Blah::Blah -> MyWebsite::Blah::Blah

sub sql_class_to_website {
    my ( $class, $website, @text ) = @_;
    foreach ( @text ) {
        s/OpenInteract/$website/g;
    }
    return wantarray ? @text : $text[0];
}



# Translate MyWebsite::Blah::Blah -> OpenInteract::Blah::Blah

sub sql_class_to_oi {
    my ( $class, $website, @text ) = @_;
    foreach ( @text ) {
        s/$website/OpenInteract/g;
    }
    return wantarray ? @text : $text[0];
}



# Translate %%INCREMENT%% to a db-specific method for finding an
# auto_increment value; we should probably have an 'else' just
# assigning every other db driver to 'int not null'...

sub sql_modify_increment {
    my ( $class, $config, $driver_name, @sql ) = @_;
    foreach ( @sql ) {
        if ( $driver_name eq 'mysql' ) {
            s/%%INCREMENT%%/INT NOT NULL AUTO_INCREMENT/g;
        }
        elsif ( $driver_name eq 'Sybase' or
                $driver_name eq 'ASAny' or
                $driver_name eq 'FreeTDS' ) {
            s/%%INCREMENT%%/NUMERIC( 10, 0 ) IDENTITY NOT NULL/g;
        }
        elsif ( $driver_name eq 'Pg' ) {
            s/%%INCREMENT%%/INT NOT NULL/g;
        }
        elsif ( $driver_name eq 'Oracle' ) {
            s/%%INCREMENT%%/INT NOT NULL/g;
        }
        elsif ( $driver_name eq 'SQLite' ) {
            s/%%INCREMENT%%/INTEGER NOT NULL/g;
        }
        elsif ( $driver_name eq 'InterBase' ) {
            s/%%INCREMENT%%/INT NOT NULL/g;
        }
    }
    return wantarray ? @sql : $sql[0];
}


# Translate %%INCREMENT_TYPE%% to a db-specific datatype -- note that
# NULL/NOT NULL are not handled here

sub sql_modify_increment_type {
    my ( $class, $config, $driver_name, @to_change ) = @_;
    foreach ( @to_change ) {
        if ( $driver_name eq 'mysql' ) {
            s/%%INCREMENT_TYPE%%/INT/g;
        }
        elsif ( $driver_name eq 'Sybase' or
                $driver_name eq 'ASAny' or
                $driver_name eq 'FreeTDS' ) {
            s/%%INCREMENT_TYPE%%/NUMERIC( 10, 0 )/g;
        }
        elsif ( $driver_name eq 'Pg' ) {
            s/%%INCREMENT_TYPE%%/INT/g;
        }
        elsif ( $driver_name eq 'Oracle' ) {
            s/%%INCREMENT_TYPE%%/INT/g;
        }
        elsif ( $driver_name eq 'SQLite' ) {
            s/%%INCREMENT_TYPE%%/INTEGER/g;
        }
        elsif ( $driver_name eq 'InterBase' ) {
            s/%%INCREMENT_TYPE%%/INT/g;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}


sub sql_modify_datetime {
    my ( $class, $config, $driver_name, @to_change ) = @_;
    foreach ( @to_change ) {
        if ( $driver_name eq 'mysql' ) {
            s/%%DATETIME%%/DATETIME/g;
        }
        elsif ( $driver_name eq 'Sybase' or
                $driver_name eq 'ASAny' or
                $driver_name eq 'FreeTDS' ) {
            s/%%DATETIME%%/DATETIME/g;
        }
        elsif ( $driver_name eq 'Pg' ) {
            s/%%DATETIME%%/TIMESTAMP/g;
        }
        elsif ( $driver_name eq 'Oracle' ) {
            s/%%DATETIME%%/DATE/g;
        }
        elsif ( $driver_name eq 'SQLite' ) {
            s/%%DATETIME%%/TIMESTAMP/g;
        }
        elsif ( $driver_name eq 'InterBase' ) {
            s/%%DATETIME%%/TIMESTAMP/g;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}

# Translate %%USERID_TYPE%% to a datatype specified in the server
# configuration. This is so we can have user IDs as characters or
# integers.

sub sql_modify_usertype {
    my ( $class, $config, $driver_name, @to_change ) = @_;
    my $type = $config->{id}{user_type} || 'int';
    foreach ( @to_change ) {
        if ( $type eq 'char' ) {
            s/%%USERID_TYPE%%/VARCHAR(25)/g;
        }
        elsif ( $type eq 'int' ) {
            s/%%USERID_TYPE%%/INT/g;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}


sub sql_modify_grouptype {
    my ( $class, $config, $driver_name, @to_change ) = @_;
    my $type = $config->{id}{group_type} || 'int';
    foreach ( @to_change ) {
        if ( $type eq 'char' ) {
            s/%%GROUPID_TYPE%%/VARCHAR(25)/g;
        }
        elsif ( $type eq 'int' ) {
            s/%%GROUPID_TYPE%%/INT/g;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}


# This is pretty generic (and not used yet)

sub sql_default {
    my ( $class, @to_change ) = @_;
    foreach ( @to_change ) {
        if ( /%%DEFAULT=(.*)%%/ ) {
            my $default_value = $1;
            s/%%DEFAULT.*%%/NOT NULL DEFAULT $default_value/;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}


# This is pretty generic (and not used yet)

sub sql_primary_key {
    my ( $class, @to_change ) = @_;
    foreach ( @to_change ) {
        if ( /%%PRIMARY_KEY=(.*)%%/ ) {
            my $key_specify = join( ', ', split /\s*,\s*/, $1 );
            s/%%PRIMARY KEY=.*%%/PRIMARY KEY( $key_specify )/;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}


# This is pretty generic (and not used yet)

sub sql_unique {
    my ( $class, @to_change ) = @_;
    foreach ( @to_change ) {
        if (/%%UNIQUE=(.*)%%/ ) {
            my $key_specify = join( ', ', split /\s*,\s*/, $1 );
            s/%%UNIQUE=.*%%/UNIQUE( $key_specify )/;
        }
    }
    return wantarray ? @to_change : $to_change[0];
}


########################################
# I/O
########################################

# Read in a file and evaluate it as perl.

sub read_perl_file {
    my ( $class, $filename ) = @_;
    my $raw = $class->read_file( $filename );
    my $data = undef;
    {
        no strict 'vars';
        $data = eval $raw;
    }
    die "Cannot parse data file ($filename): $@\n"  if ( $@ );
    return $data;
}



# Read in a file and return the contents

sub read_file {
    my ( $class, $filename ) = @_;
    die "Cannot read data file: ($filename) does not exist!\n"   unless ( -f $filename );
    DEBUG && _w( 1, "Reading file $filename" );
    open( DF, $filename ) || die "Cannot read data file: $!\n";
    local $/ = undef;
    my $raw = <DF>;
    close( DF );
    return $raw;
}


########################################
# STATUS
########################################

# Format a status information hashref:
#
#  type => (structure|data|security)
#  name => name of file/whatnot
#  ok   => 1 (ok); not true (not ok)
#  msg  => Description of how ok everything is (optional) or description of error

sub format_status {
    my ( $class, $info, $status_list ) = @_;
    my $output = "$info->{action} for $info->{driver_name}\n";
    foreach my $status ( @{ $status_list } ) {
        $output .= qq(  Name: $status->{name} -- );
        $output .= 'ok'    if ( $status->{ok} );
        $output .= 'error' if ( ! $status->{ok} );
        $output .= "\n  -- $status->{msg}" if ( $status->{msg} );
        $output .= "\n";
    }
    return $output;
}

sub _w {
    return unless ( DEBUG >= shift );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}

1;

__END__

=pod

=head1 NAME

OpenInteract::SQLInstall -- Dispatcher for installing various SQL data from packages to database

=head1 SYNOPSIS

 # Define a SQLInstaller for your package

 package OpenInteract::SQLInstall::MyPackage;

 use strict;
 use vars qw( %HANDLERS );
 %HANDLERS = (
   'create_structure' => { Sybase => \&structure_sybase,
                           Oracle => \&structure_oracle,
                           mysql  => \&structure_mysql },
   ...
 );

 sub structure_sybase { ...do stuff...}
 sub structure_oracle { ...do stuff...}
 sub structure_mysql  { ...do stuff...}

 # Use this class in a separate program
 use OpenInteract::SQLInstall;
 use OpenInteract::PackageRepository;
 use OpenInteract::Startup;
 use OpenInteract::DBI;

 my $C   = OpenInteract::Startup->create_config({
                base_config_file => "$WEBSITE_DIR/conf/base.conf"
           });
 my $dbh = eval { OpenInteract::DBI->connect( $C->{db_info} ) };
 die "Cannot open database handle: $@"  if ( $@ );

 my $repository = OpenInteract::PackageRepository->fetch(
                                   undef, { directory => $WEBSITE_DIR } );
 my $pkg_info = $repository->fetch_package_by_name( { name => 'my_package' } );
 OpenInteract::SQLInstall->require_package_installer( $pkg_info );
 my %args = ( package => $pkg_info, config => $C, db => $dbh );
 OpenInteract::SQLInstall->apply( { %args, action => 'create_structure' } );
 OpenInteract::SQLInstall->apply( { %args, action => 'install_data' } );
 OpenInteract::SQLInstall->apply( { %args, action => 'install_security' } );

=head1 DESCRIPTION

One of the difficulties with developing an application that can
potentially work with so many different databases is that it needs to
work with so many different databases. Many of the differences among
databases are dealt with by the amazing L<DBI|DBI> module, but enough
remain to warrant some thought.

This module serves two audiences:

=over 4

=item 1.

The user of OpenInteract who wants to get packages, run a few commands
and have them simply work.

=item 2.

The developer of OpenInteract packages who wants to develop for as
many databases as possible without too much of a hassle.

=back

This module provides tools for both. The first group (users) does not
need to concern itself with how this module works -- running the
various C<oi_manage> commands should be sufficient.

However, OpenInteract developers need a keen understanding of how
things work. This whole endeavor is a work-in-progress -- things work,
but there will certainly be new challenges brought on by the wide
variety of applications for which OpenInteract can be used.

=head1 USER OVERVIEW

Every package has a module that has a handful of procedures specified
in such a way that OpenInteract knows what to call and for which
database. Generally, all you need to deal with is the wrapper provided
by the C<oi_manage> program. For instance:

 oi_manage install_sql --website_dir=/home/httpd/myOI --package=mypackage

This will install the SQL for the package 'mypackage' installed to
your website. As long as you have specified your database properly
in your C<conf/server.perl> file, everything should flow smooth as silk.

=head1 DEVELOPER OVERVIEW

The SQL installation program of OpenInteract is a kind of mini
framework -- you have the freedom to do anything you like in the
handlers for your package. But OpenInteract provides a number of tools
for you as well.

=head1 METHODS

Note that subclasses do not need to define any of these methods. They
simply need to define a package variable %HANDLERS which describes the
work done for particular actions and particular databases and the
routines to accomplish this work.

B<require_package_installer( $package_object )>

Given a package object, finds and does a C<require> on the library
used to install SQL for this package.

B<apply( \%params )>

Performs a particular SQL action for a particular package.

Returns: 'ok' if no errors were returned, or the text of the error if
an error occurred.

Parameters:

=over 4

=item *

action ($)

String with name of action to perform.

=item *

db (obj)

DBI database handle

=item *

config (obj or \%)

OpenInteract configuration object (or just a hashref), which should
have the key 'db_info' with information about the database in it, and
the key 'website_name' with the name of the website.

=item *

package (\%)

Package object to perform action on

=back

B<read_db_handlers( $driver_name )>

Finds the handlers to execute for a particular database ($driver_name). If
your handler does not implement a set of handlers for $driver_name, you
can create a generic one (and hope that it works) using the key
'_default_'.

Of course, your class may implement this however it needs. But the
method implemented in the parent allows you to define a package
variable like so:

 package MyClass::SQLInstall;

 use strict;
 use vars ( %HANDLERS );

 %HANDLERS = (
     create_structure => { that_db  => \&that_db_structure,
                           other_db => \&other_db_structure },
     install_data     => { '_default_' => \&generic_data },
     install_security => {},
 );

Returns: hashref with the keys as the actions that can be performed
and the values as code references to apply for a database.

B<sql_class_to_website( $website_name, $text, [ $text, ... ] )>

Does a simple substitution of 'OpenInteract' for the website on
each string you pass to it.

Returns the strings with the substitution done in the same order.

Example:

 my @classes = sql_class_to_website( 'MyWebsite',
                                 qw( OpenInteract::News::Handler
                                     OpenInteract::News ) );
 # @classes is now: MyWebsite::News::Handler MyWebsite::News

B<sql_class_to_oi( $website_name, $text, [ $text, ... ] )>

Does a simple substitution of your website name to 'OpenInteract'
for each string you pass to it.

Returns the strings with the substitution done in the same order.

B<sql_modify_increment( $driver_name, $sql, [ $sql, ... ] )>

Modify each SQL statement to use a particular database style for
representing auto-incrementing values.

Returns the strings with the substitution done, in the same order.

B<process_data_file( \%params )>

Processes the datafile described by \%params. This is a fairly hefty
method, and its workings are described in L<PROCESSING DATA FILES>.

B<transform_data( \%action, \@data, \%params )>

Take the first item from a data file (the action) and perform any
indicated tasks necessary.

Currently, the tasks implemented by this parent class are:

=over 4

=item *

transform_class_to_website (\@)

Specify a list of fields that should have the value transformed to
replace 'OpenInteract' with the website name

=item *

transform_class_to_oi (\@)

Specify a list of fields that should have the value transformed to
replace the current website namespace with 'OpenInteract'.

=item *

transform_default_to_id (\@)

Specify a list of fields for which we need to use the value specified
lookup as a lookup in the 'default_objects' server configuration
key. This is often used when specifying security -- if you are using
LDAP, then your group ID is soemething like 'site admin' rather than
'3', so you want to ensure that the security is set appropriately.

=item *

transform_to_now (\@)

Specify a list of fields for which we need to set the value to a date
string representing right now.

=back

B<read_perl_file( $filename )>

Reads in the file $filename which describes a perl data
structure. Returns the structure.

B<read_file( $filename )>

Reads in the file $filename and returns a scalar with all the text of
the file.

B<format_status( \%info, \@status )>

=head1 PROCESSING DATA FILES

We need to be able to pass data from one database to another and be
very flexible as to how we do it. The various data file formats have
taken care of everything I could think of -- hopefully you will think
up some more.

To begin, there are two elements to a data file. The first element
tells the installer what type of data follows -- should we create
objects from them? Should we just plug the values into a SQL
statement and execute it against a particular table?

The second element is the actual data, which is in an order determined
by the first element.

There are several different ways to process a data file. Both are
described in detail below:

B<Object Processing>

Object processing allows you to just specify the field order and the
class, then let SPOPS do the dirty work. This is the preferred way of
transferring data, but it is not always feasible. An example where it
is not feasible include linking tables that SPOPS uses but does not
model.

B<SQL Processing>

SQL processing allows you to present elements of a SQL statement and
plug in values as many times as necessary. This can be used most
anywhere and for anything.

=head2 Object Processing

The first item in the list describes the class you want to use to
create objects and the order the fields that follow are in. Here is a
simple example of the data file used to install initial groups:

  $data_group = [ { spops_class => 'OpenInteract::Group',
                    field_order => [ qw/ group_id name / ] },
                  [ 1, 'admin' ],
                  [ 2, 'public' ],
                  [ 3, 'site admin' ],
  ];

Important note: when installing to a website, this module will
substitute the name of the website for 'OpenInteract' in
'spops_class'. So in the above example the class for the group objects
created in 'MyWebsite' will be C<MyWebsite::Group> -- B<not>
C<OpenInteract::Group>.

Here is a slightly abbreviated form of what steps would look like if
they were done in code:

 my $website_name = 'MyWebsite';
 my $object_class = 'OpenInteract::Group';
 $object_class =~ s/OpenInteract/$website_name/;
 my %field_num = { group_id => 0, name => 1 };
 foreach my $row ( @{ $data_rows } ) {
   my $object = $object_class->new();
   $object->{group_id} = $row->[ $field_num{group_id} ];
   $object->{name}     = $row->[ $field_num{name} ];
   $object->save({ is_add => 1, skip_security => 1,
                   skip_log => 1, skip_cache => 1 });
 }

Easy!

You can also specify operations to perform on the data before they are
saved with the object. The most common operation of this is in
security data:

  $security = [
                { spops_class => 'OpenInteract::Security',
                  field_order => [ qw/ class object_id scope scope_id security_level / ],
                  transform_default_to_id    => [ 'scope_id' ],
                  transform_class_to_website => [ 'class'] },
                [ 'OpenInteract::Group', 1, 'w', 'world', 1 ],
                [ 'OpenInteract::Group', 2, 'w', 'world', 4 ],
                [ 'OpenInteract::Group', 2, 'g', 'site_admin_group', 8 ],
                [ 'OpenInteract::Group', 3, 'w', 'world', 4 ],
                [ 'OpenInteract::Group', 3, 'g', 'site_admin_group', 8 ],
                [ 'OpenInteract::Handler::Group', 0, 'w', 'world', 4 ],
                [ 'OpenInteract::Handler::Group', 0, 'g', 'site_admin_group', 8 ]
  ];

So these steps would look like:

 my $website_name = 'MyWebsite';
 my $object_class = 'OpenInteract::Security';
 $object_class =~ s/OpenInteract/$website_name/;
 my %field_num = { class => 0, object_id => 1, scope => 2,
                   scope_id => 3, security_level => 4 };
 my $defaults = $R->CONFIG->{default_objects};
 foreach my $row ( @{ $data_rows } ) {
   my $object = $object_class->new();
   $object->{class}     = $row->[ $field_num{class} ];
   $object->{object_id} = $row->[ $field_num{object_id} ];
   $object->{scope}     = $row->[ $field_num{scope} ];
   my $scope_id         = $row->[ $field_num{scope_id} ];
   $object->{scope_id}  = $defaults->{ $scope_id } || $scope_id;
   $object->{level}     = $row->[ $field_num{security_level} ];
   $object->{class} =~ s/OpenInteract/$website_name/;
   $object->save({ is_add   => 1, skip_security => 1,
                   skip_log => 1, skip_cache    => 1 });
 }

There are currently just a few behaviors you can set to transform the
data before it gets saved (see C<transform_data()> above), but the
interface is there to do just about anything you can imagine.

=head2 SQL Processing

The actions performed when you just want to insert data into tables is
similar to those performed when you are inserting objects. The only
difference is that you need to specify a little more. Here is an
example:

  $data_link = [ { sql_type    => 'insert',
                   sql_table   => 'sys_group_user',
                   field_order => [ qw/ group_id user_id / ] },
                 [ 1, 1 ]
  ];

So we specify the action ('insert'), the table to operate on
('sys_group_user'), the order of fields in the data rows
('field_order', just like with processing objects) and then list the
data.

You are also able to specify the data types. Most of the time this
should not be necessary: if the database driver (e.g.,
L<DBD::mysql|DBD::mysql>) supports it, the
L<SPOPS::SQLInterface|SPOPS::SQLInterface> file has routines to
discover data types in a table and do the right thing with regards to
quoting values.

However, if you do find it necessary you can use the following simple
type -> DBI type mappings:

 'int'   -> DBI::SQL_INTEGER(),
 'num'   -> DBI::SQL_NUMERIC(),
 'float' -> DBI::SQL_FLOAT(),
 'char'  -> DBI::SQL_VARCHAR(),
 'date'  -> DBI::SQL_DATE(),

Here is a sample usage:

  $data_link = [ { sql_type => 'insert',
                   sql_table => 'sys_group_user',
                   field_order => [ qw/ group_id user_id link_date priority_level / ],
                   field_type => { group_id       => 'int',
                                   user_id        => 'int',
                                   link_date      => 'date',
                                   priority_level => 'char' },
                  },
                 [ 1, 1, '2000-02-14', 'high' ]
  ];


More work needs to be done on this so, for instance, you could
implement cleanup routines like this:

  $cleanup = [ { sql_type => 'delete',
                 sql_table => 'sys_group_user',
                 where  => "group_id = ? and user_id = ?" },
                 [ 1, 1 ]
  ];

Or:

  $cleanup = [ { sql_type => 'delete',
                 sql_table => 'sys_security',
                 transform_class_to_website => [ 1, 2 ] },
                 where  => "class = ? OR class = ?" },
                 [ 'OpenInteract::Group', 'OpenInteract::Handler::Group' ]
  ];

=head1 BUGS

None known.

=head1 TO DO

B<Setup removals properly>

See example under L<SQL Processing>, above.

B<Other means of abstraction>

Using something like Alzabo (see http://alzabo.sourceforge.net/) to
provide schema and data translation abilities would be sweet. However,
Alzabo is a whole nother ball of wax on top of OpenInteract...

B<Dumping data for transfer>

It would be nice if you could do something like:

 oi_manage dump_sql --website_dir=/home/httpd/myOI --package=mypkg

And get in your C<data/dump> directory a series of files that can be
read in by another OpenInteract website for installation. This is
the pie in the sky -- developing something like this would be really
cool.

And we can, but only for SPOPS objects. It is quite simple for us to
read data from a flat file, build objects from the data and save them
into a random database -- SPOPS was built for this!

However, structures are a problem with this. Data that are not held in
objects are a problem. And dealing with dependencies is an even bigger
problem.

B<Single-action process>

Creating a script that allowed you to do:

 oi_sql_process --database=Sybase \
                --apply=create_structure < table.sql > sybase_table.sql

would be pretty nifty.

B<Use as object (and other refactoring)>

Every SQL install process should create an object with information like:

 * repository
 * package
 * database driver

The object (a factory method) would create an object based on the
database driver which is a pointer to the C<OpenInteract::SQLInstall>
database-specific subclass. This subclass which would have the
specific information necessary to make the actions happen for a
particular database.

The object would then:

 * initialize the SQLInstall class for the package (do a 'require') as
   part of the constructor

And then have available a generic 'apply' class which took a specific
action:

 * run through the structures ( $install->apply( 'create_structure' ) )
 * run through the security   ( $install->apply( 'install_security' ) )
 * run through the data       ( $install->apply( 'install_data' ) )

Each of these should probably be in an 'Action' subclass or something,
since this is getting fairly hefty...

=head1 SEE ALSO

L<OpenInteract::Package|OpenInteract::Package>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

Christian Lemburg <lemburg@aixonix.de> provided the initial idea and
helped steer the module away from potentially rocky shoals.

=cut

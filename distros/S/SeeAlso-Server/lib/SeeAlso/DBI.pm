use strict;
use warnings;
package SeeAlso::DBI;
{
  $SeeAlso::DBI::VERSION = '0.71';
}
#ABSTRACT: Store L<SeeAlso::Response> objects in database.

use DBI;
use DBI::Const::GetInfoType;
use Carp qw(croak);

use base qw( SeeAlso::Source );
use SeeAlso::Source qw(expand_from_config);

## no critic


sub new {
    my ($class, %attr) = @_;
    expand_from_config( \%attr, 'DBI' );

    if ( $attr{dbi} ) {
        $attr{dbi} = 'dbi:' . $attr{dbi} unless $attr{dbi} =~ /^dbi:/i; 
        $attr{user} = "" unless defined $attr{user};
        $attr{password} = "" unless defined $attr{password};
        $attr{dbh} = DBI->connect( $attr{dbi}, $attr{user}, $attr{password} );
    }

    croak('Parameter dbh or dbi required') 
        unless UNIVERSAL::isa( $attr{dbh}, 'DBI::db' );
    croak('Parameter dbh_ro must be a DBI object') 
        if defined $attr{dbh_ro} and not UNIVERSAL::isa( $attr{dbh_ro}, 'DBI::db' );

    my $self = bless { }, $class;

    $self->description( %attr ) if %attr;

    $self->{dbh} = $attr{dbh};
    $self->{dbh_ro} = $attr{dbh_ro};
    $self->{table} = defined $attr{table} ? $attr{table} : 'seealso';
    $self->{key} = $attr{key} || 'hash';

    $self->{idtype} = $attr{idtype} || 'SeeAlso::Identifier';
    eval "require " . $self->{idtype};
    croak $@ if $@;
    croak($self->{idtype} . ' is not a SeeAlso::Identifier')
        unless UNIVERSAL::isa( $self->{idtype}, 'SeeAlso::Identifier' );

    # build SQL strings
    my $table   = $self->{dbh}->quote_identifier( $self->{table} );
    my $key    = $self->{dbh}->quote_identifier('key');
    my $label   = $self->{dbh}->quote_identifier('label');
    my $descr   = $self->{dbh}->quote_identifier('description');
    my $uri     = $self->{dbh}->quote_identifier('uri');
    my $db_name = $self->{dbh}->get_info( $GetInfoType{SQL_DBMS_NAME} );

    my @values_st;
    my @create_st = ("$key VARCHAR(255)");

    if (defined $attr{label}) {
        $self->{label} = $attr{label};
    } else {
        push @values_st, $label;
        push @create_st, "$label TEXT"
    }
    if (defined $attr{description}) {
        $self->{descr} = $attr{description};
    } else {
        push @values_st, $descr;
        push @create_st, "$descr TEXT",
    }
    if (defined $attr{uri}) {
        $self->{uri} = $attr{uri};
    } else {
        push @values_st, $uri;
        push @create_st, "$uri TEXT",
    }

    my $values = join(", ", @values_st);

    my %sql = (
        'select' => "SELECT $values FROM $table WHERE $key=?",
        'insert'   => "INSERT INTO $table ($key,$values) VALUES (?," . join(",", map {'?'} @values_st) . ")",
        # update  => "UPDATE $table SET $value = ? WHERE $key=?",
        'delete' => "DELETE FROM $table WHERE $key = ?",
        'clear'    => "DELETE FROM $table",
        # get_keys => "SELECT DISTINCT $key FROM $table",
        'create' => "CREATE TABLE IF NOT EXISTS $table (" . join(", ", @create_st) . ")", 
        # TODO: create index:     
        #  $dbh->do( 'CREATE INDEX '.$table.'_isbn_idx ON '.$table.' (isbn)' );
        'drop' => "DROP TABLE $table"
    );

    foreach my $c ( qw(select insert delete clear create) ) {
        $self->{$c} = $attr{$c} ? $attr{$c} : $sql{$c};
    }

    $self->create if $attr{build};

    return $self;
}


sub query_callback {
    my ($self, $identifier) = @_;

    my $key = $self->key($identifier);

    my $dbh = $self->{dbh_ro} ? $self->{dbh_ro} : $self->{dbh};
    my $sth = $dbh->prepare_cached( $self->{'select'} )
        or croak $dbh->errstr;
    $sth->execute($key) or croak $sth->errstr;
    my $result = $sth->fetchall_arrayref;

    my $response = SeeAlso::Response->new( $identifier );

    foreach my $row ( @{$result} ) {
        my ($label, $description, $uri) = $self->enriched_row( $key, @{$row} );
        $response->add( $label, $description, $uri );
    }

    return $response;
}


sub key {
    my ($self, $identifier) = @_;

    if ( not UNIVERSAL::isa( $identifier, $self->{idtype} ) ) {
        my $class = $self->{idtype};
        $identifier = eval "new $class(\$identifier)"; # TODO: what if this fails?
    }

    if ($self->{key} eq 'hash') {
        return $identifier->hash;
    } elsif ($self->{key} eq 'value') {
        return $identifier->value;
    } elsif ($self->{key} eq 'canonical') {
        return $identifier->canonical;
    } elsif (ref($self->{key}) eq 'CODE') {
        my $code = $self->{key};
        return $code( $identifier );
    }

    return $identifier->hash;
}


sub create {
    my ($self) = @_;
    $self->{dbh}->do( $self->{'create'} ) or croak $self->{dbh}->errstr;
    return;
}


sub clear {
    my ($self) = @_;
    $self->{dbh}->do( $self->{'clear'} ) or croak $self->{dbh}->errstr;
    return;
}


sub drop {
    my ($self) = @_;
    $self->{dbh}->do( $self->{'drop'} ) or croak $self->{dbh}->errstr;
    return;
}


sub delete {
    my ($self, $identifier) = @_;
    $self->{dbh}->do( $self->{'delete'}, undef, $self->key($identifier) ) 
        or croak $self->{dbh}->errstr;
}


sub update {
    my ($self, $response) = @_;
    $self->delete( $response->identifier );
    $self->insert( $response );
}


sub insert {
    my ($self, $response) = @_;

    croak('SeeAlso::Response object required') unless
        UNIVERSAL::isa( $response, 'SeeAlso::Response' );

    return 0 unless $response->size;

    # type hash/canonical/value
    my $key = $self->key( $response->identifier );
    my @rows;

    for(my $i=0; $i<$response->size; $i++) {
        my ($label, $description, $uri) = $response->get($i);
        my @insert = ($key);
        push @insert, $label       unless defined $self->{label};
        push @insert, $description unless defined $self->{descr};
        push @insert, $uri         unless defined $self->{uri};
        push @rows, \@insert;
    }

    return $self->bulk_insert( sub { shift @rows } );
}


sub bulk_insert {
    my ($self, $sub) = @_;

    croak('bulk_insert expects a code reference') unless ref($sub) eq 'CODE';

    my $sth = $self->{dbh}->prepare_cached( $self->{insert} );
    my $tuples = $sth->execute_for_fetch( $sub );
    $sth->finish;

    return $tuples;
}

# ($key,$label,$description,$uri,@row) => ($label,$description,$uri)
sub enriched_row {
    my ($self, @row) = @_;

    my @row2 = @row;
    my $key = shift @row2;
    my $label       = defined $self->{label} ? $self->{label} : shift @row2;
    my $description = defined $self->{descr} ? $self->{descr} : shift @row2;
    my $uri         = defined $self->{uri}   ? $self->{uri}   : shift @row2;
    # code references not supported yet!

    no warnings;
    if ( defined $self->{label} ) {
        $label       =~ s/#([0-9])/${row[$1-1]}/g;
    }
    if ( defined $self->{descr} ) {
        $description =~ s/#([0-9])/${row[$1-1]}/g;
    }
    if ( defined $self->{uri} ) {
        $uri         =~ s/#([0-9])/${row[$1-1]}/g;
    }

    return ( $label, $description, $uri );
}



sub bulk_import {
    my ($self, %param) = @_;
    my $file = $param{file};
    croak 'No file specified' unless defined $file;

    my $label       = defined $param{label} ? $param{label} : '#2';
    my $description = defined $param{descr} ? $param{descr} : '#3';
    my $uri         = defined $param{uri}   ? $param{uri} : '#4';

    open FILE, $file or croak "Failed to open file $file";
    binmode FILE, ":utf8";

    $self->bulk_insert( sub {
        my $line = readline(*FILE);
        return unless $line;
        chomp($line);
        my @v = split /\t/, $line;
        my ($l,$d,$u) = ($label,$description,$uri);

        no warnings;
        $l =~ s/#([0-9])/${v[$1-1]}/g;
        $d =~ s/#([0-9])/${v[$1-1]}/g;
        $u =~ s/#([0-9])/${v[$1-1]}/g;

        return [ $v[0], $l, $d, $u ];
    } );

    close FILE;
}

1;


__END__
=pod

=head1 NAME

SeeAlso::DBI - Store L<SeeAlso::Response> objects in database.

=head1 VERSION

version 0.71

=head1 SYNOPSIS

   # use database as SeeAlso::Source

   my $dbh = DBI->connect( ... );
   my $dbi = SeeAlso::DBI->new( dbh => $dbh );

   print SeeAlso::Server->new->query( $dbi );   

=head1 DESCRIPTION

A C<SeeAlso::DBI> object manages a store of L<SeeAlso::Response>
objects that are stored in a database. By default that database
must contain a table named C<seealso> with rows named C<key>, 
C<label>, C<database>, and C<uri>. A query for identifier C<$id>
of type L<SeeAlso::Identifier> will result in an SQL query such as

  SELECT label, description, uri FROM seealso WHERE key=?

With the hashed identifier (C<$id<gt>hash>) used as key parameter.
By default a database table accessed with this class stores the four
values key, label, description, and uri in each row - but you can also
use other schemas.

=head1 METHODS

=head2 new ( %parameters )

Create a new database store. You must specify either a database handle in 
form or a L<DBI> object with parameter C<dbh> parameter, or a C<dbi>
parameter that is passed to C<DBI-E<gt>connect>, or a C<config> parameter
to read setting from the C<DBI> section of a configuration hash reference.

  my $dbh = DBI->new( "dbi:mysql:database=$d;host=$host", $user, $password );
  my $db = SeeAlso::DBI->new( dbh => $dbh );

  my $db = SeeAlso::DBI->new( 
      dbi => "dbi:mysql:database=$database;host=$host", 
      user => $user, passwort => $password
  );

  use YAML::Any qw(LoadFile);
  my $config = LoadFile("dbiconnect.yml");
  my $db = SeeAlso::DBI->new( config => $config );
  my $db = SeeAlso::DBI->new( $%{$config->{DBI}} ); # same

The configuration hash can be stored in a configuration file (INI, YAML, etc.)
and must contains a section named C<DBI>. All values specified in this section
are added to the constructor's parameter list. A configuration file could look 
like this (replace uppercase values with real values):

  DBI:
    dbi : mysql:database=DBNAME;host=HOST
    user : USER
    password : PWD

The following parameters are recognized:

=over

=item dbh

Database Handle of type L<DBI>.

=item dbh_ro

Database Handle of type L<DBI> that will be used for all read access.
Usefull for master-slave database settings.

=item dbi

Source parameter to create a C<DBI> object. C<"dbi:"> is prepended if
the parameter does not start with this prefix.

=item user

Username if parameter C<dbi> is given.

=item password

Password if parameter C<dbi> is given.

=item table

SQL table name for default SQL statements (default: C<seealso>).

=item select

SQL statement to select rows.

=item delete

SQL statement to delete rows.

=item insert

SQL statement to insert rows.

=item clear

SQL statement to clear the database table.

=item build

Newly create the SQL table with the create statement.

=item label

Do not store the label in the database but use this value instead.

=item description

Do not store the description in the database but use this value instead.

=item uri

Do not store the uri in the database but use this value instead.

=item key

One of 'hash' (default), 'value', 'canonical' or a code that the identifier
is passed to before beeing used as key. Only useful when used together with
parameter C<idtype>.

=item idtype

Subclass of L<SeeAlso::Identifier> to be use when creating an identifier.

=item config

Configuration settings as hash reference or as configuration file that will
be read into a hash reference. Afterwarrds the The C<DBI> section of the
configuration is added to the other parameters (existing parameters are not 
overridden).

=back

=head2 query_callback ( $identifier )

Fetch from DB, uses the key value ($identifier->hash by default).

=head2 key ( $identifier )

Get a key value for a given L<SeeAlso::Identifier>.

=head2 create

Create the database table.

=head2 clear

Delete all content in the database. Be sure not to call this by accident!

=head2 drop

Delete the whole database table. Be sure not to call this by accident!

=head2 delete ( $identifier )

Removes all rows associated with a given identifier.

=head2 update ( $response )

Replace all rows associated with the the identifier of a given response
with the new response.

=head2 insert ( $response )

Add a L<SeeAlso::Response> to the database (unless the response is empty).
Returns the number of affected rows or -1 if the database driver cannot
determine this number.

=head2 bulk_insert ( $fetch_quadruple_sub )

Add a set of quadrupels to the database. The subroutine $fetch_quadruple_sub
is called unless without any parameters, until it returns a false value. It
is expected to return a reference to an array with four values (key, label,
description, uri) which will be added to the database. Returns the number
of affected rows or -1 if the database driver cannot determine this number.

=head2 enriched_row

=head2 bulk_import ( [ file => $file ... ] )

TODO: remove enrichment!

=head1 SEE ALSO

This package was partly inspired by on L<CHI::Driver::DBI> by Justin DeVuyst
and Perrin Harkins.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


package SQLite::Abstract;

use strict;
use warnings;
use Carp;
use DBI;

our $VERSION = '0.14';

my $td = {
    week =>
      { 0, 'Sun', 1, 'Mon', 2, 'Tue', 3, 'Wed', 4, 'Thu', 5, 'Fri', 6, 'Sat' },
    month => {
        '01' => 'Jan',
        '02' => 'Feb',
        '03' => 'Mar',
        '04' => 'Apr',
        '05' => 'May',
        '06' => 'Jun',
        '07' => 'Jul',
        '08' => 'Aug',
        '09' => 'Sep',
        '10' => 'Oct',
        '11' => 'Nov',
        '12' => 'Dec',
    }
};

sub new {
    my $class = shift;
    my $data  = shift;
    my $self;
    my $attrs = {
        AutoCommit => 0,
        PrintError => 0,
        RaiseError => 1,
    };

    if ( not ref $data eq 'HASH' ) {
        my $dbtype    = shift;
        my $tablename = shift;
        $self->{'dbname'}    = $data;
        $self->{'dbtype'}    = $dbtype ? $dbtype : "dbi:SQLite2:dbname";
        $self->{'tablename'} = $tablename;
        $self->{'attrs'}     = $attrs;
    }
    else {
        $self = {
            dbname    => $data->{'DB'},
            dbtype    => $data->{'DSN'},
            tablename => $data->{'TABLE'},
            attrs     => ref $data->{'attrs'} eq 'HASH'
            ? $data->{'attrs'}
            : $attrs
        };
    }

    $class eq __PACKAGE__
      or croak _err_msg("constructor not called as class method");

    -e $self->{'dbname'}
      or croak _err_msg("no database defined");
    -f $self->{'dbname'}
      or croak _err_msg("no such database $self->{dbname}");

    $self->{'dbh'} = DBI->connect( qq/$self->{dbtype}=$self->{dbname}/,
        q//, q//, $self->{'attrs'} );

    $self->{'BEGIN'}    = sub { $self->{'dbh'}->begin_work };
    $self->{'COMMIT'}   = sub { $self->{'dbh'}->commit };
    $self->{'ROLLBACK'} = sub { $self->{'dbh'}->rollback };

    return bless $self, $class;

}

sub table : lvalue {
    $_[1]
      ? $_[0]->{q{tablename}} =
        $_[1]
      : $_[0]->{q{tablename}};
}

sub tables {
    my $self = shift;
    no strict 'refs';

    map { $_->[0] } $self->select(
        q/
            SELECT name FROM 
                (SELECT * FROM sqlite_master UNION ALL
                SELECT * FROM sqlite_temp_master)
            WHERE type='table'
            ORDER BY name;
    /
    );
}

sub localtime {
    my $self = shift;
    my $ps   = shift;

    if ($ps) {
        my @td = split q/ /, $self->select(
            q/
        	select strftime("%w %m %d %H:%M:%S %Y",'now','localtime');
    	/
        )->[0];
        $td[0] = $td->{q/week/}{ $td[0] };
        $td[1] = $td->{q/month/}{ $td[1] };

        return join q/ /, @td;
    }

    return join q/ /, map { $_->[0] } $self->select(
        q/
		select datetime('now','localtime');
	/
    );
}

sub time {
    my $self = shift;

    return join q/ /, map { $_->[0] } $self->select(
        q/
        	select strftime("%s",'now');
    	/
    );

}

sub time_ahead {
    my $self  = shift;
    my $ahead = "@_";

    return join q/ /, map { $_->[0] } $self->select(
        qq/
       		select datetime('now','localtime',$ahead);
	/
    );

}

sub create_table {
    my $self      = shift;
    my $tablename = shift || $self->{tablename};

    $self->do(
        qq/
		CREATE TABLE $tablename ( @_ );
	/
    );
}

sub alter {
    my $self  = shift;
    my $query = shift;

    $self->_check_table;
    $self->do(
        qq/
		ALTER TABLE $self->{tablename} $query;
	/
    );
}

sub drop_table {
    my $self      = shift;
    my $tablename = shift || $self->{tablename};

    $self->do(
        qq/
		DROP TABLE $tablename; 
		VACUUM;
	/
    );
}

sub insert {
    my $self    = shift;
    my $columns = $_[0];
    my $data    = $_[1] || $_[0];
    my $sth     = q{};
    my $counter = 0;

    $self->_check_table;

    #~ $self->{q{BEGIN}}->();

    if ( @_ == 2 ) {
        my $prep_columns = join( ',', @$columns );
        my $prep_data = join( ',', split '', ( '?' x @$columns ) );
        $sth = $self->{q{dbh}}->prepare(
            qq/
			INSERT INTO $self->{tablename} ($prep_columns) 
			VALUES ($prep_data);
		/
        );
    }
    else {
        my $prep_data = join( ',', ( split '', ( '?' x @{ $data->[0] } ) ) );
        $sth = $self->{q{dbh}}->prepare(
            qq/
			INSERT INTO $self->{tablename} VALUES ($prep_data);
		/
        );
    }

    for (@$data) {
        $sth->execute(@$_) and $counter++;
    }

    $self->_END_;

    return $counter;
}

sub replace {
    my $self  = shift;
    my $query = shift;

    $self->_check_table;
    $self->do(
        qq/
		REPLACE INTO $self->{tablename} $query;
	/
    );
}

sub create_view {
    my $self      = shift;
    my $view_name = shift;
    my $select    = shift;

    $self->_check_table;
    $self->do(
        qq/
		CREATE VIEW $view_name AS $select;
	/
    );
}

sub drop_view {
    my $self      = shift;
    my $view_name = shift;

    $self->_check_table;
    $self->do(
        qq/
		DROP VIEW $view_name;
	/
    );
}

sub delete {
    my $self  = shift;
    my $query = shift;

    $self->_check_table;
    $self->do(
        qq/
		DELETE FROM $self->{tablename} $query;
	/
    );
}

sub delete_all {
    shift->delete(q/WHERE 1=1/);
}

sub update {
    my $self  = shift;
    my $query = shift;

    $self->_check_table;
    $self->do(
        qq/
		UPDATE $self->{tablename} SET $query;
	/
    );
}

sub select {
    my $self  = shift;
    my $query = shift;
    my $type  = shift;
    my $result;

    $self->_check_table;

    $query ||= qq/SELECT * FROM $self->{q{tablename}}/;
    $query =~ s/^\s*(\w*\s*ALL\s*)/ * /i;

    if ( not $query =~ /^\s*SELECT\s+/i ) {
        if ( $query =~ /^\s*\*/ ) {
            $query =~ s/^\s*\*(.*)/SELECT * FROM 
				$self->{q{tablename}} $1/;
        }
        else {
            $query =~ s/^\s*(\w+(\s*,\s*\w+)*)/SELECT $1 FROM 
				$self->{q{tablename}} /;
        }
    }

    local $self->{q{dbh}}->{q{RaiseError}} = 1;

    if (wantarray) {
        if ( my @data = @{ $self->{q{dbh}}->selectall_arrayref($query) } ) {
            $self->_END_;
            @data = map { $_->[0] } @data
              if ref $type eq 'SCALAR';
            return @data;
        }
    }
    else {
        local $_ = join( '_', $query );
        if ( not $self->{$_} ) {
            $self->{$_} = $self->{q{dbh}}->prepare($query);
            $self->{$_}->execute;
            $result = [ $self->{$_}->fetchrow_array ];
        }
        else {
            $result = [ $self->{$_}->fetchrow_array ];
        }

        $self->{q/select/}->{q/last/} = $result;

        return @$result
          ? ref $type eq 'SCALAR'
             ? $result->[0]
             : $result
          : undef $self->{$_};
    }
}

sub last {
    shift->{q/select/}->{q/last/};
}

sub count {
    my $self  = shift;
    my $query = shift;

    $self->_check_table;

    my $count = $query
      ? $self->{q{dbh}}->selectall_arrayref(
        qq/
			SELECT count(*) FROM $self->{tablename} $query
		/
      )
      : $self->{q{dbh}}->selectall_arrayref(
        qq/
			SELECT count(*) FROM $self->{tablename}
		/
      );

    $self->_END_;

    return $count->[0][0];
}

sub sum {
    shift->count(@_);
}

sub _END_ {
    my $self = shift;

    $self->{q{COMMIT}}->();
    $self->{dbh}->errstr
      and eval { $self->{q{ROLLBACK}}->() };
}

sub do {
    shift->_do_(@_);
}

sub _do_ {
    my $self  = shift;
    my $query = "@_";
    my $affected;

    eval {
        $affected = $self->{q{dbh}}->do($query);
        $self->{q{COMMIT}}->();
    };

    if ( $self->{q{dbh}}->errstr ) {
        $self->err = $@;
        eval { $self->{q{ROLLBACK}}->() };
        if ( $self->{q{dbh}}->{q{RaiseError}} ) {
            croak $self->err;
        }
        else {
            carp $self->err;
            return undef;
        }
    }
    else {
        return $affected == 0
          ? "0E0"
          : $affected;
    }
}

sub _check_table {
    my $self = shift;
    $self->{q{tablename}}
      or croak _err_msg("missing table name");
}

sub _err_msg {
    __PACKAGE__ . q/:/ . (caller)[2] . q/:/ . __LINE__ . q/: / . "@_";
}

sub err : lvalue {
    $_[1]
      ? $_[0]->{q{err}} = $_[1]
      : $_[0]->{q{err}};
}

sub AUTOLOAD {
    my $self  = shift;
    my $query = shift;
    my $tmp   = shift;

    $tmp and $query = $tmp;
    $query or $query = q{};

    our $AUTOLOAD;
    ( my $method = $AUTOLOAD ) =~ s/.*:://s;

    if ( $method =~ /^select_(\w+)/i ) {
        my $fields = join ',', split /_/, $1;
        if ($fields) {
            $query =~ s/^\s*SELECT.+?FROM\s+\S+//;
            return $fields !~ /\,/
              ? $self->select( "$fields $query", \$0 )
              : $self->select("$fields $query");
        }
    }

    croak _err_msg("method $method does not exist");
}

sub DESTROY {
    my $self = shift;
    $self->{q{dbh}} = undef;
    $self = undef;
}

1

__END__


=head1 NAME

SQLite::Abstract - Object oriented wrapper for SQLite2

=head1 SYNOPSIS



 use SQLite::Abstract;

 
 my $db = SQLite::Abstract->new("database name");
 my $db = SQLite::Abstract->new(
    {
        DB => "database name",
        DSN => "dbi:SQLite2:dbname", 
        TABLE => "tablename",
    }
 );

 $db->create_table($tablename,<<SQ);
      id INTEGER PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      password VARCHAR(255) NOT NULL,	
 SQ

 
 $db->table("tablename");
 
 $db->insert(\@fields, \@data);
 $db->insert(['name', 'password'], [['user1', 'password1'], ['user2', 'password2']]);
 
 $db->update(q/password = 'w0rdpass' where name = 'guest'/);
 
 $db->select(q/select name, password from tablename limit 0,2/);
 $db->select(q/* limit 0,2/);
 $db->select(q/ALL limit 0,2/);
 $db->select_name_password(q/limit 0,2/);
 $db->select_name(q/limit 0,2/);
 
 while ( $name = $db->select_name ) {
    print "$name\n";
 }
 
 # slurping mode 
 for ( @names = $db->select_name ) {
    print "name: $_\n";
 }
 
 while ( $row = $db->select ) {
    print "name: $row->[1] password: $row->[2]\n";
 }
 
 $db->count;
 $db->count(q/where name like 'user%'/);
 $db->sum(q/where name like '%name'/);
 
 $db->delete(q/where password like 'password'/);
 $db->delete_all();
 
 $db->drop_table;
 

 
=head1 DESCRIPTION

SQLite::Abstract is abstract level above DBD::SQLite. 
This package aims at intuitional SQLite database manipulation.
It pretends to be the easiest sql class.



=head1 METHODS

=over 4

=item C<new>

The constructor takes database name which must be existing file.
The $dbh attributes can be set through 'attrs' structure with the extended version 
of the constructor:
	
  $sql = SQLite::Abstract->new( 
     {
        DB => $database,
        DSN => 'dbi:SQLite2:dbname',
        attrs => {
            AutoCommit => 0,
            PrintError => 1,
            RaiseError => 1,
     }
  );

Use either the short version (database name as scalar argument) or anonymous hash with DB
and DSN which are mandatory keys:

 $sql = SQLite::Abstract->new($database);
 $sql = SQLite::Abstract->new(
    {
       DB => $database,
       DSN => 'dbi:SQLite2:dbname',
    }
 );
 
Returns object if the database connection (SQLite2 DSN by default) is set successfully.

=back

=head2 SQL Table Methods 

=over 4

=item C<table>

Accessor and mutator for the default table.
This is the table which all methods use by default.

 $sql->table(); # returns the default table name
 $sql->table($tablename); # sets and returns the default table name
 $sq->table = $tablename;

=item C<tables>

Lists the tables in the database. Returns a list with the tables or true on sucess. Returns undef on failure or raises fatal error exception according to C<$dbh> C<RaiseError> attribute.

 @tables = $sql->tables();


=item C<create_table>

Creates table.

 $sql->create_table($tablename, <<QUOTE);

  id INTEGER PRIMARY KEY,
  ...
  ...
 
 QUOTE

which is equivalent to:

 $sql->do(<<QUOTE);

  CREATE TABLE tablename (
      id INTEGER PRIMARY KEY,
      ...
      ...
  )

 QUOTE

Returns true on success. Returns undef on failure or raises fatal error exception
according to C<$dbh> C<RaiseError> attribute.

=item C<drop_table>;

Deletes table. Like all methods works on the dafault table unless explicitly given
table name.

 $sql->drop_table(); # drops the default table
 $sql->drop_table($tablename); 

Returns true on success. Returns undef on failure or raises fatal error exception
according to C<$dbh> C<RaiseError> attribute.

=item C<create_view>

Creates a view which is a named L<select> statement. Requires two arguments, the view's name and
a SELECT statement. View is created in the object's database. It is read-only. It is removed with L<drop_view>.

 $sql->create_view("view_name", q/
     SELECT id FROM $tablename
      WHERE ...
 /);
 $sql->table = "view_name";
 $sql->select();

Returns true on success otherwise returns undef or raises fatal error exception according to C<$dbh> C<RaiseError>
attribute.

=item C<drop_view>

Removes a view. Requires the view's name as argument. 

 $sql->drop_view("view_name");

Returns true on success otherwise returns undef or raises fatal error exception according to C<$dbh> C<RaiseError>
attribute.

=back

=head2 SQL Query Methods

=over 4 

=item C<insert>

Inserts data. Takes array references, the columns and the data to be inserted into 
these columns. The data array (which must be array of array references) can be given alone
in which case each element is expected to refer to the same number as the columns in
the default sql table. Returns the number of affected rows. Returns false unless inserted rows.
Returns undef on failure or raises fatal error exception according to C<$dbh> C<RaiseError> 
attribute.

 # talbe with two columns:
 @data = (['col_r11', 'col_r12'], ['col_r21', 'col_r22'])
 
 $sql->insert(\@cols, \@data);
 $sql->insert(\@data);

=item C<update>

Updates records. Takes sql query. Returns the number of affected rows. 
Returns undef on failure or raises fatal error exception according to C<$dbh> C<RaiseError>
attribute.

 $sql->update(q/name = 'system' WHERE .../);
 $sql->update(q/user = '...'/);

=item C<delete>

Deletes records. Takes sql query. Returns the number of affected rows. 
Returns undef on failure or raises fatal error exception according to C<$dbh> C<RaiseError>
attribute.

 $sql->delete(q/where id <= 100000/);

=item C<delete_all>

Implements delete method on all records.
 
  $sql->delete_all();
  $sql->delete(q/where 1 = 1/);

Returns the number of affected rows. Returns undef on failure or raises fatal error 
exception according to C<$dbh> C<RaiseError> attribute.

=item C<select>

Implements select query. Returns all results (slurping mode) or one row at a time 
depending on the context. In list context C<$dbh> C<selectall_arrayref> is called 
which returns array reference with references to each fetched row. In scalar content 
C<$dbh> C<fetchrow_array> is called which returns the next row. Note that each query
has its own statement handle. Table columns' names put after the method can generate 
select methods with the proper sql syntax. 

 @AoA_result = $sql->select('all limit 1,10'); 
 $AR_result  = $sql->select('all limit 1,10');

 @users = $sql->select_users('limit 1,10'); # all in not AoAref
 $users = $sql->select_users('limit 1,10'); # single row
 @AoA_users_fname_lname = $sql->select_users_fname_lname; # all in AoAref
 @users = $sql->select('SELECT users FROM tablename LIMIT 1,10'); # also possible
 
 # list context usage 
 for( $sql->select_username ){
   print "username: $_ \n";
 }

 # scalar context usage
 while( $username = $sql->select_username ){
   print "username: $username\n";
 }

 while( $user = $sql->select_fname_lname ){
   print "fname: $user->[0] lname: $user->[1];
 }
 
Returns array containing array references to each row in list context. In scalar context
returns result as string if one column selected, otherwise reference to the row fetched.
Returns undef at the end while in scalar context. Raises fatal error exception on failure
(C<local>ized RaiseError attribute is set to true).

=item C<count>

Implements rows counting. Returns undef on failure or raises fatal error exception 
according to C<$dbh> C<RaiseError> attribute.

 $sql->count;
 $sql->do(q/SELECT count(*) FROM tablename/);

=item C<sum>

Implements C<count> method.

=item C<time>

SQLite2 datetime('now') function, identical to Perl time() function.

=item C<localtime>

SQLite2 datetime('now','localtime') function. Format of the return is the same as Perl localtime() in scalar context
if positive argument is given, otherwise returns in the default SQLite2 format: yyyy-mm-dd HH:MM:SS.

 $sql->localtime(); # 2006-03-27 14:33:32
 $sql->localtime(1); # Mon Mar 27 14:35:25 2006

=item C<time_ahead>

SQLite2 datetime('now','localtime','+.. time', ...) function. Takes y/m/d/H/M/S arguments.
Returns the current time plus the time given in the default format: yyyy-mm-dd HH:MM:SS.

 $s1->time_ahead(q/'+5 minutes','+2 seconds','+3 hours','+9 days','+9 months','+15 years'/);

=item C<do>
 
Calls C<$dbh> C<do> method. Useful for I<non>-C<SELECT> arbitrary statements which will not be 
executed repeatedly. Returns undef on failure or raises fatal error exception
according to C<$dbh> C<RaiseError> attribute.

=back

=head2 Error handling method

=over 4

=item C<err>

Returns the last C<$dbh> error message (C<errstr>).
 
 $sql->do(q/some sql query/);
 $sql->err and die $sql->err;
 
=back

=head1 SEE ALSO

L<DBI>
L<DBD::SQLite2>

=head1 BUGS

Please report any bugs or feature requests to vidul@cpan.org. 

=head1 AUTHOR

Vidul Nikolaev Petrov, vidul@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Vidul Nikolaev Petrov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


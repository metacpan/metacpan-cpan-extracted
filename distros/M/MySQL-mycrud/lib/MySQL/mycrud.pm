package MySQL::mycrud;

use strict;
use DBI;
use Carp qw/croak/;

use vars qw/$VERSION/;
$VERSION = '0.03';


sub new {

    my $class = shift;

    my $db = shift;
    my $host = shift;
    my $port = shift;
    my $user = shift;
    my $passwd = shift;

    my $dbh = DBI->connect("dbi:mysql:database=$db;host=$host;port=$port", $user, $passwd,
                           {
                               PrintError => 0,
                               RaiseError => 1,
                           }) or croak $DBI::errstr;

    bless { 'dbh'=>$dbh }, $class;
}


sub get_rows {

    my ($self,$str,$ref) = @_;

    my @values;
    @values = @$ref if defined $ref;

    my $dbh = $self->{'dbh'};
    my $sth = $dbh->prepare($str);

    $sth->execute(@values) or croak $dbh->errstr;
    
    my @records;
    while ( my $ref = $sth->fetchrow_hashref ) {
        push @records, $ref;
    }

    $sth->finish;

    return \@records;
}


sub get_row {

    my ($self,$str,$ref) = @_;

    my @values;
    @values = @$ref if defined $ref;

    my $dbh = $self->{'dbh'};
    my $sth = $dbh->prepare($str);

    $sth->execute(@values) or croak $dbh->errstr;

    my @records = $sth->fetchrow_array;
    $sth->finish;

    return @records;
}


sub do_sql {

    my ($self,$str,$ref) = @_;

    my @values;
    @values = @$ref if defined $ref;

    my $dbh = $self->{'dbh'};
    my $sth = $dbh->prepare($str);

    $sth->execute(@values) or croak $dbh->errstr;
    $sth->finish;
}
    

sub disconnect {

    my $self = shift;
    my $dbh = $self->{'dbh'};
    $dbh->disconnect;
}


#
#self destroy
#
sub DESTROY {

    my $self = shift;
    my $dbh = $self->{'dbh'};

    if ($dbh) {
        local $SIG{'__WARN__'} = sub {};
        $dbh->disconnect();
    }
}


1;

=head1 NAME

MySQL::mycrud - nothing but the mysql methods for myself

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use MySQL::mycrud;

    # connect to the database
    my $db = MySQL::mycrud->new('database_name','host','port','user','password');

    # get one row
    my ($name,$age) = $db->get_row("select name,age from table where id=123"); # or
    my ($name,$age) = $db->get_row("select name,age from table where id=?",[123]);

    # get many rows
    my $rr = $db->get_rows("select * from table where id between 123 and 456"); # or
    my $rr = $db->get_rows("select * from table where id between ? and ?",[123,456]);
    for my $r (@$rr) { # each element is a hash ref
        print $r->{name},$r->{age};
    }

    # do updates
    $db->do_sql("insert into table(name,age) values(?,?)",['John Doe',30]);
    $db->do_sql("update table set age=32 where id=123");
    $db->do_sql("delete from table where id=123");

    # disconnect it
    $db->disconnect;


=head1 METHODS

=head2 new(db_name,host,port,user,passwd)

    my $db = MySQL::mycrud->new('database_name','host','port','user','password');

create the object and connect to the database.

=head2 get_row(sql)

    my ($name,$age) = $db->get_row("select name,age from table where id=123");

get one row, the result returned is a list.

=head2 get_rows(sql)

     my $rr = $db->get_rows("select * from table where id between 123 and 456");

get rows, the result returned is an array reference, each element in the array is a hash reference.

=head2 do_sql(sql)

    $db->do_sql("insert into table(name,age) values(?,?)",['John Doe',30]);

run any sql for updates, including insert,replace,update,delete,drop etc.

=head2 disconnect()

    $db->disconnect;

disconnect from the database. anyway if $db is gone out of the scope, the database will be disconnected automatically.


=head1 SEE ALSO

DBI DBD::mysql


=head1 AUTHOR

Ken Peng <yhpeng@cpan.org>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <yhpeng@cpan.org>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MySQL::mycrud


=head1 COPYRIGHT & LICENSE

Copyright 2012 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

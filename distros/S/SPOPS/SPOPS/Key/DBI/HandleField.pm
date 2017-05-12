package SPOPS::Key::DBI::HandleField;

# $Id: HandleField.pm,v 3.5 2004/06/02 00:48:23 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;

my $log = get_logger();

$SPOPS::Key::DBI::HandleField::VERSION  = sprintf("%d.%02d", q$Revision: 3.5 $ =~ /(\d+)\.(\d+)/);

# Ensure only POST_fetch_id used

sub pre_fetch_id      { return undef }

# Retrieve the value of the just-inserted ID

sub post_fetch_id {
    my ( $self, $p )  = @_;
    my $field = $self->CONFIG->{handle_field};
    unless ( $field ) {
        SPOPS::Exception->throw( 'Cannot retrieve ID since handle field is unknown' );
    }
    my ( $id );
    $id   = eval { $p->{db}->{ $field } };
    $id ||= eval { $p->{statement}->{ $field } };
    $log->is_info &&
        $log->info( "Found inserted ID ($id)" );
    unless ( $id ) {
        SPOPS::Exception->throw( "Cannot find ID value in $field" );
    }
    return $id;
}

1;

__END__

=head1 NAME

SPOPS::Key::DBI::HandleField -- Retrieve an auto-increment value from a DBI statement or database handle

=head1 SYNOPSIS

 # In your SPOPS configuration

 $spops  = {
   'myspops' => {
       'isa'          => [ qw/ SPOPS::Key::DBI::HandleField  SPOPS::DBI / ],
       'handle_field' => 'mysql_insertid',
       ...
   },
 };

 # Note: Other classes (such as 'SPOPS::DBI::MySQL') use this class
 # without requiring you to specify the class or any of its
 # configuration information.

=head1 DESCRIPTION

This class simply reads an ID value from a statement or database
handle using the specified key. The value will generally represent the
unique ID of the row just inserted and was presumably retrieved by the
DBD library, which made it available by a particular key.

Currently, this is only known to work with the MySQL database and
L<DBD::mysql|DBD::mysql>. MySQL supports auto-incrementing fields
using the keyword 'AUTO_INCREMENT', such as:

 CREATE TABLE mytable (
   myid   INT NOT NULL AUTO_INCREMENT,
   ...
 )

With every INSERT into this table, the database will provide a
guaranteed-unique value for 'myid' if one is not specified in the
INSERT. Rather than forcing you to run a SELECT against the table to
find out the value of the unique key, the MySQL client libraries
provide (and L<DBD::mysql|DBD::mysql> supports) the value of the field
for you.

With MySQL, this is available through the 'mysql_insertid' key of the
L<DBI|DBI> database handle. (It is also currently available via the
statement handle using the same name, but this may go away in the
future.)

So if you were using straight DBI methods, a simplified example of
doing this same action would be (using MySQL):

 my $dbh = DBI->connect( 'DBI:mysql:test', ... );
 my $sql = "INSERT INTO mytable ( name ) VALUES ( 'european swallow' )";
 my $rv = $dbh->do( $sql );
 print "ID of just-inserted record: $dbh->{mysql_insertid}\n";

=head1 METHODS

B<post_fetch_id()>

Retrieve the just-inserted value from a key in the handle, as
described above.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<DBD::mysql|DBD::mysql>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

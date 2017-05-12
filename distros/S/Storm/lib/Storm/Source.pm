package Storm::Source;
{
  $Storm::Source::VERSION = '0.240';
}


use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Storm::Types qw( StormPolicyObject StormSourceManager );
use MooseX::Types::Moose qw( ArrayRef );

use DBI;
use Storm::Policy;


has 'parameters' => (
    isa => ArrayRef,
    required => 1,
    traits   => [qw/Array/],
    writer   => '_set_parameters',
    handles  => {
        parameters => 'elements',
    }
);

sub set_parameters {
    my ( $self, @params ) = @_;
    $self->_set_parameters( \@params );
}

has '_dbh' => (
    is  => 'rw',
    isa => 'DBI::db',
    reader => '_dbh' ,
    writer => '_set_dbh',
    clearer => '_clear_dbh',
);


sub BUILDARGS {
    my $class = shift;
    
    # if there is one argument, and it starts with a @ it is a file|record pair
    # we want to load the arguments from the file
    if (@_ == 1 and $_[0] =~ /^@/)  {
        return { parameters => $class->_params_from_file($_[0]) }
    }
    # otherwise pass upwards to deal with
    else {
        return { parameters => \@_ };
    }
}


# _params_from file:
#   given a filename and record label as a singular string (@file.txt|record)
#   opens the file, finds the record and returns the connection parameters
sub _params_from_file {
    my $class = shift;
    my $statement = shift;
    
    $statement =~ s/^@//;
    $statement =~ s/^\s+//;
    $statement =~ s/\s+$//;
    
    my ($file, $record) = split '\|', $statement;
    
    # throw exception if cannot decipher filename/label
    if (! $file || ! $record) {
        confess qq[Could not decipher filename and record label from statement $statement]
    }
    
    # look for the record
    open my $FILE, '<', $file or confess qq[could not open $file for reading];
    flock $FILE, 2; 
    
    while(<$FILE>) {
        chomp;
        my ($label, @params) = split '\|', $_;
        # if we have a matching record, create the source object
        if ($label && $label eq $record) {
            return \@params;
        }
    }
    
    # if we get here, we didn't find a matching record, throw and error
    close $FILE;
    confess qq[could not find a record matching '$record' in file $file];
    
}

sub dbh  {
    my ( $self ) = @_;
    
    # return current connection if active
    return $self->_dbh if $self->_dbh;
    
    # otherwise create and set a new one
    my $dbh = DBI->connect($self->parameters);
    $dbh->{mysql_auto_reconnect} = 1;
    $self->_set_dbh($dbh);
    return $dbh;
}


sub disconnect {
    my ( $self ) = @_;
    $self->_dbh->disconnect if ( $self->_dbh );
    $self->_clear_dbh;
}


sub tables  {
    my ( $self ) = @_;
    my @tables;
    my $dbh = $self->dbh;
    
    if ( $dbh->{csv_tables} ) {
        @tables = keys %{$dbh->{csv_tables}};
    }
    elsif ( $dbh->{sqlite_version} ) {        
        my $sth = $dbh->prepare( q[SELECT name FROM sqlite_master WHERE type='table' ORDER BY name] );
        $sth->execute;
        
        while(my ($table) = $sth->fetchrow_array){
            push @tables, $table;
        }     
    }
    else {
        my $sth = $dbh->prepare('SHOW TABLES');
        $sth->execute;
        
        while(my ($table) = $sth->fetchrow_array){
            push @tables, $table;
        }        
    }
    
    return @tables;
}

sub auto_increment_token {
    my ( $self ) = @_;
    if ( $self->dbh->{sqlite_version} ) {
        return 'AUTOINCREMENT';
    }
    else {
        return 'AUTO_INCREMENT';
    }
}

sub disable_foreign_key_checks {
    my ( $self ) = @_;
    if ( $self->dbh->{sqlite_version} ) {
        $self->dbh->do('PRAGMA foreign_keys = OFF;');
        confess $self->dbh->errstr if $self->dbh->err;
    }
    else {
        $self->dbh->do('SET FOREIGN_KEY_CHECKS = 0;');
        confess $self->dbh->errstr if $self->dbh->err;
    }
}

sub enable_foreign_key_checks {
    my ( $self ) = @_;
    if ( $self->dbh->{sqlite_version} ) {
        $self->dbh->do('PRAGMA foreign_keys = ON;');
        confess $self->dbh->errstr if $self->dbh->err;
    }
    else {
        $self->dbh->do('SET FOREIGN_KEY_CHECKS = 1;');
        confess $self->dbh->errstr if $self->dbh->err;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

Storm::Source - Always produces active database handles on request

=head1 SYNOPSIS

 use Storm::Source;

 $source = Storm::Source->new(['DBI:mysql:database:3306', 'user', 'pass']);

 $source = Storm::Source->new('@file.txt|record');

 $dbh = $source->dbh;
  
=head1 DESCRIPTION

Storm::Source objects will return an active database handle on request. The
handle will be created using connection information stored internally.Connection
information can easily be retrieved from formatted ascii files.

=head1 METHODS

This class has the following methods

=head2 $class->new(\@connect_info)

The values in C<\@connect_info> are passed on to C<< DBI->connect >> to create
a database handler when one is requested.

=head2 $class->new('@file.txt|record');

You can also load the @connect_info arguments from a text file. The constructor
will recognize anytime it is called with a singular argument starting with the
@ character.  The format of the file containing the connect arguments is
one record per line, record name and connect args separated with a pipe
character, and the individual connect arguments separated by tab characters. EX:

  record1|DBI:mysql:database:address:3306|username|password
  record2|DBI:SQLite:dbname=:memory:

=head2 $source->dbh

If the $source object is aware of an active database connection, it will be
returned. Otherwise, a new database handler will be created from DBI->connect.

=head1 AUTHOR

Jeffrey Ray Hallock, <jeffrey dot hallock at gmail dot com>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Jeffrey Ray Hallock, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut




package Net::Amazon::MechanicalTurk::RowData::SQLRowData;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::RowData;
use IO::File;
use Carp;
use DBI;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::RowData };

Net::Amazon::MechanicalTurk::RowData::SQLRowData->attributes(qw{
    dbh
    sql
    params
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->assertRequiredAttributes(qw{ dbh sql });
}

sub each {
    my ($self, $block, @blockXArgs) = @_;

    my $sql = $self->sql;
    my $sth = $self->dbh->prepare($sql);
    if (!$sth) {
        Carp::croak("Couldn't prepare sql '$sql' - " . $self->dbh->errstr . ".");
    }
    $sth->{RaiseError} = 1;
    
    eval {
        my @params;
        @params = @{$self->params} if $self->params;
        $sth->execute(@params);
        my $rowNumber = 0;
        while (my $row = $sth->fetchrow_hashref) {
            if ($rowNumber++ == 0) {
                # Make a copy of the fieldNames
                $self->fieldNames([@{$sth->{NAME}}]);
            }
            $block->($self, $row, @blockXArgs);
        }
    };
    if ($@) {
        # clean up the handle
        $sth->finish;
        die $@;
    }
    $sth->finish; 
}

return 1;

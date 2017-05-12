package Pinwheel::Database::Mysql;

use strict;
use warnings;

use Pinwheel::Database::Base;

our @ISA = qw(Pinwheel::Database::Base);


sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class; # Re-bless into this class
    return $self;
}

sub connect
{
    my $self = shift;
    $self->SUPER::connect(@_);
    
    # Set some MySQL specific options
    $self->do("SET time_zone='+00:00'");
    $self->do("SET names 'utf8'");
    $self->{dbh}->{mysql_auto_reconnect} = 0;
    
    # Get the name of the remote database host
    {
        # 'show variables' returns a two-column result set: key/value
        my $sth = $self->prepare("SHOW variables LIKE 'hostname'");
        $sth->execute();
        my $row = $sth->fetchall_arrayref;
        $self->{dbhostname} = $row->[0][1];
    }
}

sub describe
{
    my ($self ,$table) = @_;
    my ($sth, $rows, %fields);

    $sth = $self->prepare('SHOW FIELDS FROM ' . $table);
    $sth->execute();
    $rows = $sth->fetchall_arrayref([0, 1, 2]);
    map {
        $fields{$_->[0]} = { type => lc($_->[1]), null => ($_->[2] eq 'YES') }
    } @$rows;
    return \%fields;
}

sub tables
{
    my $self = shift;
    return $self->selectcol_array('SHOW TABLES');
}

sub without_foreign_keys(&)
{
    my ($self, $block) = @_;
    $self->prepare('BEGIN')->execute();
    $self->prepare('SET FOREIGN_KEY_CHECKS = 0')->execute();
    &$block();
    $self->prepare('SET FOREIGN_KEY_CHECKS = 1')->execute();
    $self->prepare('COMMIT')->execute();
}



1;

__DATA__

=head1 NAME

Pinwheel::Database::Mysql

=head1 DESCRIPTION

Database backend class for talking to MySQL databases.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut


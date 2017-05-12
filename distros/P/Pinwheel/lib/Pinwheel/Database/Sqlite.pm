package Pinwheel::Database::Sqlite;

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
    $self->{dbhostname} = 'localhost';
}

sub describe
{
    my ($self ,$table) = @_;
    my ($sth, $rows, %fields);
    $sth = $self->prepare("PRAGMA table_info (`$table`)");
    $sth->execute();
    $rows = $sth->fetchall_arrayref([1, 2, 3]);
    map {
        $fields{$_->[0]} = { type => lc($_->[1]), null => ($_->[2] ? 0 : 1) }
    } @$rows;
    return \%fields;
}

sub tables
{
    my $self = shift;
    return $self->selectcol_array('SELECT tbl_name FROM sqlite_master WHERE type="table"');
}

1;

__DATA__

=head1 NAME

Pinwheel::Database::Sqlite

=head1 DESCRIPTION

Database backend class for talking to SQLite databases.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut


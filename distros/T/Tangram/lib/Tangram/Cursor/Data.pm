package Tangram::Cursor::Data;

use strict;
use Carp;

sub open
{
	my ($type, $storage, $select, $conn) = @_;
   
	confess unless $conn;
	
	bless
	{
	 select => $select,
	 storage => $storage,
	 cursor => $storage->sql_cursor(substr($select->expr, 1, -1), $conn),
	}, $type;
}

sub fetchrow
{
	my $self = shift;
	my @row = $self->{cursor}->fetchrow;
	return () unless @row;
	map { $_->{type}->read_data(\@row) } @{$self->{select}{cols}};
}

# XXX - not reached by test suite
sub fetchall_arrayref
{
	my $self = shift;
	my @results;

	while (my @row = $self->fetchrow)
	{
		push @results, [ @row ];
	}

	return \@results;
}

# XXX - not reached by test suite
sub new
{
	my $pkg = shift;
	return bless [ @_ ] , $pkg;
}

sub DESTROY
  {
	my $self = shift;
	$self->close();
  }

sub close
  {
	my $self = shift;
	$self->{cursor}{connection}->disconnect()
	  unless $self->{cursor}{connection} == $self->{storage}{db};
  }

1;


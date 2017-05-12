package Tangram::Driver::Sybase::Statement;

use strict;
use constant STH => 2;

sub execute
  {
	my $self = shift;
	my ($storage, $sql) = @$self;
	
	my $sth = $self->[STH] = $storage->{db}->prepare($sql);
	$sth->execute(@_);
	
	# $dbh->do($sql, {}, @_);
  }

sub fetchrow_array
  {
	my $self = shift;
	return $self->[STH]->fetchrow_array();
  }

sub finish
  {
	my $self = shift;
	my $sth = pop @$self;
	$sth->finish();
  }

1;

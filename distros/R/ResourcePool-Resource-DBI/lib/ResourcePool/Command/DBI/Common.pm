#*********************************************************************
#*** lib/ResourcePool/Command/DBI/Common.pm
#*** Copyright (c) 2004 by Markus Winand <mws@fatalmind.com>
#*** $Id: Common.pm,v 1.3 2004/05/02 07:48:55 mws Exp $
#*********************************************************************
package ResourcePool::Command::DBI::Common;

use ResourcePool::Command;
use ResourcePool::Command::NoFailoverException;
use strict;
use DBI;
use vars qw($VERSION);

$VERSION = "1.0101";

sub new($$;$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	my $sql   = shift;
	
	bless($self, $class);
	$self->_setOptions({});

	if (defined $sql && $sql ne '') {
		if (scalar(@_) == 0 || ref($_[0]) eq 'HASH' || scalar(@_) %2 == 0) {
			# if these things are given, the first argument is a SQL
			$self->_setSQL($sql);

			if (defined $_[0]) {
				if (ref($_[0]) eq 'HASH') {
					$self->_setBindArgs(shift);
					if (defined $_[0]) {
						$self->_setOptions({@_});
					}
				} else {
					$self->_setOptions({@_});
				}
			}
		} else {
			# otherwise, its part of an option
			$self->_setOptions({($sql, @_)});
		}

	}

	return $self;
}

sub _setSQL($$) {
	my ($self, $sql) = @_;
	$self->{sql} = $sql;
}

sub getSQL($) {
	my ($self) = @_;
	return $self->{sql};
}

sub _setBindArgs($$) {
	my ($self, $bindargs) = @_;
	$self->{bindargs} = $bindargs;
}
sub _getBindArgs($) {
	my ($self, $sql) = @_;
	return $self->{bindargs};
}

sub _setOptions($$) {
	my ($self, $options) = @_;
	# the defaults
	my %options = (
		prepare_cached => 0
	);
	%options = ((%options), %{$options});
	$self->{options} = \%options;
}

sub _getOptions($) {
	my ($self) = @_;
	return $self->{options};	
}

sub _getOptPrepareCached($) {
	my ($self) = @_;
	return $self->{options}->{prepare_cached};
}

sub getSQLfromargs($$) {
	my ($self, $argsref) = @_;
	my $sql = $self->getSQL();

	if (! defined $sql && ! ref($argsref->[0])) {
		$sql = shift @{$argsref};
	}

	if (! defined $sql) {
		die ResourcePool::Command::NoFailoverException->new(
			ref($self) . ': '
			. 'you have to specify a SQL statement'
		);
	}
	return $sql;
}

sub prepare($$) {
	my ($self, $dbh, $sql) = @_;
	my $sth;

	if ($self->_getOptPrepareCached()) {
		$sth = $dbh->prepare_cached($sql);
	} else {
		$sth = $dbh->prepare($sql);
	}

	return $sth;
}

sub bind($$) {
	my ($self, $sth, $argsref) = @_;

	if (scalar(@{$argsref}) > 0) {
		my $argshash;
		if (ref($argsref->[0]) eq 'HASH') {
			# named args syntax
			$argshash = $argsref->[0];
		} else {
			# ordered args syntax
			my %argshash;
			$argshash = {};
			my $arg;
			my $i = 1;
			foreach $arg (@{$argsref}) {
				$argshash{$i} = $arg;
				++$i;
			}
			$argshash = \%argshash;
		}

		# bind parameters
		my $bindargs = $self->_getBindArgs();
		my ($name);
		foreach $name (keys(%{$argshash})) {
			if (defined $bindargs->{$name}->{max_len}) {
				# in that case, $value is required to be a ref
				$sth->bind_param_inout($name
					, $argshash->{$name}
					, $bindargs->{$name}->{max_len}
					, $bindargs->{$name}->{type}
				);
			} else {
				$sth->bind_param($name
					, $argshash->{$name}
					, $bindargs->{$name}->{type});
			}
		}
	}
}

sub info($) {
	my ($self) = @_;
	my $sql = $self->getSQL();
	if (defined $sql) {
		return ref($self) . ": '" . $sql . "'";
	} else {
		return ref($self) . ": no SQL pre-declared";
	}
}


1;

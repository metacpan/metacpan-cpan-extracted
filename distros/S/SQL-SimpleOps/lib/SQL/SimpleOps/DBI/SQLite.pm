# ABSTRACT SQL Simple Operations Commands
#
## LICENSE AND COPYRIGHT
# 
## Copyright (C) Carlos Celso
# 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
# 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
#
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see L<http://www.gnu.org/licenses/>.
#
	package SQL::SimpleOps::DBI::SQLite;

	use 5.006001;
	use strict;
	use warnings;
	use Exporter;

	our @ISA = qw ( Exporter );

	our @EXPORT = qw(new Open $VERSION);

	our $VERSION = "2023.284.1";

	our @EXPORT_OK = @EXPORT;

	our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
	1;

###############################################################################
## plugin initialization

sub new()
{
	my $class = shift; $class = ref($class) || $class || 'SQL::SimpleOps::DBI::SQLite';
	my $self = {@_};

	if ($self->{sql_simple}->{argv}{db} eq "" && $self->{sql_simple}->{argv}{dbfile} eq "")
	{
		$self->{sql_simple}->setMessage($self,"new",-1,"001");
		return undef;
	}
	$self->{sql_simple}->{init}{plugin_id} = "SQLite";
	$self->{sql_simple}->{init}{schema} = 0;
	$self->{sql_simple}->{init}{test_server} = 0;
	$self->{sql_simple}->{init}{alias_with_as} = 0;

	bless($self,$class);
}

###############################################################################
## initialize here the dsname by:
#
## All methods can be executed using the format:
#	$self_sql_simple->[method_name]();
#
## return codes:
##	rc=0	ok, continue
##	rc<1	syntax, abort
##	rc=1	error, abort
##	rc=2	ok, ignore caller

sub Open()
{
	my $self = shift;
	my $argv = shift;

	## sets the dsnam here
	$self->{sql_simple}->{argv}{dbfile} = $self->{sql_simple}->{argv}{db}.".db" if (!defined($self->{sql_simple}->{argv}{dbfile}) || $self->{sql_simple}->{argv}{dbfile} eq "");
	$self->{sql_simple}->{argv}{dsname} = "DBI:SQLite:dbname=$self->{sql_simple}->{argv}{dbfile}";

	return 0;
}

__END__

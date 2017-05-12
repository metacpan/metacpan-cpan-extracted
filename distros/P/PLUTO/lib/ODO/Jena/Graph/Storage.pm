#
# Copyright (c) 2004-2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Graph/Storage.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/02/2004
# Revision:	$Id: Storage.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Graph::Storage;

use strict;
use warnings;

use ODO::Node;

use ODO::Jena::Graph;
use ODO::Jena::Node;
use ODO::Jena::Node::Parser;

use ODO::Jena::SQL;

use ODO::Query::RDQL;
use ODO::Query::RDQL::Parser;
use ODO::Query::RDQL::DefaultHandler;

use ODO::Query::Simple;
use ODO::Jena::Query::Result;

use ODO::Exception;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Graph::Storage/;

__PACKAGE__->mk_ro_accessors(qw/graph_id table_prefix table_name full_table_name sql_library dbh/);

=head1 NAME

ODO::Graph::Storage::Jena - Database storage methods for Jena schema

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut


sub add {
	my ($self, $statements) = @_;
	
	$self->dbh()->begin();
	
	my $db_stmt = $self->dbh()->prepare_cached( $self->sql_library()->retr('insertStatement', $self->full_table_name()) );
	
	foreach my $stmt (@{ $statements } ) {
		# TODO: Handle long objects
		my $s = ODO::Jena::Node->to_jena_node($stmt->subject());
		my $p = ODO::Jena::Node->to_jena_node($stmt->predicate());
		my $o = ODO::Jena::Node->to_jena_node($stmt->object());
		
		unless($db_stmt->execute($s, $p, $o, $self->graph_id())) {
			$self->dbh()->rollback();
			$db_stmt->finish();
			
			throw ODO::Exception::DB(error=> 'Unable to execute insertStatement query');
		}
	}
	
	$self->dbh()->commit();
	
	$db_stmt->finish();
}


sub remove {
	my ($self, $statements) = @_;
	
	$self->dbh()->begin();
	
	my $db_stmt = $self->dbh()->prepare_cached( $self->sql_library()->retr('deleteStatement', $self->full_table_name()) );

	foreach my $stmt (@{ $statements } ) {
		# TODO: Handle long objects
		my $s = ODO::Jena::Node->to_jena_node($stmt->subject());
		my $p = ODO::Jena::Node->to_jena_node($stmt->predicate());
		my $o = ODO::Jena::Node->to_jena_node($stmt->object());
		
		unless($db_stmt->execute($s, $p, $o, $self->graph_id())) {
			$self->dbh()->rollback();
			$db_stmt->finish();
			
			throw ODO::Exception::DB(error=> 'Unable to execute deleteStatement query');
		}
	}
	
	$self->dbh()->commit();
	
	$db_stmt->finish();
}


sub clear {
	my $self = shift;
	
	my $db_stmt = $self->dbh()->prepare( $self->sql_library()->retr('removeRowsFromTable', $self->full_table_name()) );
	
	unless($db_stmt->execute($self->graph_id())) {
		$db_stmt->finish();
		
		throw ODO::Exception::DB(error=> 'Unable to execute removeRowsFromTable query');
	}
	
	$db_stmt->finish();
}


sub size {
	my $self = shift;
	
	my $db_stmt = $self->dbh()->prepare( $self->sql_library()->retr('getRowCount', $self->full_table_name()) );
	
	unless($db_stmt->execute()) {
		$db_stmt->finish();
		
		throw ODO::Exception::DB(error=> 'Unable to execute getRowCount query');
	}
	
	my @rs = $db_stmt->fetchrow_array();
	
	unless(scalar(@rs) == 1) {
		$db_stmt->finish();
		
		throw ODO::Exception::DB(error=> 'Unable to fetch row count for table: ' . $self->full_table_name());
	}
	
	my $size = $rs[0];
	$db_stmt->finish();
	return $size;
}


sub issue_query {
	my ($self, $query, $query_options) = @_;

	return $self->issue_simple_query($query)
		if(UNIVERSAL::isa($query, 'ODO::Query::Simple'));

	# TODO: Handle more sophisticated queries?
	my $rdql_query = ODO::Query::RDQL::Parser->parse($query);

	my $result_graph = ODO::Query::RDQL::DefaultHandler->new(data=> $self->parent_graph(), query_object=> $rdql_query)->evaluate_query();
	
	my $statements = $result_graph->query($ODO::Query::Simple::ALL_STATEMENTS)->results();
	return ODO::Query::Simple::Result->new(source_graph=> $self->parent_graph(), query=> $rdql_query, results=> $statements);	
}


sub issue_simple_query {
	my ($self, $query) = @_;
	
	my @parameters;
	my $select = 'selectStatement';
	
	unless(UNIVERSAL::isa($query->subject(), 'ODO::Node::Any')) {
		$select .= 'S';
		push @parameters, ODO::Jena::Node->to_jena_node($query->subject())->serialize();
	}
	
	unless(UNIVERSAL::isa($query->predicate(), 'ODO::Node::Any')) {
		$select .= 'P';
		push @parameters, ODO::Jena::Node->to_jena_node($query->predicate())->serialize();
	}
	
	unless(UNIVERSAL::isa($query->object(), 'ODO::Node::Any')) {
		$select .= 'O';
		unshift @parameters, ODO::Jena::Node->to_jena_node($query->object())->serialize();
	}

	push @parameters, $self->graph_id();
		
	my $select_sql_query = $self->sql_library()->retr($select, $self->full_table_name());
	
	my $db_stmt = $self->dbh()->prepare( $select_sql_query );

	unless($db_stmt->execute(@parameters)) {
		$db_stmt->finish();
		
		throw ODO::Exception::DB(error=> 'Unable to execute query for statements with specified ODO::Query::Simple');
	}
	
	my $rs_array = $db_stmt->fetchall_arrayref();
	
	$db_stmt->finish();

	return ODO::Jena::Query::Result->new(results=> $rs_array);
}


sub __clone {
	my ($self, $graph_id) = @_;
	
	return $self;
}


sub __initialize_tables { 
	my $self = shift;

	my @tables = $self->{'dbh'}->tables();
	
	my $storage_table_name = $self->full_table_name();
	
	return 1
		if(grep(/$storage_table_name/, @tables));
	
	$self->dbh()->do( $self->sql_library()->retr('createStatementTable', $self->full_table_name()) );
}


sub init  {
	my ($self, $config) = @_;
	
	$self = $self->SUPER::init($config);
	
	return undef
		unless($self);
	
	my %defaults = %{ODO::Jena::Graph::DEFAULTS};
	$self->params(\%defaults, qw/table_name_prefix graph_id/);
	$self->params($config, qw/connection table_name_prefix table_name graph_id dbh/);
	
	$self->{'full_table_name'} = $self->{'table_name_prefix'} . $self->{'table_name'};
	
	# Use SQL Library chooser
	my $lib_file = ODO::Jena::SQL->find_sql_library_file($self->dbh());
	$self->{'sql_library'} = ODO::Jena::SQL::Library->new({lib=> $lib_file});
	
	$self->__initialize_tables();
	
	return $self;
}


=back

=head1 COPYRIGHT

Copyright (c) 2004-2007 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut


1;

__END__

#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Graph/System.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/29/2004
# Revision:	$Id: System.pm,v 1.3 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Graph::System;

use strict;
use warnings;

use ODO::Node;

use ODO::Jena;
use ODO::Jena::Graph;
use ODO::Jena::Vocabulary;

use ODO::Jena::Node;
use ODO::Jena::Node::Parser;

use ODO::Jena::DB::Settings;
use ODO::Jena::Graph::Settings;

use ODO::Exception;
use ODO::Statement;
use ODO::Query::Simple;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Jena::Graph/;

__PACKAGE__->mk_ro_accessors(qw/column_type table_impl_type key_length head_column_type head_key_len/);


=head1 NAME

ODO::Jena::Graph::System - Interface to the database table that contains the system graphs.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=item new(  )

=head1 METHODS

=over

=item find_graph( $graph_name )

Find all GraphName predicates with the object value as the graph name 

=cut

sub find_graph {
	my ($self, $graph_name) = @_;
	
	my $object = ODO::Node::Literal->new($graph_name);
	my $query = ODO::Query::Simple->new(-s=> undef, -p=> ${ODO::Jena::Vocabulary::GraphName}, -o=> $object);

	my $rs = $self->{'storage'}->issue_query($query);
	
	my @graph_settings;
	foreach my $graph_name_result (@{ $rs->results() }) {
		push @graph_settings, ODO::Jena::Graph::Settings->new($graph_name_result->s(), $self);
	}
	
	return \@graph_settings;
}


=item remove_graph( $graph_name )

=cut

sub remove_graph {
	my ($self, $graph_name) = @_;
	
	my $object = ODO::Node::Literal->new( $graph_name );
	my $query = ODO::Query::Simple->new(undef, ${ODO::Jena::Vocabulary::GraphName}, $object);
	
	my $rs = $self->{'storage'}->issue_query( $query );
	
	return undef;
}


=item clean( )

Clear all RDF information from the database.

=cut

sub clean {
	my $self = shift;
	
	my @tables = $self->{'dbh'}->tables();
	
	foreach my $name (@tables) {
		my $stm = $self->{'dbh'}->prepare( $self->{'sql_library'}->retr('dropTable', $name) );
		
		throw ODO::Exception::DB(error=> 'Unable to get statement handle to drop table. DBI Error: ' . $self->{'dbh'}->errstr() )
			unless($stm);
		
		throw ODO::Exception::DB(error=> "Unable to execute statement for table: $name. DBI Error: " . $self->{'dbh'}->errstr() )
			unless($stm->execute());

		$stm->finish();
	}
}


sub __intialize_system {
	my ($self) = @_;
	
	my @tables = $self->{'dbh'}->tables();
	
	my $storage_table_name = $self->{'storage'}->full_table_name();
	
	return 1
		if(grep(/$storage_table_name/, @tables));
	
	my $sql_lib = $self->{'storage'}->sql_library();
	
	# TODO: Check to see if we have initialzed the system tables yet	
	my @variables = ($self->{'column_type'}, $self->{'table_impl_type'}, $self->{'key_length'}, $self->{'head_column_type'}, $self->{'head_key_len'});
	
	my $init_db = $sql_lib->retr('initDBtables', @variables);
	
	$self->{'dbh'}->do($init_db);
}


sub init {	
	my ($self, $config) = @_;
	
	my $default_config = {
		column_type=> 'VARCHAR(250)',
		table_impl_type=> 'MyISAM',
		key_length=> 250,
		head_column_type=> 'TINYBLOB',
		head_key_len=> 250,
	};
	$self->params($default_config, qw/column_type table_impl_type key_length head_column_type head_key_len/);
	
	$self->params($config, qw/dbh column_type table_impl_type key_length head_column_type head_key_len/);
	
	$config->{'dbh'} = $self->{'dbh'};
	$config->{'table_name'} = ${ODO::Jena::Graph::SYSTEM_GRAPH_TABLE_NAME};
	$config->{'storage_package'} = 'ODO::Jena::Graph::Storage';
	
	$self = $self->SUPER::init( $config );
	
	return undef
		unless($self);
	
	$self->__intialize_system();

	return $self;	
}


=back

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Graph::Storage>, L<ODO::Jena>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut


1;

__END__

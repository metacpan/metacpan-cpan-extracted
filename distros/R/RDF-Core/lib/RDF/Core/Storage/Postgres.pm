# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Storage::Postgres;

use strict;
require Exporter;

our @ISA = qw(RDF::Core::Storage);

use Carp;
use DBI qw(:sql_types);
require RDF::Core::Storage;
require RDF::Core::Enumerator::Postgres;

############################################################
# constants

#use constant RDF_CORE_UNDEFINED => 0;

#use constant RDF_CORE_DB_DONT_CREATE => 0;
use constant RDF_CORE_DB_CREATE => 1;

#use constant RDF_CORE_SELECT_OBJECT_RES => 1;
#use constant RDF_CORE_SELECT_OBJECT_LIT => 2;

#use constant RDF_CORE_SELECT_DATA => 1;
#use constant RDF_CORE_EXISTS_ONLY => 2;

#use constant RDF_CORE_COUNT_ONLY => 1;
#use constant RDF_CORE_DATA => 2;


############################################################
# constructor

sub new {
    my ($class, %params) = @_;
    $class = ref $class || $class;
    my $self = { 
		dbconn => $params{ConnectStr},
		dbuser => $params{DBUser},
		dbpasswd => $params{DBPassword},
		model => $params{Model}, 
	       };
    bless $self, $class;
    return $self;
}

############################################################
# internal private methods

sub _getDBHandle {
    my $self = shift;
    unless ($self->{dbh}) {
	$self->{dbh} = DBI->connect($self->{dbconn}, $self->{dbuser},
				    $self->{dbpasswd}, {RaiseError => 1});
	my $sth = $self->{dbh}->prepare('set client_encoding to unicode');
	$sth->execute();
    }
    return $self->{dbh};
}

sub _getModelId {
    my ($self) = @_;
    unless ($self->{model_id}) {
	my $sth = $self->_getDBHandle()->prepare('select rdf_model_get(?,?)');
	$sth->bind_param(1,$self->{model});
	$sth->bind_param(2,1);
	$sth->execute;
	my @row = $sth->fetchrow_array;
	$self->{model_id} = $row[0];    
    };
    return $self->{model_id};
}

sub _getStmt {
    my ($self, $stmt, $create) = @_;
    my $rval;
    my $isLiteral = $stmt->getObject()->isLiteral(); 
    my $proc = $isLiteral ? 
      'select rdf_stmt_get(?,?,?,?,?,?,?,?,?)' : 
	'select rdf_stmt_get(?,?,?,?,?,?,?,?)';
    my $sth = $self->_getDBHandle()->prepare($proc);
    my $i = 1;
    $sth->bind_param($i++, $self->_getModelId);
    $sth->bind_param($i++, $stmt->getSubject()->getNamespace());
    $sth->bind_param($i++,  $stmt->getSubject()->getLocalValue());
    $sth->bind_param($i++, $stmt->getPredicate()->getNamespace());
    $sth->bind_param($i++, $stmt->getPredicate()->getLocalValue());
    if ($isLiteral) {
	$sth->bind_param($i++, $stmt->getObject()->getValue());
	$sth->bind_param($i++, $stmt->getObject()->getLang());
	$sth->bind_param($i++, $stmt->getObject()->getDatatype());
    } else {
	$sth->bind_param($i++,$stmt->getObject()->getNamespace());
	$sth->bind_param($i++,$stmt->getObject()->getLocalValue());
    };
    $sth->bind_param($i++, $create);
    $sth->execute();		
    my @row = $sth->fetchrow_array;      
    return $row[0];
}

sub _buildSelect {
    my ($self, $subj, $pred, $obj, %switches) = @_; 
    #apropriate switches are {count} (and {exists} ?)

    my $sql;
    my @bindings;
    #build select part
    my $select;
    if ($switches{count}) {
	$select = "Select count(*)\n"
    } elsif ($switches{exists}) {
	$select = "Select exists (Select 1 \n";
    } else {
	$select = "Select n1.namespace, r1.local_name, n2.namespace, ";
	$select .= "r2.local_name, n3.namespace, r3.local_name, s.object_lit,";
	$select .= "s.object_lang, s.object_type\n"
    }

    #build from and where part
    my $from = "From rdf_statement s ";
    my $where = "\nWhere s.model_id = ?";
    push @bindings, $self->_getModelId;
    if (($obj && !$obj->isLiteral) || 
	!($switches{count} || $switches{exists})) {
	$from .= "\nLeft Join rdf_resource r3 On r3.res_id = s.object_res ";
	$from .= "\nLeft Join rdf_namespace n3 On n3.ns_id = r3.ns_id ";
	
    }
    if ($subj || !($switches{count} || $switches{exists})) {
	$from .= ",\n rdf_resource r1, rdf_namespace n1 ";
	$where .= "\n and s.subject = r1.res_id ";
	$where .= "\n and r1.ns_id = n1.ns_id ";
    }
    if ($pred || !($switches{count} || $switches{exists})) {
	$from .= ",\n rdf_resource r2, rdf_namespace n2 ";
	$where .= "\n and s.predicate = r2.res_id ";
	$where .= "\n and r2.ns_id = n2.ns_id ";
    }
    ##
    if ($subj) {
	$where .= "\n and r1.local_name = ? and n1.namespace = ? ";
	push @bindings, $subj->getLocalValue;
	push @bindings, $subj->getNamespace;
    }
    if ($pred) {
	$where .= "\n and r2.local_name = ? and n2.namespace = ? ";
	push @bindings, $pred->getLocalValue;
	push @bindings, $pred->getNamespace;
    }
    if ($obj) {
	if ($obj->isLiteral) {
	    $where .= "\n and s.object_lit = ? ";
	    push @bindings, $obj->getValue;
	    if (defined $obj->getLang) {
		$where .= "\n and s.object_lang = ? ";
		push @bindings, $obj->getLang;
	    } else {
		$where .= "\n and s.object_lang is null ";
	    }
	    if (defined $obj->getDatatype) {
		$where .= "\n and s.object_type = ? ";
		push @bindings, $obj->getDatatype;
	    } else {
		$where .= "\n and s.object_type is null ";
	    }
	} else {
	    $where .= "\n and r3.local_name = ? and n3.namespace = ? ";
	    push @bindings, $obj->getLocalValue;
	    push @bindings, $obj->getNamespace;
	}
    }
    $sql = "$select $from $where";
    $sql .= ")" if $switches{exists};
    return $sql, \@bindings;
}

sub _getStmts {
    my ($self, $subject, $predicate, $object, %switches) = @_;

    my ($sql, $bindings) = $self->_buildSelect
      ($subject, $predicate, $object, %switches);

    my $sth = $self->_getDBHandle()->prepare($sql);
    $sth->execute(@$bindings);
    return $sth;
}


############################################################
# methods

sub addStmt {
    my ($self, $stmt) = @_;
    return _getStmt ($self, $stmt, RDF_CORE_DB_CREATE);
}
sub removeStmt {
    my ($self, $stmt) = @_;
    my $rval;
    my $isLiteral = $stmt->getObject()->isLiteral(); 
    my $proc = $isLiteral ? 
      'select rdf_stmt_del(?,?,?,?,?,?,?,?)' : 
	'select rdf_stmt_del(?,?,?,?,?,?,?)';
    my $sth = $self->_getDBHandle()->prepare($proc);
    my $i = 1;
    $sth->bind_param($i++, $self->_getModelId);
    $sth->bind_param($i++, $stmt->getSubject()->getNamespace());
    $sth->bind_param($i++,  $stmt->getSubject()->getLocalValue());
    $sth->bind_param($i++, $stmt->getPredicate()->getNamespace());
    $sth->bind_param($i++, $stmt->getPredicate()->getLocalValue());
    if ($isLiteral) {
	$sth->bind_param($i++, $stmt->getObject()->getValue());
	$sth->bind_param($i++, $stmt->getObject()->getLang());
	$sth->bind_param($i++, $stmt->getObject()->getDatatype());
    } else {
	$sth->bind_param($i++,$stmt->getObject()->getNamespace());
	$sth->bind_param($i++,$stmt->getObject()->getLocalValue());
    };
    $sth->execute();		
    my @row = $sth->fetchrow_array;      
    return $row[0];
}

sub existsStmt {
    my ($self, $subject, $predicate, $object) = @_;    
    my $dbh = $self->_getDBHandle();
    unless ($subject || $predicate || $object) {
	my $sth = $dbh->prepare('SET ENABLE_SEQSCAN TO OFF');
	$sth->execute();
    }
    my $sth = $self->_getStmts($subject, $predicate, $object, exists=>1);
    my @row = $sth->fetchrow_array;      
    $dbh = $self->_getDBHandle();
    unless ($subject || $predicate || $object) {
	my $sth = $dbh->prepare('SET ENABLE_SEQSCAN TO ON');
	$sth->execute();
    }
    return $row[0];
}

sub getStmts {
    my ($self, $subject, $predicate, $object) = @_;
    my $dbh = $self->_getDBHandle();
    unless ($subject || $predicate || $object) {
	my $sth = $dbh->prepare('SET ENABLE_SEQSCAN TO OFF');
	$sth->execute();
    }

    my $sth = $self->_getStmts($subject, $predicate, $object);
    unless ($subject || $predicate || $object) {
	my $sth = $dbh->prepare('SET ENABLE_SEQSCAN TO ON');
	$sth->execute();
    }
    return new RDF::Core::Enumerator::Postgres( (Cursor  => $sth) );
}

sub countStmts {
    my ($self, $subject, $predicate, $object) = @_;   

    my $dbh = $self->_getDBHandle();
    unless ($subject || $predicate || $object) {
	my $sth = $dbh->prepare('SET ENABLE_SEQSCAN TO OFF');
	$sth->execute();
    }
    my $sth = $self->_getStmts($subject, $predicate, $object, count=>1);
    my @row = $sth->fetchrow_array;      
    unless ($subject || $predicate || $object) {
	my $sth = $dbh->prepare('SET ENABLE_SEQSCAN TO ON');
	$sth->execute();
    }
    return $row[0];
}

sub getNewResourceId {
    my $self = shift;
    my $sth = $self->_getDBHandle()->prepare('select rdf_res_new_id()');
    $sth->execute();		
    my @row = $sth->fetchrow_array;      
    return $row[0];    
}

sub DESTROY {
    my $self = shift;
    $self->{dbh}->disconnect() if ($self->{dbh});
};

1;
__END__

=head1 NAME

RDF::Core::Storage::Postgres - PostgreSQL implementation of RDF::Core::Storage

=head1 SYNOPSIS

  require RDF::Core::Storage::Postgres;
  my $storage = new RDF::Core::Storage::Postgres((
						  ConnectStr=>'dbi:Pg:dbname=rdf',
						  DBUser=>'username',
						  Model=>'1',
						 ));
  my $model = new RDF::Core::Model (Storage => $storage);

=head1 DESCRIPTION

The storage is based on PostgreSQL database.

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * ConnectStr

Connect string (see PostgreSQL documentation)

=item * DBUser, DBPassword

Database username and pasword.

=item * Model

More then one model can be stored in one database, use Model to distinct between them.

=back


The rest of the interface is described in RDF::Core::Storage.

=back

=head2 INSTALLATION

You need to have PostgreSQL database installed. Then run scripts in dbmodel/pgsql/rdf-pgsql.sql and database will be created and ready for use.



=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Storage, RDF::Core::Model


=cut


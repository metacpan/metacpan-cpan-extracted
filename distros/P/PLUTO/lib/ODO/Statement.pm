#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Statement.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/05/2004
# Revision:	$Id: Statement.pm,v 1.3 2010-02-17 17:17:09 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Statement;

use strict;
use warnings;

use ODO::Exception;
use ODO::Node;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use Digest::MD5 qw/md5_hex/;

__PACKAGE__->mk_accessors(qw/s p o/);

=head1 NAME

ODO::Statement - Encapsulation of an RDF triple for graphs

=head1 SYNOPSIS

 use ODO::Node;
 use ODO::Statement;

 my $s = ODO::Node::Resource->new('urn:lsid:testuri.org:ns:object:');
 my $p = ODO::Node::Resource->new('http://testuri.org/predicate');
 my $o = ODO::Node::Literal->new('literal');

 my $statement_1 = ODO::Statement->new($s, $p, $o);

 # or

 my $statement_2 = ODO::Statement->new(s=> $s, p=> $p, o=> $o);

 # and then..

 if($statement_1->equals($statement_2)) {
 	print "\$statement_1 == \$statement_2\n";
 }	
 else {
 	print "The statements are not equal\n";
 }

=head1 DESCRIPTION

A simple container that encapsulates a single RDF statement. This object also provides tests
for equality.

=head1 METHODS

=over

=item new( s=> $subject, p=> $predicate, o=> $object)

=item new( $s, $p, $o )

Creates a new ODO::Statement object with the specified subject ($s), predicate ($p), object ($o)
The subject, predicate, object must be any combination of L<ODO::Node::Resource|ODO::Node>, 
L<ODO::Node::Literal|ODO::Node>, L<ODO::Node::Variable|ODO::Node>, L<ODO::Node::Blank|ODO::Node> 
(more generically, anything that conforms to L<ODO::Node|ODO::Node>).

=cut

sub new {
	my $self = shift;
	my $params = $self->params_to_hash(\@_, 0, [qw/s p o/], { 'subject'=> 's', 'predicate'=> 'p', 'object'=> 'o' } );
	return $self->SUPER::new(%{ $params });
}

no warnings;

*subject = \&s;
*predicate = \&p;
*object = \&o;

use warnings;

=item s( [ $subject ] )

Get or set the subject of this statement.

=item p( [ $predicate ] )

Get or set the predicate of this statement.

=item o( [ $object ] )

Get or set the object of this statement

=item equal( $statement ) 

Determines whether or not the statement is the same as the statement passed as the parameter.

=cut

sub equal {
	my ($self, $statement) = @_;
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Parameter must be an ODO::Statement')
		unless($statement->isa('ODO::Statement'));
		
	return 1
		if(   $self->s()->equal($statement->s())
		   && $self->p()->equal($statement->p())
		   && $self->o()->equal($statement->o())
		);
		
	return 0;
}

=item strict_equal( $statement )

Tests whether or not $self and $statement are the same statement, L<ODO::Node|ODO::Node::Any> nodes
_MUST_ match in this method.

=cut

sub strict_equal {
	my ($self, $statement) = @_;
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Parameter must be an ODO::Statement')
		unless($statement->isa('ODO::Statement'));

	# TripleMatches are equal iff each component is the same.. 
	# 'Any' nodes must be 'Any' nodes
	foreach my $comp ('s', 'p', 'o') {
	
		return 0
			if(    $self->$comp()->isa('ODO::Node::Any')
			   && !$statement->$comp()->isa('ODO::Node::Any'));
	}
	
	return 1
		if(   $self->s()->equal($statement->s())
		   && $self->p()->equal($statement->p())
		   && $self->o()->equal($statement->o())
		);
	
	return 0;
}


=item hash( )

Generates a hash signature of this statement for comparison purposes internally and wherever
the application developer feels appropriate.

=cut

sub hash {
	my $self = shift;

	if(!defined($self->{'_hash_value'})) {
		$self->{'_hash_value'} = $self->s()->hash() . '-' . $self->p()->hash() . '-' . $self->o()->hash();
	}
		
	return $self->{'_hash_value'};	 
}


sub init {
	my ($self, $config) = @_;
	
	unless(
	       $config->{'s'}->isa('ODO::Node')
		&& $config->{'p'}->isa('ODO::Node')
		&& $config->{'o'}->isa('ODO::Node')
		) {

		throw ODO::Exception::Parameter::Invalid(error=> 'All three parameters to constructor must be ODO::Node');
	}
	
	$self->params($config, qw/s p o/);
	
	return $self;
}

=back

=cut

package ODO::Statement::Virtual;

use strict;
use warnings;

our @ISA = ( 'ODO::Statement' );

=head1 NAME

ODO::Statement::Virtual - Encapsulation of an virtual RDF triple pattern.

=head1 SYNOPSIS
 use ODO::Node;
 use ODO::Statement::Virtual;

 my $s = ODO::Node::Resource->new('urn:lsid:testuri.org:ns:object:');
 my $p = ODO::Node::Resource->new('http://testuri.org/predicate');
 my $o = ODO::Node::Literal->new('literal');

 my $virtual_1 = ODO::Statement::Virtual->new($s, $p, $o);

 my $virtual_2 = ODO::Statement::Virtual->new(s=> $s, p=> $p, o=> $o);

 if($statement_1->equals($statement_2)) {
 	print "\$statement_1 == \$statement_2\n";
 }
 else {
 	print "The statements are not equal\n";
 }

=head1 DESCRIPTION

These objects are used in the presences of a reasoner to create statements that have 
been inferred in order to differentiate them from statements that are actually 'in'
the graph.

=head1 SEE ALSO

L<ODO::Node>, L<ODO::Graph>, L<ODO::Query::Simple>, L<ODO::Statement::Group>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut

1;

__END__

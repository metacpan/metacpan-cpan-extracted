#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Statement/Group.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/18/2005
# Revision:	$Id: Group.pm,v 1.3 2010-02-17 17:17:09 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Statement::Group;

use strict;
use warnings;

use ODO::Exception;
use ODO::Node;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_accessors(qw/subject predicates properties/);

=head1 NAME

ODO::Statement::Group - Group of statements with a common subject.

=head1 SYNOPSIS

Synopsis.

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item new( [ s=> $subject ] | $subject )

Create a new group of statements with the same subject

=item add( $subject, $predicate, $object )

=cut

sub add {
	my ($self, $subject, $predicate, $object) = @_;
	
	unless($self->subject()->equal($subject)) {
		my $s1 = $self->subject()->value();
		my $s2 = $subject->value();
		
		throw ODO::Exception::Parameter::Invalid(error=> "Cannot add statements to ODO::Statement::Group with differing subjects: $s1 != $s2");
	}
		
	throw ODO::Exception::Parameter::Invalid(error=> 'Predicate node must be an ODO::Node::Resource')
		unless($predicate->isa('ODO::Node::Resource'));
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Object node must be an ODO::Node')
		unless($object->isa('ODO::Node'));
	
	# Properties are keys in the hash, that hold arrays of objects for that property
	unless(exists($self->properties()->{ $predicate->hash() })) {
		$self->properties()->{ $predicate->hash() } = [];
		$self->predicates()->{ $predicate->hash() } = $predicate;
	}
	
	# Finally add the property's object to the list
	push @{ $self->properties()->{ $predicate->hash() }}, $object;
}

=item delete( )

=cut

sub delete {
	my ($self, $subject, $predicate, $object) = @_;
	
	unless($self->subject()->equal($subject)) {	
		my $s1 = $self->subject()->value();
		my $s2 = $subject->value();

		throw ODO::Exception::Parameter::Invalid(error=> "Cannot delete statements from ODO::Statement::Group with differing subjects: $s1 != $s2");
	}
		
	throw ODO::Exception::Parameter::Invalid(error=> 'Predicate node must be an ODO::Node::Resource')
		unless($predicate->isa('ODO::Node::Resource'));
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Object node must be an ODO::Node')
		unless($object->isa('ODO::Node'));
	
	# FIXME: Finish delete method	
}

=item add_property( $predicate, $object )

=cut

sub add_property {
	my $self = shift;
	$self->add($self->subject(), @_);
}

=item remove_property( $predicate, $object )

=cut

sub remove_property {
	my $self = shift;
	$self->delete($self->subject(), @_);
}

=item merge( $stmt_group )

=cut

sub merge {
	my ($self, $stmt_group) = @_;
	
	unless($stmt_group->subject()->equal($self->subject())) {
		my $s1 = $stmt_group->subject()->value();
		my $s2 = $self->subject()->value();
		throw ODO::Exception::Statement(error=> "Subjects of statement groups must match in order to be merged: $s1 != $s2");
	}
	
	foreach my $predicateURI (keys( %{ $stmt_group->properties() })) {
		foreach my $object ($stmt_group->properties()->{ $predicateURI }) {
			$self->add($self->subject(), $stmt_group->predicates()->{ $predicateURI }, $object);
		}
	}
	
	return $self;
}

=item statements()

Convert this group in to an array of statements.

=cut

sub statements {
	my $self = shift;
	
	my $statements = [];
	
	foreach my $predicate (keys(%{ $self->properties() })) {
		foreach my $object (@{ $self->properties()->{ $predicate }}) {
			push @{ $statements }, ODO::Statement->new($self->subject(), $self->predicate()->{ $predicate }, $object);
		}
	}
	
	return (wantarray) ? @{ $statements } : $statements;
}


sub init {
	my ($self, $config) = @_;
	
	my $subject = $config->{'s'};
	
	$subject = ODO::Node::Resource->new($subject);
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Subject for a ODO::Statement::Group must be an ODO::Node::Resource')
		unless($subject->isa('ODO::Node::Resource'));
	
	$self->subject($subject);
	$self->properties( {} );
	$self->predicates( {} );
	
	return $self;
}


=back

=head1 AUTHOR

IBM Corporation

=head1 COPYRIGHT

Copyright (c) 2005-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__

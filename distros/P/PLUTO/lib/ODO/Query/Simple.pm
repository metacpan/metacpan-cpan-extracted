#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Simple.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/05/2004
# Revision:	$Id: Simple.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Simple;

use strict;
use warnings;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Statement/;

=head1 NAME

ODO::Query::Simple - Simple single statement wildcard graph pattern matcher

=head1 SYNOPSIS

 use ODO::Node;
 use ODO::Query::Simple;
 use ODO::Query::Simple::Result;

 my $s = ODO::Node::Resource->new('urn:lsid:testuri.org:ns:object:');
 my $p = ODO::Node::Resource->new('http://testuri.org/predicate');

 my $stmt = ODO::Query::Simple->new($s, $p, undef);

 # ... $graph is an ODO::Graph

 # Search for statements that match $s, $p, <ANY>
 my $result_set = $graph->query($stmt);

=head1 DESCRIPTION

A simple single statement based graph pattern for searching.

=head1 CONSTANTS

=over

=item $ALL_STATEMENTS

=back

=cut

our $ALL_STATEMENTS = ODO::Query::Simple->new();

=head1 METHODS

=over

=item new( [ [s=> $s ], [ p=> $p], [ o=> $o ] ] | [ $s, [ $p, [ $o ] ] ] )

Creates a new L<ODO::Query::Simple> object with the specified $subject, $predicate, $object
The $subject, $predicate, $object may be any combination of L<ODO::Node::Resource|ODO::Node::Resource>, 
L<ODO::Node::Literal|ODO::Node::Literal>, L<ODO::Node::Variable|ODO::Node::Variable>, 
L<ODO::Node::Blank|ODO::Node::Blank> (more generically, anything that conforms to L<ODO::Node|ODO::Node>).

If any of the parameters $subject, $predicate, $object are undef, that node will become
an L<ODO::Node::Any|ODO::Node::Any>.

=item equal( $statement )

Tests whether or not $self and $statement are the same statement, taking
L<ODO::Node::Any|ODO::Node::Any> nodes in to account.

=cut

sub equal {
	my ($self, $statement) = @_;

	throw ODO::Exception::Parameter::Invalid(error=> 'Missing statement parameter, must be type ODO::Statement')
		unless(UNIVERSAL::isa($statement, 'ODO::Statement'));

	return 1
		if(   $self->s()->equal($statement->s())
		   && $self->p()->equal($statement->p())
		   && $self->o()->equal($statement->o())
		);
	
	return 0;
}


sub init {
	my ($self, $config) = @_;
	
	# ANY nodes match everything
	my $s = $config->{'s'} || $ODO::Node::ANY;
	my $p = $config->{'p'} || $ODO::Node::ANY;
	my $o = $config->{'o'} || $ODO::Node::ANY;

	$self->s($s);
	$self->p($p);
	$self->o($o);
	
	return $self;
}


=back

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Graph>, L<ODO::Statement>, L<ODO::Node>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut

1;

__END__

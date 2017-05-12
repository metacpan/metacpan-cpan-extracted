#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Graph.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/18/2005
# Revision:	$Id: Graph.pm,v 1.3 2010-05-20 17:29:00 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Graph;

use strict;
use warnings;

use base qw/ODO/;

use ODO::Exception;

use Module::Load::Conditional qw/can_load/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use Class::Interfaces('ODO::Graph'=> 
	{
		'isa'=> 'ODO',
		'methods'=> [ 'add', 'remove', 'query', 'contains', 'size', 'clear', 'intersection', 'union' ],
	}
  );

__PACKAGE__->mk_accessors(qw/name/);
__PACKAGE__->mk_ro_accessors(qw/storage storage_package/);


sub AUTOLOAD {
	our $AUTOLOAD;
	
	my $caller_package = shift @_;
	my $storage_type = $AUTOLOAD;
	
	$storage_type =~ s/^${caller_package}:://;
	
	return undef
		if($storage_type =~ /::DESTROY$/);
	
	my $backend_loaded = can_load( modules => {"ODO::Graph::Storage::$storage_type"=> undef} );
	
	throw ODO::Exception::Module(error=> "Could not load graph storage module: 'ODO::Graph::Storage::$storage_type'\n==> $@")
		if(!defined($backend_loaded) || !UNIVERSAL::can("ODO::Graph::Storage::$storage_type", 'new'));

	throw ODO::Exception::Module(error=> "Can not load $caller_package")
		if(!UNIVERSAL::can($caller_package, 'new_from_autoload'));
	
	shift; # Get rid of the package
	
	return $caller_package->new_from_autoload(storage_package=> "ODO::Graph::Storage::$storage_type", @_);
}

=head1 NAME

ODO::Graph - Base methods for a graph object

=head1 SYNOPSIS

 use ODO::Graph::Simple;

 # Create an ODO::Graph::Simple object backed by memory
 my $graph = ODO::Graph::Simple->Memory();

=head1 DESCRIPTION

Base graph object that defines the graph interface.

=head1 CONSTRUCTOR

Constructor.

=head1 AUTOLOAD

Autoload.

=head1 METHODS

=over

=item add( $statement )

=item add( \@statements )

=item add( @statements )

Add statement(s).

=item remove( $statement )

=item remove( \@statements )

=item remove( @statements )

Remove statement(s).

=item size( )

Returns the number of statements in the graph.

=item query( $query )

Query the graph based on the query parameter which must be a subclass of L<ODO::Query|ODO::Query>.

=item clear( )

Remove all statements from the graph.

=item contains( $query )

Returns a boolean value of the graph contains results that match the query.

=item storage( )

Returns the underlying graph storage object. See L<ODO::Graph::Storage> for more information.

=item storage_package( )

Returns the name of the package for the underlying graph storage object. 
See L<ODO::Graph::Storage> for more information.

=cut

sub new_from_autoload {
	my $self = shift;
	return $self->new(@_);
}

sub init {
	my ($self, $config) = @_;
	
	$self->params($config, qw/name storage_package/);
	
	my $backend_loaded = can_load( modules => {$self->{'storage_package'}=> undef} );
	throw ODO::Exception::Module(error=> "Could not load graph storage module: '". $self->{'storage_package'} ."'\n==> $@")
		if(!defined($backend_loaded));
	
	$self->{'storage'} = $self->{'storage_package'}->new( %{ $config }, parent_graph=> $self );
	
	return $self;
}

=back

=head1 SEE ALSO

L<ODO::Graph::Storage>, L<ODO::Statement>, L<ODO::Query>

=head1 COPYRIGHT

Copyright (c) 2005-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut

1;

__END__

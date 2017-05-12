#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/21/2004
# Revision:	$Id: Ontology.pm,v 1.6 2009-11-25 17:46:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology;

use strict;
use warnings;

use ODO::Exception;
use ODO::Query::Simple;

use URI;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

our @METHODS = qw/graph schema_graph schema_name base_namespace base_class/;

__PACKAGE__->mk_accessors(@METHODS);
__PACKAGE__->mk_ro_accessors(qw/symbol_table_list/);

our $PERL_IDENTIFIER = "/^[A-Za-z_][A-Za-z_0-9]*$/";
our $PERL_VARIABLE = "/^(:${PERL_IDENTIFIER}::)+$/";


=head1 NAME

ODO::Ontology

=head1 SYNOPSIS
	
=head1 DESCRIPTION

=head1 METHODS

=over

=item add_symtab_entry( $hashref, $uri, $name)

=cut

sub add_symtab_entry {
	my ($self, $table_ref, $uri, $label) = @_;
	
	my $symtab = $self->__declare_symbol_table($table_ref);
	
	$symtab->{'labels'}->{ $label } = $uri;
	$symtab->{'uris'}->{ $uri } = $label;

	return 1;	
}


=item get_symtab_entry( $hashref, $uri )

=cut

sub get_symtab_entry {
	my ($self, $table_ref, $uri) = @_;
	
	my $symtab = $self->__declare_symbol_table($table_ref);
	
	return undef
		unless(exists($symtab->{'uris'}->{ $uri }) && defined($symtab->{'uris'}->{ $uri } ));

	return $symtab->{'uris'}->{ $uri };
}

sub get_symbol_table {
	my ($self, $table_ref) = @_;
	
	return $self->__declare_symbol_table($table_ref);
}


=item make_perl_package_name( $base, ( $name | [ name1, name2, name3 ] ) )

=cut

sub make_perl_package_name {
	my ($self, $base, $name) = @_;
	
	my @name_list;
	if(UNIVERSAL::isa($name, 'ARRAY')) {
		@name_list = @{ $name };
	}
	else {
		@name_list = ($name);
	}
	
	unshift @name_list, $base
		if(defined($base) && $base ne '');
	
	return join('::', @name_list);
}


sub __declare_symbol_table {
	my ($self, $table_ref) = @_;
	
	return $self->{'symbol_table_list'}->{ $table_ref }
		if(	   exists($self->{'symbol_table_list'}->{ $table_ref })
			&& UNIVERSAL::isa($self->{'symbol_table_list'}->{ $table_ref }, 'HASH'));
	
	$self->{'symbol_table_list'}->{ $table_ref } = {
		labels=> {},
		uris=> {},
	};
	
	return $self->{'symbol_table_list'}->{ $table_ref };
}


sub __parse_uri_for_name {
	my ($self, $uri) = @_;

	$uri = URI->new($uri);	

	my $name = $uri->fragment();	
	
	return $name
		if($name);
		
	($name) = $uri->as_string() =~ /(?:[\#\/\:])([^\#\/\:]+)$/;

	return $name
		if($name);
		
	return $uri->as_string();
	
	# FIXME: Figure out what to do here
	# return ($uri->fragment() || $uri->as_string());
}


sub __is_perl_package {
	my ($self, $perl_test_structure) = @_;

	return 1
		if(UNIVERSAL::can($perl_test_structure, 'new'));
	
	return 0;
}


sub __make_perl_identifier {
	my ($self, $name) = @_;
	$name =~ s/\ |#|\:|\\|\/|\-|\.//g;
	return $name
}


sub __make_perl_string {
	my ($self, $string) = @_;
	
	$string =~ s/ +/ /g;
	$string =~ s/\n|\r//g;

	return $string;
}

sub init {
	my ($self, $config) = @_;
	$self->params($config, @METHODS);
	
	$self->{'symbol_table_list'} = {}
		unless(UNIVERSAL::isa($self->{'symbol_table_list'}, 'HASH'));
	
	return $self;
}

=back

=head1 COPYRIGHT

Copyright (c) 2005-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html
  
=cut

1;

__END__

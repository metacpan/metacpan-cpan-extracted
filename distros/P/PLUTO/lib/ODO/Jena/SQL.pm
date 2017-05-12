#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/SQL.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/14/2004
# Revision:	$Id: SQL.pm,v 1.2 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::SQL;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

ODO::Jena::SQL - Jena SQL related methods

=head1 SYNOPSIS

 use ODO::Jena::SQL;

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item find_sql_library_file( $dbh )

=cut

sub find_sql_library_file {
	my ($self, $dbh, @more_search_dirs) = @_;
	
	@more_search_dirs = ()
		unless(scalar(@more_search_dirs) > 0);
	
	my @data_sources = $dbh->data_sources();

	my $db_type = 'generic_generic';	
	foreach my $dsn (@data_sources) {
		if($dsn =~ /^DBI:(\w+):.*$/) {
			$db_type = lc($1);
			last;	
		}
	}
	
	my $sql_lib_file = 'ODO/Jena/etc/' . $db_type . '.sql';
	
	foreach my $inc_dir (@more_search_dirs, @INC) {
		if(-e $inc_dir . '/' . $sql_lib_file) {
			$sql_lib_file = $inc_dir . '/' . $sql_lib_file;
			last;
		}
	}
	
	return $sql_lib_file; 
}

=back

=cut

1;

package ODO::Jena::SQL::Library;

use strict;
use warnings;

use base qw/SQL::Library/;

use ODO::Exception;

our $DEBUG = 0;

=head1 NAME

ODO::Jena::SQL::Library - Load SQL statements in the Jena file format

=head1 SYNOPSIS

 use ODO::Jena::SQL;

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item new( \%options )

=cut

sub new {
	my ($package, $options) = @_;
	
	my $self = {
		'options'=> $options,
		'contents'=> undef
	};
	
	$self->{'contents'} = $package->__load_jena_sql_lib($self->{'options'}->{'lib'});
	
	return bless $self, $package;
}


=item retr($name, @variables)

=cut

sub retr {
	my ($self, $name, @variables) = @_;
	
	return undef
		unless(exists($self->{'contents'}->{ $name }));

	my @var_names = ('a' .. 'z');
	
	my @sql_entity = @{ $self->{'contents'}->{ $name } };
	while(@variables) {
		my $var_value = shift @variables;
		my $cur_var_name = shift @var_names;
		
		map { $_ =~ s/\${$cur_var_name}/$var_value/g; } @sql_entity;
	}
	
	return join('', @sql_entity);
}


=item __load_jena_sql_lib( )

Loads the SQL statements necessary for interacting with the database.

Parameters: 
 $filename - Required. The filename to load the SQL from.

Returns:
 A HASH ref of the operations and their associated SQL statement(s)

=cut

sub __load_jena_sql_lib {
	my ($self, $filename) = @_;
	
	throw ODO::Exception::File::Missing(error=> "Unable to open file: $filename")
		unless(open(SQL_FILE, $filename));
	
	my $op_name;
	my @sql_op;
	
	my %operations;
	my $line_num = 0;
	
	$/ = "\n";
	while(<SQL_FILE>) {
		
		print STDERR $_
			if($DEBUG);
		
		$line_num++;
		
		next
			if($_ =~ /^[#]/);
		
		# Start a new operation
		if($_ =~ /^[\n\r]+$/) {
			# Save the final operation
			unless($op_name) {
				print STDERR "WARNING: operationName is not defined at line #$line_num\n" 
					if($DEBUG);
				
				next;
			}
			
			push @{ $operations{ $op_name } },  (join('', @sql_op) || '');
			
			# Reset to a blank operation
			@sql_op = ();
			$op_name = undef;
		}
		else {
			# Check to see if this is a new operation or a continuation
			if($op_name) {
				
				push @sql_op, $_ ;
				
				# If this is the end of a multiline SQL operation,
				# add it to the SQL statement list
				if($_ =~ /;;$/) {
					push @{ $operations{ $op_name } },  join('', @sql_op);
					
					@sql_op = ();
				}
			}
			else {
				# Start the new operation
				s/[ \r\n]//g;
				
				$op_name = $_;
				
				# Initializae the operations SQL statement array
				$operations{ $op_name } = [];
			}

		} #end if/else
	
	} # end while
	
	close(SQL_FILE);
	
	return \%operations;
}


sub __get_sql_lib_coderefs {
	my ($self, $operations) = @_;
		
	# Parse and substitute the specialized values in to the SQL statements and build
	# a dispatch table in ODO::DB::SQLOperations::Interface
	my $sql_lib_coderefs = {};
		
	foreach my $op_name (keys(%{ $operations } ) ) {
		my $process = " my \@lines = q( @{ $operations->{ $op_name } } );\n foreach my \$var ( 'a'..'z' ) {\n  my \$param = shift \@_;\n  last unless(\$param);\n  map {\n   \$_ =~ s/\\\${\$var}/\$param/g;\n  } \@lines; }\n";
		
		my $function = "sub {\n shift;\n  $process return join(\"\\n\", \@lines);\n}";
		
		$sql_lib_coderefs->{ $op_name } = $function;
	}
	
	return $sql_lib_coderefs;
}

=back

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Jena>, L<SQL::Library>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__

package Tangram::Expr::CursorObject;

use strict;
use Carp;

sub new
{
	my ($pkg, $storage, $class) = @_;

	my $schema = $storage->{schema};
	my $classes = $schema->{classes};
	$schema->check_class($class);

	my @tables;
	my $table_hash = { };
	my $self = bless { storage => $storage, tables => \@tables, class => $class,
					   table_hash => $table_hash }, $pkg;

	my %seen;

	for my $part ($storage->{engine}->get_parts($schema->classdef($class))) {
	  my $table = $part->{table};

	  unless (exists $seen{$table}) {
		my $id = $seen{$table} = $storage->alloc_table;
		#push @tables, [ $part->{name}, $id ];
		push @tables, [ $table, $id ];
	  }

	  my $id =  $seen{$table};
	  $table_hash->{ $part->{name} } = $id;

	  $self->{root} ||= $id;
	}

	# use Data::Dumper; print Dumper \@tables;


# 	$storage->{schema}->visit_up($class,
# 								 sub
# 								 {
# 									 my $class = shift;
			
# 									 unless ($classes->{$class}{stateless})
# 									 {
# 										 my $id = $storage->alloc_table;
# 										 push @tables, [ $class, $id ];
# 										 $table_hash->{$class} = $id;
# 									 }
# 								 } );

	return $self;
}

# sub copy
# {
# 	my ($pkg, $other) = @_;

# 	my $self = { %$other };
# 	$self->{tables} = [ @{ $self->{tables} } ];

# 	bless $self, $pkg;
# }

sub storage
{
	shift->{storage}
}

sub table
{
	my ($self, $class) = @_;
	$self->{table_hash}{$class} or confess "no table for $class in stored '$self->{class}'";
}

# sub tables
# {
# 	shift->{tables}
# }

sub class
{
	shift->{class}
		#my ($self) = @_;
		#my $tables = $self->{tables};
		#return $tables->[$#$tables][0];
}

sub table_ids
{
	return map { $_->[1] } @{ shift->{tables} };
}

# sub parts
# {
# 	return map { $_->[0] } @{ shift->{tables} };
# }

sub root_table
{
	my ($self) = @_;
	return $self->{root};
}

# sub class_id_col
# {
# 	my ($self) = @_;
# 	return "t$self->{tables}[0][1].$self->{storage}{class_col}";
# }

# sub leaf_table
# {
# 	my ($self) = @_;
# 	return $self->{tables}[-1][1];
# }

sub from
{
	return join ', ', &from unless wantarray;

	my ($self) = @_;
	my $schema = $self->storage->{schema};
	my $classes = $schema->{classes};
	my $tables = $self->{tables};
	map { "$_->[0] t$_->[1]" } @$tables;
}

sub where
{
	return join ' AND ', &where unless wantarray;

	my ($self) = @_;
   
	my $tables = $self->{tables};
	my $root = $tables->{root};
	my $id = $self->storage->{schema}{sql}{id_col};

	map { "t$_->[1].$id = t$root.$id" } @$tables[1..$#$tables];
}

# sub mark
# {
# 	return @{ shift->{tables} };
# }

sub expr_hash
{
	my ($self) = @_;
	my $storage = $self->{storage};
	my $schema = $storage->{schema};
	my $classes = $schema->{classes};
	my @tables = @{$self->{tables}};
   
	my %hash =
		(
		 _object => $self, 
		 id => Tangram::Type::Number->expr("t$self->{root}.$storage->{id_col}", $self),
		 type => Tangram::Type::Number->expr("t$self->{root}.$storage->{class_col}", $self),
		);

	$hash{_IID_} = $hash{_ID_} = $hash{id};
	$hash{_TYPE_} = $hash{type};

	for my $part ($storage->{engine}->get_parts($schema->classdef($self->{class}))) {
	  for my $field ($part->direct_fields) {
		$hash{ $field->{name} }
		    = $field->remote_expr($self, $self->{table_hash}{$part->{name}}, $storage);
	  }
	}
													  
	  
	

# 	$schema->visit_up($self->{class},
# 					  sub
# 					  {
# 						  my $classdef = $classes->{shift()};

# 						  my $tid = (shift @tables)->[1] unless $classdef->{stateless};

# 						  foreach my $typetag (keys %{$classdef->{members}})
# 						  {
# 							  my $type = $schema->{types}{$typetag};
# 							  my $memdefs = $classdef->{members}{$typetag};
# 							  @hash{$type->members($memdefs)} =
# 								  $type->query_expr($self, $memdefs, $tid, $storage);
# 						  }
# 					  } );

	return \%hash;
}

1;

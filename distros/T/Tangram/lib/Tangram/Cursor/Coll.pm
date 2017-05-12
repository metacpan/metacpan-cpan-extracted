
package Tangram::Cursor::Coll;

@Tangram::Cursor::Coll::ISA = 'Tangram::Cursor';

sub build_select
{
	my ($self, $template, $cols, $from, $where) = @_;

	push @$where, $self->{-coll_where}
	if $self->{-coll_where};

	push @$cols, $self->{-coll_cols} if exists $self->{-coll_cols};
	push @$from, $self->{-coll_from} if exists $self->{-coll_from};
	
	$self->SUPER::build_select($template, $cols, $from, $where);
}

sub DESTROY
{
	my ($self) = @_;
	#print "@{[ keys %$self ]}\n";
	# $self->{-storage}->free_table($self->{-coll_tid});
}

1;

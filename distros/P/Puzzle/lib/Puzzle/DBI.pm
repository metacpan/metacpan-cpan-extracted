package Puzzle::DBI;

our $VERSION = '0.04';

use base 'DBIx::Class::Schema';

use DBIx::Class::Schema::Loader;

sub new {
    my $proto   = shift;
    my $class   = ref($proto) || $proto;
	my $dsn = shift;
	my $user = shift;
	my $password = shift;
    	my $schema  = shift || 'DBIx::Class::Schema::Loader';
    my $s       = $schema->connect($dsn,$user,$password);
    bless $s, $class;
    return $s;
}

sub row2hash {
	my $selft	= shift;
	my $rs      = shift;
	my $include_columns = shift;
	my @columns = ($rs->columns, @$include_columns);
	return {map { $rs->table.'.'.$_ => $rs->get_column($_) } @columns};
}

sub rs2aoh {
	my $self	= shift;
    my $rs      = shift;
	my $include_columns = shift;
    my @ret;
    while (my $row = $rs->next) {
        push @ret, $self->row2hash($row,$include_columns);
    }
    return \@ret;
}

=head rs2hash()

Return an hashref where every key is the primary key value or a contatenation
of primary keys and value is an hashref with record elements

=cut

sub rs2hash {
	my $self	= shift;
    my $rs      = shift;
	my $include_columns = shift;
	my $ret		= {};
	my @pk		= $rs->result_source->primary_columns;
	while (my $row = $rs->next) {
		my $key = scalar(@pk) == 1
					? $row->get_column($pk[0]) . ''
					: join('-',map {$row->$_} @pk);
		$ret->{$key} = $self->row2hash($row,$include_columns);
	}
	return $ret;
}

1;


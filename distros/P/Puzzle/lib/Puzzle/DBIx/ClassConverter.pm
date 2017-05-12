package Puzzle::DBIx::ClassConverter;

our $VERSION = '0.18';

use base 'Class::Container';

sub resultset {
	my $self	= shift;
	my $rs		= shift;
	my $key		= shift || $rs->result_source->name;
	my $relship	= shift || {};

	my @ret;

	while ($rec = $rs->next) {
		push @ret,$self->row($rec,$relship);
	}

	return {$key => \@ret};
}

sub row {
	my $self	= shift;
	my $rs		= shift;
	my $relship	= shift || {};

	my $tblName	= $rs->result_source->name;

	my %ret		= $rs->get_columns;
	$ret{"$tblName.$_"} = $ret{$_} foreach(keys %ret);

	#foreach (keys %{$rs->result_source->_relationships}) {
	foreach my $rel (keys %$relship) {
		# relationships must exist
		if (exists $rs->result_source->_relationships->{$rel}) {
			my $rrow = $rs->$rel;
			if (ref($rrow) eq 'DBIx::Class::ResultSet') {
				if ($rrow->count == 1) {
					my $single_row = $rrow->next;
					%ret = (%ret,%{$self->row($single_row, $relsphip->{$rel})});
				} else {
					%ret = (%ret,%{$self->resultset($rrow,undef,$relsphip->{$rel})});
				}
			} elsif ($rrow && $rrow->isa('DBIx::Class::Row')) {
				%ret = (%ret,%{$self->row($rrow)});
			}
		}
	}

	return \%ret;
}

1;

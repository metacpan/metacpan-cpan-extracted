package ODS::Iterator;

use YAOO;

auto_build;

has table => isa(object);

has next_index => isa(integer(0));

has prev_index => isa(integer(0));

use overload
        '@{}' => sub { $_[0]->all };

# The following sub routines only manipulate the data that is in "memory"
# to query a larger dataset you should use the storage api/sub routines.

sub all {
	return $_[0]->table->rows;
}

sub first {
	return $_[0]->table->rows->[0];	
}

sub last {
	return $_[0]->table->rows->[-1];
}

sub next {
	my $next = $_[0]->table->rows->[$_[0]->next_index];
	$_[0]->next_index($_[0]->next_index + 1);
	return $next ? $next : $_[0]->next_index(0) && 0;
}

sub prev {
	if (not defined $_[0]->prev_index ) {
		$_[0]->prev_index(scalar @{ $_[0] });
	}
	my $prev = $_[0]->table->rows->[$_[0]->prev_index];
	$_[0]->prev_index($_[0]->prev_index + 1);
	return $prev ? $prev : $_[0]->prev_index(scalar @{$_[0]}) && 0;
}

sub flat {
	my ($self, $keyfield) = @_;
	my @array;
	for my $row (@{ $self }) {
		push @array, {%{$row}};
	}
	return \@array;
}

sub array_to_hash {
	my ($self, $keyfield) = @_;
	$keyfield ||= $self->table->keyfield;
	my %hash;
	for my $row (@{ $self }) {
		$hash{$row->{$keyfield}} = {%{$row}};
	}
	return \%hash;
}

sub foreach {
	my ($self, $cb) = @_;
	my @results;
	foreach my $row ( @{ $self }) {
		push @results, $cb->($row);
	}
	return wantarray ? @results : \@results;
}

sub find {
	my ($self, $cb) = @_;
	my $result;
	foreach my $row ( @{ $self }) {
		my $valid = $cb->({%{$row}});
		do { $result = $row } and last if $valid;
	}
	return $result;
}

sub find_index {
	my ($self, $cb) = @_;
	my $i;
	my @rows = @{ $self };
	for ($i = 0; $i < scalar @rows; $i++) {
		my $row = $rows[$i];
		my $valid = $cb->({%{$row}});
		last if $valid;
	}
	return $i;
}

sub reverse {
	my $self = shift;
	@{$self} = reverse @{$self};
	return [@{$self}];
}

sub filter {
	my ($self, $cb) = @_;
	my @results = grep {
		$cb->({%{$_}}) && $_
	} @{ $self };
	return wantarray ? @results : \@results;
}

sub sort {
	my ($self, $cb) = @_;
	@{ $self } = sort { $cb->($_) } @{ $self };
	@{ $self };
}

sub shift {
	shift @{ $_[0] };
}

sub pop {
	pop @{ $_[0] };
}

sub splice {
	my ($self, @params) = @_;
	return splice @{$self}, shift @params, shift @params;
}

1;

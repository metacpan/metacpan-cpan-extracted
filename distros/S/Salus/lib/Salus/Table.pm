package Salus::Table;
use strict; use warnings;
use Rope;
use Rope::Autoload;
use Text::CSV_XS qw/csv/;
use Types::Standard qw/Str ArrayRef Bool/; 
use Salus::Row;
use Salus::Row::Column;
use Digest::SHA qw/hmac_sha256_hex/;
use Text::Diff qw//;

property file => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,	
	type => Str,
);

property secret => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,	
	type => Str,
);

property unprotected_read => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,	
	type => Bool,
	value => 0
);

property headers => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	required => 1,
	enumerable => 1,	
	type => ArrayRef,
	value => []
);

property rows => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,	
	type => ArrayRef,
	value => [],
);

private hmac => sub {
	my ($self, $data) = @_;
	return hmac_sha256_hex($data, $self->secret ? $self->secret : ());
};

function count => sub {
	return scalar @{$_[0]->rows};
};

function read => sub {
	my ($self, $file, $read) = @_;
	$file ||= $self->file;
	my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
	open my $fh, "<:encoding(utf8)", $file or die "${file}: $!";
	if (!$self->unprotected_read) {
		my $data = do { local $/; <$fh> };
		seek $fh, 0, 0;
		my $match = $data =~ s/\n+(.*)$// && $1;
		if ($self->hmac($data) !~ m/^$match$/) {
			die "HMAC does not match for file ${file}";
		}
	}
	my ($line, $salus, @rows) = (0, 0);
	while (my $columns = $csv->getline($fh)) {
		if (0 == $line) {
			$salus = 1 if ($columns->[-1] eq 'SALUS');
			$line++;
			next;
		}
		last if scalar @{$columns} == 1;
		my @cols;
		if ($salus) {
			$salus = pop @{$columns};
			$csv->combine(@{$columns}) or die 'kaput' . $!;
			if ($self->hmac($csv->string()) !~ m/^$salus$/) {
				die "HMAC does not match for row ${line} in file ${file}";
			}
		}
		for (my $i = 0; $i < scalar @{$columns}; $i++) {
			push @cols, Salus::Row::Column->new({
				header => $self->headers->[$i],
				value => $columns->[$i]
			});
		}
		push @rows, Salus::Row->new(
			columns => \@cols
		);
		$line++;
    	}
	close $fh;

	return \@rows if $read;

	$self->rows = \@rows;
};

function combine => sub {
	my ($self, $file, $primary) = @_;
	
	my $rows = $self->read($file, 1);

	ROW:
	for my $row (@{$rows}) {
		for my $r (@{$self->rows}) {
			if ($r->get_col($primary)->value =~ $row->get_col($primary)->value) {
				for (@{$row->columns}) {
					$r->get_col($_->header->index)->value = $_->value;
				}
				next ROW;
			}
		}
		push @{$self->rows}, $row;
	}
};

function write => sub {
	my ($self, $file) = @_;
	$file ||= $self->file;
	my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
	open my $fh, ">:encoding(utf8)", $file or die "${file}: $!";
        my @headers = map {
		$_->label || $_->name
	} @{$self->headers};
	push @headers, 'SALUS';
        $csv->say($fh, \@headers);
	for my $row (@{$self->rows}) {
		my $row_array = $row->as_array;
		$csv->combine(@{$row_array});
		my $row_hmac = $self->hmac($csv->string());
		push @{$row_array}, $row_hmac;
		$csv->say($fh, $row_array);
	}
	close $fh;
	open $fh, "<:encoding(utf8)", $file or die "${file}: $!";
	my $data = do { local $/; <$fh> };
	close $fh;
	my $file_hmac = $self->hmac($data);
	open my $gfh, ">>:encoding(utf8)", $file or die "${file}: $!";
	seek $gfh, 0, 2;
	print $gfh $file_hmac . "\n";
	close $gfh;
};

function add_row => sub {
	my ($self, $columns) = @_;
	my @cols;
	for (my $i = 0; $i < scalar @{$columns}; $i++) {
		push @cols, Salus::Row::Column->new({
			header => $self->headers->[$i],
			value => $columns->[$i]
		});
	}
	push @{$self->rows}, Salus::Row->new(
		columns => \@cols
	);
};

function add_rows => sub {
	my ($self, $rows) = @_;
	for my $columns (@{$rows}) {
		my @cols;
		for (my $i = 0; $i < scalar @{$columns}; $i++) {
			push @cols, Salus::Row::Column->new({
				header => $self->headers->[$i],
				value => $columns->[$i]
			});
		}
		push @{$self->rows}, Salus::Row->new(
			columns => \@cols
		);
	}
};

function add_row_hash => sub {
	my ($self, $columns) = (shift, ref $_[0] ? $_[0] : {@_});
	my @cols;
	for my $header (@{$self->headers}) {
		push @cols, Salus::Row::Column->new({
			header => $header,
			value => $columns->{$header->label} || $columns->{$header->name}
		});
	}
	push @{$self->rows}, Salus::Row->new(
		columns => \@cols
	);
};

function get_row => sub {
	my ($self, $row) = @_;
	return $self->rows->[$row];
};

function get_row_col => sub {
	my ($self, $row, $col) = @_;
	$self->get_row($row)->get_col($col);
};

function set_row => sub {
	my ($self, $row, $cols) = @_;
	$row = $self->get_row($row);
	for (my $i = 0; $i < scalar @{$cols}; $i++) {
		$row->set_col($i, $cols->[$i] // "");
	}
};

function set_row_col => sub {
	my ($self, $row, $col, $value) = @_;
	$self->get_row($row)->set_col($col, $value);
};

function delete_row => sub {
	my ($self, $row) = @_;
	splice @{ $self->rows }, $row, 1;
};

function delete_row_col => sub {
	my ($self, $row, $col) = @_;
	$self->get_row($row)->delete_col($col);
};

function sort => sub {
	my ($self, $col, $order, $return) = @_;
	$col = $self->find_column_index($col);
	my @rows = $order eq 'asc'
		? sort { $a->get_col($col)->value cmp $b->get_col($col)->value } @{$self->rows}
		: sort { $b->get_col($col)->value cmp $a->get_col($col)->value } @{$self->rows};
	$self->rows = \@rows unless $return;
	return \@rows;
};

function search => sub {
	my ($self, $col, $search) = @_;
	$col = $self->find_column_index($col);
	my ($i, @indexes) = (0);
	my @rows = grep {
		if ( $_->get_col($col)->value =~ m/$search/i ) {
			push @indexes, $i++;
			return $_;
		}
		$i++;
		return ();
	} @{$self->rows};
	return (\@rows, \@indexes);
};

function find => sub {
	my ($self, $col, $search) = @_;
	$col = $self->find_column_index($col);
	my ($i, $found) = (0, undef);
	for ( @{$self->rows} ) {
		if ($_->get_col($col)->value =~ m/$search/i) {
			$found = $i;
			last;
		}
		$i++;
	}
	return $found;
};

function find_column_index => sub {
	my ($self, $col) = @_;
	if ($col !~ m/^\d+$/) {
		for (@{$self->headers}) {
			if ($_->name =~ m/^($col)$/) {
				$col = $_->index;
			}
		}
	}
	return $col;
};

function sum => sub {
	my ($self, $col) = @_;
	$col = $self->find_column_index($col);
	my $sum = 0;
	for (@{$self->rows}) {
		my $c = $_->get_col($col);
		if ($c->value !~ m/^\d+$/) {
			die "Cannot sum column as it has non numeric values";
		}
		$sum += $c->value;
	}
	return $sum;
};

function mean => sub {
	my ($self, $col) = @_;
	my $sum = $self->sum($col);
	return $sum / scalar @{$self->rows};
};

function median => sub {
	my ($self, $col, $as_row) = @_;
	$col = $self->find_column_index($col);
	my $rows = $self->sort($col, 'asc', 1);
	my $median = int(scalar @{$rows} / 2);
	if ($median % 2 != 0) {
		$median += 1;
	}
	return $as_row ? $rows->[$median - 1] : $rows->[$median - 1]->get_col($col)->value;
};

function mode => sub {
	my ($self, $col) = @_;
	$col = $self->find_column_index($col);
	my %map;
	$map{$_->get_col($col)->value}++ for (@{$self->rows});
	my ($key, $mode) = ('', 0);
	for my $k (keys %map) {
		if ($map{$k} > $mode) {
			$key = $k;
			$mode = $map{$k};
		}
	}
	return ($key, $mode);
};

function min => sub {
	my ($self, $col, $as_row) = @_;
	$col = $self->find_column_index($col);
	my $rows = $self->sort($col, 'asc', 1);
	return $as_row ? $rows->[0] : $rows->[0]->get_col($col)->value;
};

function max => sub {
	my ($self, $col, $as_row) = @_;
	$col = $self->find_column_index($col);
	my $rows = $self->sort($col, 'desc', 1);
	return $as_row ? $rows->[0] : $rows->[0]->get_col($col)->value;
};

function headers_as_array => sub {
	my ($self) = @_;
	my @array = map {
		$_->{label} || $_->{name}
	} @{$self->headers};
	return \@array;
};

function headers_stringify => sub {
	my ($self) = @_;
	my @array = map {
		$_->{label} ? sprintf("%s (%s) (%s)", $_->{label}, $_->{name}, $_->{index}) : sptrintf("%s (%s)", $_->{name}, $_->{index})
	} @{$self->headers};
	return \@array;
};

function diff_files => sub {
	my ($self, $file1, $file2) = @_;
	return Text::Diff::diff $file1, $file2, { STYLE => "Context" };
};

1;

__END__


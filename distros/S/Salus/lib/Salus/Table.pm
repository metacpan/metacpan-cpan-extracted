package Salus::Table;
use strict; use warnings;
use Rope;
use Rope::Autoload;
use Text::CSV_XS qw/csv/;
use Types::Standard qw/Str ArrayRef Bool/; 
use Salus::Row;
use Salus::Row::Column;
use Digest::SHA qw/hmac_sha256_hex/;

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

function total_rows => sub {
	return scalar @{$_[0]->rows};
};

function hmac => sub {
	my ($self, $data) = @_;
	return hmac_sha256_hex($data, $self->secret ? $self->secret : ());
};

function read => sub {
	my ($self, $file) = @_;
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
	$self->rows = \@rows;
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

1;

package ODS::Storage::File;

use YAOO;
use Cwd qw/getcwd/;

extends 'ODS::Storage::Base';

use ODS::Utils qw/move error/;

auto_build;

has file_handle => isa(fh);

has file => isa(string), coerce(sub {
	my ($self, $value) = @_;
	my $path = getcwd;
	$value =~ s/^\///;
	return sprintf("%s/%s.%s", $path, $value, $self->file_suffix);
}), trigger(sub {
	my ($self, $value) = @_;
	$value .= '.tmp';
	$self->save_file($value);
});

has save_file => isa(string);

sub all {
	my ($self) = @_;
	
	my $data = $self->into_rows($self->read_file());

	return $data;
}

sub create {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $data = $self->into_rows(\%params, 1);

	$data->validate();

	push @{ $self->table->rows }, $data;

	$data = $self->into_storage(1);

	$self->write_file( $data );

	$self->table;
}

sub search {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $data = $self->table->rows ? ODS::Iterator->new(table => $self->table) : $self->all;
	
	# this only works for JSON and YAML, CSS and JSONL we can stream/read rows/lines instead of reading/loading 
	# all into memory.
	my $select = $data->filter(sub {
		my $row = shift;
		my $select = 1;
		for my $key ( keys %params ) {
			if ( $params{$key} ne $row->{$key} ) {
				$select = undef;
				last;
			}
		}
		$select;
	});

	my $table = $self->table->clone();
	$table->rows($select);
	my $table = $self->table->clone();
	$table->rows($select);
	ODS::Iterator->new(table => $table);
}

sub find {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $data = $self->table->rows ? ODS::Iterator->new(table => $self->table) : $self->all;
	
	# this only works for JSON and YAML, CSS and JSONL we can stream/read rows/lines instead of reading/loading 
	# all into memory.
	my $select = $data->find(sub {
		my $row = shift;
		my $select = 1;
		for my $key ( keys %params ) {
			if ( $params{$key} ne $row->{$key} ) {
				$select = undef;
				last;
			}
		}
		$select;
	});

	return $select;
}

sub update {
	my ($self, $update, %params) = (shift, pop, @_);

	my $find = $self->find(%params);

	croak sprintf "No row found for search params %s", Dumper \%params
		unless $find;

	$find->validate($update);

	$self->update_row();
}

sub update_row {
	my ($self) = @_;

	my $data = $self->into_storage(1);

	$self->write_file( $data );

	$self->table;
}

sub delete {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $data = $self->table->rows ?  ODS::Iterator->new(table => $self->table) : $self->all;
	
	my $index = $data->find_index(sub {
		my $row = shift;
		my $select = 1;
		for my $key ( keys %params ) {
			if ( $params{$key} ne $row->{$key} ) {
				$select = undef;
				last;
			}
		}
		$select;
	});
	
	$data->splice($index, 1);

	$data = $self->into_storage(1);

	$self->write_file( $data );

	$self->table;
}

sub delete_row {
	my ($self, $r) = @_;

	my $data = ODS::Iterator->new(table => $self->table);

	my $keyfield = $data->table->keyfield;

	my $index;
	if ($keyfield) {
		$index = $data->find_index(sub {
			$_[0]->{$keyfield} eq $r->$keyfield;
		});
	} else {
		$index = $data->find_index(sub {
			my $row = shift;
			my $select = 1;
			for my $key ( keys %{ $row->columns } ) {
				if ( $r->$key ne $row->{$key} ) {
					$select = undef;
					last;
				}
			}
			$select;
		});
	}

	$data->splice($index, 1);

	$data = $self->into_storage(1);

	$self->write_file( $data );

	$self->table;
}


# methods very much specific to files

sub open_file {
	my ($self) = @_;
	open my $fh, '<:encoding(UTF-8)', $self->file or die "Cannot open file for reading: $!";
	$self->file_handle($fh);
	return $fh;
}

sub open_write_file {
	my ($self) = @_;
	open my $fh, '>:encoding(UTF-8)', $self->save_file  or die "Cannot open file for writing: $!";
	return $fh;
}

sub seek_file {
	my ($self, @args) = @_;
	@args = (0, 0) if (!scalar @args);
	seek $self->file_handle, shift @args, shift @args;
}

sub read_file {
	my ($self) = @_;
	my $fh = $self->open_file;
	my $data = do { local $/; <$fh> };
	return $data;
}

sub write_file {
	my ($self, $data) = @_;
	my $fh = $self->open_write_file;
	print $fh $data;
	$self->close_file($fh);
	$self->close_file($self->file_handle);
	move($self->save_file, $self->file);
	unlink $self->save_file;
}

sub close_file {
	close $_[1];
}

1;

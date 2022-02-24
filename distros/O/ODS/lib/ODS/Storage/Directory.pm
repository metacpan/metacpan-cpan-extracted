package ODS::Storage::Directory;

use YAOO;
use Cwd qw/getcwd/;
use Parallel::ForkManager;

extends 'ODS::Storage::Base';

use ODS::Utils qw/load move unique_class_name error write_directory/;

auto_build;

has file_handle => isa(fh);

has directory => isa(string);

has cache_directory => isa(string);

has remove_regex => isa(string("\'\"\."));

sub all {
	my ($self, %params) = @_;

	$params{type} ||= 'all';
	$params{sort} ||= $self->table->keyfield;
	$params{sort_direction} ||= 'asc';

	my ($data, $from_cache) = $self->into_rows($self->cache_or_all(%params));

	return $data;
}

sub create {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $file = $params{__custom_file_name} || sprintf '%s_%s.%s', time, unique_class_name, $self->serialize_class->file_suffix;

	$params{__file} = $file;

	$file .= '.tmp';

	my $data = $self->into_rows(\%params, 1);

	$data->validate();

	if ($self->table->rows) {
		push @{ $self->table->rows }, $data;
	} else {
		$self->table->rows(ref($data || "") eq 'ARRAY' ? $data : [$data]);
	}

	$data = $self->into_storage($data);

	$self->write_file(sprintf("%s/%s", $self->directory, $file), $data);

	$self->cache_clear();

	$self->table;
}

sub search {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $cache_prefix = $self->cache_prefix('search', %params);

	my ($data, $from_cache) = $self->cache_or_filter($cache_prefix, %params);

	if (ref $data eq 'ARRAY' && ref $data->[0] eq 'HASH') {
		$data = [ map { $self->into_rows($_) } @{ $self->into_rows($data) } ];
	}

	my $table = $self->table->clone();
	$table->rows($data);
	return ODS::Iterator->new(table => $table);
}

sub find {
	my ($self, %params) = (shift, @_ > 1 ? @_ : %{ $_[0] });

	my $cache_prefix = $self->cache_prefix('find', %params);

	my ($data, $from_cache) = $self->cache_or_find($cache_prefix, %params);

	if (ref $data eq 'HASH') {
		$data = $self->into_rows($data);
	}

	return $data;
}

sub update {
	my ($self, $update, %params) = (shift, pop, @_);

	my $find = $self->find(%params);

	croak sprintf "No row found for search params %s", Dumper \%params
		unless $find;

	$find->validate($update);

	$self->update_row($find);
}

sub update_row {
	my ($self, $row) = @_;

	my $data = $self->into_storage($row);

	my $file = $row->__custom_file_name || $row->__file;

	$self->write_file(sprintf("%s/%s", $self->directory, $file), $data);

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

	my $delete = $data->splice($index, 1);

	my $file = $delete->__file;

	$self->unlink_file(sprintf("%s/%s", $self->directory, $file));

	$self->cache_clear($delete);

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

	my $delete = $data->splice($index, 1);

	my $file = $delete->__file;

	$self->unlink_file(sprintf("%s/%s", $self->directory, $file));

	$self->cache_clear($delete);

	$self->table;
}

sub parse_data_format {
	my ($self, $data) = @_;
	return $self->serialize_class->parse($data);
}

sub stringify_data_format {
	my ($self, $data) = @_;
	return $self->serialize_class->stringify($data);
}

# methods very much specific to files

sub directory_files_last_updated {
	my ($self) = @_;
	my $files = $self->read_directory($self->directory);
	(my $last_update = $files->[-1]) =~ s/(\d+).*/$1/;
	return ($files, $last_update);
}

sub cache_write {
	my ($self, $type, $data) = @_;
	my $file = sprintf "%s/%s__%s.%s.tmp", $self->cache_directory, $type, time, $self->serialize_class->file_suffix;
	$self->write_file($file, $data);
}

sub cache_clear {
	my ($self, $row) = @_;
	my $files = $self->read_directory($self->cache_directory);
	for (@{$files}) {
		my %file_params = $self->cache_parse_filename($_);
		my $clear = 1;
		if (scalar keys %file_params) {
			PARAM:
			for my $key ( keys %file_params ) {
				next PARAM if $key =~ m/^__/;
				if (!$row || $row->$key ne $file_params{$key}) {
					$clear = 0;
					last PARAM;
				}
			}
		}
		$self->unlink_file(sprintf("%s/%s", $self->cache_directory, $_))
			if $clear;
	}
}

sub cache_parse_filename {
	my ($self, $name) = @_;
	my %file;
	return %file unless $name =~ s/^find__//;
	my @parts = split "__", $name;
	($file{__create_time} = pop @parts) =~ s/\.\w+$//;
	for (@parts) {
		my ($key, $value) = split "_", $_;
		$file{$key} = $value;
	}
	return %file;
}


sub cache_prefix {
	my ($self, $type, %args) = @_;

	my $regex = $self->remove_regex;
	for my $key ( keys %args ) {
		(my $value = $args{$key}) =~ s/$regex//g;
		$type .= sprintf('__%s_%s', $key, $value);
	}

	return $type;
}

sub cache_file {
	my ($self, $type) = @_;

	my @cache_file = grep {
		$_ =~ m/^$type/;
	} @{ $self->read_directory($self->cache_directory) };

	return scalar @cache_file ? sprintf( "%s/%s", $self->cache_directory, $cache_file[0]) : undef;
}

sub cache_or_all {
	my ($self, %args) = @_;

	my $type = delete $args{type};

	my $file_prefix = $self->cache_prefix($type, %args);

	my ($files, $last_update) = $self->directory_files_last_updated();

	my $cache_file = $self->cache_file($file_prefix);

	if ($cache_file) {
		return ($self->serialize_class->parse(
			$self->read_file($cache_file)
		), 1);
	}

	my $fm = Parallel::ForkManager->new(5000);

	my @data;
	$fm->run_on_finish(sub {
		 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;

		 push @data, $data_structure_reference;

	});

	READ_FILE:
	for my $file (@{$files}) {
		my $pid = $fm->start and next READ_FILE;

		my $d = $self->serialize_class->parse(
			$self->read_file(sprintf("%s/%s", $self->directory, $file))
		);

		$d->{__file} = $file;
		if ($file !~ m/^\d{9}\d+/) {
			$d->{__custom_file_name} = $file;
		}


		$fm->finish(0, $d);
	}

	$fm->wait_all_children;

	if ($args{sort_direction} eq 'asc') {
		@data = sort { $a->{$args{sort}} cmp $b->{$args{sort}} } @data;
	} else {
		@data = sort { $b->{$args{sort}} <=> $a->{$args{sort}} } @data;
	}
	$self->cache_write($file_prefix, $self->serialize_class->stringify(\@data));

	return \@data;
}

sub cache_or_filter {
	my ($self, $type, %params) = @_;

	my ($files, $last_update) = $self->directory_files_last_updated();

	my $cache_file = $self->cache_file($type);

	if ($cache_file) {
		return $self->serialize_class->parse(
			$self->read_file($cache_file)
		);
	}

	my $data = $self->table->rows ? ODS::Iterator->new(table => $self->table) : $self->all();

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

	$self->cache_write($type, $self->serialize_class->stringify([ map { $_->as_hash } @{$select}]));

	return $select;
}

sub cache_or_find {
	my ($self, $type, %params) = @_;

	my ($files, $last_update) = $self->directory_files_last_updated();

	my $cache_file = $self->cache_file($type);

	if ($cache_file) {
		return $self->serialize_class->parse(
			$self->read_file($cache_file)
		);
	}

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

	$self->cache_write($type, $self->serialize_class->stringify($select->as_hash))
		if ($select);

	return $select;
}

sub open_file {
	my ($self, $file) = @_;
	open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open file $file for reading: $!";
	return $fh;
}

sub open_write_file {
	my ($self, $file) = @_;
	write_directory($file, 1);
	open my $fh, '>:encoding(UTF-8)', $file  or die "Cannot open file $file for writing: $!";
	return $fh;
}

sub seek_file {
	my ($self, @args) = @_;
	@args = (0, 0) if (!scalar @args);
	seek $self->file_handle, shift @args, shift @args;
}

sub read_file {
	my ($self, $file) = @_;
	my $fh = $self->open_file($file);
	my $data = do { local $/; <$fh> };
	return $data;
}

sub read_directory {
	my ($self, $directory) = @_;
	write_directory($directory);
	opendir(my $dh, $directory) || die "Can't opendir $directory: $!";
	my @files = sort { $a cmp $b } grep { $_ !~ m/^\.+$/ } readdir($dh);
	closedir $dh;
	return \@files;
}

sub write_file {
	my ($self, $file, $data) = @_;
	my $fh = $self->open_write_file($file);
	print $fh $data;
	$self->close_file($fh);
	(my $real = $file) =~ s/\.tmp$//;
	move($file, $real);
}

sub unlink_file {
	my ($self, $file) = @_;
	unlink $file;
}

sub close_file {
	close $_[1];
}

1;

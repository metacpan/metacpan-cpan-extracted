package ODS::Table::Generate;
use strict;
use warnings;
use YAOO;

use ODS::Utils qw/load valid_email valid_phone file_dir/;

auto_build;

has serializer => isa(object), required, coerce(sub {
	my ($self, $value) = @_;
	my $module = 'ODS::Serialize::' . $value;
	load $module;
	$module->new;
});

has table_class => isa(string);

has table_base_class => isa(string);

has in_directory => isa(string);

has out_directory => isa(string), required;

has file => isa(string);

has table_from_file_name => isa(boolean);

has build_objects => isa(boolean);

has keyfield => isa(string);

has column_defaults => isa(ordered_hash(
	type => undef,
	mandatory => \0,
	no_render => \0,
	sortable => \0,
	filterable => \0,
	field => undef,
));

has array_defaults => isa(ordered_hash(
	min_length => \0,
	max_length => undef
));

has boolean_defaults => isa(ordered_hash());

has email_defaults => isa(ordered_hash());

has epoch_defaults => isa(ordered_hash());

has float_defaults => isa(ordered_hash(
	precision => undef,
	number => \1
));

has hash_defaults => isa(ordered_hash(
	required_keys => undef
));

has integer_defaults => isa(ordered_hash(
	auto_increment => \0
));

has object_defaults => isa(ordered_hash(
	object_class => undef
));

has phone_defaults => isa(ordered_hash);

has string_defaults => isa(ordered_hash);

has build_resultset_class => isa(boolean(1));

has build_row_class => isa(boolean(1));

sub generate {
	my ($self) = @_;

# TODO read in existing table spec, parse the file and merge so that it doesn't just overwrite custom column
# definitions.

	my $files = $self->read_files();

	for my $file ( keys %{ $files } ) {
		my $table_class = $self->generate_table($file, $files->{$file});
		$self->generate_resultset($table_class) if $self->build_resultset_class;
		$self->generate_row($table_class) if $self->build_row_class;
	}
}

sub generate_resultset {
	my ($self, $class) = @_;

	$class =~ s/Table/ResultSet/;

	my $resultset = qq|package ${class};

use YAOO;

extends 'ODS::Table::ResultSet';

# insert custom sub routines/methods for the resultset here

1;

__END__|;

	write_file(sprintf("%s/%s.pm", $self->out_directory, join("/", split("::", $class))), $resultset);

	return $class;
}

sub generate_row {
	my ($self, $class) = @_;

	$class =~ s/Table/Row/;

	my $row = qq|package ${class};

use YAOO;

extends 'ODS::Table::Row';

# insert custom sub routines/methods for the row here

1;

__END__|;

	write_file(sprintf("%s/%s.pm", $self->out_directory, join("/", split("::", $class))), $row);

	return $class;
}

sub generate_table {
	my ($self, $file, $data) = @_;

	my $pkg = sprintf(
		"%sTable::%s",
		($self->table_base_class ? ($self->table_base_class . "::") : ""),
		ucfirst($file)
	);

	my $columns;
	for my $key (keys %{ $data }) {
		my $column = $self->generate_column(
			$self->column_detection($key, $data->{$key}),
			$key, $data->{$key}
		);
		$columns .= ($columns ? "\n\n" : "") . $column;
	}

	my $table = qq|package ${pkg};

use strict;
use warnings;

use ODS;

name "${file}";

options (

);

${columns}

1;

__END__|;

	write_file(sprintf("%s/%s.pm", $self->out_directory, join("/", split("::", $pkg))), $table);

	return $pkg;
}

sub read_files {
	my ($self) = @_;

	my @files;
	if ($self->in_directory) {
		@files = read_directory($self->in_directory);
	} else {
		push @files, $self->file;
	}

	my %data;
	for (@files) {
		my $file = sprintf "%s/%s", $self->in_directory, $_;
		open my $fh, '<', $file or die "Cannot open file: $file $!";
		my $dta = do { local $/; <$fh> };
		close $fh;
		my $name = [ split "\/", do { ($file =~ s/\.\S+//g); $file } ]->[-1];
		$data{$name} = $self->serializer->parse($dta);
	}

	return \%data;
}

sub column_detection {
	my ($self, $key, $data) = @_;

	my $ref = ref $data;
	if (! $ref) {
		if ($key =~ m/epoch|data|time/) {
			return 'epoch';
		} elsif ($data =~ m/true|false/) {
			return 'boolean';
		} elsif ($data =~ m/\d+\.\d+/) {
			return 'float';
		} elsif ($data =~ m/\d+/) {
			return 'integer';
		} elsif (valid_email($data)) {
			return 'email';
		} elsif (valid_phone($data)) {
			return 'phone';
		}  else {
			return 'string';
		}
	} elsif ($ref eq 'HASH') {
		return $self->build_objects ? 'object' : 'hash';
	} elsif ($ref eq 'ARRAY') {
		return 'array';
	} elsif ($ref eq 'SCALAR') {
		return 'boolean';
	} else {
		return 'object';
	}
}

sub generate_column {
	my ($self, $type, $key, $data) = @_;

	my $defaults = YAOO::deep_clone_ordered_hash($self->column_defaults());
	$defaults->{type} = sprintf ('"%s"', $type);
	my $column = sprintf '%s_defaults', $type;
	my $other_defaults = $self->$column();
	for (keys %{$other_defaults}) {
		$defaults->{$_} = $other_defaults->{$_};
	}

	my $column_attrs = '';
	$column_attrs .= ($column_attrs ? ",\n" : "") . sprintf(
		"\t%s => %s",
		$_,
		(ref($defaults->{$_}) || "") eq 'SCALAR'
			? to_boolean($defaults->{$_})
			: $defaults->{$_} || "undef"
	) for keys %{$defaults};

	my $col = qq|column $key => (
$column_attrs
);|;

	return $col;
}

sub to_boolean {
	!! ${$_[0]} ? 'true' : 'false'
}

1;

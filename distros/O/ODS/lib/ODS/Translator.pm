package ODS::Translator;

use YAOO;

auto_build;

use ODS::Utils qw/load/;

has [translation, into_translation, file] => isa(string);

has stub => isa(string('ODS::Storage'));

sub translate {
	my ($self) = @_;

	my $stub = 'ODS::Storage';
	
	my $original = load( sprintf "%s::%s", $self->stub, $self->translation );
	
	my $into = load(sprintf "%s::%s", $self->stub, $self->into_translation);

	if ($self->translation =~ m/^File/ && $self->into_translation =~ m/^File/) {
		$original = $original->new(
			file => $self->file
		);
		$into = $into->new(
			file => $self->file
		);

		my $data = $original->parse_data_format($original->read_file());
		
		$into->write_file($into->stringify_data_format($data));
	}

	return 1;
}

1;

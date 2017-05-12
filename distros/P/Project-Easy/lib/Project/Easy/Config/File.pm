package Project::Easy::Config::File;

use Class::Easy;

use base qw(IO::Easy::File);

use Project::Easy::Config;

sub deserialize {
	my $self = shift;
	my $expansion = shift;
	
	my $contents = $self->contents;
	if ($expansion and ref $expansion and ref $expansion eq 'HASH') {
		$contents = Project::Easy::Config::string_from_template (
			$contents,
			$expansion
		);
	}
	
	my $serializer = Project::Easy::Config->serializer ($self->extension);
	
	return $serializer->parse_string ($contents);
}

sub patch {
	my $self  = shift;
	my $patch = shift;
	
	my $structure = $self->deserialize;
	Project::Easy::Config::patch ($structure, $patch);
	
	$self->serialize ($structure);
}

sub serialize {
	my $self   = shift;
	my $struct = shift;
	
	my $serializer = Project::Easy::Config->serializer ($self->extension);
	
	$self->store ($serializer->dump_struct ($struct));
}

1;
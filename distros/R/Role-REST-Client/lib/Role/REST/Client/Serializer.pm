package Role::REST::Client::Serializer;
$Role::REST::Client::Serializer::VERSION = '0.23';
use Try::Tiny;
use Moo;
use Types::Standard qw(Enum InstanceOf);
use Data::Serializer::Raw;

has 'type' => (
	isa => Enum[qw{application/json application/xml application/yaml application/x-www-form-urlencoded text/javascript}],
	is  => 'rw',
	default => sub { 'application/json' },
);

has 'serializer' => (
	isa => InstanceOf['Data::Serializer::Raw'],
	is => 'ro',
	default => \&_set_serializer,
	lazy => 1,
);

our %modules = (
	'application/json' => {
		module => 'JSON',
	},
	'application/xml' => {
		module => 'XML::Simple',
	},
	'application/yaml' => {
		module => 'YAML',
	},
	'application/x-www-form-urlencoded' => {
		module => 'FORM',
	},
	'text/javascript' => {
	        module => 'JSON',	
	},
);

sub _set_serializer {
	my $self = shift;
	return unless $modules{$self->type};

	my $module = $modules{$self->type}{module};
	return $module if $module eq 'FORM';

	return Data::Serializer::Raw->new(
		serializer => $module,
	);
}

sub content_type {
	my ($self) = @_;
	return $self->type;
}

sub serialize {
	my ($self, $data) = @_;
	return unless $self->serializer;

	my $result;
	try {
		$result = $self->serializer->serialize($data)
	} catch {
		warn "Couldn't serialize data with " . $self->type . ": $_";
	};

	return $result;
}

sub deserialize {
	my ($self, $data) = @_;
	return unless $self->serializer;

	my $result;
	try {
		$result = $self->serializer->deserialize($data);
	} catch {
        use Data::Dumper 'Dumper';
        $Data::Dumper::Maxdepth = 4;
        warn 'Data was ' . Dumper([ $data ]), ' ';
		warn "Couldn't deserialize data with " . $self->type . ": $_";
	};

	return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::REST::Client::Serializer

=head1 VERSION

version 0.23

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

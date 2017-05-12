package Padre::Plugin::Moose::Role::HasClassMembers;

use Moose::Role;

our $VERSION = '0.21';

has 'attributes' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'subtypes'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'methods'    => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub to_class_members_code {
	my $self    = shift;
	my $options = shift;

	my $code = '';

	# Generate attributes
	$code .= "\n" if scalar @{ $self->attributes };
	for my $attribute ( @{ $self->attributes } ) {
		$code .= $attribute->generate_code($options);
	}

	# Generate subtypes
	$code .= "\n" if scalar @{ $self->subtypes };
	for my $subtype ( @{ $self->subtypes } ) {
		$code .= $subtype->generate_code($options);
	}

	# Generate methods
	$code .= "\n" if scalar @{ $self->methods };
	for my $method ( @{ $self->methods } ) {
		$code .= $method->generate_code($options);
	}

	return $code;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::HasClassMembers - Something that has attributes, subtypes and methods

=cut
